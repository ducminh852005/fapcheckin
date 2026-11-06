// Configure the three requested test accounts atomically.
// Preview by default; add --apply to commit.
import { connect, parseArgs } from './lib.mjs';
import { FieldValue } from 'firebase-admin/firestore';

const args = parseArgs();
const cleanStaffEmail = 'letrananhkhoa942005@gmail.com';
const studentEmail = 'daocrisdevilgamer@gmail.com';
const qrStaffEmail = 'letrananhkhoa09042005@gmail.com';
const studentClasses = [
  'PRM393_SE1913', 'PRM393_SE1919', 'PRM393_SE1922', 'PRN232_SE1920',
];
const qrStaffClasses = [
  'PRM393_SE1917', 'PRM393_SE1920', 'PRM393_SE1928',
  'PRN232_SE1917', 'PRN232_SE1919', 'SWD392_SE1927',
];

const { db, auth, projectId } = connect(args);
async function account(email, expectedRole) {
  const authUser = await auth.getUserByEmail(email);
  const profile = await db.collection('users').doc(authUser.uid).get();
  if (!profile.exists) throw new Error(`Missing profile: ${email}`);
  const data = profile.data();
  if (data.role !== expectedRole || data.active === false) {
    throw new Error(`Invalid ${expectedRole} profile: ${email}`);
  }
  return { authUser, data };
}

const cleanStaff = await account(cleanStaffEmail, 'staff');
const student = await account(studentEmail, 'user');
const qrStaff = await account(qrStaffEmail, 'staff');

const oldEnrollmentSnaps = await Promise.all([
  'PRN232_SE1950', 'PRN232_SE1950_02',
].map((classCode) => db.collection('enrollments')
  .where('classCode', '==', classCode)
  .where('email', '==', cleanStaffEmail).get()));
const oldEnrollments = oldEnrollmentSnaps.flatMap((snap) => snap.docs);

const classDocs = new Map();
for (const code of [...studentClasses, ...qrStaffClasses]) {
  const doc = await db.collection('classes').doc(code).get();
  if (!doc.exists) throw new Error(`Missing class: ${code}`);
  classDocs.set(code, doc);
}
for (const code of qrStaffClasses) {
  const owner = String(classDocs.get(code).data().teacherMemberCode ?? '');
  if (owner && owner !== qrStaff.data.memberCode) {
    throw new Error(`Class ${code} belongs to ${owner}; no changes made.`);
  }
}

const studentRoll = String(student.data.rollNumber ?? '').toUpperCase();
if (!studentRoll) throw new Error(`Student ${studentEmail} has no rollNumber.`);
const qrEnrollmentSnaps = await Promise.all(qrStaffClasses.map((code) =>
  db.collection('enrollments').where('classCode', '==', code).get()));
const qrEnrollmentDocs = qrEnrollmentSnaps.flatMap((snap) => snap.docs);

console.log(JSON.stringify({
  projectId,
  apply: args.apply === true,
  deleteOldStaffEnrollments: oldEnrollments.map((doc) => ({
    id: doc.id,
    classCode: doc.data().classCode,
    rollNumber: doc.data().rollNumber,
  })),
  addStudent: { email: studentEmail, rollNumber: studentRoll, classes: studentClasses },
  assignQrStaff: {
    email: qrStaffEmail,
    memberCode: qrStaff.data.memberCode,
    classes: qrStaffClasses,
    enrollmentDocuments: qrEnrollmentDocs.length,
  },
}, null, 2));

if (args.apply !== true) {
  console.log('Preview only. Add --apply to commit.');
  process.exit(0);
}

const writes = oldEnrollments.length + studentClasses.length * 2 +
  qrStaffClasses.length + qrEnrollmentDocs.length;
if (writes > 500) throw new Error(`Atomic batch too large: ${writes}`);

const batch = db.batch();
for (const doc of oldEnrollments) batch.delete(doc.ref);

for (const code of studentClasses) {
  const classRef = db.collection('classes').doc(code);
  const existing = await db.collection('enrollments')
    .where('classCode', '==', code).get();
  const rolls = new Set(existing.docs
    .map((doc) => String(doc.data().rollNumber ?? '').toUpperCase()).filter(Boolean));
  rolls.add(studentRoll);
  batch.set(db.collection('enrollments').doc(`${code}_${studentRoll}`), {
    classCode: code,
    rollNumber: studentRoll,
    memberCode: String(student.data.memberCode ?? studentRoll),
    fullName: String(student.data.fullName ?? ''),
    email: studentEmail,
    teacherMemberCode: String(classDocs.get(code).data().teacherMemberCode ?? ''),
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  batch.update(classRef, {
    studentCount: rolls.size,
    updatedAt: FieldValue.serverTimestamp(),
  });
}

for (const code of qrStaffClasses) {
  batch.update(db.collection('classes').doc(code), {
    teacherMemberCode: qrStaff.data.memberCode,
    updatedAt: FieldValue.serverTimestamp(),
  });
}
for (const doc of qrEnrollmentDocs) {
  batch.update(doc.ref, {
    teacherMemberCode: qrStaff.data.memberCode,
    updatedAt: FieldValue.serverTimestamp(),
  });
}
await batch.commit();
console.log(`Applied ${writes} writes atomically.`);
