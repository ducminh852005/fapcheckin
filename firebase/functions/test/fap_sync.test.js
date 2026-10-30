import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { fakeDb } from './fakes.js';
import { runFapSync, FapSyncError } from '../src/fap_sync.js';

function seedDb() {
  const db = fakeDb({
    'users/u-t1': { memberCode: 'GV001', role: 'staff', active: true },
    'users/u-t2': { memberCode: 'GV002', role: 'staff', active: true },
    'users/u-student': { memberCode: 'HE180101', role: 'user', active: true },
    'classes/PRN231_SE1801': { classCode: 'PRN231_SE1801', teacherMemberCode: 'GV001' },
    'classes/SWT301_SE1802': { classCode: 'SWT301_SE1802', teacherMemberCode: 'GV002' },
    'attendance_records/s1_HE180101': {
      sessionId: 's1',
      classCode: 'PRN231_SE1801',
      teacherMemberCode: 'GV001',
      rollNumber: 'HE180101',
      status: 'Present',
      syncedToFap: false,
    },
    'attendance_records/s1_HE180102': {
      sessionId: 's1',
      classCode: 'PRN231_SE1801',
      teacherMemberCode: 'GV001',
      rollNumber: 'HE180102',
      status: 'Absent',
      syncedToFap: true,
    },
  });
  return db;
}

describe('runFapSync', () => {
  it('đồng bộ các bản ghi chưa đồng bộ và đánh dấu syncedToFap = true', async () => {
    const db = seedDb();
    const deps = { db, serverTimestamp: () => 'TS' };
    const first = await runFapSync(deps, { uid: 'u-t1', classCode: 'PRN231_SE1801' });
    assert.equal(first.syncedCount, 1);
    const updated = (await db.doc('attendance_records/s1_HE180101').get()).data();
    assert.equal(updated.syncedToFap, true);
    assert.equal(updated.updatedBy, 'GV001');

    // Gọi lại lần 2 -> không còn bản ghi chưa đồng bộ
    const second = await runFapSync(deps, { uid: 'u-t1', classCode: 'PRN231_SE1801' });
    assert.equal(second.syncedCount, 0);
  });

  it('từ chối người chưa đăng nhập, sinh viên hoặc lớp của giảng viên khác', async () => {
    const db = seedDb();
    const deps = { db, serverTimestamp: () => 'TS' };
    await assert.rejects(() => runFapSync(deps, {}), (e) => e instanceof FapSyncError && e.code === 'UNAUTHORIZED');
    await assert.rejects(
      () => runFapSync(deps, { uid: 'u-student' }),
      (e) => e instanceof FapSyncError && e.code === 'FORBIDDEN',
    );
    await assert.rejects(
      () => runFapSync(deps, { uid: 'u-t1', classCode: 'SWT301_SE1802' }),
      (e) => e instanceof FapSyncError && e.code === 'FORBIDDEN',
    );
  });
});
