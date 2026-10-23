// Kịch bản end-to-end trên Firebase Emulator (Auth + Firestore), dùng đúng SDK client như app/web:
//   admin cấp invite + lớp -> GV mở phiên -> SV đăng nhập lần đầu (tạo hồ sơ từ invite) và điểm danh
//   -> điểm danh trùng / sai QR bị chặn -> GV đóng phiên (sinh Absent) -> GV đọc lịch sử, SV không đọc được phiên.
//
// Chạy:  npm test   (trong thư mục e2e_test, cần Java + firebase-tools)
import { after, before, describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { initializeApp as initAdmin } from 'firebase-admin/app';
import { getAuth as getAdminAuth } from 'firebase-admin/auth';
import { getFirestore as getAdminDb } from 'firebase-admin/firestore';
import { deleteApp, initializeApp } from 'firebase/app';
import { connectAuthEmulator, getAuth, signInWithEmailAndPassword } from 'firebase/auth';
import {
  collection, connectFirestoreEmulator, doc, getDoc, getDocs, getFirestore, query, serverTimestamp, setDoc,
  updateDoc, where, writeBatch,
} from 'firebase/firestore';

const PROJECT = 'demo-fapcheckin';
const FS_HOST = '127.0.0.1';
const FS_PORT = Number((process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8085').split(':')[1]);
const AUTH_URL = `http://${process.env.FIREBASE_AUTH_EMULATOR_HOST ?? '127.0.0.1:9099'}`;
process.env.FIRESTORE_EMULATOR_HOST ??= `${FS_HOST}:${FS_PORT}`;
process.env.FIREBASE_AUTH_EMULATOR_HOST ??= AUTH_URL.replace('http://', '');

const PASSWORD = 'Passw0rd!';
const accounts = {
  admin: { email: 'admin@fpt.edu.vn', name: 'Admin' },
  teacher: { email: 'gv001@fpt.edu.vn', name: 'GV Một' },
  alice: { email: 'se1001@fpt.edu.vn', name: 'Alice' },
  bob: { email: 'se1002@fpt.edu.vn', name: 'Bob' },
  carol: { email: 'se1003@fpt.edu.vn', name: 'Carol' },
};

const clients = [];
async function signIn(key) {
  const app = initializeApp({ projectId: PROJECT, apiKey: 'fake-key', authDomain: 'localhost' }, `${key}-${clients.length}`);
  const auth = getAuth(app);
  connectAuthEmulator(auth, AUTH_URL, { disableWarnings: true });
  const db = getFirestore(app);
  connectFirestoreEmulator(db, FS_HOST, FS_PORT);
  await signInWithEmailAndPassword(auth, accounts[key].email, PASSWORD);
  clients.push(app);
  return { db, uid: auth.currentUser.uid, email: auth.currentUser.email };
}

/** Hồ sơ lần đầu: đúng như web/checkin và app mobile (tạo từ user_invites). */
async function createProfileFromInvite({ db, uid, email }) {
  const invite = (await getDoc(doc(db, 'user_invites', email))).data();
  await setDoc(doc(db, 'users', uid), {
    memberCode: invite.memberCode,
    fullName: invite.fullName,
    email,
    role: invite.role,
    ...(invite.rollNumber ? { rollNumber: invite.rollNumber } : {}),
    active: true,
    createdAt: serverTimestamp(),
  });
}

const checkinData = (sessionId, roll, token, over = {}) => ({
  sessionId,
  rollNumber: roll,
  classCode: 'PRN232_SE1917',
  teacherMemberCode: 'GV001',
  qrToken: token,
  status: 'Present',
  checkinTime: serverTimestamp(),
  networkVerificationResult: 'Skipped',
  ipAddress: '',
  syncedToFap: false,
  ...over,
});

describe('luồng điểm danh end-to-end', () => {
  let admin;
  let teacher;
  const sessionId = 'sess-e2e';
  let secret;

  before(async () => {
    initAdmin({ projectId: PROJECT });
    const adminAuth = getAdminAuth();
    const adminDb = getAdminDb();
    // Tạo tài khoản đăng nhập (email đã xác minh như Google Sign-In).
    for (const a of Object.values(accounts)) {
      await adminAuth.createUser({ email: a.email, password: PASSWORD, emailVerified: true, displayName: a.name });
    }
    // Admin đầu tiên (giống scripts/seed-admin.mjs).
    const adminUid = (await adminAuth.getUserByEmail(accounts.admin.email)).uid;
    await adminDb.doc(`users/${adminUid}`).set({
      memberCode: 'AD001', fullName: 'Admin', email: accounts.admin.email, role: 'admin', active: true,
    });
    admin = await signIn('admin');
  });

  after(async () => {
    await Promise.all(clients.map((app) => deleteApp(app)));
  });

  it('admin cấp invite cho GV/SV và tạo lớp + ghi danh', async () => {
    const { db } = admin;
    await setDoc(doc(db, 'user_invites', accounts.teacher.email), { role: 'staff', memberCode: 'GV001', fullName: 'GV Một' });
    for (const [key, roll] of [['alice', 'SE1001'], ['bob', 'SE1002'], ['carol', 'SE1003']]) {
      await setDoc(doc(db, 'user_invites', accounts[key].email), {
        role: 'user', memberCode: roll, rollNumber: roll, fullName: accounts[key].name,
      });
    }
    await setDoc(doc(db, 'classes', 'PRN232_SE1917'), {
      classCode: 'PRN232_SE1917', subjectCode: 'PRN232', subjectName: 'Web API', room: '303',
      studentCount: 3, teacherMemberCode: 'GV001', slotCode: 'A1',
    });
    for (const [roll, name] of [['SE1001', 'Alice'], ['SE1002', 'Bob'], ['SE1003', 'Carol']]) {
      await setDoc(doc(db, 'enrollments', `PRN232_SE1917_${roll}`), {
        classCode: 'PRN232_SE1917', rollNumber: roll, teacherMemberCode: 'GV001', fullName: name,
      });
    }
  });

  it('GV đăng nhập lần đầu, tạo hồ sơ từ invite và mở phiên điểm danh', async () => {
    teacher = await signIn('teacher');
    await createProfileFromInvite(teacher);
    assert.equal((await getDoc(doc(teacher.db, 'users', teacher.uid))).data().role, 'staff');

    secret = 'e2e-secret-0123456789abcdef';
    await setDoc(doc(teacher.db, 'sessions', sessionId), {
      classCode: 'PRN232_SE1917', teacherMemberCode: 'GV001', sessionDate: '2026-10-23', slotCode: 'A1',
      sessionStatus: 'open', qrSecret: secret, ipCheck: false, teacherIp: '',
    });
  });

  it('SV đăng nhập lần đầu và điểm danh thành công', async () => {
    const alice = await signIn('alice');
    await createProfileFromInvite(alice);
    await setDoc(doc(alice.db, 'attendance_records', `${sessionId}_SE1001`), checkinData(sessionId, 'SE1001', secret));
    const record = (await getDoc(doc(alice.db, 'attendance_records', `${sessionId}_SE1001`))).data();
    assert.equal(record.status, 'Present');
  });

  it('điểm danh trùng bị chặn', async () => {
    const alice = await signIn('alice');
    await assert.rejects(
      setDoc(doc(alice.db, 'attendance_records', `${sessionId}_SE1001`), checkinData(sessionId, 'SE1001', secret)),
      { code: 'permission-denied' },
    );
  });

  it('QR sai bị chặn; QR mới sau khi GV xoay thì mã cũ hết hiệu lực', async () => {
    const bob = await signIn('bob');
    await createProfileFromInvite(bob);
    await assert.rejects(
      setDoc(doc(bob.db, 'attendance_records', `${sessionId}_SE1002`), checkinData(sessionId, 'SE1002', 'wrong-wrong-wrong-0000')),
      { code: 'permission-denied' },
    );
    const rotated = 'e2e-rotated-0123456789abcdef';
    await updateDoc(doc(teacher.db, 'sessions', sessionId), { qrSecret: rotated });
    await assert.rejects(
      setDoc(doc(bob.db, 'attendance_records', `${sessionId}_SE1002`), checkinData(sessionId, 'SE1002', secret)),
      { code: 'permission-denied' },
    );
    await setDoc(doc(bob.db, 'attendance_records', `${sessionId}_SE1002`), checkinData(sessionId, 'SE1002', rotated));
  });

  it('SV không đọc được phiên (không lộ qrSecret)', async () => {
    const alice = await signIn('alice');
    await assert.rejects(getDoc(doc(alice.db, 'sessions', sessionId)), { code: 'permission-denied' });
  });

  it('GV đóng phiên và sinh Absent cho SV chưa điểm danh', async () => {
    const { db } = teacher;
    const enrolled = await getDocs(query(collection(db, 'enrollments'),
      where('teacherMemberCode', '==', 'GV001'), where('classCode', '==', 'PRN232_SE1917')));
    const records = await getDocs(query(collection(db, 'attendance_records'),
      where('teacherMemberCode', '==', 'GV001'), where('sessionId', '==', sessionId)));
    const done = new Set(records.docs.map((d) => d.data().rollNumber));

    const batch = writeBatch(db);
    batch.update(doc(db, 'sessions', sessionId), { sessionStatus: 'closed' });
    let absent = 0;
    for (const e of enrolled.docs) {
      const roll = e.data().rollNumber;
      if (done.has(roll)) continue;
      absent++;
      batch.set(doc(db, 'attendance_records', `${sessionId}_${roll}`), {
        sessionId, rollNumber: roll, classCode: 'PRN232_SE1917', teacherMemberCode: 'GV001',
        status: 'Absent', networkVerificationResult: 'AutoAbsent', ipAddress: '', syncedToFap: false,
      });
    }
    await batch.commit();
    assert.equal(absent, 1); // chỉ Carol

    // Sau khi đóng, SV không điểm danh được nữa.
    const carol = await signIn('carol');
    await createProfileFromInvite(carol);
    await assert.rejects(
      updateDoc(doc(carol.db, 'attendance_records', `${sessionId}_SE1003`), { status: 'Present' }),
      { code: 'permission-denied' },
    );
  });

  it('GV đọc lịch sử lớp; GV khác/SV không đọc được', async () => {
    const history = await getDocs(query(collection(teacher.db, 'attendance_records'),
      where('teacherMemberCode', '==', 'GV001'), where('classCode', '==', 'PRN232_SE1917')));
    const byRoll = Object.fromEntries(history.docs.map((d) => [d.data().rollNumber, d.data().status]));
    assert.deepEqual(byRoll, { SE1001: 'Present', SE1002: 'Present', SE1003: 'Absent' });

    const alice = await signIn('alice');
    await assert.rejects(
      getDocs(query(collection(alice.db, 'attendance_records'), where('teacherMemberCode', '==', 'GV001'))),
      { code: 'permission-denied' },
    );
  });
});
