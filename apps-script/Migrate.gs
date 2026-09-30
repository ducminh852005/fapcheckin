// File: Migrate.gs
//
// One-off tools to move the data from the Google Sheet into Firestore and to
// switch the backend. Run these by hand from the Apps Script editor
// (they are NOT exposed through Router.gs):
//
//   1. authorizeFirestore()               grant the datastore scope, check access
//   2. seedSlots()                        write the fixed A/P slot rule
//   3. migrateSheetsToFirestoreDryRun()   dry run: counts + warnings only
//   4. migrateSheetsToFirestore()         real import (idempotent, safe to re-run)
//   5. verifyMigration()                  compare Firestore with the sheet
//   6. setDbBackend('firestore')          cut the API over (setDbBackend('sheet') = rollback)
//      The editor's Run button passes no arguments: use useFirestore() / useSheet() there.
//
// Runbook: docs/deploy-firebase.md

var MIGRATION_ZONE = 'Asia/Ho_Chi_Minh';

// 4 time blocks (the only place holding clock times) and the 12 slot codes.
var TIME_SLOT_ROWS = [
  { timeSlotId: 'A-1', period: 'Morning', slotInPeriod: 1, daySlotNo: 1, startTime: '07:00', endTime: '09:15' },
  { timeSlotId: 'A-2', period: 'Morning', slotInPeriod: 2, daySlotNo: 2, startTime: '09:30', endTime: '11:45' },
  { timeSlotId: 'P-1', period: 'Afternoon', slotInPeriod: 1, daySlotNo: 3, startTime: '12:30', endTime: '14:45' },
  { timeSlotId: 'P-2', period: 'Afternoon', slotInPeriod: 2, daySlotNo: 4, startTime: '15:00', endTime: '17:15' }
];
// digit -> weekdays (Vietnamese numbering: 2 = Monday ... 7 = Saturday)
var SLOT_WEEKDAYS = { 1: [2, 5], 2: [2, 5], 3: [3, 6], 4: [3, 6], 5: [4, 7], 6: [4, 7] };

function buildSlotDocs() {
  var slots = [];
  ['A', 'P'].forEach(function(letter) {
    for (var n = 1; n <= 6; n++) {
      slots.push({
        id: letter + n,
        fields: {
          slotCode: letter + n,
          timeSlotId: letter + '-' + (n % 2 === 1 ? 1 : 2),
          weekdays: SLOT_WEEKDAYS[n].slice()
        }
      });
    }
  });
  var timeSlots = TIME_SLOT_ROWS.map(function(row) { return { id: row.timeSlotId, fields: row }; });
  return { slots: slots, timeSlots: timeSlots };
}

// ------------------------------------------------------------ normalizers
function migText(value) {
  if (value == null) return '';
  if (Object.prototype.toString.call(value) === '[object Date]') return migIsoDateTime(value);
  return String(value).trim();
}

function migSerialToDate(serial) {
  return new Date(Date.UTC(1899, 11, 30) + Math.round(Number(serial) * 86400000));
}

function migDateOnly(value) {
  if (value == null || value === '') return '';
  if (Object.prototype.toString.call(value) === '[object Date]') {
    return Utilities.formatDate(value, MIGRATION_ZONE, 'yyyy-MM-dd');
  }
  if (typeof value === 'number') return migSerialToDate(value).toISOString().slice(0, 10);
  var str = String(value).trim();
  var iso = /^(\d{4})[-/](\d{1,2})[-/](\d{1,2})/.exec(str);
  if (iso) return iso[1] + '-' + ('0' + iso[2]).slice(-2) + '-' + ('0' + iso[3]).slice(-2);
  var vn = /^(\d{1,2})\/(\d{1,2})\/(\d{4})/.exec(str);
  if (vn) return vn[3] + '-' + ('0' + vn[2]).slice(-2) + '-' + ('0' + vn[1]).slice(-2);
  if (/^\d+(\.\d+)?$/.test(str)) return migSerialToDate(Number(str)).toISOString().slice(0, 10);
  return str;
}

function migIsoDateTime(value) {
  if (value == null || value === '') return '';
  if (Object.prototype.toString.call(value) === '[object Date]') return value.toISOString();
  if (typeof value === 'number') return migSerialToDate(value).toISOString();
  return String(value).trim();
}

function migBool(value) {
  if (value === true || value === 1) return true;
  var str = String(value == null ? '' : value).trim().toLowerCase();
  return str === 'true' || str === '1' || str === 'yes';
}

function migNumber(value) {
  if (value === '' || value == null) return null;
  var n = Number(value);
  return isFinite(n) ? n : null;
}

function migTextColumns(row, fields) {
  var out = {};
  fields.forEach(function(field) {
    if (row[field] !== undefined) out[field] = migText(row[field]);
  });
  return out;
}

// ---------------------------------------------------------------- planning
// Builds every document to write, without touching Firestore. Shared by the
// migration itself and by verifyMigration().
function buildMigrationPlan() {
  var warnings = [];
  var plan = { users: [], subjects: [], classSections: [], enrollments: [],
    classSchedules: [], attendanceSessions: [], attendanceRecords: [] };

  function optionalRows(sheetName) {
    try { return SheetsStore.getRawRows(sheetName); }
    catch (e) {
      if (e.code === 'SHEET_NOT_FOUND') { warnings.push('Không có tab ' + sheetName + ', bỏ qua.'); return []; }
      throw e;
    }
  }

  var validSlots = {};
  buildSlotDocs().slots.forEach(function(s) { validSlots[s.id] = true; });
  function checkSlot(where, slotCode) {
    if (slotCode && !validSlots[slotCode]) {
      warnings.push(where + ': slotCode "' + slotCode + '" không thuộc A1..A6/P1..P6.');
    }
  }
  // The evening slots P7-P9 no longer exist (docs/db-erd-notes.md); leave the
  // slot empty instead of copying a code that matches no slot.
  var droppedLegacySlots = 0;
  function dropLegacySlot(slotCode) {
    if (/^P[7-9]$/.test(slotCode || '')) { droppedLegacySlots++; return ''; }
    return slotCode;
  }

  // Users -----------------------------------------------------------------
  var userSeen = {};
  optionalRows('Users').forEach(function(row) {
    var memberCode = migText(row.memberCode);
    if (!memberCode) return;
    var doc = migTextColumns(row, ['memberCode', 'fullName', 'role', 'rollNumber', 'email']);
    doc._row = row._rowNumber;
    if (userSeen[memberCode]) warnings.push('Users: memberCode trùng "' + memberCode + '", dòng ' + row._rowNumber + ' ghi đè.');
    userSeen[memberCode] = true;
    plan.users = plan.users.filter(function(d) { return d.id !== memberCode; });
    plan.users.push({ id: memberCode, fields: doc });
  });

  // Class_Section (+ subjects) -------------------------------------------------
  var subjectSeen = {};
  optionalRows('Class_Section').forEach(function(row) {
    var classCode = migText(row.classCode);
    if (!classCode) return;
    var subjectCode = migText(row.subjectCode) || SheetsStore.subjectCodeFromClassCode(classCode);
    if (!subjectCode) warnings.push('Class_Section ' + classCode + ': không suy ra được subjectCode.');
    var slotCode = dropLegacySlot(migText(row.slotCode));
    checkSlot('Class_Section ' + classCode, slotCode);
    var doc = {
      classCode: classCode,
      subjectCode: subjectCode,
      room: migText(row.room),
      teacherMemberCode: migText(row.teacherMemberCode),
      slotCode: slotCode,
      _row: row._rowNumber
    };
    var students = migNumber(row.studentCount);
    if (students !== null) doc.studentCount = students;
    plan.classSections.push({ id: classCode, fields: doc });

    if (subjectCode && !subjectSeen[subjectCode]) {
      var subject = { subjectCode: subjectCode, subjectName: migText(row.subjectName) };
      var credits = migNumber(row.credits);
      if (credits !== null) subject.credits = credits;
      if (subject.subjectName) { subjectSeen[subjectCode] = true; plan.subjects.push({ id: subjectCode, fields: subject }); }
    }
  });
  var classCodes = {};
  plan.classSections.forEach(function(c) { classCodes[c.id] = true; });

  // Enrollment ---------------------------------------------------------------
  var enrollById = {};
  optionalRows('Enrollment').forEach(function(row) {
    var classCode = migText(row.classCode), rollNumber = migText(row.rollNumber);
    if (!classCode || !rollNumber) return;
    var id = classCode + '_' + rollNumber;
    var doc = { classCode: classCode, rollNumber: rollNumber, _row: row._rowNumber };
    var enrolled = migDateOnly(row.enrollmentDate);
    if (enrolled) doc.enrollmentDate = enrolled;
    enrollById[id] = { id: id, fields: doc };
  });
  plan.enrollments = Object.keys(enrollById).map(function(id) { return enrollById[id]; });

  // Class_Schedule (start/end times are no longer stored) ----------------------
  optionalRows('Class_Schedule').forEach(function(row) {
    var scheduleId = migText(row.scheduleId);
    if (!scheduleId) return;
    var doc = migTextColumns(row, ['scheduleId', 'requestId', 'teacherMemberCode', 'classCode', 'slotCode',
      'room', 'lessonType', 'teachingMethod', 'note', 'status']);
    doc.scheduleDate = migDateOnly(row.scheduleDate);
    doc.createdAt = migIsoDateTime(row.createdAt);
    doc._row = row._rowNumber;
    checkSlot('Class_Schedule ' + scheduleId, doc.slotCode);
    plan.classSchedules.push({ id: scheduleId, fields: doc });
  });

  // Attendance_Session ---------------------------------------------------------
  var sessionIds = {};
  optionalRows('Attendance_Session').forEach(function(row) {
    var sessionId = migText(row.sessionId);
    if (!sessionId) return;
    var doc = migTextColumns(row, ['sessionId', 'classCode', 'slotCode', 'sessionStatus', 'qrSecret', 'teacherIp']);
    doc.slotCode = dropLegacySlot(doc.slotCode);
    doc.sessionDate = migDateOnly(row.sessionDate);
    // Sessions from before the option existed have no value and keep IP checking on.
    if (row.ipCheck !== undefined && row.ipCheck !== '') doc.ipCheck = migBool(row.ipCheck);
    doc._row = row._rowNumber;
    checkSlot('Attendance_Session ' + sessionId, doc.slotCode);
    sessionIds[sessionId] = true;
    plan.attendanceSessions.push({ id: sessionId, fields: doc });
  });

  // Attendance_Record (latest row wins per session + student) -------------------
  var recordById = {};
  optionalRows('Attendance_Record').forEach(function(row) {
    var sessionId = migText(row.sessionId), rollNumber = migText(row.rollNumber);
    if (!sessionId || !rollNumber) return;
    var id = sessionId + '_' + rollNumber;
    var doc = migTextColumns(row, ['recordId', 'rollNumber', 'sessionId', 'status',
      'networkVerificationResult', 'ipAddress', 'note', 'updatedBy']);
    if (!doc.recordId) doc.recordId = id;
    doc.checkinTime = migIsoDateTime(row.checkinTime);
    doc.updatedAt = migIsoDateTime(row.updatedAt);
    doc.syncedToFap = migBool(row.syncedToFap);
    doc._row = row._rowNumber;
    if (recordById[id]) warnings.push('Attendance_Record: trùng ' + id + ', giữ dòng ' + row._rowNumber + '.');
    recordById[id] = { id: id, fields: doc };
  });
  plan.attendanceRecords = Object.keys(recordById).map(function(id) { return recordById[id]; });

  // Reference checks (warnings only) -------------------------------------------
  var rolls = {};
  plan.users.forEach(function(u) { if (u.fields.rollNumber) rolls[u.fields.rollNumber] = true; });
  plan.enrollments.forEach(function(e) {
    if (!classCodes[e.fields.classCode]) warnings.push('Enrollment ' + e.id + ': lớp không có trong Class_Section.');
    if (!rolls[e.fields.rollNumber]) warnings.push('Enrollment ' + e.id + ': rollNumber không có trong Users.');
  });
  plan.attendanceSessions.forEach(function(s) {
    if (!classCodes[s.fields.classCode]) warnings.push('Attendance_Session ' + s.id + ': lớp "' + s.fields.classCode + '" không có trong Class_Section.');
  });
  plan.attendanceRecords.forEach(function(r) {
    if (!sessionIds[r.fields.sessionId]) warnings.push('Attendance_Record ' + r.id + ': phiên không có trong Attendance_Session.');
  });

  if (droppedLegacySlots) warnings.push('Đã bỏ slotCode P7-P9 (không còn tồn tại) ở ' + droppedLegacySlots + ' dòng.');
  return { plan: plan, warnings: warnings };
}

// -------------------------------------------------------------- entry points
/** Step 1: triggers the OAuth consent for the datastore scope and checks access. */
function authorizeFirestore() {
  var result = FirestoreStore.ping();
  Logger.log('Firestore OK, project: ' + result.projectId);
  return result;
}

/** Step 2: write the fixed slot rule (timeSlots + slots). Safe to re-run. */
function seedSlots() {
  var docs = buildSlotDocs();
  var errors = FirestoreStore.batchUpsert('timeSlots', docs.timeSlots)
    .concat(FirestoreStore.batchUpsert('slots', docs.slots));
  if (errors.length) throw new Error('seedSlots lỗi: ' + errors.join('; '));
  Logger.log('Seeded ' + docs.timeSlots.length + ' timeSlots, ' + docs.slots.length + ' slots.');
}

/**
 * Steps 3-4: import the sheet into Firestore.
 * @param {boolean=} dryRun  true = only log counts and warnings
 * @param {string[]=} only   subset of collections, e.g. ['users','enrollments']
 */
function migrateSheetsToFirestore(dryRun, only) {
  var built = buildMigrationPlan();
  var names = Object.keys(built.plan).filter(function(name) {
    return !only || only.indexOf(name) !== -1;
  });
  var summary = {};
  names.forEach(function(name) {
    var docs = built.plan[name];
    summary[name] = docs.length;
    if (dryRun) return;
    var errors = FirestoreStore.batchUpsert(name, docs);
    if (errors.length) throw new Error('Ghi ' + name + ' lỗi: ' + errors.slice(0, 5).join('; '));
  });
  Logger.log((dryRun ? '[DRY RUN] ' : '') + 'Collections: ' + JSON.stringify(summary));
  built.warnings.forEach(function(w) { Logger.log('WARN ' + w); });
  Logger.log(built.warnings.length + ' warning(s).' + (dryRun ? ' Nothing was written.' : ''));
  return { collections: summary, warnings: built.warnings, dryRun: !!dryRun };
}

/** Step 3: the editor's Run button passes no arguments, so the dry run gets its own entry point. */
function migrateSheetsToFirestoreDryRun() {
  return migrateSheetsToFirestore(true);
}

/** Step 5: compare the document ids in Firestore with what the sheet should produce. */
function verifyMigration() {
  var built = buildMigrationPlan();
  var problems = [];
  Object.keys(built.plan).forEach(function(name) {
    var expected = built.plan[name].map(function(d) { return d.id; });
    var actual = FirestoreStore.listIds(name);
    var actualSet = {}; actual.forEach(function(id) { actualSet[id] = true; });
    var missing = expected.filter(function(id) { return !actualSet[id] && !actualSet[encodeURIComponent(id)]; });
    Logger.log(name + ': sheet=' + expected.length + ' firestore=' + actual.length + ' missing=' + missing.length);
    if (missing.length) problems.push(name + ' thiếu ' + missing.length + ' doc, ví dụ ' + missing.slice(0, 3).join(', '));
  });
  var slots = FirestoreStore.listIds('slots').length, blocks = FirestoreStore.listIds('timeSlots').length;
  Logger.log('slots=' + slots + ' timeSlots=' + blocks);
  if (slots !== 12 || blocks !== 4) problems.push('Chưa seed đủ slots (12) / timeSlots (4): chạy seedSlots().');
  built.warnings.forEach(function(w) { Logger.log('WARN ' + w); });
  Logger.log(problems.length ? 'VERIFY FAILED: ' + problems.join(' | ') : 'VERIFY OK');
  return { ok: problems.length === 0, problems: problems, warnings: built.warnings };
}

/** Editor-friendly wrappers (Run button has no arguments). */
function useFirestore() { return setDbBackend('firestore'); }
function useSheet() { return setDbBackend('sheet'); }

/** Step 6: 'firestore' = cut over, 'sheet' = rollback (data written since cutover is NOT copied back). */
function setDbBackend(value) {
  if (value !== 'sheet' && value !== 'firestore') throw new Error('Giá trị hợp lệ: "sheet" hoặc "firestore".');
  PropertiesService.getScriptProperties().setProperty('DB_BACKEND', value);
  SheetDB.resetBackendCache();
  Logger.log('DB_BACKEND = ' + value);
  return value;
}
