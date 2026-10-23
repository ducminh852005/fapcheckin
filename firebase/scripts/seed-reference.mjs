// Ghi dữ liệu tham chiếu cố định: 4 khung giờ (timeSlots) và 12 mã slot A/P (slots).
// Quy tắc lịch: docs/03-du-lieu-firestore.md §3. Chạy lại bao nhiêu lần cũng được.
//
//   node scripts/seed-reference.mjs [--emulator] [--project <id>]
import { pathToFileURL } from 'node:url';
import { connect, parseArgs, writeAll } from './lib.mjs';

export const TIME_SLOTS = [
  { timeSlotId: 'A-1', period: 'Morning', slotInPeriod: 1, daySlotNo: 1, startTime: '07:00', endTime: '09:15' },
  { timeSlotId: 'A-2', period: 'Morning', slotInPeriod: 2, daySlotNo: 2, startTime: '09:30', endTime: '11:45' },
  { timeSlotId: 'P-1', period: 'Afternoon', slotInPeriod: 1, daySlotNo: 3, startTime: '12:30', endTime: '14:45' },
  { timeSlotId: 'P-2', period: 'Afternoon', slotInPeriod: 2, daySlotNo: 4, startTime: '15:00', endTime: '17:15' },
];
// Chữ số trong mã slot -> các thứ trong tuần (2 = thứ hai ... 7 = thứ bảy)
const WEEKDAYS = { 1: [2, 5], 2: [2, 5], 3: [3, 6], 4: [3, 6], 5: [4, 7], 6: [4, 7] };

export function buildSlots() {
  const slots = [];
  for (const letter of ['A', 'P']) {
    for (let n = 1; n <= 6; n++) {
      slots.push({
        slotCode: `${letter}${n}`,
        timeSlotId: `${letter}-${n % 2 === 1 ? 1 : 2}`,
        weekdays: WEEKDAYS[n],
      });
    }
  }
  return slots;
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  const args = parseArgs();
  const { db, projectId } = connect(args);
  const t = await writeAll(db, 'timeSlots', TIME_SLOTS.map((d) => ({ id: d.timeSlotId, data: d })));
  const s = await writeAll(db, 'slots', buildSlots().map((d) => ({ id: d.slotCode, data: d })));
  console.log(`[${projectId}] timeSlots: ${t}, slots: ${s}`);
}
