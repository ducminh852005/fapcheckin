// Prepare one staff account and release the classes visible in the OCR fixture.
// Preview by default. Add --apply to commit the changes.
//
// node scripts/prepare-ocr-test-account.mjs \
//   --email letrananhkhoa942005@gmail.com --member-code GV942005 [--apply]
import { connect, parseArgs } from './lib.mjs';
import { FieldValue } from 'firebase-admin/firestore';

const OCR_CLASS_CODES = [
  'PRN232_SE1917',
  'PRM393_SE1913',
  'PRM393_SE1917',
  'SWD392_SE1927',
  'PRN232_SE1920',
  'PRM393_SE1922',
  'PRN232_SE1919',
  'PRM393_SE1920',
  'PRM393_SE1928',
  'PRM393_SE1919',
];
const OCR_CLASS_DEFAULTS = {
  PRM393_SE1913: { subjectCode: 'PRM393', room: '604' },
  PRN232_SE1920: { subjectCode: 'PRN232', room: '606' },
  PRM393_SE1922: { subjectCode: 'PRM393', room: '604' },
  PRM393_SE1919: { subjectCode: 'PRM393', room: '602' },
};

const args = parseArgs();
const email = String(args.email ?? '').trim().toLowerCase();
const memberCode = String(args['member-code'] ?? '').trim().toUpperCase();
if (!email || !memberCode) {
  throw new Error('Required: --email <gmail> --member-code <code>');
}

const { db, auth, projectId } = connect(args);
let authUser = null;
try {
  authUser = await auth.getUserByEmail(email);
} catch (error) {
  if (error.code !== 'auth/user-not-found') throw error;
}

const classDocs = await Promise.all(
  OCR_CLASS_CODES.map((code) => db.collection('classes').doc(code).get()),
);
const missingClasses = classDocs.filter((doc) => !doc.exists).map((doc) => doc.id);
const existingClasses = classDocs.filter((doc) => doc.exists);

const enrollmentSnapshots = await Promise.all(
  OCR_CLASS_CODES.map((code) =>
    db.collection('enrollments').where('classCode', '==', code).get(),
  ),
);
const enrollmentDocs = enrollmentSnapshots.flatMap((snapshot) => snapshot.docs);

const preview = {
  projectId,
  apply: args.apply === true,
  account: {
    email,
    memberCode,
    authUid: authUser?.uid ?? null,
    authUserExists: authUser != null,
  },
  classes: existingClasses.map((doc) => ({
    classCode: doc.id,
    currentTeacherMemberCode: doc.data().teacherMemberCode ?? '',
  })),
  missingClasses,
  createMissing: args['create-missing'] === true,
  enrollmentsToRelease: enrollmentDocs.length,
};
console.log(JSON.stringify(preview, null, 2));

if (args.apply !== true) {
  console.log('Preview only. Add --apply to commit.');
  process.exit(0);
}
if (missingClasses.length && args['create-missing'] !== true) {
  throw new Error(
    `No changes made. Missing classes: ${missingClasses.join(', ')}. ` +
    'Add --create-missing to create OCR fixtures.',
  );
}

const writes = existingClasses.length + missingClasses.length +
  enrollmentDocs.length + 1 + (authUser ? 1 : 0);
if (writes > 500) {
  throw new Error(`No changes made. Atomic batch would contain ${writes} writes.`);
}

const batch = db.batch();
batch.set(db.collection('user_invites').doc(email), {
  role: 'staff',
  memberCode,
  fullName: authUser?.displayName?.trim() || 'Giảng viên kiểm thử OCR',
  rollNumber: '',
  phone: '',
  birthDate: '',
  department: '',
  division: '',
  jobTitle: '',
  employmentDate: '',
  contractType: '',
  updatedAt: FieldValue.serverTimestamp(),
});
if (authUser) {
  batch.set(db.collection('users').doc(authUser.uid), {
    memberCode,
    fullName: authUser.displayName?.trim() || 'Giảng viên kiểm thử OCR',
    email,
    role: 'staff',
    rollNumber: '',
    phone: '',
    birthDate: '',
    avatarPath: '',
    department: '',
    division: '',
    jobTitle: '',
    employmentDate: '',
    contractType: '',
    active: true,
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
}
for (const doc of existingClasses) {
  batch.update(doc.ref, { teacherMemberCode: '' });
}
for (const code of missingClasses) {
  const defaults = OCR_CLASS_DEFAULTS[code];
  if (!defaults) throw new Error(`Missing fixture defaults for ${code}`);
  batch.set(db.collection('classes').doc(code), {
    classCode: code,
    subjectCode: defaults.subjectCode,
    subjectName: defaults.subjectCode,
    room: defaults.room,
    slotCode: '',
    studentCount: 0,
    teacherMemberCode: '',
    createdAt: FieldValue.serverTimestamp(),
  });
}
for (const doc of enrollmentDocs) {
  batch.update(doc.ref, { teacherMemberCode: '' });
}
await batch.commit();

console.log(`Applied ${writes} writes. OCR test account and classes are ready.`);
