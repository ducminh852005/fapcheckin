const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

function backend() {
  const tables = {
    Class_Section: [
      ['classCode', 'teacherMemberCode', 'subjectName', 'room', 'studentCount', 'slotCode'],
      [101, 7, 'SWP391 Project', 303, 1, 'A1'],
      ['', '', '', '', '', ''],
    ],
    Slot: [
      ['slotCode', 'period', 'startTime', 'endTime'],
      ['A1', 'Morning', '07:30', '09:00'],
      ['A2', 'Morning', '09:15', '10:45'],
    ],
    Attendance_Session: [
      ['sessionId', 'classCode', 'slotCode', 'sessionDate', 'sessionStatus'],
      [10, '101', 2, '2026-09-19', 'closed'],
    ],
    Attendance_Record: [
      ['recordId', 'sessionId', 'rollNumber', 'status', 'syncedToFap'],
      [20, '10', 123, 'Present', false],
    ],
    Enrollment: [['classCode', 'rollNumber'], ['101', '123']],
    Users: [
      ['memberCode', 'rollNumber', 'email', 'fullName'],
      [8, 123, 'student@example.test', 'Test Student'],
    ],
  };
  const context = vm.createContext({
    SpreadsheetApp: {
      getActiveSpreadsheet: () => { throw new Error('Must not read the bound demo spreadsheet'); },
      openById: id => {
        assert.equal(id, '1X342Hzd9_lwQeAwUZi80r1Zcs7_qyFZNDglUTw9y1l4');
        return ({
        getSheetByName: name => tables[name] && ({
          getDataRange: () => ({ getValues: () => tables[name] }),
          appendRow: row => tables[name].push(row),
          getRange: (row, col) => ({
            setValue: value => { tables[name][row - 1][col - 1] = value; },
          }),
        }),
        });
      },
    },
    ContentService: {
      MimeType: { JSON: 'application/json' },
      createTextOutput: body => ({ setMimeType: () => JSON.parse(body) }),
    },
    Utilities: { getUuid: () => 'test-uuid' },
  });
  for (const file of ['Response', 'SheetDB', 'TeacherService', 'AuthService',
    'StudentService', 'SyncService', 'Router', 'Code']) {
    vm.runInContext(fs.readFileSync(path.join(__dirname, '..', file + '.gs'), 'utf8'), context);
  }
  const call = (action, params = {}) => context.doPost({
    postData: { contents: JSON.stringify({ action, ...params }) },
  });
  return { context, tables, call };
}

test('getClasses serializes numeric rooms and joins mixed numeric/text keys', () => {
  const { call } = backend();
  const result = call('getClasses', { teacherMemberCode: '7' });
  assert.equal(result.success, true);
  assert.equal(result.data.length, 1);
  assert.equal(result.data[0].room, '303');
  assert.equal(result.data[0].classCode, '101');
  assert.equal(result.data[0].studentCount, 1);
  assert.equal(result.data[0].slotCode, 'A1');
  assert.equal(result.data[0].timeLabel, 'Slot A1 (07:30 - 09:00)');
  assert.equal(result.data[0].startTime, '07:30');
  assert.equal(result.data[0].endTime, '09:00');
  assert.equal(result.data[0].period, 'Morning');
  assert.equal(result.data[0].completedSessions, 1);
  assert.equal(result.data[0].averageAttendance, 100);
  assert.deepEqual(call('getClasses', { teacherMemberCode: 'unknown' }).data, []);
});

test('session, roster, history and stats APIs use consistent string identifiers', () => {
  const { call } = backend();
  assert.equal(call('getSessions', { classCode: '101' }).data[0].slotCode, '2');
  const roster = call('getRoster', { sessionId: '10' });
  assert.equal(roster.data[0].student.rollNumber, '123');
  assert.equal(roster.data[0].record.recordId, '20');
  const history = call('getAttendanceHistory', { classCode: '101' });
  assert.equal(history.data.students[0].status, 'Present');
  assert.equal(call('getStats', { classCode: '101' }).data[0].attendancePercentage, 100);
});

test('normalized identifiers still update the original numeric spreadsheet row', () => {
  const { call, tables } = backend();
  const result = call('manualCheckin', { sessionId: '10', rollNumber: '123', status: 'Late' });
  assert.equal(result.success, true);
  assert.equal(tables.Attendance_Record.length, 2);
  assert.equal(tables.Attendance_Record[1][3], 'Late');
  assert.equal(tables.Attendance_Record[1][4], false);
});

test('blank rows are skipped; trimmed headers work for reads and writes', () => {
  const { context, tables } = backend();
  tables.Users[0][0] = ' memberCode ';
  assert.equal(context.SheetDB.getRowsAsObjects('Class_Section').length, 1);
  assert.equal(context.SheetDB.getRowsAsObjects('Users')[0].memberCode, '8');
  assert.equal(context.SheetDB.updateRow('Users', 'memberCode', '8', { fullName: 'Changed' }), true);
  context.SheetDB.insertRow('Users', { memberCode: '9' });
  assert.equal(tables.Users[2][0], '9');
});

test('Class_Section derives subjectCode from its composite classCode', () => {
  const { context, tables } = backend();
  tables.Class_Section[1][0] = 'PRN232_SE1917';
  const row = context.SheetDB.getRowsAsObjects('Class_Section')[0];
  assert.equal(row.classCode, 'PRN232_SE1917');
  assert.equal(row.subjectCode, 'PRN232');
});

test('router exposes read APIs and returns structured validation errors', () => {
  const { call } = backend();
  const backendInfo = call('getBackendInfo');
  assert.equal(backendInfo.success, true);
  assert.equal(backendInfo.data.revision, '2026-09-25-timetable-ocr-v3');
  assert.equal(backendInfo.data.timetableCompositeClassCodes, true);
  for (const action of ['getClasses', 'getSessions', 'getRoster', 'getStats', 'getAttendanceHistory']) {
    assert.equal(call(action).error.code, 'VALIDATION_ERROR');
  }
  assert.equal(call('missing').error.code, 'UNKNOWN_ACTION');
});

test('notes beginning with = are written as literal cell text', () => {
  const { context, tables } = backend();
  tables.Attendance_Record[0].push('note');
  context.SheetDB.updateRow('Attendance_Record', 'recordId', '20', { note: '=1+1' });
  assert.equal(tables.Attendance_Record[1][5], "'=1+1");
  context.SheetDB.insertRow('Attendance_Record', { recordId: '21', note: '=2+2' });
  assert.equal(tables.Attendance_Record[2][5], "'=2+2");
});
