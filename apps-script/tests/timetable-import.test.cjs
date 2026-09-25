const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

function setup(overrides = {}) {
  const tables = {
    Class_Section: [
      { classCode: 'PRN232_SE1917', teacherMemberCode: '' },
      { classCode: 'SWD392_SE1927', teacherMemberCode: 'OTHER' },
      { classCode: 'PRM393_SE1922', teacherMemberCode: 'T1' },
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
    Utilities: {
      getUuid: () => 'scan-1',
      base64Decode: value => Buffer.from(value, 'base64'),
      newBlob: (bytes, mimeType, name) => ({ bytes, mimeType, name }),
      sleep: overrides.sleep || (() => {}),
    },
    Drive: overrides.Drive,
    DriveApp: overrides.DriveApp,
    DocumentApp: overrides.DocumentApp,
    console,
    throwError: (code, message) => { throw Object.assign(new Error(message), { code }); },
  });
  vm.runInContext(fs.readFileSync('apps-script/TimetableImportService.gs', 'utf8'), context);
  return { api: context.TimetableImportService, tables, cache, get released() { return released; } };
}

test('manifest enables Drive OCR and declares its required OAuth scopes', () => {
  const manifest = JSON.parse(fs.readFileSync('apps-script/appsscript.json', 'utf8'));
  assert.ok(manifest.dependencies.enabledAdvancedServices.some(service =>
    service.userSymbol === 'Drive' && service.serviceId === 'drive' && service.version === 'v3'
  ));
  assert.ok(manifest.oauthScopes.includes('https://www.googleapis.com/auth/drive'));
  assert.ok(manifest.oauthScopes.includes('https://www.googleapis.com/auth/documents'));
});

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

test('parses class-subject pairs when OCR drops the location label or inserts spaces', () => {
  const { api } = setup();
  const parsed = api.parseText(`SE 1917 - PRN 232\nSE1927_PRM393\nSE1917 PRN232`);
  assert.deepEqual(JSON.parse(JSON.stringify(parsed.entries)), [
    { key: 'SE1917|PRN232', classCode: 'SE1917', subjectCode: 'PRN232', room: '' },
    { key: 'SE1927|PRM393', classCode: 'SE1927', subjectCode: 'PRM393', room: '' },
  ]);
});

test('waits for the converted OCR document before parsing it', () => {
  let reads = 0;
  let trashed = false;
  const backend = setup({
    Drive: { Files: { create: () => ({ id: 'doc-1' }) } },
    DocumentApp: {
      openById: () => {
        reads++;
        if (reads === 1) throw new Error('Document is not ready yet');
        return { getBody: () => ({ getText: () => 'SE1917-PRN232 at NVH 602' }) };
      },
    },
    DriveApp: { getFileById: () => ({ setTrashed: () => { trashed = true; } }) },
  });

  const result = backend.api.scan({
    sessionToken: 'valid',
    mimeType: 'image/jpeg',
    fileName: 'lich_hoc.jpg',
    imageBase64: 'aW1hZ2U=',
  });

  assert.equal(reads, 2);
  assert.equal(trashed, true);
  assert.equal(result.entries[0].classCode, 'SE1917');
  assert.equal(result.entries[0].room, '602');
});

test('reports missing OCR authorization instead of blaming image quality', () => {
  const backend = setup({
    Drive: { Files: { create: () => { throw new Error('Authorization is required'); } } },
    DocumentApp: {},
    DriveApp: {},
  });

  assert.throws(
    () => backend.api.scan({
      sessionToken: 'valid',
      mimeType: 'image/jpeg',
      fileName: 'lich_hoc.jpg',
      imageBase64: 'aW1hZ2U=',
    }),
    { code: 'OCR_NOT_CONFIGURED' },
  );
});

test('does not report missing authorization after Drive accepted the OCR image', () => {
  let reads = 0;
  const backend = setup({
    Drive: { Files: { create: () => ({ id: 'doc-pending' }) } },
    DocumentApp: {
      openById: () => {
        reads++;
        throw new Error('You do not have permission to access the requested document');
      },
    },
    DriveApp: { getFileById: () => ({ setTrashed: () => {} }) },
  });

  assert.throws(
    () => backend.api.scan({
      sessionToken: 'valid',
      mimeType: 'image/jpeg',
      fileName: 'lich_hoc.jpg',
      imageBase64: 'aW1hZ2U=',
    }),
    { code: 'OCR_PROCESSING_TIMEOUT' },
  );
  assert.equal(reads, 6);
});

test('matches available, conflicting and already assigned classes', () => {
  const { api } = setup();
  const parsed = api.parseText('SE1917-PRN232 at NVH 602\nSE1927-SWD392 at NVH 611\nSE1922-PRM393 at NVH 604');
  const entries = api.matchEntries(parsed, { memberCode: 'T1' });
  assert.deepEqual(Array.from(entries, entry => entry.status), ['available', 'conflict', 'alreadyAssigned']);
  assert.equal(entries[0].matchedClassCode, 'PRN232_SE1917');
  assert.equal(entries[1].matchedClassCode, 'SWD392_SE1927');
});

test('matches every class restored from the ten-entry timetable', () => {
  const backend = setup();
  backend.tables.Class_Section.splice(0, backend.tables.Class_Section.length,
    { classCode: 'PRN232_SE1917', teacherMemberCode: '' },
    { classCode: 'PRM393_SE1913', teacherMemberCode: '' },
    { classCode: 'PRM393_SE1917', teacherMemberCode: '' },
    { classCode: 'SWD392_SE1927', teacherMemberCode: '' },
    { classCode: 'PRN232_SE1920', teacherMemberCode: '' },
    { classCode: 'PRM393_SE1922', teacherMemberCode: '' },
    { classCode: 'PRN232_SE1919', teacherMemberCode: '' },
    { classCode: 'PRM393_SE1920', teacherMemberCode: '' },
    { classCode: 'PRM393_SE1928', teacherMemberCode: '' },
    { classCode: 'PRM393_SE1919', teacherMemberCode: '' },
  );
  const parsed = backend.api.parseText([
    'SE1917-PRN232', 'SE1913-PRM393', 'SE1917-PRM393', 'SE1927-SWD392',
    'SE1920-PRN232', 'SE1922-PRM393', 'SE1919-PRN232', 'SE1920-PRM393',
    'SE1928-PRM393', 'SE1919-PRM393',
  ].join('\n'));
  const entries = backend.api.matchEntries(parsed, { memberCode: 'T1' });

  assert.equal(entries.length, 10);
  assert.deepEqual(Array.from(entries, entry => entry.status), Array(10).fill('available'));
});

test('imports only cache-authorized unowned classes and is idempotent', () => {
  const backend = setup();
  backend.cache.set('timetable-scan:proof', JSON.stringify({ teacherMemberCode: 'T1', classCodes: ['PRN232_SE1917'] }));
  const first = backend.api.importAssignments({ sessionToken: 'valid', scanToken: 'proof', classCodes: ['PRN232_SE1917'] });
  assert.equal(first.assignedCount, 1);
  assert.equal(backend.tables.Class_Section[0].teacherMemberCode, 'T1');
  assert.equal(backend.released, 1);

  backend.cache.set('timetable-scan:proof-2', JSON.stringify({ teacherMemberCode: 'T1', classCodes: ['PRN232_SE1917'] }));
  const retry = backend.api.importAssignments({ sessionToken: 'valid', scanToken: 'proof-2', classCodes: ['PRN232_SE1917'] });
  assert.equal(retry.alreadyAssignedCount, 1);
});

test('rejects expired proofs, forged classes and ownership races', () => {
  const backend = setup();
  assert.throws(
    () => backend.api.importAssignments({ sessionToken: 'valid', scanToken: 'missing', classCodes: ['SE1917'] }),
    { code: 'SCAN_EXPIRED' },
  );
  backend.cache.set('timetable-scan:proof', JSON.stringify({ teacherMemberCode: 'T1', classCodes: ['PRN232_SE1917'] }));
  assert.throws(
    () => backend.api.importAssignments({ sessionToken: 'valid', scanToken: 'proof', classCodes: ['SWD392_SE1927'] }),
    { code: 'FORBIDDEN' },
  );
  backend.tables.Class_Section[0].teacherMemberCode = 'OTHER';
  assert.throws(
    () => backend.api.importAssignments({ sessionToken: 'valid', scanToken: 'proof', classCodes: ['PRN232_SE1917'] }),
    { code: 'ASSIGNMENT_CONFLICT' },
  );
});

test('validates the entire import before writing any assignment', () => {
  const backend = setup();
  backend.tables.Class_Section.push({ classCode: 'PRN999_SE1999', teacherMemberCode: 'OTHER' });
  backend.cache.set('timetable-scan:batch', JSON.stringify({
    teacherMemberCode: 'T1',
    classCodes: ['PRN232_SE1917', 'PRN999_SE1999'],
  }));
  assert.throws(
    () => backend.api.importAssignments({
      sessionToken: 'valid',
      scanToken: 'batch',
      classCodes: ['PRN232_SE1917', 'PRN999_SE1999'],
    }),
    { code: 'ASSIGNMENT_CONFLICT' },
  );
  assert.equal(backend.tables.Class_Section[0].teacherMemberCode, '');
});
