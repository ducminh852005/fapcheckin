const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const PROJECT = 'fapcheckin-3bn2di';
const DOCS = `projects/${PROJECT}/databases/(default)/documents`;
const BASE = `https://firestore.googleapis.com/v1/${DOCS}`;

// In-memory stand-in for the parts of the Firestore REST API the store uses.
function fakeFirestore() {
  const docs = new Map(); // 'collection/id' -> { fields, createTime }
  const calls = [];
  let clock = 0;
  const failures = []; // queued { status, message }

  const reply = (status, body) => ({
    getResponseCode: () => status,
    getContentText: () => (body === undefined ? '' : JSON.stringify(body)),
  });
  const docOf = (key) => ({ name: `${DOCS}/${key}`, fields: docs.get(key).fields, createTime: docs.get(key).createTime });
  const keysOf = (collection) => [...docs.keys()].filter((k) => k.split('/')[0] === collection);
  const stamp = () => new Date(Date.UTC(2026, 8, 1) + (++clock) * 1000).toISOString();
  const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);

  function fetch(url, opts) {
    const method = opts.method || 'GET';
    const body = opts.payload ? JSON.parse(opts.payload) : undefined;
    calls.push({ method, url, body, headers: opts.headers });
    if (failures.length) {
      const f = failures.shift();
      return reply(f.status, { error: { message: f.message || 'boom' } });
    }
    const rest = url.slice('https://firestore.googleapis.com/v1/'.length);
    const [pathPart, query = ''] = rest.split('?');
    const params = new URLSearchParams(query);

    if (pathPart === `${DOCS.replace('/documents', '')}/documents:runQuery` || pathPart.endsWith('/documents:runQuery')) {
      const q = body.structuredQuery;
      const collection = q.from[0].collectionId;
      let filters = [];
      if (q.where && q.where.fieldFilter) filters = [q.where.fieldFilter];
      if (q.where && q.where.compositeFilter) filters = q.where.compositeFilter.filters.map((f) => f.fieldFilter);
      const out = keysOf(collection).filter((k) => filters.every((f) => same((docs.get(k).fields || {})[f.field.fieldPath], f.value)))
        .map((k) => ({ document: docOf(k) }));
      return reply(200, out.length ? out : [{ readTime: 'x' }]);
    }
    if (pathPart.endsWith('/documents:batchWrite')) {
      const status = body.writes.map((w) => {
        const key = w.update.name.slice(`${DOCS}/`.length);
        const existing = docs.get(key);
        docs.set(key, { fields: w.update.fields, createTime: existing ? existing.createTime : stamp() });
        return {};
      });
      return reply(200, { status });
    }
    const rel = pathPart.slice(`projects/${PROJECT}/databases/(default)/documents`.length + 1);
    if (method === 'POST') {
      const id = params.get('documentId');
      const key = `${rel}/${decodeURIComponent(id)}`;
      if (docs.has(key)) return reply(409, { error: { message: 'Document already exists' } });
      docs.set(key, { fields: body.fields, createTime: stamp() });
      return reply(200, docOf(key));
    }
    if (method === 'PATCH') {
      const key = decodeURIComponent(rel);
      const mustExist = params.get('currentDocument.exists') === 'true';
      const existing = docs.get(key);
      if (mustExist && !existing) return reply(404, { error: { message: 'No document to update' } });
      const masked = params.getAll('updateMask.fieldPaths');
      const fields = existing ? { ...existing.fields } : {};
      (masked.length ? masked : Object.keys(body.fields)).forEach((f) => { if (body.fields[f]) fields[f] = body.fields[f]; });
      docs.set(key, { fields, createTime: existing ? existing.createTime : stamp() });
      return reply(200, docOf(key));
    }
    if (method === 'GET') {
      if (rel.includes('/')) {
        const key = decodeURIComponent(rel);
        return docs.has(key) ? reply(200, docOf(key)) : reply(404, { error: { message: 'not found' } });
      }
      const size = Number(params.get('pageSize') || 20);
      const offset = Number(params.get('pageToken') || 0);
      const keys = keysOf(rel);
      const page = keys.slice(offset, offset + size).map(docOf);
      const out = {};
      if (page.length) out.documents = page;
      if (offset + size < keys.length) out.nextPageToken = String(offset + size);
      return reply(200, out);
    }
    return reply(400, { error: { message: `unhandled ${method} ${url}` } });
  }

  return { docs, calls, fetch, failures };
}

function setup({ backend = 'firestore', tables = {}, services = [] } = {}) {
  const fs_ = fakeFirestore();
  const props = { DB_BACKEND: backend };
  let uuid = 0;
  const context = vm.createContext({
    Logger: { log: (line) => context.__logs.push(String(line)) },
    __logs: [],
    Utilities: {
      getUuid: () => `uuid-${++uuid}`,
      sleep: () => {},
      formatDate: (d, tz, fmt) => new Date(d.getTime() + 7 * 3600 * 1000).toISOString().slice(0, fmt === 'yyyy-MM-dd' ? 10 : 19),
    },
    ScriptApp: { getOAuthToken: () => 'tok-123' },
    PropertiesService: {
      getScriptProperties: () => ({
        getProperty: (k) => (k in props ? props[k] : null),
        setProperty: (k, v) => { props[k] = v; },
      }),
    },
    UrlFetchApp: { fetch: fs_.fetch },
    SpreadsheetApp: {
      openById: () => ({
        getSheetByName: (name) => tables[name] && ({ getDataRange: () => ({ getValues: () => tables[name], getDisplayValues: () => tables[name].map((r) => r.map((c) => (c == null ? '' : String(c)))) }) }),
      }),
    },
  });
  for (const file of ['Response', 'SheetDB', 'FirestoreStore', 'Migrate', ...services]) {
    vm.runInContext(fs.readFileSync(path.join(__dirname, '..', file + '.gs'), 'utf8'), context);
  }
  return { context, ...fs_, props };
}

const listCalls = (calls, collection) => calls.filter((c) => c.method === 'GET' && c.url.includes(`/documents/${collection}?`));

test('facade defaults to the sheet store and follows the DB_BACKEND property', () => {
  const sheet = setup({ backend: 'sheet' });
  assert.equal(sheet.context.SheetDB.backend(), 'sheet');
  const cut = setup({ backend: 'firestore' });
  assert.equal(cut.context.SheetDB.backend(), 'firestore');
  cut.context.setDbBackend('sheet');
  assert.equal(cut.context.SheetDB.backend(), 'sheet');
  assert.throws(() => cut.context.setDbBackend('oracle'));
  // Without PropertiesService (unit-test environments) the sheet store is used.
  const bare = vm.createContext({});
  vm.runInContext(fs.readFileSync(path.join(__dirname, '..', 'SheetDB.gs'), 'utf8'), bare);
  assert.equal(bare.SheetDB.backend(), 'sheet');
});

test('requests carry the owner OAuth token and the Firebase quota project', () => {
  const t = setup();
  t.context.SheetDB.getRowsAsObjects('Users');
  const call = t.calls[0];
  assert.equal(call.headers.Authorization, 'Bearer tok-123');
  assert.equal(call.headers['X-Goog-User-Project'], PROJECT);
});

test('Firestore values round-trip', () => {
  const { FirestoreStore } = setup().context;
  const value = { a: 'x', b: 3, c: 2.5, d: true, e: null, f: ['A1', 2], g: { h: 'i' } };
  const decoded = FirestoreStore.decodeValue(FirestoreStore.encodeValue(value));
  assert.deepEqual(JSON.parse(JSON.stringify(decoded)), { ...value, e: '' });
  assert.deepEqual(JSON.parse(JSON.stringify(FirestoreStore.encodeValue(7))), { integerValue: '7' });
});

test('insertRow uses composite document ids and rejects duplicates with DB_CONFLICT', () => {
  const t = setup();
  const db = t.context.SheetDB;
  db.insertRow('Enrollment', { classCode: 'PRN232_SE1917', rollNumber: 'SE1', enrollmentDate: '' });
  assert.ok(t.docs.has('enrollments/PRN232_SE1917_SE1'));
  db.insertRow('Attendance_Record', { recordId: 'r-1', sessionId: 's1', rollNumber: 'SE1', status: 'Present', syncedToFap: false });
  assert.ok(t.docs.has('attendanceRecords/s1_SE1'));
  assert.throws(
    () => db.insertRow('Attendance_Record', { recordId: 'r-2', sessionId: 's1', rollNumber: 'SE1', status: 'Present' }),
    { code: 'DB_CONFLICT' });
  assert.throws(() => db.insertRow('Enrollment', { classCode: 'C1' }), { code: 'VALIDATION_ERROR' });
  // room 303 (number) is stored as text, like the sheet TEXT_FIELDS
  db.insertRow('Class_Section', { classCode: 'PRM393_SE1917', room: 303, studentCount: '35', teacherMemberCode: 'T1', slotCode: 'A2', subjectName: 'Lap trinh di dong', credits: '3' });
  const stored = t.docs.get('classSections/PRM393_SE1917').fields;
  assert.deepEqual(stored.room, { stringValue: '303' });
  assert.deepEqual(stored.studentCount, { integerValue: '35' });
  assert.equal('subjectName' in stored, false);
});

test('Class_Section is split into classSections + subjects and joined back on read', () => {
  const t = setup();
  const db = t.context.SheetDB;
  db.insertRow('Class_Section', { classCode: 'PRM393_SE1917', room: '602', studentCount: 35, teacherMemberCode: 'T1', slotCode: 'A2', subjectName: 'Lap trinh di dong', credits: 3 });
  db.insertRow('Class_Section', { classCode: 'PRM393_SE1913', room: '604', studentCount: 0, teacherMemberCode: 'T1', slotCode: 'A5', subjectName: 'Ten khac' });
  assert.equal(t.docs.get('subjects/PRM393').fields.subjectName.stringValue, 'Lap trinh di dong'); // first one wins
  const rows = db.getRowsAsObjects('Class_Section');
  assert.equal(rows.length, 2);
  assert.equal(rows[0].subjectCode, 'PRM393');
  assert.equal(rows[0].subjectName, 'Lap trinh di dong');
  assert.equal(rows[1].subjectName, 'Lap trinh di dong');
  assert.equal(rows[0].credits, 3);
  assert.equal(db.updateRow('Class_Section', 'classCode', 'PRM393_SE1913', { teacherMemberCode: 'T2' }), true);
  assert.equal(db.getRowsAsObjects('Class_Section')[1].teacherMemberCode, 'T2');
  assert.equal(db.updateRow('Class_Section', 'classCode', 'NOPE_SE0000', { teacherMemberCode: 'T2' }), false);
});

test('seedSlots writes the A/P rule and Slot reads keep the legacy shape', () => {
  const t = setup();
  t.context.seedSlots();
  assert.equal(t.docs.size, 16);
  const slots = t.context.SheetDB.getRowsAsObjects('Slot');
  assert.equal(slots.length, 12);
  const by = Object.fromEntries(slots.map((s) => [s.slotCode, s]));
  assert.deepEqual([by.A1.startTime, by.A1.endTime, by.A1.period], ['07:00', '09:15', 'Morning (A)']);
  assert.deepEqual([by.A4.startTime, by.A4.endTime], ['09:30', '11:45']);
  assert.deepEqual([by.P3.startTime, by.P3.endTime, by.P3.period], ['12:30', '14:45', 'Afternoon (P)']);
  assert.deepEqual([by.P6.startTime, by.P6.endTime], ['15:00', '17:15']);
  assert.equal(by.P1.daySlotNo, 3); // afternoon numbering continues after the morning
  assert.equal(by.A2.daySlotNo, 2);
  const days = (code) => t.docs.get(`slots/${code}`).fields.weekdays.arrayValue.values.map((v) => Number(v.integerValue));
  assert.deepEqual(days('A1'), [2, 5]);
  assert.deepEqual(days('P2'), [2, 5]);
  assert.deepEqual(days('A3'), [3, 6]);
  assert.deepEqual(days('P5'), [4, 7]);
  assert.deepEqual(days('A6'), [4, 7]);
  // Slots are fixed by the rule: writes from the OCR import are ignored.
  const before = t.calls.length;
  t.context.SheetDB.insertRow('Slot', { slotCode: 'A1', startTime: '07:30' });
  assert.equal(t.context.SheetDB.updateRow('Slot', 'slotCode', 'A1', { startTime: '07:30' }), true);
  assert.equal(t.calls.length, before);
  assert.equal(t.docs.get('timeSlots/A-1').fields.startTime.stringValue, '07:00');
});

test('updateRow patches by document id and finds other keys with a query', () => {
  const t = setup();
  const db = t.context.SheetDB;
  db.insertRow('Attendance_Session', { sessionId: 's1', classCode: 'C1', sessionStatus: 'open', qrSecret: 'q1', teacherIp: '1.1.1.1' });
  assert.equal(db.updateRow('Attendance_Session', 'sessionId', 's1', { sessionStatus: 'closed' }), true);
  const patch = t.calls.filter((c) => c.method === 'PATCH').pop();
  assert.ok(patch.url.includes('updateMask.fieldPaths=sessionStatus'));
  assert.ok(patch.url.includes('currentDocument.exists=true'));
  assert.equal(t.docs.get('attendanceSessions/s1').fields.sessionStatus.stringValue, 'closed');
  assert.equal(t.docs.get('attendanceSessions/s1').fields.qrSecret.stringValue, 'q1'); // untouched
  assert.equal(db.updateRow('Attendance_Session', 'sessionId', 'missing', { sessionStatus: 'x' }), false);

  db.insertRow('Attendance_Record', { recordId: 'rec-9', sessionId: 's1', rollNumber: 'SE1', status: 'Absent', syncedToFap: false });
  assert.equal(db.updateRow('Attendance_Record', 'recordId', 'rec-9', { status: 'Present', syncedToFap: true }), true);
  const fields = t.docs.get('attendanceRecords/s1_SE1').fields;
  assert.equal(fields.status.stringValue, 'Present');
  assert.equal(fields.syncedToFap.booleanValue, true);
  assert.equal(db.updateRow('Attendance_Record', 'recordId', 'nope', { status: 'Present' }), false);
});

test('reads paginate, honour filter hints and keep sheet order', () => {
  const t = setup();
  for (let i = 0; i < 650; i++) {
    t.docs.set(`enrollments/C1_SE${i}`, {
      createTime: new Date(Date.UTC(2026, 8, 1, 0, 0, 0) + i * 1000).toISOString(),
      fields: { classCode: { stringValue: i % 2 ? 'C2' : 'C1' }, rollNumber: { stringValue: `SE${i}` } },
    });
  }
  const all = t.context.SheetDB.getRowsAsObjects('Enrollment');
  assert.equal(all.length, 650);
  assert.equal(listCalls(t.calls, 'enrollments').length, 3); // 300 + 300 + 50

  const before = t.calls.length;
  const hinted = t.context.SheetDB.getRowsAsObjects('Enrollment', { classCode: 'C2', rollNumber: 'SE3' });
  assert.deepEqual(Array.from(hinted, (r) => r.rollNumber), ['SE3']);
  const query = t.calls[before];
  assert.ok(query.url.endsWith(':runQuery'));
  assert.equal(query.body.structuredQuery.where.compositeFilter.op, 'AND');
  assert.equal(query.body.structuredQuery.where.compositeFilter.filters.length, 2);

  // _row (sheet order) wins over createTime, and _ fields never leak out
  const u = setup();
  u.docs.set('users/B', { createTime: '2026-09-01T00:00:01Z', fields: { memberCode: { stringValue: 'B' }, _row: { integerValue: '2' } } });
  u.docs.set('users/A', { createTime: '2026-09-01T00:00:02Z', fields: { memberCode: { stringValue: 'A' }, _row: { integerValue: '1' } } });
  u.docs.set('users/Z', { createTime: '2026-09-01T00:00:03Z', fields: { memberCode: { stringValue: 'Z' } } });
  const users = u.context.SheetDB.getRowsAsObjects('Users');
  assert.deepEqual(Array.from(users, (r) => r.memberCode), ['A', 'B', 'Z']);
  assert.equal('_row' in users[0], false);
});

test('reads of Users/Slot/Class_Section are memoised per execution and refreshed after a write', () => {
  const t = setup();
  const db = t.context.SheetDB;
  db.insertRow('Users', { memberCode: 'T1', fullName: 'A' });
  db.getRowsAsObjects('Users');
  db.getRowsAsObjects('Users');
  assert.equal(listCalls(t.calls, 'users').length, 1);
  db.insertRow('Users', { memberCode: 'T2', fullName: 'B' });
  assert.equal(db.getRowsAsObjects('Users').length, 2);
  assert.equal(listCalls(t.calls, 'users').length, 2);
  const rows = db.getRowsAsObjects('Users');
  rows[0].fullName = 'mutated';
  assert.equal(db.getRowsAsObjects('Users')[0].fullName, 'A'); // callers cannot corrupt the cache
});

test('HTTP failures map to API error codes; transient ones are retried', () => {
  const t = setup();
  t.failures.push({ status: 403, message: 'permission denied' });
  assert.throws(() => t.context.SheetDB.getRowsAsObjects('Users'), { code: 'DB_PERMISSION' });
  t.failures.push({ status: 503 }, { status: 503 });
  assert.equal(t.context.SheetDB.getRowsAsObjects('Users').length, 0); // succeeds on the 3rd attempt
  t.failures.push({ status: 503 }, { status: 503 }, { status: 503 });
  assert.throws(() => t.context.SheetDB.getRowsAsObjects('Enrollment'), { code: 'DB_UNAVAILABLE' });
  assert.equal(t.failures.length, 0); // exactly 3 attempts were made
});

// ----------------------------------------------------------- migration
function sheetTables() {
  const serial = 46284; // date serial as stored in the live sheet
  return {
    Users: [
      ['memberCode', 'fullName', 'role', 'rollNumber', 'email'],
      ['KhoaLTA', 'Khoa', 'GV', '', 'khoa@fpt.edu.vn'],
      ['NamNC', 'Nam', 'SV', 'SE190507', 'nam@gmail.com'],
      ['', '', '', '', ''],
    ],
    Class_Section: [
      ['classCode', 'subjectName', 'credits', 'room', 'studentCount', 'teacherMemberCode', 'slotCode'],
      ['PRN232_SE1917', 'End Application With .NET', 3, 602, 35, 'KhoaLTA', 'A1'],
      ['PRM393_SE1913', 'Lap trinh di dong', 3, 604, 0, 'KhoaLTA', 7],
    ],
    Enrollment: [
      ['rollNumber', 'classCode', 'enrollmentDate'],
      ['SE190507', 'PRN232_SE1917', ''],
      ['SE190507', 'PRN232_SE1917', ''],
      ['SE999999', 'PRN232_SE1917', ''],
    ],
    Attendance_Session: [
      ['sessionId', 'classCode', 'sessionDate', 'slotCode', 'sessionStatus', 'qrSecret', 'teacherIp'],
      ['S1', 'PRN232_SE1917', serial, 'A1', 'closed', 'sec', '127.0.0.1'],
      ['S2', 'PRN232_SE1917', new Date(Date.UTC(2026, 8, 20, 0, 0, 0) - 7 * 3600 * 1000), 'A1', 'open', 'sec2', '127.0.0.1'],
    ],
    Attendance_Record: [
      ['recordId', 'rollNumber', 'sessionId', 'checkinTime', 'status', 'networkVerificationResult', 'syncedToFap', 'ipAddress'],
      ['r1', 'SE190507', 'S1', '2026-09-19T16:15:30.843Z', 'ManualByGV', 'Manual', 1, ''],
      ['r2', 'SE190507', 'S1', '', 'Absent', 'AutoAbsent', 'FALSE', ''],
      ['r3', 'SE190507', 'S2', '', 'Absent', 'AutoAbsent', false, ''],
    ],
  };
}

test('migration dry run writes nothing and reports data quirks as warnings', () => {
  const t = setup({ backend: 'sheet', tables: sheetTables() });
  const result = t.context.migrateSheetsToFirestoreDryRun();
  assert.equal(t.calls.length, 0);
  assert.deepEqual(JSON.parse(JSON.stringify(result.collections)), {
    users: 2, subjects: 2, classSections: 2, enrollments: 2,
    classSchedules: 0, attendanceSessions: 2, attendanceRecords: 2,
  });
  const text = result.warnings.join('\n');
  assert.match(text, /slotCode "7"/);
  assert.match(text, /SE999999.*Users/);
  assert.match(text, /Attendance_Record: trùng S1_SE190507/);
});

test('migration drops the retired P7-P9 slots from classes and sessions', () => {
  const tables = sheetTables();
  tables.Class_Section.push(['PRN232_SE1950', 'End Application With .NET', 3, 321, 37, 'HuyTG', 'P8']);
  tables.Attendance_Session.push(['S3', 'PRN232_SE1917', '2026-09-21', 'P7', 'closed', 'sec3', '127.0.0.1']);
  const t = setup({ backend: 'sheet', tables });
  const dry = t.context.migrateSheetsToFirestoreDryRun();
  const text = dry.warnings.join('\n');
  assert.doesNotMatch(text, /slotCode "P[7-9]"/);
  assert.match(text, /Đã bỏ slotCode P7-P9 .* 2 dòng/);

  t.context.seedSlots();
  t.context.migrateSheetsToFirestore();
  assert.equal(t.docs.get('classSections/PRN232_SE1950').fields.slotCode.stringValue, '');
  assert.equal(t.docs.get('attendanceSessions/S3').fields.slotCode.stringValue, '');
  assert.equal(t.docs.get('classSections/PRN232_SE1917').fields.slotCode.stringValue, 'A1');
});

test('migration normalises data, is idempotent and verifyMigration passes', () => {
  const t = setup({ backend: 'sheet', tables: sheetTables() });
  t.context.seedSlots();
  t.context.migrateSheetsToFirestore();
  const count = t.docs.size;
  t.context.migrateSheetsToFirestore(); // re-run = same documents
  assert.equal(t.docs.size, count);

  const session = t.docs.get('attendanceSessions/S1').fields;
  assert.equal(session.sessionDate.stringValue, new Date(Date.UTC(1899, 11, 30) + 46284 * 864e5).toISOString().slice(0, 10));
  assert.equal(t.docs.get('attendanceSessions/S2').fields.sessionDate.stringValue, '2026-09-20');
  const record = t.docs.get('attendanceRecords/S1_SE190507').fields;
  assert.equal(record.recordId.stringValue, 'r2'); // latest sheet row wins
  assert.equal(record.syncedToFap.booleanValue, false);
  assert.equal(t.docs.get('classSections/PRN232_SE1917').fields.room.stringValue, '602');
  assert.equal(t.docs.get('subjects/PRN232').fields.credits.integerValue, '3');
  assert.equal(t.docs.get('users/KhoaLTA').fields._row.integerValue, '2');
  assert.equal(t.docs.has('enrollments/PRN232_SE1917_SE190507'), true);
  assert.equal([...t.docs.keys()].filter((k) => k.startsWith('users/')).length, 2);

  const verify = t.context.verifyMigration();
  assert.equal(verify.ok, true, verify.problems.join('; '));

  // After the cut-over the API reads what was migrated.
  t.context.setDbBackend('firestore');
  const rows = t.context.SheetDB.getRowsAsObjects('Class_Section');
  assert.deepEqual(Array.from(rows, (r) => r.classCode), ['PRN232_SE1917', 'PRM393_SE1913']);
  assert.equal(rows[0].subjectName, 'End Application With .NET');

  t.docs.delete('enrollments/PRN232_SE1917_SE190507');
  assert.equal(t.context.verifyMigration().ok, false);
});

// ------------------------------------------------------------ services
test('services run on Firestore: start session, student check-in, duplicate scan, close session', () => {
  const t = setup({ services: ['StudentService', 'TeacherService'] });
  const db = t.context.SheetDB;
  t.context.seedSlots();
  db.insertRow('Users', { memberCode: 'KhoaLTA', fullName: 'Khoa', role: 'GV', email: 'k@fpt.edu.vn' });
  db.insertRow('Class_Section', { classCode: 'PRN232_SE1917', subjectName: 'NET', credits: 3, room: '602', studentCount: 2, teacherMemberCode: 'KhoaLTA', slotCode: 'A1' });
  db.insertRow('Enrollment', { rollNumber: 'SE1', classCode: 'PRN232_SE1917' });
  db.insertRow('Enrollment', { rollNumber: 'SE2', classCode: 'PRN232_SE1917' });

  const started = t.context.TeacherService.startSession({ classCode: 'PRN232_SE1917', slotCode: 'A1', teacherIp: '203.0.113.5', ipCheck: true });
  const token = started.qrToken;
  assert.equal(started.session.sessionStatus, 'open');
  assert.equal(started.session.ipCheck, true);

  assert.throws(() => t.context.StudentService.checkin({ qrToken: token, rollNumber: 'SE1' }), { code: 'IP_REQUIRED' });
  assert.throws(() => t.context.StudentService.checkin({ qrToken: token, studentIp: '9.9.9.9', rollNumber: 'SE1' }), { code: 'IP_MISMATCH' });
  assert.throws(() => t.context.StudentService.checkin({ qrToken: token, studentIp: '203.0.113.5', rollNumber: 'SE77' }), { code: 'NOT_ENROLLED' });
  const ok = t.context.StudentService.checkin({ qrToken: token, studentIp: '203.0.113.5', rollNumber: 'SE1' });
  assert.equal(ok.status, 'Present');
  assert.equal(ok.networkVerificationResult, 'Match');
  assert.ok(t.docs.has(`attendanceRecords/${started.session.sessionId}_SE1`));
  assert.throws(() => t.context.StudentService.checkin({ qrToken: token, studentIp: '203.0.113.5', rollNumber: 'SE1' }), { code: 'ALREADY_CHECKED_IN' });

  const closed = t.context.TeacherService.closeSession({ sessionId: started.session.sessionId });
  assert.equal(closed.autoAbsentCount, 1);
  assert.equal(t.docs.get(`attendanceRecords/${started.session.sessionId}_SE2`).fields.status.stringValue, 'Absent');
  assert.equal(t.docs.get(`attendanceRecords/${started.session.sessionId}_SE2`).fields.syncedToFap.booleanValue, false);
  assert.throws(() => t.context.StudentService.checkin({ qrToken: token, studentIp: '203.0.113.5', rollNumber: 'SE2' }), { code: 'SESSION_NOT_FOUND' });

  const roster = t.context.TeacherService.getRoster({ sessionId: started.session.sessionId });
  assert.equal(roster.length, 0); // Users has no SV rows in this fixture: roster joins Users by rollNumber
  const classes = t.context.TeacherService.getClasses({ teacherMemberCode: 'KhoaLTA' });
  assert.equal(classes[0].subjectCode, 'PRN232');
  assert.equal(classes[0].startTime, '07:00');
  assert.equal(classes[0].endTime, '09:15');
  assert.equal(classes[0].completedSessions, 1);
});

test('the Firestore hints are honoured by the sheet store (ignored) so both stores agree', () => {
  const tables = sheetTables();
  const t = setup({ backend: 'sheet', tables });
  const rows = t.context.SheetDB.getRowsAsObjects('Enrollment', { classCode: 'NOT_A_FILTER_FOR_SHEETS' });
  assert.equal(rows.length, 3); // the sheet always returns every row
});

test('IP check is optional per session: off by default, on when the teacher ticks it', () => {
  const t = setup({ services: ['StudentService', 'TeacherService'] });
  const db = t.context.SheetDB;
  t.context.seedSlots();
  db.insertRow('Class_Section', { classCode: 'PRN232_SE1917', subjectName: 'NET', room: '602', teacherMemberCode: 'T1', slotCode: 'A1' });
  ['SE1', 'SE2', 'SE3'].forEach((r) => db.insertRow('Enrollment', { rollNumber: r, classCode: 'PRN232_SE1917' }));

  // default (option not ticked): no teacher IP needed, no student IP needed
  const off = t.context.TeacherService.startSession({ classCode: 'PRN232_SE1917', slotCode: 'A1', teacherIp: '203.0.113.5' });
  assert.equal(off.session.ipCheck, false);
  assert.equal(off.session.teacherIp, ''); // the IP is not even stored when the check is off
  const first = t.context.StudentService.checkin({ qrToken: off.qrToken, rollNumber: 'SE1' });
  assert.equal(first.status, 'Present');
  assert.equal(first.networkVerificationResult, 'Skipped');
  const elsewhere = t.context.StudentService.checkin({ qrToken: off.qrToken, studentIp: '9.9.9.9', rollNumber: 'SE2' });
  assert.equal(elsewhere.status, 'Present'); // any network is accepted while the check is off
  assert.equal(t.context.TeacherService.getClasses({ teacherMemberCode: 'T1' })[0].activeSessionIpCheck, false);

  // ticked: teacher IP is mandatory and students must match it
  assert.throws(() => t.context.TeacherService.startSession({ classCode: 'PRN232_SE1917', slotCode: 'A1', ipCheck: true }), { code: 'VALIDATION_ERROR' });
  const on = t.context.TeacherService.startSession({ classCode: 'PRN232_SE1917', slotCode: 'A1', teacherIp: '203.0.113.5', ipCheck: 'true' });
  assert.equal(on.session.ipCheck, true);
  assert.equal(t.docs.get(`attendanceSessions/${off.session.sessionId}`).fields.sessionStatus.stringValue, 'closed'); // old open session auto-closed
  assert.throws(() => t.context.StudentService.checkin({ qrToken: on.qrToken, rollNumber: 'SE3' }), { code: 'IP_REQUIRED' });
  assert.throws(() => t.context.StudentService.checkin({ qrToken: on.qrToken, studentIp: '9.9.9.9', rollNumber: 'SE3' }), { code: 'IP_MISMATCH' });
  assert.equal(t.context.StudentService.checkin({ qrToken: on.qrToken, studentIp: '203.0.113.5', rollNumber: 'SE3' }).networkVerificationResult, 'Match');

  // sessions from before the option existed (no ipCheck value) still check the IP
  t.docs.set('attendanceSessions/legacy', { createTime: 'x', fields: {
    sessionId: { stringValue: 'legacy' }, classCode: { stringValue: 'PRN232_SE1917' },
    sessionStatus: { stringValue: 'open' }, qrSecret: { stringValue: 'legacy-qr' }, teacherIp: { stringValue: '1.2.3.4' } } });
  assert.throws(() => t.context.StudentService.checkin({ qrToken: 'legacy-qr', rollNumber: 'SE1' }), { code: 'IP_REQUIRED' });
});
