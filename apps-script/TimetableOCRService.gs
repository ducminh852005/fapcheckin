// OCR and parser utilities for importing class timetables from teacher photos.
var TimetableOCRService = (function() {
  var ZONE = 'Asia/Ho_Chi_Minh';
  var TEMP_PREFIX = 'fapcheckin-timetable-ocr-';
  var SLOT_COLUMNS = ['slotCode', 'period', 'startTime', 'endTime'];
  var CLASS_COLUMNS = [
    'classCode',
    'subjectName',
    'credits',
    'room',
    'studentCount',
    'teacherMemberCode',
    'slotCode'
  ];
  var DEFAULT_SLOT_TIMES = {
    A1: {startTime: '07:30', endTime: '09:50', period: 'Morning'},
    A2: {startTime: '10:00', endTime: '12:20', period: 'Morning'},
    P3: {startTime: '12:50', endTime: '15:10', period: 'Afternoon'},
    P4: {startTime: '15:20', endTime: '17:40', period: 'Afternoon'},
    E5: {startTime: '17:50', endTime: '20:10', period: 'Evening'},
    E6: {startTime: '20:20', endTime: '22:40', period: 'Evening'}
  };
  var DAYS = {
    monday: 'Monday', mon: 'Monday', 'thu 2': 'Monday', t2: 'Monday',
    tuesday: 'Tuesday', tue: 'Tuesday', 'thu 3': 'Tuesday', t3: 'Tuesday',
    wednesday: 'Wednesday', wed: 'Wednesday', 'thu 4': 'Wednesday', t4: 'Wednesday',
    thursday: 'Thursday', thu: 'Thursday', 'thu 5': 'Thursday', t5: 'Thursday',
    friday: 'Friday', fri: 'Friday', 'thu 6': 'Friday', t6: 'Friday',
    saturday: 'Saturday', sat: 'Saturday', 'thu 7': 'Saturday', t7: 'Saturday',
    sunday: 'Sunday', sun: 'Sunday', cn: 'Sunday', 'chu nhat': 'Sunday'
  };

  function text(value) {
    return value == null ? '' : String(value).trim();
  }

  function normalize(value) {
    return text(value)
      .replace(/\r/g, '\n')
      .replace(/[–—]/g, '-')
      .replace(/\u00a0/g, ' ')
      .replace(/[ \t]+/g, ' ')
      .trim();
  }

  function removeVietnameseMarks(value) {
    return text(value)
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/đ/g, 'd')
      .replace(/Đ/g, 'D');
  }

  function normalizeTime(hour, minute) {
    var h = parseInt(hour, 10);
    var m = parseInt(minute || '0', 10);
    if (isNaN(h) || isNaN(m) || h > 23 || m > 59) return '';
    return ('0' + h).slice(-2) + ':' + ('0' + m).slice(-2);
  }

  function extractTimes(line, slotCode) {
    var times = [];
    var match;
    var re = /(\d{1,2})[:h.](\d{2})/gi;
    while ((match = re.exec(line)) !== null) {
      var value = normalizeTime(match[1], match[2]);
      if (value && times.indexOf(value) === -1) times.push(value);
    }
    if (times.length >= 2) return {startTime: times[0], endTime: times[1]};
    if (slotCode && DEFAULT_SLOT_TIMES[slotCode]) {
      return {
        startTime: DEFAULT_SLOT_TIMES[slotCode].startTime,
        endTime: DEFAULT_SLOT_TIMES[slotCode].endTime
      };
    }
    return {startTime: times[0] || '', endTime: ''};
  }

  function extractSlot(line) {
    var plain = removeVietnameseMarks(line);
    var compact = plain.replace(/\s+/g, '').toUpperCase();
    var prefixed = /\b(?:SLOT|CA|KIP)([A-Z]?\d)\b/i.exec(compact);
    var raw = prefixed ? prefixed[1] : '';
    if (!raw) {
      var direct = /\b([APE])[-\s]?([1-6])\b/i.exec(plain);
      if (direct) raw = direct[1].toUpperCase() + direct[2];
    }
    if (!raw) {
      var number = /\bslot\s*([1-6])\b/i.exec(plain);
      if (number) raw = number[1];
    }
    if (!raw) return '';
    raw = raw.toUpperCase();
    if (/^[1-2]$/.test(raw)) return 'A' + raw;
    if (/^[3-4]$/.test(raw)) return 'P' + raw;
    if (/^[5-6]$/.test(raw)) return 'E' + raw;
    if (/^[APE][1-6]$/.test(raw)) return raw;
    return '';
  }

  function extractDay(line) {
    var lowered = removeVietnameseMarks(line).toLowerCase();
    var keys = Object.keys(DAYS).sort(function(a, b) { return b.length - a.length; });
    for (var i = 0; i < keys.length; i++) {
      var key = keys[i];
      var re = new RegExp('(^|\\W)' + key.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '(\\W|$)', 'i');
      if (re.test(lowered)) return DAYS[keys[i]];
    }
    return '';
  }

  function extractRoom(line) {
    var plain = removeVietnameseMarks(line);
    var patterns = [
      /\b(?:room|phong)\s*[:\-]?\s*([A-Z]{1,4}[-\s]?\d{2,4}[A-Z]?|\d{3,4}[A-Z]?)\b/i,
      /\b([A-Z]{1,4}[-]\d{2,4}[A-Z]?)\b/i,
      /\b([A-Z]{2}\d{3,4}[A-Z]?)\b/i
    ];
    for (var i = 0; i < patterns.length; i++) {
      var match = patterns[i].exec(plain);
      if (match) return match[1].replace(/\s+/g, '').toUpperCase();
    }
    return '';
  }

  function extractClassCode(line) {
    var plain = removeVietnameseMarks(line);
    var patterns = [
      /\b(?:class|lop)\s*[:\-]?\s*([A-Z]{2,6}\d{2,4}[A-Z0-9._-]*)\b/i,
      /\b([A-Z]{2,6}\d{2,4}[A-Z0-9._-]*)\b/i
    ];
    for (var i = 0; i < patterns.length; i++) {
      var match = patterns[i].exec(plain);
      if (match) return match[1].toUpperCase();
    }
    return '';
  }

  function extractSubject(line, classCode, slotCode, room) {
    var cleaned = removeVietnameseMarks(line)
      .replace(/\b(?:monday|tuesday|wednesday|thursday|friday|saturday|sunday|mon|tue|wed|thu|fri|sat|sun)\b/ig, ' ')
      .replace(/\bthu\s*[2-7]\b/ig, ' ')
      .replace(/\b(?:room|phong|class|lop|slot|ca|kip)\s*[:\-]?/ig, ' ')
      .replace(/\d{1,2}[:h.]\d{2}\s*-\s*\d{1,2}[:h.]\d{2}/g, ' ')
      .replace(/\d{1,2}[:h.]\d{2}/g, ' ');
    [classCode, slotCode, room].forEach(function(part) {
      if (!part) return;
      cleaned = cleaned.replace(new RegExp(part.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'ig'), ' ');
    });
    var pieces = cleaned.split(/[|,;]/).map(text).filter(function(part) {
      return part && part.length > 2 && !/^\d+$/.test(part);
    });
    return pieces[0] || '';
  }

  function rowWarnings(row) {
    var warnings = [];
    ['classCode', 'slotCode', 'startTime', 'endTime', 'room'].forEach(function(field) {
      if (!row[field]) warnings.push('Missing ' + field);
    });
    if (!row.subjectName) warnings.push('Missing subjectName');
    if (!row.dayOfWeek) warnings.push('Missing dayOfWeek');
    return warnings;
  }

  function confidenceFor(warnings) {
    if (warnings.length === 0) return 'high';
    if (warnings.length <= 2) return 'medium';
    return 'low';
  }

  function parseTimetableText(rawText) {
    var normalized = normalize(rawText);
    if (!normalized) {
      var emptyError = new Error('OCR did not return any text.');
      emptyError.code = 'OCR_EMPTY_TEXT';
      emptyError.data = {rawText: '', parsedRows: [], warnings: ['OCR text is empty']};
      throw emptyError;
    }

    var lines = normalized.split('\n').map(normalize).filter(Boolean);
    var candidates = [];
    lines.forEach(function(line) {
      var slotCode = extractSlot(line);
      var times = extractTimes(line, slotCode);
      var row = {
        classCode: extractClassCode(line),
        subjectName: '',
        dayOfWeek: extractDay(line),
        slotCode: slotCode,
        startTime: times.startTime,
        endTime: times.endTime,
        room: extractRoom(line),
        sourceText: line
      };
      row.subjectName = extractSubject(line, row.classCode, row.slotCode, row.room);
      row.warnings = rowWarnings(row);
      row.confidence = confidenceFor(row.warnings);
      if (row.classCode || row.slotCode || row.room || (row.startTime && row.endTime)) {
        candidates.push(row);
      }
    });

    var parsedRows = candidates.filter(function(row) {
      return row.classCode && row.slotCode && row.startTime && row.endTime && row.room;
    });
    if (parsedRows.length === 0 && candidates.length > 0) parsedRows = candidates;

    if (parsedRows.length === 0) {
      var parseError = new Error('Could not recognize any timetable rows. Please retake the photo or enter the schedule manually.');
      parseError.code = 'OCR_PARSE_FAILED';
      parseError.data = {
        rawText: normalized,
        parsedRows: [],
        warnings: ['No row contained enough class, slot, time, and room information']
      };
      throw parseError;
    }

    var warnings = [];
    parsedRows.forEach(function(row, index) {
      row.warnings.forEach(function(warning) {
        warnings.push('Row ' + (index + 1) + ': ' + warning);
      });
    });

    return {rawText: normalized, parsedRows: parsedRows, warnings: warnings};
  }

  function createDocFromBase64(params) {
    var base64 = text(params.imageBase64 || params.base64);
    var mimeType = text(params.mimeType) || 'image/jpeg';
    var fileName = text(params.fileName) || 'timetable.jpg';
    base64 = base64.replace(/^data:[^;]+;base64,/, '');
    if (!base64) throwError('VALIDATION_ERROR', 'Missing imageBase64.');
    var blob = Utilities.newBlob(Utilities.base64Decode(base64), mimeType, fileName);
    return Drive.Files.insert(
      {title: TEMP_PREFIX + new Date().getTime(), mimeType: MimeType.GOOGLE_DOCS},
      blob,
      {ocr: true, ocrLanguage: text(params.ocrLanguage) || 'vi'}
    );
  }

  function createDocFromDriveFile(params) {
    var fileId = text(params.fileId || params.driveFileId);
    if (!fileId) throwError('VALIDATION_ERROR', 'Missing fileId.');
    return Drive.Files.copy(
      {title: TEMP_PREFIX + new Date().getTime(), mimeType: MimeType.GOOGLE_DOCS},
      fileId,
      {ocr: true, ocrLanguage: text(params.ocrLanguage) || 'vi'}
    );
  }

  function extractTextWithDriveOCR(params) {
    var docFile = null;
    try {
      docFile = params.fileId || params.driveFileId
        ? createDocFromDriveFile(params)
        : createDocFromBase64(params);
      Utilities.sleep(1000);
      return DocumentApp.openById(docFile.id).getBody().getText();
    } finally {
      if (docFile && docFile.id) {
        try {
          DriveApp.getFileById(docFile.id).setTrashed(true);
        } catch (cleanupError) {
          Logger.log('Failed to clean OCR temp doc: ' + cleanupError);
        }
      }
    }
  }

  function periodForSlot(slotCode) {
    if (DEFAULT_SLOT_TIMES[slotCode]) return DEFAULT_SLOT_TIMES[slotCode].period;
    if (/^A/.test(slotCode)) return 'Morning';
    if (/^P/.test(slotCode)) return 'Afternoon';
    if (/^E/.test(slotCode)) return 'Evening';
    return '';
  }

  function persistRows(params, parsedRows) {
    var teacher = AuthService.requireTeacher(params);
    var lock = LockService.getScriptLock();
    lock.waitLock(30000);
    try {
      SheetDB.ensureSheet('Slot', SLOT_COLUMNS);
      SheetDB.ensureSheet('Class_Section', CLASS_COLUMNS);

      var existingSlots = SheetDB.getRowsAsObjects('Slot');
      var existingClasses = SheetDB.getRowsAsObjects('Class_Section');
      var savedSlots = {};
      var createdClasses = [];

      parsedRows.forEach(function(row) {
        if (!row.slotCode || !row.startTime || !row.endTime) return;
        if (!savedSlots[row.slotCode]) {
          var slotPayload = {
            slotCode: row.slotCode,
            period: periodForSlot(row.slotCode),
            startTime: row.startTime,
            endTime: row.endTime
          };
          var hasSlot = existingSlots.some(function(slot) {
            return text(slot.slotCode) === row.slotCode;
          });
          if (hasSlot) SheetDB.updateRow('Slot', 'slotCode', row.slotCode, slotPayload);
          else SheetDB.insertRow('Slot', slotPayload);
          savedSlots[row.slotCode] = true;
        }

        if (!row.classCode) return;
        var hasClass = existingClasses.some(function(cls) {
          return text(cls.classCode) === row.classCode;
        });
        if (!hasClass) {
          SheetDB.insertRow('Class_Section', {
            classCode: row.classCode,
            subjectName: row.subjectName || row.classCode,
            credits: '',
            room: row.room || '',
            studentCount: 0,
            teacherMemberCode: text(teacher.memberCode),
            slotCode: row.slotCode || ''
          });
          createdClasses.push(row.classCode);
          existingClasses.push({classCode: row.classCode});
        }
      });

      return {
        savedSlotCodes: Object.keys(savedSlots),
        createdClassCodes: createdClasses
      };
    } finally {
      lock.releaseLock();
    }
  }

  function ocrTimetable(params) {
    var rawText = text(params.rawText);
    if (!rawText) rawText = extractTextWithDriveOCR(params);
    var result = parseTimetableText(rawText);
    var shouldPersist = params.save === true || params.save === 'true' ||
      params.persist === true || params.persist === 'true';
    result.saved = false;
    if (shouldPersist) {
      result.persistResult = persistRows(params, result.parsedRows);
      result.saved = true;
    }
    return result;
  }

  return {
    ocrTimetable: ocrTimetable,
    parseTimetableText: parseTimetableText
  };
})();
