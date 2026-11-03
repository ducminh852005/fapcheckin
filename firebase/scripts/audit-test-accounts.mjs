import { connect } from './lib.mjs';

const emails = process.argv.slice(2).map((email) => email.trim().toLowerCase());
if (!emails.length) throw new Error('Provide account emails.');

const { db, auth, projectId } = connect({});
const allClasses = await db.collection('classes').get();
const allClassCodes = new Set(allClasses.docs.map((doc) => doc.id));
const results = [];

for (const email of emails) {
  let authUser = null;
  try {
    authUser = await auth.getUserByEmail(email);
  } catch (error) {
    if (error.code !== 'auth/user-not-found') throw error;
  }
  const invite = await db.collection('user_invites').doc(email).get();
  const profile = authUser
    ? await db.collection('users').doc(authUser.uid).get()
    : null;
  const data = profile?.data() ?? {};
  const memberCode = String(data.memberCode ?? invite.data()?.memberCode ?? '');
  const rollNumber = String(data.rollNumber ?? invite.data()?.rollNumber ?? '').toUpperCase();
  const role = String(data.role ?? invite.data()?.role ?? '');

  let assignedClasses = [];
  if (memberCode) {
    const snap = await db.collection('classes')
      .where('teacherMemberCode', '==', memberCode).get();
    assignedClasses = snap.docs.map((doc) => doc.id).sort();
  }

  const enrollmentDocs = new Map();
  if (rollNumber) {
    const snap = await db.collection('enrollments')
      .where('rollNumber', '==', rollNumber).get();
    for (const doc of snap.docs) enrollmentDocs.set(doc.id, doc);
  }
  const emailSnap = await db.collection('enrollments')
    .where('email', '==', email).get();
  for (const doc of emailSnap.docs) enrollmentDocs.set(doc.id, doc);
  const enrolledClassCodes = [...new Set([...enrollmentDocs.values()]
    .map((doc) => String(doc.data().classCode ?? ''))
    .filter(Boolean))].sort();

  const optionalFields = [
    'phone', 'birthDate', 'avatarPath', 'department', 'division', 'jobTitle',
    'employmentDate', 'contractType',
  ];
  results.push({
    email,
    auth: {
      exists: authUser != null,
      uid: authUser?.uid ?? null,
      disabled: authUser?.disabled ?? null,
      emailVerified: authUser?.emailVerified ?? null,
      displayName: authUser?.displayName ?? '',
    },
    invite: invite.exists ? invite.data() : null,
    profile: profile?.exists ? {
      role,
      active: data.active !== false,
      memberCode,
      rollNumber,
      fullName: String(data.fullName ?? ''),
      optionalFields: Object.fromEntries(optionalFields.map((field) => [
        field,
        String(data[field] ?? ''),
      ])),
    } : null,
    assignedClasses,
    enrollments: {
      documentCount: enrollmentDocs.size,
      classCount: enrolledClassCodes.length,
      classCodes: enrolledClassCodes,
      missingFromAllClasses: [...allClassCodes]
        .filter((code) => !enrolledClassCodes.includes(code)).sort(),
      unknownClassCodes: enrolledClassCodes
        .filter((code) => !allClassCodes.has(code)).sort(),
    },
  });
}

console.log(JSON.stringify({ projectId, totalClasses: allClasses.size, accounts: results }, null, 2));
