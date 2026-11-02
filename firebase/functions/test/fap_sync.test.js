import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { fakeDb } from './fakes.js';
import { runFapSync, FapSyncError, FAP_REQUEST_TIMEOUT_MS } from '../src/fap_sync.js';

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
  it('đồng bộ các bản ghi chưa đồng bộ và đánh dấu syncedToFap = true', async (t) => {
    t.mock.timers.enable({ apis: ['setTimeout'] });
    const db = seedDb();
    const requests = [];
    const deps = {
      db,
      serverTimestamp: () => 'TS',
      fapUrl: 'https://fap.example.test/attendance',
      fetchImpl: async (url, options) => {
        requests.push({ url, options });
        return { ok: true, status: 200 };
      },
    };
    const first = await runFapSync(deps, { uid: 'u-t1', classCode: 'PRN231_SE1801' });
    assert.equal(first.syncedCount, 1);
    assert.equal(requests.length, 1);
    assert.equal(requests[0].url, deps.fapUrl);
    const updated = (await db.doc('attendance_records/s1_HE180101').get()).data();
    assert.equal(updated.syncedToFap, true);
    assert.equal(updated.updatedBy, 'GV001');
    t.mock.timers.tick(FAP_REQUEST_TIMEOUT_MS);
    assert.equal(requests[0].options.signal.aborted, false, 'success clears the timeout');

    // Gọi lại lần 2 -> không còn bản ghi chưa đồng bộ
    const second = await runFapSync(deps, { uid: 'u-t1', classCode: 'PRN231_SE1801' });
    assert.equal(second.syncedCount, 0);
  });

  it('aborts a stalled gateway without marking records as synced (CR-05)', async (t) => {
    t.mock.timers.enable({ apis: ['setTimeout'] });
    const db = seedDb();
    const before = (await db.doc('attendance_records/s1_HE180101').get()).data();
    let signal;
    let started;
    const requestStarted = new Promise((resolve) => { started = resolve; });
    const pending = runFapSync({
      db,
      serverTimestamp: () => assert.fail('must not write after timeout'),
      fapUrl: 'https://fap.example.test/attendance',
      fetchImpl: (_url, options) => new Promise((_resolve, reject) => {
        signal = options.signal;
        signal.addEventListener('abort', () => reject(signal.reason), { once: true });
        started();
      }),
    }, { uid: 'u-t1' });
    const rejected = assert.rejects(pending, (e) =>
      e instanceof FapSyncError && e.status === 'deadline-exceeded' && e.code === 'UPSTREAM_TIMEOUT');
    await requestStarted;
    t.mock.timers.tick(FAP_REQUEST_TIMEOUT_MS - 1);
    assert.equal(signal.aborted, false);
    t.mock.timers.tick(1);
    await rejected;
    assert.equal(signal.aborted, true);
    assert.deepEqual((await db.doc('attendance_records/s1_HE180101').get()).data(), before);
  });

  it('preserves network and HTTP errors and clears their timeout', async (t) => {
    t.mock.timers.enable({ apis: ['setTimeout'] });
    const networkError = new TypeError('fetch failed');
    for (const failure of [networkError, { ok: false, status: 503 }]) {
      const db = seedDb();
      let signal;
      await assert.rejects(() => runFapSync({
        db,
        serverTimestamp: () => assert.fail('must not write after gateway failure'),
        fapUrl: 'https://fap.example.test/attendance',
        fetchImpl: async (_url, options) => {
          signal = options.signal;
          if (failure === networkError) throw failure;
          return failure;
        },
      }, { uid: 'u-t1' }), (e) => failure === networkError
        ? e === networkError
        : e instanceof FapSyncError && e.code === 'UPSTREAM_ERROR');
      t.mock.timers.tick(FAP_REQUEST_TIMEOUT_MS);
      assert.equal(signal.aborted, false, 'failure clears the timeout');
      assert.equal((await db.doc('attendance_records/s1_HE180101').get()).data().syncedToFap, false);
    }
  });

  it('does not mark records as synced when the FAP gateway is missing', async () => {
    const db = seedDb();
    await assert.rejects(
      () => runFapSync({ db, serverTimestamp: () => 'TS', fapUrl: '' }, { uid: 'u-t1' }),
      (e) => e instanceof FapSyncError && e.code === 'FAP_NOT_CONFIGURED',
    );
    const record = (await db.doc('attendance_records/s1_HE180101').get()).data();
    assert.equal(record.syncedToFap, false);
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
