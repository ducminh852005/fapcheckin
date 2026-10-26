// Migrate MỘT LẦN dữ liệu Firestore cũ (do Apps Script ghi) sang schema mới.
//
//   cũ                       ->  mới
//   users (GV/SV, id=memberCode) -> user_invites/{emailLower} (role staff/user)
//        (collection `users` được dùng lại cho schema mới, id=uid; bản ghi cũ nhận biết
//         bằng việc thiếu trường `active`. Thêm --purge-legacy-users để xóa chúng sau khi ghi invite.)
//   classSections + subjects ->  classes/{classCode}
//   enrollments              ->  enrollments  (+ teacherMemberCode, fullName, email)
//   classSchedules           ->  class_schedules
//   attendanceSessions       ->  sessions     (+ teacherMemberCode, ipCheck mặc định true nếu thiếu)
//   attendanceRecords        ->  attendance_records (+ classCode, teacherMemberCode; ISO string -> Timestamp)
//
// Collection cũ KHÔNG bị xóa/sửa; xóa tay sau khi kiểm tra (docs/deploy-firebase.md).
// Idempotent: id tài liệu xác định, chạy lại sẽ ghi đè đúng các tài liệu đó.
//
//   node scripts/migrate-legacy.mjs --dry-run            # chỉ thống kê + cảnh báo
//   node scripts/migrate-legacy.mjs                      # ghi thật
//   node scripts/migrate-legacy.mjs --only classes,sessions
//   thêm --emulator / --project <id> như các script khác
import { Timestamp } from 'firebase-admin/firestore';
import { connect, parseArgs, writeAll } from './lib.mjs';

const args = parseArgs();
const dryRun = !!args['dry-run'];
const only = typeof args.only === 'string' ? args.only.split(',') : null;
const { db, projectId } = connect(args);
const warnings = [];
const warn = (m) => warnings.push(m);

const text = (v) => (v == null ? '' : String(v).trim());
const stripInternal = (o) => Object.fromEntries(Object.entries(o).filter(([k]) => !k.startsWith('_')));
const ts = (v) => {
  if (v == null || v === '') return null;
  if (v instanceof Timestamp) return v;
  const d = new Date(v);
  return Number.isNaN(d.getTime()) ? null : Timestamp.fromDate(d);
};

function mapRole(raw) {
  const r = text(raw).toUpperCase();
  if (['GV', 'TEACHER', 'GIANG_VIEN', 'GIẢNG VIÊN', 'STAFF'].includes(r)) return 'staff';
  if (['SV', 'STUDENT', 'USER'].includes(r)) return 'user';
  if (r === 'ADMIN') return 'admin';
  return null;
}

async function readAll(name) {
  const snap = await db.collection(name).get();
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

const [allUsers, sections, subjects, enrollments, schedules, sessions, records] = await Promise.all(
  ['users', 'classSections', 'subjects', 'enrollments', 'classSchedules', 'attendanceSessions', 'attendanceRecords'].map(readAll),
);

// Chỉ coi là bản ghi cũ nếu chưa có trường `active` (schema mới luôn có).
const users = allUsers.filter((u) => u.active === undefined);

// --- user_invites ---------------------------------------------------------
const usersByRoll = new Map();
const invites = new Map();
for (const u of users) {
  if (u.rollNumber) usersByRoll.set(text(u.rollNumber), u);
  const email = text(u.email).toLowerCase();
  const role = mapRole(u.role);
  if (!email) { warn(`users/${u.id}: thiếu email, bỏ qua invite`); continue; }
  if (!role) { warn(`users/${u.id}: role không hợp lệ "${u.role}", bỏ qua`); continue; }
  if (invites.has(email)) { warn(`users/${u.id}: trùng email ${email}, giữ bản đầu`); continue; }
  const data = { role, memberCode: text(u.memberCode) || u.id, fullName: text(u.fullName), email };
  if (role === 'user' && u.rollNumber) data.rollNumber = text(u.rollNumber);
  invites.set(email, { id: email, data });
}

// --- classes --------------------------------------------------------------
const subjectByCode = new Map(subjects.map((s) => [s.id, s]));
const classByCode = new Map();
const classes = sections.map((c) => {
  const subjectCode = text(c.subjectCode) || text(c.classCode).split('_')[0];
  const subject = subjectByCode.get(subjectCode) ?? {};
  const data = {
    classCode: text(c.classCode) || c.id,
    subjectCode,
    subjectName: text(c.subjectName) || text(subject.subjectName),
    credits: Number(c.credits ?? subject.credits ?? 0) || 0,
    room: text(c.room),
    studentCount: Number(c.studentCount) || 0,
    teacherMemberCode: text(c.teacherMemberCode),
    slotCode: text(c.slotCode),
  };
  classByCode.set(data.classCode, data);
  return { id: data.classCode, data };
});

// --- enrollments ----------------------------------------------------------
const enrollDocs = enrollments.map((e) => {
  const classCode = text(e.classCode);
  const rollNumber = text(e.rollNumber);
  const cls = classByCode.get(classCode);
  if (!cls) warn(`enrollments/${e.id}: lớp ${classCode} không tồn tại`);
  const student = usersByRoll.get(rollNumber);
  if (!student) warn(`enrollments/${e.id}: không thấy SV ${rollNumber} trong users`);
  const data = {
    classCode,
    rollNumber,
    teacherMemberCode: cls?.teacherMemberCode ?? '',
    fullName: text(student?.fullName),
    email: text(student?.email).toLowerCase(),
  };
  if (e.enrollmentDate) data.enrollmentDate = text(e.enrollmentDate);
  return { id: `${classCode}_${rollNumber}`, data };
});

// --- class_schedules ------------------------------------------------------
const scheduleDocs = schedules.map((s) => {
  const data = stripInternal(s);
  delete data.id;
  data.teacherMemberCode = text(s.teacherMemberCode) || classByCode.get(text(s.classCode))?.teacherMemberCode || '';
  if (data.createdAt) data.createdAt = ts(data.createdAt) ?? data.createdAt;
  return { id: s.id, data };
});

// --- sessions -------------------------------------------------------------
const sessionById = new Map();
const sessionDocs = sessions.map((s) => {
  const data = stripInternal(s);
  delete data.id;
  const cls = classByCode.get(text(s.classCode));
  if (!cls) warn(`attendanceSessions/${s.id}: lớp ${s.classCode} không tồn tại`);
  data.teacherMemberCode = cls?.teacherMemberCode ?? '';
  // Phiên cũ không có ipCheck vẫn được kiểm tra IP như trước.
  data.ipCheck = s.ipCheck === undefined || s.ipCheck === '' ? true : s.ipCheck === true || String(s.ipCheck).toUpperCase() === 'TRUE';
  data.teacherIp = text(s.teacherIp);
  sessionById.set(s.id, data);
  return { id: s.id, data };
});

// --- attendance_records ---------------------------------------------------
const recordDocs = [];
for (const r of records) {
  const sess = sessionById.get(text(r.sessionId));
  if (!sess) { warn(`attendanceRecords/${r.id}: phiên ${r.sessionId} không tồn tại, bỏ qua`); continue; }
  const data = stripInternal(r);
  delete data.id;
  data.classCode = sess.classCode;
  data.teacherMemberCode = sess.teacherMemberCode;
  data.ipAddress = text(r.ipAddress);
  data.syncedToFap = r.syncedToFap === true || String(r.syncedToFap).toUpperCase() === 'TRUE';
  for (const f of ['checkinTime', 'updatedAt']) {
    const t = ts(r[f]);
    if (t) data[f] = t; else delete data[f];
  }
  recordDocs.push({ id: `${text(r.sessionId)}_${text(r.rollNumber)}`, data });
}

const plan = {
  user_invites: [...invites.values()],
  classes,
  enrollments: enrollDocs,
  class_schedules: scheduleDocs,
  sessions: sessionDocs,
  attendance_records: recordDocs,
};

const summary = {};
for (const [name, docs] of Object.entries(plan)) {
  if (only && !only.includes(name)) continue;
  summary[name] = await writeAll(db, name, docs, { dryRun });
}
console.log(`[${projectId}] ${dryRun ? '[DRY RUN] ' : ''}collections:`, summary);
warnings.forEach((w) => console.warn('WARN', w));
if (args['purge-legacy-users'] && !dryRun && (!only || only.includes('user_invites'))) {
  for (let i = 0; i < users.length; i += 400) {
    const batch = db.batch();
    users.slice(i, i + 400).forEach((u) => batch.delete(db.collection('users').doc(u.id)));
    await batch.commit();
  }
  console.log(`Đã xóa ${users.length} bản ghi users cũ (id=memberCode).`);
}
console.log(`${warnings.length} cảnh báo.${dryRun ? ' Chưa ghi gì.' : ''}`);
