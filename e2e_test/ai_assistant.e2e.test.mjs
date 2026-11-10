// E2E tự động cho Trợ lý AI trên Firebase Emulator (Auth + Firestore + Functions), KHÔNG cần Gemini key thật:
// Cloud Function `aiAssistant` thật chạy trong Functions emulator và gọi Gemini giả (support/fake_gemini.mjs).
//
// Kiểm:  (1) callable: xác thực, phân quyền, kiểm tra đầu vào, định dạng tool_calls, lỗi upstream, rate-limit;
//        (2) phần "app thực thi tool ghi" với quyền của GV: Security Rules vẫn là lớp chặn cuối cùng.
//
// Chạy:  npm run test:ai   (trong e2e_test; cần Java + firebase-tools — script run-ai-e2e.mjs dựng env + emulator)
import { after, before, describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { initializeApp as initAdmin } from 'firebase-admin/app';
import { getAuth as getAdminAuth } from 'firebase-admin/auth';
import { Timestamp, getFirestore as getAdminDb } from 'firebase-admin/firestore';
import { deleteApp, initializeApp } from 'firebase/app';
import { connectAuthEmulator, getAuth, signInWithEmailAndPassword } from 'firebase/auth';
import { connectFirestoreEmulator, doc, getDoc, getFirestore, serverTimestamp, setDoc } from 'firebase/firestore';
import { callReply, endsWithToolResult, lastUserText, startFakeGemini, textReply } from './support/fake_gemini.mjs';

const PROJECT = 'demo-fapcheckin';
const FS_HOST = '127.0.0.1';
const FS_PORT = Number((process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8085').split(':')[1]);
const AUTH_URL = `http://${process.env.FIREBASE_AUTH_EMULATOR_HOST ?? '127.0.0.1:9099'}`;
const FUNCTIONS_URL = `http://${process.env.FUNCTIONS_EMULATOR_HOST ?? '127.0.0.1:5001'}/${PROJECT}/asia-southeast1`;
process.env.FIRESTORE_EMULATOR_HOST ??= `${FS_HOST}:${FS_PORT}`;
process.env.FIREBASE_AUTH_EMULATOR_HOST ??= AUTH_URL.replace('http://', '');

const PASSWORD = 'Passw0rd!';
const accounts = {
  teacher: { email: 'gv001@fpt.edu.vn', memberCode: 'GV001', role: 'staff', name: 'GV Một' },
  other: { email: 'gv002@fpt.edu.vn', memberCode: 'GV002', role: 'staff', name: 'GV Hai' },
  student: { email: 'se1001@fpt.edu.vn', memberCode: 'SE1001', role: 'user', name: 'Alice', rollNumber: 'SE1001' },
};

const user = (text) => ({ role: 'user', text });

/** 17:00 UTC kế tiếp (= 00:00 giờ VN) — đúng quy ước hạn điểm danh tay của app. */
function nextDeadline(now = new Date()) {
  const d = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(), 17));
  if (d <= now) d.setUTCDate(d.getUTCDate() + 1);
  return Timestamp.fromDate(d);
}

const vnToday = () => new Date(Date.now() + 7 * 3600_000).toISOString().slice(0, 10);

async function idTokenFor(key) {
  const res = await fetch(`${AUTH_URL}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: accounts[key].email, password: PASSWORD, returnSecureToken: true }),
  });
  assert.equal(res.status, 200, `đăng nhập ${key} thất bại`);
  return (await res.json()).idToken;
}

/** Gọi callable theo giao thức https callable: POST { data } -> { result } | { error }. */
async function callAi(history, key) {
  const headers = { 'Content-Type': 'application/json' };
  if (key) headers.Authorization = `Bearer ${await idTokenFor(key)}`;
  const res = await fetch(`${FUNCTIONS_URL}/aiAssistant`, { method: 'POST', headers, body: JSON.stringify({ data: { history } }) });
  const json = await res.json();
  return { http: res.status, result: json.result, error: json.error };
}

const clients = [];
async function signIn(key) {
  const app = initializeApp({ projectId: PROJECT, apiKey: 'fake-key', authDomain: 'localhost' }, `${key}-${clients.length}`);
  const auth = getAuth(app);
  connectAuthEmulator(auth, AUTH_URL, { disableWarnings: true });
  const db = getFirestore(app);
  connectFirestoreEmulator(db, FS_HOST, FS_PORT);
  await signInWithEmailAndPassword(auth, accounts[key].email, PASSWORD);
  clients.push(app);
  return { db, uid: auth.currentUser.uid };
}

const manualRecord = (sessionId, roll, over = {}) => ({
  sessionId,
  rollNumber: roll,
  classCode: 'PRN232_SE1917',
  teacherMemberCode: 'GV001',
  status: 'ManualByGV',
  networkVerificationResult: 'Manual',
  ipAddress: '',
  syncedToFap: false,
  updatedAt: serverTimestamp(),
  updatedBy: 'GV001',
  checkinTime: serverTimestamp(),
  ...over,
});

describe('Trợ lý AI end-to-end (Functions + Rules trên Emulator)', () => {
  let gemini;
  let teacher;

  before(async () => {
    gemini = await startFakeGemini({ port: Number(process.env.FAKE_GEMINI_PORT ?? 5599) });
    initAdmin({ projectId: PROJECT });
    const adminAuth = getAdminAuth();
    const adminDb = getAdminDb();
    for (const a of Object.values(accounts)) {
      const created = await adminAuth.createUser({ email: a.email, password: PASSWORD, emailVerified: true, displayName: a.name });
      await adminDb.doc(`users/${created.uid}`).set({
        memberCode: a.memberCode, fullName: a.name, email: a.email, role: a.role, active: true,
        ...(a.rollNumber ? { rollNumber: a.rollNumber } : {}),
      });
    }
    await adminDb.doc('classes/PRN232_SE1917').set({
      classCode: 'PRN232_SE1917', subjectCode: 'PRN232', subjectName: 'Web API', room: '303',
      studentCount: 1, teacherMemberCode: 'GV001', slotCode: 'A1',
    });
    await adminDb.doc('classes/SWD392_SE1801').set({
      classCode: 'SWD392_SE1801', subjectCode: 'SWD392', subjectName: 'Architecture', room: '101',
      studentCount: 1, teacherMemberCode: 'GV002', slotCode: 'A1',
    });
    await adminDb.doc('enrollments/PRN232_SE1917_SE1001').set({
      classCode: 'PRN232_SE1917', rollNumber: 'SE1001', teacherMemberCode: 'GV001', fullName: 'Alice',
    });
    const base = { sessionStatus: 'open', qrSecret: 'e2e-secret-0123456789abcdef', ipCheck: false, slotCode: 'A1', sessionDate: vnToday() };
    await adminDb.doc('sessions/s-open').set({
      ...base, classCode: 'PRN232_SE1917', teacherMemberCode: 'GV001', manualAttendanceDeadline: nextDeadline(), createdAt: Timestamp.now(),
    });
    await adminDb.doc('sessions/s-expired').set({
      ...base, classCode: 'PRN232_SE1917', teacherMemberCode: 'GV001',
      manualAttendanceDeadline: Timestamp.fromDate(new Date('2020-01-01T17:00:00Z')), createdAt: Timestamp.now(),
    });
    await adminDb.doc('sessions/s-other').set({
      ...base, classCode: 'SWD392_SE1801', teacherMemberCode: 'GV002', manualAttendanceDeadline: nextDeadline(), createdAt: Timestamp.now(),
    });
    teacher = await signIn('teacher');
  });

  after(async () => {
    await Promise.all(clients.map((app) => deleteApp(app)));
    await gemini?.close();
  });

  describe('callable aiAssistant', () => {
    it('chưa đăng nhập -> UNAUTHENTICATED, không gọi Gemini', async () => {
      const before = gemini.requests.length;
      const r = await callAi([user('xin chào')], null);
      assert.equal(r.error?.status, 'UNAUTHENTICATED');
      assert.equal(gemini.requests.length, before);
    });

    it('sinh viên -> PERMISSION_DENIED (code FORBIDDEN), không gọi Gemini', async () => {
      const before = gemini.requests.length;
      const r = await callAi([user('xin chào')], 'student');
      assert.equal(r.error?.status, 'PERMISSION_DENIED');
      assert.equal(r.error?.details?.code, 'FORBIDDEN');
      assert.equal(gemini.requests.length, before);
    });

    it('GV hỏi thường -> text; request gửi Gemini có key, system prompt và đủ 6 tool', async () => {
      const r = await callAi([user('xin chào')], 'teacher');
      assert.equal(r.http, 200, JSON.stringify(r.error));
      assert.equal(r.result.type, 'text');
      assert.match(r.result.text, /giúp gì/);
      const req = gemini.requests.at(-1);
      // Functions emulator ưu tiên firebase/functions/.secret.local (nếu có) hơn env, nên chỉ kiểm key có được gửi đi.
      assert.ok(req.headers['x-goog-api-key']?.length > 0);
      assert.match(req.url, /\/models\/[^/]+:generateContent$/);
      assert.match(req.body.systemInstruction.parts[0].text, /GIẢNG VIÊN/);
      assert.equal(req.body.tools[0].functionDeclarations.length, 6);
      assert.equal(lastUserText(req.body), 'xin chào');
    });

    it('lệnh điểm danh -> tool_calls(mark_attendance) đúng schema, giữ thoughtSignature', async () => {
      const r = await callAi([user('điểm danh SE1001 lớp PRN232_SE1917 có mặt')], 'teacher');
      assert.equal(r.result.type, 'tool_calls');
      assert.deepEqual(r.result.calls, [{
        name: 'mark_attendance',
        args: { classCode: 'PRN232_SE1917', students: [{ rollNumber: 'SE1001', status: 'ManualByGV' }] },
        thoughtSignature: 'sig-1',
      }]);
    });

    it('vòng tool: gửi lại functionCall + kết quả tool -> Gemini nhận đúng cấu trúc và trả tóm tắt', async () => {
      const call = { name: 'mark_attendance', args: { classCode: 'PRN232_SE1917', students: [{ rollNumber: 'SE1001', status: 'ManualByGV' }] }, thoughtSignature: 'sig-1' };
      const r = await callAi([
        user('điểm danh SE1001'),
        { role: 'model', toolCalls: [call] },
        { role: 'tool', name: 'mark_attendance', result: { ok: true, marked: 1 } },
      ], 'teacher');
      assert.equal(r.result.type, 'text');
      const body = gemini.requests.at(-1).body;
      assert.ok(endsWithToolResult(body));
      assert.equal(body.contents[1].parts[0].thoughtSignature, 'sig-1');
      assert.deepEqual(body.contents[2].parts[0].functionResponse, { name: 'mark_attendance', response: { result: { ok: true, marked: 1 } } });
    });

    it('đầu vào xấu bị chặn trước khi gọi Gemini', async () => {
      const before = gemini.requests.length;
      const tooLong = await callAi([user('a'.repeat(1001))], 'teacher');
      assert.equal(tooLong.error?.status, 'INVALID_ARGUMENT');
      const tooMany = await callAi(Array.from({ length: 31 }, () => user('a')), 'teacher');
      assert.equal(tooMany.error?.status, 'INVALID_ARGUMENT');
      const unknownTool = await callAi([user('a'), { role: 'model', toolCalls: [{ name: 'drop_database', args: {} }] }, { role: 'tool', name: 'list_my_classes', result: {} }], 'teacher');
      assert.equal(unknownTool.error?.status, 'INVALID_ARGUMENT');
      const empty = await callAi([], 'teacher');
      assert.equal(empty.error?.status, 'INVALID_ARGUMENT');
      assert.equal(gemini.requests.length, before);
    });

    it('Gemini lỗi 500 -> UNAVAILABLE, details.code AI_UNAVAILABLE', async () => {
      const r = await callAi([user('FAIL500')], 'teacher');
      assert.equal(r.error?.status, 'UNAVAILABLE');
      assert.equal(r.error?.details?.code, 'AI_UNAVAILABLE');
    });

    it('Gemini trả rỗng / bị chặn an toàn -> FAILED_PRECONDITION có mã rõ ràng', async () => {
      gemini.setResponder(() => ({ json: { promptFeedback: { blockReason: 'SAFETY' } } }));
      try {
        const r = await callAi([user('x')], 'teacher');
        assert.equal(r.error?.status, 'FAILED_PRECONDITION');
        assert.equal(r.error?.details?.code, 'AI_BLOCKED');
      } finally {
        gemini.setResponder(null);
      }
    });

    it('rate-limit: vượt 60 lượt/10 phút -> RESOURCE_EXHAUSTED', async () => {
      const db = getAdminDb();
      const uid = (await getAdminAuth().getUserByEmail(accounts.other.email)).uid;
      await db.doc(`ai_usage/${uid}`).set({ windowStart: Date.now(), count: 60 });
      const r = await callAi([user('xin chào')], 'other');
      assert.equal(r.error?.status, 'RESOURCE_EXHAUSTED');
      assert.equal(r.error?.details?.code, 'RATE_LIMITED');
    });

    it('client không đọc/ghi được ai_usage (chỉ Admin SDK)', async () => {
      await assert.rejects(setDoc(doc(teacher.db, 'ai_usage', teacher.uid), { windowStart: 0, count: 0 }));
      await assert.rejects(getDoc(doc(teacher.db, 'ai_usage', teacher.uid)));
    });
  });

  // App thực thi mark_attendance bằng đúng ghi này (TeacherRepository.manualCheckin*). Rules là chốt chặn cuối.
  describe('thực thi tool ghi dưới quyền GV (Security Rules)', () => {
    it('GV điểm danh tay SV trong phiên của mình, còn hạn -> được ghi', async () => {
      await setDoc(doc(teacher.db, 'attendance_records', 's-open_SE1001'), manualRecord('s-open', 'SE1001'));
      const rec = (await getDoc(doc(teacher.db, 'attendance_records', 's-open_SE1001'))).data();
      assert.equal(rec.status, 'ManualByGV');
      assert.equal(rec.networkVerificationResult, 'Manual');
    });

    it('trạng thái ngoài danh sách cho phép bị chặn', async () => {
      await assert.rejects(setDoc(doc(teacher.db, 'attendance_records', 's-open_SE1002'), manualRecord('s-open', 'SE1002', { status: 'Hacked' })));
    });

    it('quá hạn điểm danh tay (manualAttendanceDeadline) bị chặn', async () => {
      await assert.rejects(setDoc(doc(teacher.db, 'attendance_records', 's-expired_SE1001'), manualRecord('s-expired', 'SE1001')));
    });

    it('phiên/lớp của GV khác bị chặn', async () => {
      await assert.rejects(setDoc(
        doc(teacher.db, 'attendance_records', 's-other_SE2001'),
        manualRecord('s-other', 'SE2001', { classCode: 'SWD392_SE1801', teacherMemberCode: 'GV002' }),
      ));
      await assert.rejects(setDoc(
        doc(teacher.db, 'attendance_records', 's-other_SE2001'),
        manualRecord('s-other', 'SE2001', { classCode: 'SWD392_SE1801' }), // giả mạo teacherMemberCode GV001
      ));
    });

    it('thêm trường lạ vào bản ghi bị chặn (AI không thể ghi dữ liệu ngoài schema)', async () => {
      await assert.rejects(setDoc(doc(teacher.db, 'attendance_records', 's-open_SE1003'), manualRecord('s-open', 'SE1003', { injected: 'x' })));
    });
  });
});
