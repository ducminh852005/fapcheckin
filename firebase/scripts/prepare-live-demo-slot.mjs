// Create an idempotent real schedule entry for the requested live-session demo.
// Preview by default; add --apply to commit.
import { connect, parseArgs } from './lib.mjs';
import { FieldValue } from 'firebase-admin/firestore';

const args = parseArgs();
const teacherMemberCode = 'KhoaLTASE194176';
const classCode = 'PRN232_SE1917';
const scheduleDate = '2026-11-04';
const slotCode = 'A1';
const scheduleId = `demo_${teacherMemberCode}_${scheduleDate}_${slotCode}`;
const { db, projectId } = connect(args);

const classDoc = await db.collection('classes').doc(classCode).get();
if (!classDoc.exists) throw new Error(`Missing class ${classCode}`);
if (classDoc.data().teacherMemberCode !== teacherMemberCode) {
  throw new Error(`${classCode} is not assigned to ${teacherMemberCode}`);
}
const ref = db.collection('class_schedules').doc(scheduleId);
const existing = await ref.get();
const data = {
  scheduleId,
  requestId: `demo-${scheduleDate}-${slotCode}`,
  teacherMemberCode,
  classCode,
  scheduleDate,
  slotCode,
  room: String(classDoc.data().room ?? '602'),
  lessonType: 'workshop',
  teachingMethod: 'onCampus',
  note: 'Demo Live Session ca 1',
  status: 'scheduled',
};
console.log(JSON.stringify({ projectId, apply: args.apply === true,
  exists: existing.exists, document: data }, null, 2));
if (args.apply !== true) {
  console.log('Preview only. Add --apply to commit.');
  process.exit(0);
}
await ref.set({ ...data, createdAt: existing.data()?.createdAt ?? FieldValue.serverTimestamp(),
  updatedAt: FieldValue.serverTimestamp() }, { merge: true });
console.log(`Ready: ${scheduleId}`);
