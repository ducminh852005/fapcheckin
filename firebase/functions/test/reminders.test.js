import { test } from 'node:test';
import assert from 'node:assert/strict';
import { buildSlotTable, runReminders, upcomingLessons, vnDay } from '../src/reminders.js';
import { deps, fakeDb, fakeMessaging } from './fakes.js';

// 26/10/2026 là thứ hai (weekday 2). Giờ VN = UTC+7.
const at = (vnTime, day = '2026-10-26') => new Date(`${day}T${vnTime}:00+07:00`);
const slotTable = buildSlotTable(
  [{ slotCode: 'A1', timeSlotId: 'A-1', weekdays: [2, 5] }, { slotCode: 'P1', timeSlotId: 'P-1', weekdays: [3, 6] }],
  [{ timeSlotId: 'A-1', startTime: '07:00' }, { timeSlotId: 'P-1', startTime: '12:30' }],
);
const classes = [
  { classCode: 'PRN232_SE1917', subjectCode: 'PRN232', slotCode: 'A1', room: '303' },
  { classCode: 'SWD392_SE1801', subjectCode: 'SWD392', slotCode: 'P1', room: '101' },
];

test('vnDay dùng múi giờ VN và quy ước thứ 2..8', () => {
  assert.deepEqual(vnDay(new Date('2026-10-25T23:50:00Z')), { day: '2026-10-26', weekday: 2 });
  assert.deepEqual(vnDay(new Date('2026-10-25T10:00:00Z')), { day: '2026-10-25', weekday: 8 });
});

test('buildSlotTable có bảng dự phòng khi chưa seed slots', () => {
  const table = buildSlotTable([], []);
  assert.deepEqual(table.A1, { startTime: '07:00', weekdays: [2, 5] });
  assert.deepEqual(table.P4, { startTime: '15:00', weekdays: [3, 6] });
});

test('upcomingLessons chỉ lấy buổi bắt đầu trong 15 phút tới, đúng thứ', () => {
  const pick = (now) => upcomingLessons({ classes, plans: [], slotTable, now }).map((l) => l.classCode);
  assert.deepEqual(pick(at('06:50')), ['PRN232_SE1917']);
  assert.deepEqual(pick(at('06:45')), ['PRN232_SE1917']);
  assert.deepEqual(pick(at('06:40')), []); // còn 20 phút
  assert.deepEqual(pick(at('07:00')), []); // đã bắt đầu
  assert.deepEqual(pick(at('06:50', '2026-10-27')), []); // thứ ba không có A1
});

test('upcomingLessons tính lịch bổ sung, bỏ lịch đã hủy', () => {
  const plans = [
    { classCode: 'PRN232_SE1917', scheduleDate: '2026-10-26', slotCode: 'P1', room: '999', status: 'scheduled' },
    { classCode: 'SWD392_SE1801', scheduleDate: '2026-10-26', slotCode: 'P1', status: 'cancelled' },
    { classCode: 'NOT_MINE', scheduleDate: '2026-10-26', slotCode: 'P1', status: 'scheduled' },
  ];
  const lessons = upcomingLessons({ classes, plans, slotTable, now: at('12:20') });
  assert.equal(lessons.length, 1);
  assert.equal(lessons[0].classCode, 'PRN232_SE1917');
  assert.equal(lessons[0].room, '999');
  assert.equal(lessons[0].isMakeup, true);
});

function seeded() {
  return fakeDb({
    'slots/A1': { slotCode: 'A1', timeSlotId: 'A-1', weekdays: [2, 5] },
    'timeSlots/A-1': { timeSlotId: 'A-1', startTime: '07:00' },
    'users/u-t1': { role: 'staff', memberCode: 'GV001', active: true },
    'users/u-t2': { role: 'staff', memberCode: 'GV002', active: true },
    'users/u-t3': { role: 'staff', memberCode: 'GV003', active: false },
    'users/u-s1': { role: 'user', memberCode: 'SE1001', active: true },
    'user_preferences/u-t1': { reminders: true, theme: 'light', language: 'vi' },
    'user_preferences/u-t2': { reminders: false, theme: 'light', language: 'vi' },
    'user_preferences/u-t3': { reminders: true, theme: 'light', language: 'vi' },
    'user_preferences/u-s1': { reminders: true, theme: 'light', language: 'vi' },
    'classes/PRN232_SE1917': { subjectCode: 'PRN232', teacherMemberCode: 'GV001', slotCode: 'A1', room: '303' },
    'classes/SWD392_SE1801': { subjectCode: 'SWD392', teacherMemberCode: 'GV002', slotCode: 'A1', room: '101' },
    'classes/MAD101_SE1700': { subjectCode: 'MAD101', teacherMemberCode: 'GV003', slotCode: 'A1', room: '202' },
    'device_tokens/u-t1/tokens/good': { token: 'tok-good' },
    'device_tokens/u-t1/tokens/stale': { token: 'tok-stale' },
  });
}

test('runReminders tạo thông báo một lần, push FCM và xóa token hỏng', async () => {
  const db = seeded();
  const fcm = fakeMessaging({ 'tok-stale': 'messaging/registration-token-not-registered' });
  const summary = await runReminders(deps(db, fcm), { now: at('06:50') });

  assert.equal(summary.candidates, 1, 'chỉ GV đang hoạt động có bật nhắc');
  assert.equal(summary.notified, 1);
  assert.equal(summary.pushed, 1);
  assert.equal(summary.tokensRemoved, 1);
  const item = db.store.get('user_notifications/u-t1/items/lesson_2026-10-26_PRN232_SE1917_A1');
  assert.equal(item.type, 'teaching_reminder');
  assert.equal(item.read, false);
  assert.equal(item.classCode, 'PRN232_SE1917');
  assert.match(item.body, /07:00.*303/);
  assert.equal(db.store.has('device_tokens/u-t1/tokens/stale'), false);
  assert.equal(db.store.has('device_tokens/u-t1/tokens/good'), true);
  assert.deepEqual(fcm.sent[0].tokens, ['tok-good', 'tok-stale']);
  assert.equal(fcm.sent[0].data.classCode, 'PRN232_SE1917');

  // Không ai khác nhận thông báo.
  const others = [...db.store.keys()].filter((k) => k.startsWith('user_notifications/') && !k.includes('/u-t1/'));
  assert.deepEqual(others, []);

  // Lượt cron kế tiếp (5 phút sau) không nhắc lại.
  const again = await runReminders(deps(db, fcm), { now: at('06:55') });
  assert.equal(again.notified, 0);
  assert.equal(fcm.sent.length, 1);
});

test('runReminders vẫn tạo thông báo trong app khi không có FCM / token', async () => {
  const db = seeded();
  db.store.delete('device_tokens/u-t1/tokens/good');
  db.store.delete('device_tokens/u-t1/tokens/stale');
  const summary = await runReminders(deps(db, null), { now: at('06:50') });
  assert.equal(summary.notified, 1);
  assert.equal(summary.pushed, 0);
});

test('runReminders không làm gì khi không ai bật nhắc', async () => {
  const db = fakeDb({ 'user_preferences/u-t1': { reminders: false } });
  assert.deepEqual(await runReminders(deps(db), { now: at('06:50') }),
    { candidates: 0, notified: 0, pushed: 0, pushFailed: 0, tokensRemoved: 0, errors: 0 });
});
