// Import FAP SpreadsheetML (.xls XML) student lists into enrollments.
// Preview by default; add --apply to write.
import { readFileSync } from 'node:fs';
import { basename } from 'node:path';
import { connect, parseArgs } from './lib.mjs';
import { FieldValue } from 'firebase-admin/firestore';

const args = parseArgs();
const files = args._;
if (!files.length) {
  throw new Error('Provide one or more .xls paths. Add --apply to commit.');
}

function decodeXml(value) {
  return value
    .replace(/<[^>]+>/g, '')
    .replace(/&#(\d+);/g, (_, code) => String.fromCodePoint(Number(code)))
    .replace(/&#x([0-9a-f]+);/gi, (_, code) => String.fromCodePoint(Number.parseInt(code, 16)))
    .replace(/&lt;/g, '<').replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"').replace(/&apos;/g, "'").replace(/&amp;/g, '&')
    .trim();
}

function parseFile(path) {
  const name = basename(path);
  const fileMatch = /^(SE\d+)_([A-Z]{2,5}\d{3})_/i.exec(name);
  if (!fileMatch) throw new Error(`Cannot derive class code from ${name}`);
  const [, groupCode, subjectCode] = fileMatch.map((part) => part.toUpperCase());
  const classCode = `${subjectCode}_${groupCode}`;
  const xml = readFileSync(path, 'utf8').replace(/^\uFEFF/, '');
  const rows = [...xml.matchAll(/<ss:Row\b[^>]*>([\s\S]*?)<\/ss:Row>/gi)]
    .map((row) => [...row[1].matchAll(/<ss:Cell\b[^>]*>([\s\S]*?)<\/ss:Cell>/gi)]
      .map((cell) => {
        const data = /<ss:Data\b[^>]*>([\s\S]*?)<\/ss:Data>/i.exec(cell[1]);
        return data ? decodeXml(data[1]) : '';
      }));
  if (rows.length < 2) throw new Error(`No student rows in ${name}`);
  const headers = rows[0];
  const index = (header) => {
    const value = headers.indexOf(header);
    if (value < 0) throw new Error(`Missing ${header} in ${name}`);
    return value;
  };
  const classIndex = index('Class');
  const rollIndex = index('RollNumber');
  const emailIndex = index('Email');
  const memberIndex = index('MemberCode');
  const nameIndex = index('FullName');
  const students = rows.slice(1).map((cells, rowIndex) => ({
    sourceRow: rowIndex + 2,
    groupCode: cells[classIndex]?.trim().toUpperCase() ?? '',
    rollNumber: cells[rollIndex]?.trim().toUpperCase() ?? '',
    email: cells[emailIndex]?.trim().toLowerCase() ?? '',
    memberCode: cells[memberIndex]?.trim() ?? '',
    fullName: cells[nameIndex]?.trim() ?? '',
  }));
  for (const student of students) {
    if (student.groupCode !== groupCode || !student.rollNumber ||
        !student.email || !student.fullName) {
      throw new Error(`Invalid row ${student.sourceRow} in ${name}`);
    }
  }
  if (new Set(students.map((student) => student.rollNumber)).size !== students.length) {
    throw new Error(`Duplicate RollNumber in ${name}`);
  }
  return { name, classCode, subjectCode, groupCode, students };
}

const imports = files.map(parseFile);
if (new Set(imports.map((item) => item.classCode)).size !== imports.length) {
  throw new Error('Each input file must target a different class.');
}

const { db, projectId } = connect(args);
const preview = [];
for (const item of imports) {
  const classDoc = await db.collection('classes').doc(item.classCode).get();
  if (!classDoc.exists) throw new Error(`Class not found: ${item.classCode}`);
  const existing = await db.collection('enrollments')
    .where('classCode', '==', item.classCode).get();
  const incoming = new Set(item.students.map((student) => student.rollNumber));
  preview.push({
    file: item.name,
    classCode: item.classCode,
    teacherMemberCode: classDoc.data().teacherMemberCode ?? '',
    inputStudents: item.students.length,
    existingEnrollments: existing.size,
    newStudents: item.students.filter((student) =>
      !existing.docs.some((doc) => doc.data().rollNumber === student.rollNumber)).length,
    existingStudentsNotInFile: existing.docs.filter((doc) =>
      !incoming.has(String(doc.data().rollNumber ?? '').toUpperCase())).length,
  });
}
console.log(JSON.stringify({ projectId, apply: args.apply === true, classes: preview }, null, 2));

if (args.apply !== true) {
  console.log('Preview only. Add --apply to commit.');
  process.exit(0);
}

for (const item of imports) {
  const classRef = db.collection('classes').doc(item.classCode);
  const classDoc = await classRef.get();
  const teacherMemberCode = String(classDoc.data().teacherMemberCode ?? '');
  const existing = await db.collection('enrollments')
    .where('classCode', '==', item.classCode).get();
  const finalRollNumbers = new Set([
    ...existing.docs.map((doc) => String(doc.data().rollNumber ?? '').toUpperCase()),
    ...item.students.map((student) => student.rollNumber),
  ].filter(Boolean));
  const batch = db.batch();
  for (const student of item.students) {
    const id = `${item.classCode}_${student.rollNumber}`;
    batch.set(db.collection('enrollments').doc(id), {
      classCode: item.classCode,
      rollNumber: student.rollNumber,
      email: student.email,
      memberCode: student.memberCode,
      fullName: student.fullName,
      teacherMemberCode,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  }
  batch.update(classRef, {
    studentCount: finalRollNumbers.size,
    updatedAt: FieldValue.serverTimestamp(),
  });
  await batch.commit();
  console.log(`Imported ${item.students.length} students into ${item.classCode}.`);
}
