// Nhắc lịch trước giờ dạy. Cloud Scheduler gọi mỗi 5 phút; với mỗi GV bật
// `user_preferences/{uid}.reminders`, tìm buổi dạy hôm nay (lịch cố định theo slot của lớp
// + lịch bổ sung `class_schedules`) bắt đầu trong LEAD_MINUTES phút tới, tạo thông báo
// trong app (id xác định -> chỉ một lần) rồi push FCM.
import { createNotification, pushToUser, safeId } from './notify.js';

export const LEAD_MINUTES = 15;
const VN_OFFSET_MS = 7 * 60 * 60 * 1000; // Asia/Ho_Chi_Minh, không có giờ mùa hè

// Bảng slot chuẩn khi Firestore chưa seed `slots`/`timeSlots` (khớp scripts/seed-reference.mjs).
const FALLBACK_START = { 'A-1': '07:00', 'A-2': '09:30', 'P-1': '12:30', 'P-2': '15:00' };
const FALLBACK_WEEKDAYS = { 1: [2, 5], 2: [2, 5], 3: [3, 6], 4: [3, 6], 5: [4, 7], 6: [4, 7] };

/** Ngày (YYYY-MM-DD) và thứ theo quy ước VN (2 = thứ hai ... 7 = thứ bảy, 8 = chủ nhật). */
export function vnDay(now) {
  const d = new Date(now.getTime() + VN_OFFSET_MS);
  const js = d.getUTCDay();
  return { day: d.toISOString().slice(0, 10), weekday: js === 0 ? 8 : js + 1 };
}

function validTime(v) {
  const m = /^(\d{1,2}):(\d{2})(?::\d{2})?$/.exec(String(v ?? '').trim());
  if (!m || Number(m[1]) > 23 || Number(m[2]) > 59) return '';
  return `${m[1].padStart(2, '0')}:${m[2]}`;
}

/** slotCode -> { startTime, weekdays } từ `slots` + `timeSlots`, có bảng dự phòng. */
export function buildSlotTable(slotDocs, timeSlotDocs) {
  const times = Object.fromEntries(timeSlotDocs.map((t) => [t.timeSlotId ?? t.id, validTime(t.startTime)]));
  const table = {};
  for (const letter of ['A', 'P']) {
    for (let n = 1; n <= 6; n++) {
      const id = `${letter}-${n % 2 === 1 ? 1 : 2}`;
      table[`${letter}${n}`] = { startTime: times[id] || FALLBACK_START[id], weekdays: FALLBACK_WEEKDAYS[n] };
    }
  }
  for (const s of slotDocs) {
    const code = s.slotCode ?? s.id;
    if (!code) continue;
    const startTime = validTime(s.startTime) || times[s.timeSlotId] || table[code]?.startTime || '';
    const weekdays = Array.isArray(s.weekdays) ? s.weekdays.map(Number) : (table[code]?.weekdays ?? []);
    table[code] = { startTime, weekdays };
  }
  return table;
}

/**
 * Buổi dạy bắt đầu trong (now, now + leadMinutes]. Thuần, không I/O.
 * @param classes [{classCode, subjectCode, subjectName, slotCode, room}]
 * @param plans   class_schedules của GV trong ngày `day`
 */
export function upcomingLessons({ classes, plans, slotTable, now, leadMinutes = LEAD_MINUTES }) {
  const { day, weekday } = vnDay(now);
  const horizon = now.getTime() + leadMinutes * 60 * 1000;
  const byCode = Object.fromEntries(classes.map((c) => [c.classCode, c]));
  const out = [];
  const seen = new Set();
  const add = (cls, slotCode, room, isMakeup) => {
    const slot = slotTable[slotCode];
    if (!cls || !slot?.startTime) return;
    const startAt = new Date(`${day}T${slot.startTime}:00+07:00`);
    if (startAt.getTime() <= now.getTime() || startAt.getTime() > horizon) return;
    const key = `${day}_${cls.classCode}_${slotCode}`;
    if (seen.has(key)) return;
    seen.add(key);
    out.push({
      key, day, classCode: cls.classCode, slotCode, startTime: slot.startTime, startAt, isMakeup,
      subject: cls.subjectCode || cls.subjectName || cls.classCode, room: room || cls.room || '',
    });
  };
  for (const cls of classes) {
    if (cls.slotCode && slotTable[cls.slotCode]?.weekdays.includes(weekday)) add(cls, cls.slotCode, cls.room, false);
  }
  for (const p of plans) {
    if (p.status === 'cancelled' || p.scheduleDate !== day) continue;
    add(byCode[p.classCode], p.slotCode, p.room, true);
  }
  return out;
}

export function reminderMessage(lesson) {
  const where = lesson.room ? ` tại phòng ${lesson.room}` : '';
  return {
    title: lesson.isMakeup ? 'Sắp đến buổi học bù' : 'Sắp đến giờ dạy',
    body: `${lesson.subject} (${lesson.classCode}) bắt đầu lúc ${lesson.startTime}${where} — slot ${lesson.slotCode}.`,
  };
}

const docs = (snap) => snap.docs.map((d) => ({ id: d.id, ...d.data() }));

/**
 * @param deps {db, messaging?, serverTimestamp, toTimestamp, log?}
 * @returns thống kê để ghi log
 */
export async function runReminders(deps, { now = new Date(), leadMinutes = LEAD_MINUTES } = {}) {
  const { db, toTimestamp, log = () => {} } = deps;
  const summary = { candidates: 0, notified: 0, pushed: 0, pushFailed: 0, tokensRemoved: 0, errors: 0 };
  const prefs = await db.collection('user_preferences').where('reminders', '==', true).get();
  if (prefs.docs.length === 0) return summary;

  const [slots, timeSlots] = await Promise.all([db.collection('slots').get(), db.collection('timeSlots').get()]);
  const slotTable = buildSlotTable(docs(slots), docs(timeSlots));
  const { day } = vnDay(now);

  for (const pref of prefs.docs) {
    const uid = pref.id;
    try {
      const snap = await db.doc(`users/${uid}`).get();
      const profile = snap.exists ? snap.data() : null;
      if (!profile || profile.role !== 'staff' || profile.active === false || !profile.memberCode) continue;
      summary.candidates++;

      const [classSnap, planSnap] = await Promise.all([
        db.collection('classes').where('teacherMemberCode', '==', profile.memberCode).get(),
        db.collection('class_schedules').where('teacherMemberCode', '==', profile.memberCode)
          .where('scheduleDate', '==', day).get(),
      ]);
      const classes = docs(classSnap).map((c) => ({ ...c, classCode: c.classCode || c.id }));
      const lessons = upcomingLessons({ classes, plans: docs(planSnap), slotTable, now, leadMinutes });

      for (const lesson of lessons) {
        const id = safeId(`lesson_${lesson.key}`);
        const message = reminderMessage(lesson);
        const created = await createNotification(deps, uid, id, {
          type: 'teaching_reminder', ...message,
          data: { classCode: lesson.classCode, slotCode: lesson.slotCode, room: lesson.room,
            startAt: toTimestamp(lesson.startAt), isMakeup: lesson.isMakeup },
        });
        if (!created) continue; // lượt chạy trước đã nhắc
        summary.notified++;
        const push = await pushToUser(deps, uid, {
          ...message,
          data: { type: 'teaching_reminder', notificationId: id, classCode: lesson.classCode, slotCode: lesson.slotCode },
        });
        summary.pushed += push.sent;
        summary.pushFailed += push.failed;
        summary.tokensRemoved += push.removed;
      }
    } catch (error) {
      summary.errors++;
      log('reminder failed', uid, error);
    }
  }
  return summary;
}
