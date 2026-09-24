const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

function setup() {
  const tables = {
    Class_Section: [
      { classCode: 'SE1917', subjectCode: 'PRN232', teacherMemberCode: '' },
      { classCode: 'SE1927-SWD392', subjectCode: 'SWD392', teacherMemberCode: 'OTHER' },
      { classCode: 'SE1922', subjectCode: 'PRM393', teacherMemberCode: 'T1' },
    ],
  };
  const cache = new Map();
  let released = 0;
  const context = vm.createContext({
    JSON,
    AuthService: {
      requireTeacher: params => {
        if (params.sessionToken !== 'valid') throw Object.assign(new Error('Unauthorized'), { code: 'UNAUTHORIZED' });
        return { memberCode: 'T1' };
      },
    },
    SheetDB: {
      getRowsAsObjects: name => tables[name],
      updateRow: (name, field, value, updates) => {
        const row = tables[name].find(item => String(item[field]) === String(value));
        if (!row) return false;
        Object.assign(row, updates);
        return true;
      },
    },
    CacheService: {
      getScriptCache: () => ({
        get: key => cache.get(key) || null,
        put: (key, value) => cache.set(key, value),
        remove: key => cache.delete(key),
      }),
    },
    LockService: {
      getScriptLock: () => ({ waitLock: () => {}, releaseLock: () => released++ }),
    },
    Utilities: { getUuid: () => 'scan-1' },
    throwError: (code, message) => { throw Object.assign(new Error(message), { code }); },
  });
  vm.runInContext(fs.readFileSync('apps-script/TimetableImportService.gs', 'utf8'), context);
  return { api: context.TimetableImportService, tables, cache, get released() { return released; } };
}

test('parses class-subject pairs, rooms and timetable dates from noisy OCR', () => {
  const { api } = setup();
  const parsed = api.parseText(`WEEK 07/09 To 13/09
    SE1917-PRN232 at NVH
    602 (Not yet)
    SE1927–SWD392 at NVH 611
    SE1917-PRN232 at NVH 602`);
  assert.deepEqual(JSON.parse(JSON.stringify(parsed.entries)), [
    { key: 'SE1917|PRN232', classCode: 'SE1917', subjectCode: 'PRN232', room: '602' },
    { key: 'SE1927|SWD392', classCode: 'SE1927', subjectCode: 'SWD392', room: '611' },
  ]);
  assert.deepEqual(Array.from(parsed.detectedDates), ['07/09', '13/09']);
});

test('matches available, conflicting and already assigned classes', () => {
  const { api } = setup();
  const parsed = api.parseText('SE1917-PRN232 at NVH 602\nSE1927-SWD392 at NVH 611\nSE1922-PRM393 at NVH 604');
  const entries = api.matchEntries(parsed, { memberCode: 'T1' });
  assert.deepEqual(Array.from(entries, entry => entry.status), ['available', 'conflict', 'alreadyAssigned']);
  assert.equal(entries[1].matchedClassCode, 'SE1927-SWD392');
});

test('imports only cache-authorized unowned classes and is idempotent', () => {
  const backend = setup();
  backend.cache.set('timetable-scan:proof', JSON.stringify({ teacherMemberCode: 'T1', classCodes: ['SE1917'] }));
  const first = backend.api.importAssignments({ sessionToken: 'valid', scanToken: 'proof', classCodes: ['SE1917'] });
  assert.equal(first.assignedCount, 1);
  assert.equal(backend.tables.Class_Section[0].teacherMemberCode, 'T1');
  assert.equal(backend.released, 1);

  backend.cache.set('timetable-scan:proof-2', JSON.stringify({ teacherMemberCode: 'T1', classCodes: ['SE1917'] }));
  const retry = backend.api.importAssignments({ sessionToken: 'valid', scanToken: 'proof-2', classCodes: ['SE1917'] });
  assert.equal(retry.alreadyAssignedCount, 1);
});

test('rejects expired proofs, forged classes and ownership races', () => {
  const backend = setup();
  assert.throws(
    () => backend.api.importAssignments({ sessionToken: 'valid', scanToken: 'missing', classCodes: ['SE1917'] }),
    { code: 'SCAN_EXPIRED' },
  );
  backend.cache.set('timetable-scan:proof', JSON.stringify({ teacherMemberCode: 'T1', classCodes: ['SE1917'] }));
  assert.throws(
    () => backend.api.importAssignments({ sessionToken: 'valid', scanToken: 'proof', classCodes: ['SE1927-SWD392'] }),
    { code: 'FORBIDDEN' },
  );
  backend.tables.Class_Section[0].teacherMemberCode = 'OTHER';
  assert.throws(
    () => backend.api.importAssignments({ sessionToken: 'valid', scanToken: 'proof', classCodes: ['SE1917'] }),
    { code: 'ASSIGNMENT_CONFLICT' },
  );
});

test('validates the entire import before writing any assignment', () => {
  const backend = setup();
  backend.tables.Class_Section.push({ classCode: 'SE1999', subjectCode: 'PRN999', teacherMemberCode: 'OTHER' });
  backend.cache.set('timetable-scan:batch', JSON.stringify({
    teacherMemberCode: 'T1',
    classCodes: ['SE1917', 'SE1999'],
  }));
  assert.throws(
    () => backend.api.importAssignments({
      sessionToken: 'valid',
      scanToken: 'batch',
      classCodes: ['SE1917', 'SE1999'],
    }),
    { code: 'ASSIGNMENT_CONFLICT' },
  );
  assert.equal(backend.tables.Class_Section[0].teacherMemberCode, '');
});
