const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

function service() {
  const context = vm.createContext({
    Logger: { log: () => {} },
  });
  for (const file of ['Response', 'TimetableOCRService']) {
    vm.runInContext(fs.readFileSync(path.join(__dirname, '..', file + '.gs'), 'utf8'), context);
  }
  return context.TimetableOCRService;
}

function plain(value) {
  return JSON.parse(JSON.stringify(value));
}

test('parser extracts class, day, slot, time and room from OCR text', () => {
  const result = service().parseTimetableText(`
    Monday | PRM392 Mobile Programming | Class SE18D01 | Slot A1 | 07:30 - 09:50 | Room BE-301
    Thu 3 SWE201c Software Engineering lop SE18D02 P3 12:50-15:10 phong AL404
  `);

  assert.equal(result.parsedRows.length, 2);
  assert.deepEqual(plain(result.parsedRows.map(row => ({
    classCode: row.classCode,
    dayOfWeek: row.dayOfWeek,
    slotCode: row.slotCode,
    startTime: row.startTime,
    endTime: row.endTime,
    room: row.room,
  }))), [
    {
      classCode: 'SE18D01',
      dayOfWeek: 'Monday',
      slotCode: 'A1',
      startTime: '07:30',
      endTime: '09:50',
      room: 'BE-301',
    },
    {
      classCode: 'SE18D02',
      dayOfWeek: 'Tuesday',
      slotCode: 'P3',
      startTime: '12:50',
      endTime: '15:10',
      room: 'AL404',
    },
  ]);
  assert.equal(result.parsedRows[0].confidence, 'high');
});

test('parser returns structured error data when OCR text is unusable', () => {
  assert.throws(
    () => service().parseTimetableText('blur blur no schedule fields here'),
    error => {
      assert.equal(error.code, 'OCR_PARSE_FAILED');
      assert.equal(error.data.rawText, 'blur blur no schedule fields here');
      assert.deepEqual(plain(error.data.parsedRows), []);
      return true;
    },
  );
});
