const STUDENT_ROLES = new Set(['user', 'sv', 'student']);

/** Keep the check-in UI aligned with the legacy roles accepted by Firestore Rules. */
export function isStudentProfile(profile) {
  const role = String(profile?.role ?? '').trim().toLowerCase();
  const rollNumber = String(profile?.rollNumber ?? '').trim();
  return STUDENT_ROLES.has(role) && rollNumber.length > 0;
}
