import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, setDoc, Timestamp } from 'firebase/firestore';

const here = dirname(fileURLToPath(import.meta.url));

export const PROJECT_ID = 'demo-fapcheckin';
export const SECRET = 'qr-secret-0123456789abcdef';
export const TEACHER_IP = '203.0.113.7';

export async function createEnv() {
  const [fsHost, fsPort] = (process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8085').split(':');
  const [stHost, stPort] = (process.env.FIREBASE_STORAGE_EMULATOR_HOST ?? '127.0.0.1:9199').split(':');
  return initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(join(here, '..', 'firestore.rules'), 'utf8'),
      host: fsHost,
      port: Number(fsPort),
    },
    storage: {
      rules: readFileSync(join(here, '..', 'storage.rules'), 'utf8'),
      host: stHost,
      port: Number(stPort),
    },
  });
}

/** Người dùng đã đăng nhập Google (email đã xác minh). */
export const ACCOUNTS = {
  admin: { uid: 'u-admin', email: 'admin@fpt.edu.vn' },
  t1: { uid: 'u-t1', email: 'gv001@fpt.edu.vn' },
  t2: { uid: 'u-t2', email: 'gv002@fpt.edu.vn' },
  s1: { uid: 'u-s1', email: 'se1001@fpt.edu.vn' },
  s2: { uid: 'u-s2', email: 'se1002@fpt.edu.vn' },
  s3: { uid: 'u-s3', email: 'se1003@fpt.edu.vn' },
  newbie: { uid: 'u-new', email: 'se9999@fpt.edu.vn' },
  stranger: { uid: 'u-stranger', email: 'stranger@gmail.com' },
};

export function as(env, key, extra = {}) {
  const a = ACCOUNTS[key];
  return env.authenticatedContext(a.uid, { email: a.email, email_verified: true, ...extra }).firestore();
}
export function asUnverified(env, key) {
  const a = ACCOUNTS[key];
  return env.authenticatedContext(a.uid, { email: a.email, email_verified: false }).firestore();
}
export function anon(env) {
  return env.unauthenticatedContext().firestore();
}

/** Dữ liệu nền dùng chung cho mọi test (ghi bằng quyền bỏ qua rules). */
export async function seed(env) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const put = (path, data) => setDoc(doc(db, path), data);

    await put('users/u-admin', { memberCode: 'AD01', fullName: 'Admin', email: ACCOUNTS.admin.email, role: 'admin', active: true });
    await put('users/u-t1', { memberCode: 'GV001', fullName: 'GV Một', email: ACCOUNTS.t1.email, role: 'staff', active: true });
    await put('users/u-t2', { memberCode: 'GV002', fullName: 'GV Hai', email: ACCOUNTS.t2.email, role: 'staff', active: true });
    await put('users/u-s1', { memberCode: 'SE1001', rollNumber: 'SE1001', fullName: 'SV Một', email: ACCOUNTS.s1.email, role: 'user', active: true });
    await put('users/u-s2', { memberCode: 'SE1002', rollNumber: 'SE1002', fullName: 'SV Hai', email: ACCOUNTS.s2.email, role: 'user', active: true });
    // s3: tài khoản đã bị khóa
    await put('users/u-s3', { memberCode: 'SE1003', rollNumber: 'SE1003', fullName: 'SV Ba', email: ACCOUNTS.s3.email, role: 'user', active: false });

    await put('user_invites/se9999@fpt.edu.vn', { role: 'user', memberCode: 'SE9999', rollNumber: 'SE9999', fullName: 'SV Mới' });
    await put('user_invites/gv009@fpt.edu.vn', { role: 'staff', memberCode: 'GV009', fullName: 'GV Mới' });

    await put('subjects/PRN232', { subjectName: 'Web API', credits: 3 });
    await put('timeSlots/A-1', { period: 'Morning', startTime: '07:00', endTime: '09:15' });
    await put('slots/A1', { timeSlotId: 'A-1', weekdays: [2, 5] });

    await put('classes/PRN232_SE1917', { subjectCode: 'PRN232', teacherMemberCode: 'GV001', slotCode: 'A1', room: '303' });
    await put('classes/SWD392_SE1801', { subjectCode: 'SWD392', teacherMemberCode: 'GV002', slotCode: 'A1', room: '101' });
    await put('classes/MAD101_SE1700', { subjectCode: 'MAD101', teacherMemberCode: '', slotCode: 'A1', room: '202' });

    await put('enrollments/PRN232_SE1917_SE1001', { classCode: 'PRN232_SE1917', rollNumber: 'SE1001', teacherMemberCode: 'GV001', fullName: 'SV Một' });
    // Enrollment legacy có ID tự sinh: roster vẫn đọc được theo field và GV
    // phải có thể điểm danh tay cho sinh viên này.
    await put('enrollments/legacy-random-enrollment', { classCode: 'PRN232_SE1917', rollNumber: 'SE1003', teacherMemberCode: 'GV001', fullName: 'SV Ba' });
    await put('enrollments/SWD392_SE1801_SE1002', { classCode: 'SWD392_SE1801', rollNumber: 'SE1002', teacherMemberCode: 'GV002', fullName: 'SV Hai' });
    await put('enrollments/MAD101_SE1700_SE1001', { classCode: 'MAD101_SE1700', rollNumber: 'SE1001', teacherMemberCode: '', fullName: 'SV Một' });

    const futureDeadline = Timestamp.fromMillis(Date.now() + 60 * 60 * 1000);
    const pastDeadline = Timestamp.fromMillis(Date.now() - 60 * 1000);
    const base = { classCode: 'PRN232_SE1917', teacherMemberCode: 'GV001', sessionDate: '2026-10-20', slotCode: 'A1', manualAttendanceDeadline: futureDeadline };
    await put('sessions/sess-open', { ...base, sessionStatus: 'open', qrSecret: SECRET, ipCheck: false, teacherIp: '' });
    await put('sessions/sess-ip', { ...base, sessionStatus: 'open', qrSecret: SECRET, ipCheck: true, teacherIp: TEACHER_IP });
    await put('sessions/sess-closed', { ...base, sessionStatus: 'closed', qrSecret: SECRET, ipCheck: false, teacherIp: '' });
    await put('sessions/sess-expired', { ...base, manualAttendanceDeadline: pastDeadline, sessionStatus: 'closed', qrSecret: SECRET, ipCheck: false, teacherIp: '' });
    await put('sessions/sess-other', { classCode: 'SWD392_SE1801', teacherMemberCode: 'GV002', sessionDate: '2026-10-20', slotCode: 'A1', manualAttendanceDeadline: futureDeadline, sessionStatus: 'open', qrSecret: SECRET, ipCheck: false, teacherIp: '' });

    await put('attendance_records/sess-closed_SE1001', {
      sessionId: 'sess-closed', rollNumber: 'SE1001', classCode: 'PRN232_SE1917', teacherMemberCode: 'GV001',
      status: 'Present', networkVerificationResult: 'Skipped', ipAddress: '', syncedToFap: false,
    });
    await put('attendance_records/sess-other_SE1002', {
      sessionId: 'sess-other', rollNumber: 'SE1002', classCode: 'SWD392_SE1801', teacherMemberCode: 'GV002',
      status: 'Present', networkVerificationResult: 'Skipped', ipAddress: '', syncedToFap: false,
    });

    await put('class_schedules/sch-1', { classCode: 'PRN232_SE1917', teacherMemberCode: 'GV001', scheduleDate: '2026-10-25', slotCode: 'A1', status: 'scheduled' });

    await put('requests/req-s1', { type: 'leave', authorUid: 'u-s1', authorMemberCode: 'SE1001', reason: 'Ốm', status: 'pending' });
    await put('requests/req-done', { type: 'leave', authorUid: 'u-s1', authorMemberCode: 'SE1001', reason: 'Ốm', status: 'approved' });

    await put('announcements/ann-all', { audience: 'all', title: 'Chung', body: 'x' });
    await put('announcements/ann-staff', { audience: 'staff', title: 'GV', body: 'x' });
    await put('announcements/ann-user', { audience: 'user', title: 'SV', body: 'x' });
  });
}
