import { describe, it, before, after, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  collection, deleteDoc, doc, getDoc, getDocs, query, serverTimestamp, setDoc, Timestamp, updateDoc, where,
} from 'firebase/firestore';
import { ACCOUNTS, SECRET, TEACHER_IP, anon, as, asUnverified, createEnv, seed } from './helpers.mjs';

let env;
const nextVietnamMidnight = () => {
  const vietnamNow = new Date(Date.now() + 7 * 60 * 60 * 1000);
  return Timestamp.fromMillis(
    Date.UTC(
      vietnamNow.getUTCFullYear(),
      vietnamNow.getUTCMonth(),
      vietnamNow.getUTCDate() + 1,
    ) - 7 * 60 * 60 * 1000,
  );
};
before(async () => { env = await createEnv(); });
after(async () => { await env.cleanup(); });
beforeEach(async () => {
  await env.clearFirestore();
  await seed(env);
});

const checkinData = (over = {}) => ({
  sessionId: 'sess-open',
  rollNumber: 'SE1001',
  classCode: 'PRN232_SE1917',
  teacherMemberCode: 'GV001',
  qrToken: SECRET,
  status: 'Present',
  checkinTime: serverTimestamp(),
  networkVerificationResult: 'Skipped',
  ipAddress: '',
  syncedToFap: false,
  ...over,
});

describe('deny by default', () => {
  it('chặn collection không khai báo, kể cả admin', async () => {
    await assertFails(getDoc(doc(as(env, 'admin'), 'secrets/x')));
    await assertFails(setDoc(doc(as(env, 'admin'), 'secrets/x'), { a: 1 }));
  });
  it('chặn người chưa đăng nhập trên mọi collection chính', async () => {
    const db = anon(env);
    for (const p of ['users/u-s1', 'classes/PRN232_SE1917', 'sessions/sess-open',
      'attendance_records/sess-closed_SE1001', 'requests/req-s1', 'announcements/ann-all',
      'subjects/PRN232', 'user_invites/se9999@fpt.edu.vn']) {
      await assertFails(getDoc(doc(db, p)));
    }
    await assertFails(setDoc(doc(db, 'attendance_records/sess-open_SE1001'), checkinData()));
  });
  it('chặn email chưa xác minh', async () => {
    await assertFails(getDoc(doc(asUnverified(env, 's1'), 'users/u-s1')));
  });
});

describe('users', () => {
  it('đọc hồ sơ của chính mình', async () => {
    await assertSucceeds(getDoc(doc(as(env, 's1'), 'users/u-s1')));
  });
  it('không đọc hồ sơ người khác', async () => {
    await assertFails(getDoc(doc(as(env, 's1'), 'users/u-s2')));
    await assertFails(getDoc(doc(as(env, 't1'), 'users/u-s1')));
  });
  it('admin đọc/list mọi hồ sơ', async () => {
    await assertSucceeds(getDoc(doc(as(env, 'admin'), 'users/u-s1')));
    await assertSucceeds(getDocs(collection(as(env, 'admin'), 'users')));
  });
  it('user thường không list được users', async () => {
    await assertFails(getDocs(collection(as(env, 't1'), 'users')));
  });
  it('tạo hồ sơ lần đầu khớp invite', async () => {
    await assertSucceeds(setDoc(doc(as(env, 'newbie'), 'users/u-new'), {
      memberCode: 'SE9999', rollNumber: 'SE9999', fullName: 'SV Mới', email: ACCOUNTS.newbie.email,
      role: 'user', active: true, createdAt: serverTimestamp(),
    }));
  });
  it('không tự nâng role so với invite', async () => {
    await assertFails(setDoc(doc(as(env, 'newbie'), 'users/u-new'), {
      memberCode: 'SE9999', rollNumber: 'SE9999', fullName: 'SV Mới', email: ACCOUNTS.newbie.email,
      role: 'admin', active: true, createdAt: serverTimestamp(),
    }));
  });
  it('không đổi memberCode/rollNumber khác invite', async () => {
    await assertFails(setDoc(doc(as(env, 'newbie'), 'users/u-new'), {
      memberCode: 'SE1001', rollNumber: 'SE1001', fullName: 'Mạo danh', email: ACCOUNTS.newbie.email,
      role: 'user', active: true, createdAt: serverTimestamp(),
    }));
  });
  it('không có invite thì không tạo được hồ sơ', async () => {
    await assertFails(setDoc(doc(as(env, 'stranger'), 'users/u-stranger'), {
      memberCode: 'X', fullName: 'X', email: ACCOUNTS.stranger.email,
      role: 'user', active: true, createdAt: serverTimestamp(),
    }));
  });
  it('không tạo hồ sơ cho uid khác', async () => {
    await assertFails(setDoc(doc(as(env, 'newbie'), 'users/u-other'), {
      memberCode: 'SE9999', rollNumber: 'SE9999', fullName: 'X', email: ACCOUNTS.newbie.email,
      role: 'user', active: true, createdAt: serverTimestamp(),
    }));
  });
  it('tự sửa fullName được, sửa role/active thì không', async () => {
    const db = as(env, 's1');
    await assertSucceeds(updateDoc(doc(db, 'users/u-s1'), { fullName: 'Tên mới' }));
    await assertFails(updateDoc(doc(db, 'users/u-s1'), { role: 'admin' }));
    await assertFails(updateDoc(doc(db, 'users/u-s1'), { active: false }));
  });
  it('admin sửa role; người khác không xóa được', async () => {
    await assertSucceeds(updateDoc(doc(as(env, 'admin'), 'users/u-s2'), { role: 'staff' }));
    await assertFails(deleteDoc(doc(as(env, 't1'), 'users/u-s2')));
    await assertSucceeds(deleteDoc(doc(as(env, 'admin'), 'users/u-s2')));
  });
});

describe('user_invites', () => {
  it('chủ email đọc được invite của mình, không đọc của người khác', async () => {
    await assertSucceeds(getDoc(doc(as(env, 'newbie'), 'user_invites/se9999@fpt.edu.vn')));
    await assertFails(getDoc(doc(as(env, 'newbie'), 'user_invites/gv009@fpt.edu.vn')));
  });
  it('chỉ admin ghi/list', async () => {
    await assertSucceeds(setDoc(doc(as(env, 'admin'), 'user_invites/new@fpt.edu.vn'), { role: 'user', memberCode: 'SE5', rollNumber: 'SE5' }));
    await assertFails(setDoc(doc(as(env, 't1'), 'user_invites/new@fpt.edu.vn'), { role: 'admin', memberCode: 'X' }));
    await assertFails(getDocs(collection(as(env, 't1'), 'user_invites')));
    await assertSucceeds(getDocs(collection(as(env, 'admin'), 'user_invites')));
  });
});

describe('subjects / timeSlots / slots (tham chiếu)', () => {
  for (const p of ['subjects/PRN232', 'timeSlots/A-1', 'slots/A1']) {
    it(`${p}: mọi user có hồ sơ đọc được, chỉ admin ghi`, async () => {
      await assertSucceeds(getDoc(doc(as(env, 's1'), p)));
      await assertSucceeds(getDoc(doc(as(env, 't1'), p)));
      await assertFails(getDoc(doc(as(env, 'stranger'), p)));
      await assertFails(setDoc(doc(as(env, 't1'), p), { x: 1 }));
      await assertSucceeds(setDoc(doc(as(env, 'admin'), p), { x: 1 }));
    });
  }
});

describe('classes', () => {
  it('GV đọc lớp của mình và lớp chưa có GV', async () => {
    const db = as(env, 't1');
    await assertSucceeds(getDoc(doc(db, 'classes/PRN232_SE1917')));
    await assertSucceeds(getDoc(doc(db, 'classes/MAD101_SE1700')));
  });
  it('GV không đọc lớp của GV khác', async () => {
    await assertFails(getDoc(doc(as(env, 't1'), 'classes/SWD392_SE1801')));
  });
  it('GV list lớp của mình theo teacherMemberCode', async () => {
    await assertSucceeds(getDocs(query(collection(as(env, 't1'), 'classes'), where('teacherMemberCode', '==', 'GV001'))));
    await assertFails(getDocs(collection(as(env, 't1'), 'classes')));
  });
  it('SV không đọc classes', async () => {
    await assertFails(getDoc(doc(as(env, 's1'), 'classes/PRN232_SE1917')));
  });
  it('GV nhận lớp chưa có GV (chỉ đổi teacherMemberCode)', async () => {
    await assertSucceeds(updateDoc(doc(as(env, 't1'), 'classes/MAD101_SE1700'), { teacherMemberCode: 'GV001' }));
  });
  it('GV không nhận hộ GV khác / không đổi trường khác / không cướp lớp đã có GV', async () => {
    const db = as(env, 't1');
    await assertFails(updateDoc(doc(db, 'classes/MAD101_SE1700'), { teacherMemberCode: 'GV002' }));
    await assertFails(updateDoc(doc(db, 'classes/MAD101_SE1700'), { teacherMemberCode: 'GV001', room: '999' }));
    await assertFails(updateDoc(doc(db, 'classes/SWD392_SE1801'), { teacherMemberCode: 'GV001' }));
  });
  it('chỉ admin tạo/xóa lớp', async () => {
    await assertFails(setDoc(doc(as(env, 't1'), 'classes/NEW_1'), { teacherMemberCode: 'GV001' }));
    await assertSucceeds(setDoc(doc(as(env, 'admin'), 'classes/NEW_1'), { teacherMemberCode: 'GV001' }));
    await assertFails(deleteDoc(doc(as(env, 't1'), 'classes/NEW_1')));
    await assertSucceeds(deleteDoc(doc(as(env, 'admin'), 'classes/NEW_1')));
  });
});

describe('enrollments', () => {
  it('GV đọc danh sách lớp của mình', async () => {
    const db = as(env, 't1');
    await assertSucceeds(getDocs(query(collection(db, 'enrollments'),
      where('teacherMemberCode', '==', 'GV001'), where('classCode', '==', 'PRN232_SE1917'))));
  });
  it('GV không đọc ghi danh lớp GV khác', async () => {
    await assertFails(getDoc(doc(as(env, 't1'), 'enrollments/SWD392_SE1801_SE1002')));
  });
  it('SV đọc ghi danh của chính mình, không đọc của bạn', async () => {
    await assertSucceeds(getDoc(doc(as(env, 's1'), 'enrollments/PRN232_SE1917_SE1001')));
    await assertFails(getDoc(doc(as(env, 's1'), 'enrollments/SWD392_SE1801_SE1002')));
  });
  it('GV nhận ghi danh lớp chưa có GV; không sửa trường khác', async () => {
    const db = as(env, 't1');
    await assertSucceeds(updateDoc(doc(db, 'enrollments/MAD101_SE1700_SE1001'), { teacherMemberCode: 'GV001' }));
    await assertFails(updateDoc(doc(db, 'enrollments/PRN232_SE1917_SE1001'), { fullName: 'Sửa' }));
  });
  it('SV/GV không tự thêm ghi danh; admin thì được', async () => {
    const data = { classCode: 'PRN232_SE1917', rollNumber: 'SE1002', teacherMemberCode: 'GV001' };
    await assertFails(setDoc(doc(as(env, 's2'), 'enrollments/PRN232_SE1917_SE1002'), data));
    await assertFails(setDoc(doc(as(env, 't1'), 'enrollments/PRN232_SE1917_SE1002'), data));
    await assertSucceeds(setDoc(doc(as(env, 'admin'), 'enrollments/PRN232_SE1917_SE1002'), data));
  });
});

describe('class_schedules', () => {
  const data = { classCode: 'PRN232_SE1917', teacherMemberCode: 'GV001', scheduleDate: '2026-11-01', slotCode: 'A1', status: 'scheduled' };
  it('GV đọc/tạo lịch cho lớp của mình', async () => {
    const db = as(env, 't1');
    await assertSucceeds(getDoc(doc(db, 'class_schedules/sch-1')));
    await assertSucceeds(setDoc(doc(db, 'class_schedules/sch-2'), data));
  });
  it('GV được kiểm tra ID idempotency chưa tồn tại của chính mình', async () => {
    const db = as(env, 't1');
    const ownId = 'GV001_1762250000000000_123456';
    const otherId = 'GV002_1762250000000000_123456';
    const snapshot = await assertSucceeds(
      getDoc(doc(db, 'class_schedules', ownId)),
    );
    assert.equal(snapshot.exists(), false);
    await assertFails(getDoc(doc(db, 'class_schedules', otherId)));
  });
  it('GV không tạo lịch cho lớp của GV khác hoặc mạo danh', async () => {
    const db = as(env, 't1');
    await assertFails(setDoc(doc(db, 'class_schedules/sch-3'), { ...data, classCode: 'SWD392_SE1801' }));
    await assertFails(setDoc(doc(db, 'class_schedules/sch-3'), { ...data, teacherMemberCode: 'GV002' }));
  });
  it('GV khác không đọc/sửa/xóa lịch', async () => {
    const db = as(env, 't2');
    await assertFails(getDoc(doc(db, 'class_schedules/sch-1')));
    await assertFails(updateDoc(doc(db, 'class_schedules/sch-1'), { status: 'cancelled' }));
    await assertFails(deleteDoc(doc(db, 'class_schedules/sch-1')));
  });
  it('GV chủ sửa trạng thái nhưng không đổi lớp; SV không đọc', async () => {
    await assertSucceeds(updateDoc(doc(as(env, 't1'), 'class_schedules/sch-1'), { status: 'cancelled' }));
    await assertFails(updateDoc(doc(as(env, 't1'), 'class_schedules/sch-1'), { classCode: 'SWD392_SE1801' }));
    await assertFails(getDoc(doc(as(env, 's1'), 'class_schedules/sch-1')));
  });
});

describe('sessions', () => {
  const newSession = (over = {}) => ({
    classCode: 'PRN232_SE1917', teacherMemberCode: 'GV001', sessionDate: '2026-10-21', slotCode: 'A1',
    sessionStatus: 'open', qrSecret: SECRET, ipCheck: false, teacherIp: '',
    manualAttendanceDeadline: nextVietnamMidnight(), ...over,
  });
  it('GV mở phiên cho lớp của mình', async () => {
    await assertSucceeds(setDoc(doc(as(env, 't1'), 'sessions/new'), newSession()));
  });
  it('GV không mở phiên lớp người khác / mạo danh / secret yếu / trạng thái sai', async () => {
    const db = as(env, 't1');
    await assertFails(setDoc(doc(db, 'sessions/x1'), newSession({ classCode: 'SWD392_SE1801' })));
    await assertFails(setDoc(doc(db, 'sessions/x2'), newSession({ teacherMemberCode: 'GV002' })));
    await assertFails(setDoc(doc(db, 'sessions/x3'), newSession({ qrSecret: 'short' })));
    await assertFails(setDoc(doc(db, 'sessions/x4'), newSession({ sessionStatus: 'closed' })));
    await assertFails(setDoc(doc(db, 'sessions/x-deadline'), newSession({
      manualAttendanceDeadline: Timestamp.fromMillis(Date.now() + 30 * 60 * 1000),
    })));
  });
  it('SV không tạo phiên, không đọc phiên (lộ qrSecret)', async () => {
    await assertFails(setDoc(doc(as(env, 's1'), 'sessions/x5'), newSession()));
    await assertFails(getDoc(doc(as(env, 's1'), 'sessions/sess-open')));
  });
  it('GV chủ xoay QR và đóng phiên; GV khác thì không', async () => {
    await assertSucceeds(updateDoc(doc(as(env, 't1'), 'sessions/sess-open'), { qrSecret: 'another-secret-0123456789' }));
    await assertSucceeds(updateDoc(doc(as(env, 't1'), 'sessions/sess-open'), { sessionStatus: 'closed' }));
    await assertFails(updateDoc(doc(as(env, 't2'), 'sessions/sess-open'), { sessionStatus: 'closed' }));
    await assertFails(getDoc(doc(as(env, 't2'), 'sessions/sess-open')));
  });
  it('GV không chuyển phiên sang lớp/GV khác', async () => {
    const db = as(env, 't1');
    await assertFails(updateDoc(doc(db, 'sessions/sess-open'), { teacherMemberCode: 'GV002' }));
    await assertFails(updateDoc(doc(db, 'sessions/sess-open'), { classCode: 'SWD392_SE1801' }));
    await assertFails(updateDoc(doc(db, 'sessions/sess-open'), {
      manualAttendanceDeadline: Timestamp.fromMillis(Date.now() + 23 * 60 * 60 * 1000),
    }));
  });
  it('chỉ admin xóa phiên', async () => {
    await assertFails(deleteDoc(doc(as(env, 't1'), 'sessions/sess-open')));
    await assertSucceeds(deleteDoc(doc(as(env, 'admin'), 'sessions/sess-open')));
  });
  it('GV list phiên của mình', async () => {
    const q = query(collection(as(env, 't1'), 'sessions'), where('teacherMemberCode', '==', 'GV001'));
    await assertSucceeds(getDocs(q));
  });
});

describe('attendance_records — SV check-in', () => {
  const rec = (db, id) => doc(db, 'attendance_records', id);

  it('SV đã ghi danh điểm danh thành công (phiên không kiểm tra IP)', async () => {
    await assertSucceeds(setDoc(rec(as(env, 's1'), 'sess-open_SE1001'), checkinData()));
  });
  it('phiên kiểm tra IP: IP khớp → được; IP lệch / thiếu → bị chặn', async () => {
    const db = as(env, 's1');
    const ok = checkinData({ sessionId: 'sess-ip', ipAddress: TEACHER_IP, networkVerificationResult: 'Match' });
    await assertFails(setDoc(rec(db, 'sess-ip_SE1001'), { ...ok, ipAddress: '198.51.100.9' }));
    await assertFails(setDoc(rec(db, 'sess-ip_SE1001'), { ...ok, ipAddress: '' }));
    await assertFails(setDoc(rec(db, 'sess-ip_SE1001'), { ...ok, networkVerificationResult: 'Skipped' }));
    await assertSucceeds(setDoc(rec(db, 'sess-ip_SE1001'), ok));
  });
  it('sai QR token → bị chặn', async () => {
    await assertFails(setDoc(rec(as(env, 's1'), 'sess-open_SE1001'), checkinData({ qrToken: 'wrong-wrong-wrong-0000' })));
  });
  it('phiên đã đóng → bị chặn', async () => {
    await assertFails(setDoc(rec(as(env, 's2'), 'sess-closed_SE1002'),
      checkinData({ sessionId: 'sess-closed', rollNumber: 'SE1002' })));
  });
  it('SV chưa ghi danh lớp này → bị chặn', async () => {
    await assertFails(setDoc(rec(as(env, 's2'), 'sess-open_SE1002'), checkinData({ rollNumber: 'SE1002' })));
  });
  it('điểm danh hộ bạn (rollNumber khác của mình) → bị chặn', async () => {
    await assertFails(setDoc(rec(as(env, 's2'), 'sess-open_SE1001'), checkinData()));
  });
  it('điểm danh lần hai (trùng) → bị chặn', async () => {
    const db = as(env, 's1');
    await assertSucceeds(setDoc(rec(db, 'sess-open_SE1001'), checkinData()));
    await assertFails(setDoc(rec(db, 'sess-open_SE1001'), checkinData()));
  });
  it('doc id không đúng {sessionId}_{rollNumber} → bị chặn', async () => {
    await assertFails(setDoc(rec(as(env, 's1'), 'whatever'), checkinData()));
  });
  it('giả mạo trạng thái / giờ / classCode / teacherMemberCode → bị chặn', async () => {
    const db = as(env, 's1');
    await assertFails(setDoc(rec(db, 'sess-open_SE1001'), checkinData({ status: 'ManualByGV' })));
    await assertFails(setDoc(rec(db, 'sess-open_SE1001'), checkinData({ checkinTime: new Date('2020-01-01') })));
    await assertFails(setDoc(rec(db, 'sess-open_SE1001'), checkinData({ classCode: 'SWD392_SE1801' })));
    await assertFails(setDoc(rec(db, 'sess-open_SE1001'), checkinData({ teacherMemberCode: 'GV002' })));
    await assertFails(setDoc(rec(db, 'sess-open_SE1001'), checkinData({ syncedToFap: true })));
    await assertFails(setDoc(rec(db, 'sess-open_SE1001'), checkinData({ extra: 'x' })));
  });
  it('tài khoản bị khóa / chưa có hồ sơ / GV → bị chặn', async () => {
    await assertFails(setDoc(rec(as(env, 's3'), 'sess-open_SE1003'), checkinData({ rollNumber: 'SE1003' })));
    await assertFails(setDoc(rec(as(env, 'stranger'), 'sess-open_SE1001'), checkinData()));
    await assertFails(setDoc(rec(as(env, 't1'), 'sess-open_SE1001'), checkinData()));
  });
  it('SV không sửa / xóa bản ghi của mình sau khi điểm danh', async () => {
    const db = as(env, 's1');
    await assertSucceeds(setDoc(rec(db, 'sess-open_SE1001'), checkinData()));
    await assertFails(updateDoc(rec(db, 'sess-open_SE1001'), { status: 'Absent' }));
    await assertFails(deleteDoc(rec(db, 'sess-open_SE1001')));
  });
});

describe('attendance_records — đọc & GV chỉnh sửa', () => {
  const rec = (db, id) => doc(db, 'attendance_records', id);

  it('SV đọc bản ghi của mình, không đọc của bạn', async () => {
    await assertSucceeds(getDoc(rec(as(env, 's1'), 'sess-closed_SE1001')));
    await assertFails(getDoc(rec(as(env, 's2'), 'sess-closed_SE1001')));
  });
  it('GV đọc bản ghi lớp mình, không đọc lớp khác', async () => {
    await assertSucceeds(getDoc(rec(as(env, 't1'), 'sess-closed_SE1001')));
    await assertFails(getDoc(rec(as(env, 't1'), 'sess-other_SE1002')));
  });
  it('GV query lịch sử theo teacherMemberCode + classCode', async () => {
    const q = query(collection(as(env, 't1'), 'attendance_records'),
      where('teacherMemberCode', '==', 'GV001'), where('classCode', '==', 'PRN232_SE1917'));
    await assertSucceeds(getDocs(q));
    await assertFails(getDocs(collection(as(env, 't1'), 'attendance_records')));
  });
  it('GV chấm tay một SV vắng cho phiên của mình', async () => {
    await assertSucceeds(setDoc(rec(as(env, 't1'), 'sess-open_SE1001'), {
      sessionId: 'sess-open', rollNumber: 'SE1001', classCode: 'PRN232_SE1917', teacherMemberCode: 'GV001',
      status: 'Absent', networkVerificationResult: 'AutoAbsent', ipAddress: '', syncedToFap: false,
    }));
  });
  it('GV điểm danh tay cho enrollment legacy với payload đầy đủ của mobile', async () => {
    await assertSucceeds(setDoc(rec(as(env, 't1'), 'sess-open_SE1003'), {
      sessionId: 'sess-open', rollNumber: 'SE1003', classCode: 'PRN232_SE1917', teacherMemberCode: 'GV001',
      status: 'ManualByGV', checkinTime: serverTimestamp(), networkVerificationResult: 'Manual',
      ipAddress: '', note: 'Giảng viên xác nhận', updatedAt: serverTimestamp(),
      updatedBy: 'GV001', syncedToFap: false,
    }));
  });
  it('GV không được điểm danh tay sau deadline của ngày học', async () => {
    await assertFails(setDoc(rec(as(env, 't1'), 'sess-expired_SE1003'), {
      sessionId: 'sess-expired', rollNumber: 'SE1003', classCode: 'PRN232_SE1917', teacherMemberCode: 'GV001',
      status: 'ManualByGV', checkinTime: serverTimestamp(), networkVerificationResult: 'Manual',
      ipAddress: '', note: 'Bổ sung muộn', updatedAt: serverTimestamp(),
      updatedBy: 'GV001', syncedToFap: false,
    }));
  });
  it('GV được điểm danh tay cho phiên legacy thiếu deadline nếu được tạo trong hôm nay', async () => {
    await assertSucceeds(setDoc(rec(as(env, 't1'), 'sess-legacy-current_SE1003'), {
      sessionId: 'sess-legacy-current', rollNumber: 'SE1003', classCode: 'PRN232_SE1917', teacherMemberCode: 'GV001',
      status: 'ManualByGV', checkinTime: serverTimestamp(), networkVerificationResult: 'Manual',
      ipAddress: '', note: 'Xác nhận phiên legacy', updatedAt: serverTimestamp(),
      updatedBy: 'GV001', syncedToFap: false,
    }));
  });
  it('GV không được điểm danh tay cho phiên legacy thiếu deadline từ ngày cũ', async () => {
    await assertFails(setDoc(rec(as(env, 't1'), 'sess-legacy-old_SE1003'), {
      sessionId: 'sess-legacy-old', rollNumber: 'SE1003', classCode: 'PRN232_SE1917', teacherMemberCode: 'GV001',
      status: 'ManualByGV', checkinTime: serverTimestamp(), networkVerificationResult: 'Manual',
      ipAddress: '', note: 'Không được bổ sung muộn', updatedAt: serverTimestamp(),
      updatedBy: 'GV001', syncedToFap: false,
    }));
  });
  it('GV không tạo bản ghi cho phiên của GV khác', async () => {
    await assertFails(setDoc(rec(as(env, 't1'), 'sess-other_SE1002'), {
      sessionId: 'sess-other', rollNumber: 'SE1002', classCode: 'SWD392_SE1801', teacherMemberCode: 'GV001',
      status: 'Present', networkVerificationResult: 'Manual', ipAddress: '', syncedToFap: false,
    }));
    await assertFails(setDoc(rec(as(env, 't1'), 'sess-other_SE1002'), {
      sessionId: 'sess-other', rollNumber: 'SE1002', classCode: 'SWD392_SE1801', teacherMemberCode: 'GV002',
      status: 'Present', networkVerificationResult: 'Manual', ipAddress: '', syncedToFap: false,
    }));
  });
  it('GV sửa trạng thái bản ghi của mình nhưng không đổi khóa; GV khác thì không', async () => {
    await assertSucceeds(updateDoc(rec(as(env, 't1'), 'sess-closed_SE1001'), {
      status: 'Late', networkVerificationResult: 'Manual', updatedAt: serverTimestamp(),
      updatedBy: 'GV001', syncedToFap: false,
    }));
    await assertFails(updateDoc(rec(as(env, 't1'), 'sess-closed_SE1001'), { rollNumber: 'SE1002' }));
    await assertFails(updateDoc(rec(as(env, 't1'), 'sess-closed_SE1001'), { teacherMemberCode: 'GV002' }));
    await assertFails(updateDoc(rec(as(env, 't2'), 'sess-closed_SE1001'), { status: 'Absent' }));
  });
  it('GV không xóa; admin xóa được', async () => {
    await assertFails(deleteDoc(rec(as(env, 't1'), 'sess-closed_SE1001')));
    await assertSucceeds(deleteDoc(rec(as(env, 'admin'), 'sess-closed_SE1001')));
  });
});

describe('requests', () => {
  const newReq = (over = {}) => ({
    type: 'leave', authorUid: 'u-s1', authorMemberCode: 'SE1001', reason: 'Xin nghỉ',
    status: 'pending', createdAt: serverTimestamp(), ...over,
  });
  it('SV/GV tạo đơn của mình ở trạng thái pending', async () => {
    await assertSucceeds(setDoc(doc(as(env, 's1'), 'requests/new'), newReq()));
    await assertSucceeds(setDoc(doc(as(env, 't1'), 'requests/new2'),
      newReq({ authorUid: 'u-t1', authorMemberCode: 'GV001', type: 'attendance_fix', sessionId: 'sess-open' })));
  });
  it('không tạo đơn đã approved / mạo danh tác giả / reason rỗng / type lạ', async () => {
    const db = as(env, 's1');
    await assertFails(setDoc(doc(db, 'requests/a'), newReq({ status: 'approved' })));
    await assertFails(setDoc(doc(db, 'requests/b'), newReq({ authorUid: 'u-s2', authorMemberCode: 'SE1002' })));
    await assertFails(setDoc(doc(db, 'requests/c'), newReq({ reason: '' })));
    await assertFails(setDoc(doc(db, 'requests/d'), newReq({ type: 'hack' })));
  });
  it('tác giả đọc đơn của mình, người khác không đọc', async () => {
    await assertSucceeds(getDoc(doc(as(env, 's1'), 'requests/req-s1')));
    await assertFails(getDoc(doc(as(env, 's2'), 'requests/req-s1')));
    await assertFails(getDoc(doc(as(env, 't1'), 'requests/req-s1')));
    await assertSucceeds(getDoc(doc(as(env, 'admin'), 'requests/req-s1')));
  });
  it('admin duyệt đơn pending; không duyệt lại đơn đã xử lý', async () => {
    const adm = as(env, 'admin');
    await assertSucceeds(updateDoc(doc(adm, 'requests/req-s1'), { status: 'approved', resolvedBy: 'AD01', resolvedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(adm, 'requests/req-done'), { status: 'rejected' }));
  });
  it('SV/GV không tự duyệt đơn của mình', async () => {
    await assertFails(updateDoc(doc(as(env, 's1'), 'requests/req-s1'), { status: 'approved' }));
    await assertFails(updateDoc(doc(as(env, 't1'), 'requests/req-s1'), { status: 'approved' }));
  });
  it('admin không sửa nội dung đơn khi duyệt', async () => {
    await assertFails(updateDoc(doc(as(env, 'admin'), 'requests/req-s1'), { status: 'approved', reason: 'đổi lý do' }));
  });
  it('tác giả rút đơn pending, không xóa đơn đã duyệt', async () => {
    await assertSucceeds(deleteDoc(doc(as(env, 's1'), 'requests/req-s1')));
    await assertFails(deleteDoc(doc(as(env, 's1'), 'requests/req-done')));
  });
});

describe('announcements', () => {
  it('đọc theo audience: all, staff, user', async () => {
    await assertSucceeds(getDoc(doc(as(env, 's1'), 'announcements/ann-all')));
    await assertSucceeds(getDoc(doc(as(env, 's1'), 'announcements/ann-user')));
    await assertFails(getDoc(doc(as(env, 's1'), 'announcements/ann-staff')));
    await assertSucceeds(getDoc(doc(as(env, 't1'), 'announcements/ann-staff')));
    await assertFails(getDoc(doc(as(env, 't1'), 'announcements/ann-user')));
    await assertSucceeds(getDoc(doc(as(env, 'admin'), 'announcements/ann-user')));
  });
  it('GV query inbox với audience in [all, staff]', async () => {
    const q = query(collection(as(env, 't1'), 'announcements'), where('audience', 'in', ['all', 'staff']));
    await assertSucceeds(getDocs(q));
  });
  it('chỉ admin phát hành / sửa / xóa', async () => {
    const data = { audience: 'all', title: 'T', body: 'B', createdAt: serverTimestamp() };
    await assertFails(setDoc(doc(as(env, 't1'), 'announcements/n'), data));
    await assertFails(setDoc(doc(as(env, 's1'), 'announcements/n'), data));
    await assertSucceeds(setDoc(doc(as(env, 'admin'), 'announcements/n'), data));
    await assertFails(deleteDoc(doc(as(env, 't1'), 'announcements/ann-all')));
  });
});
