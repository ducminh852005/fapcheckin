// File: SheetDB.gs

var SheetDB = (function() {
  // Thay thế ID này bằng ID của Google Sheet thực tế của bạn
  var SPREADSHEET_ID = '1X342Hzd9_lwQeAwUZi80r1Zcs7_qyFZNDglUTw9y1l4'; 

  // Sheets auto-detects numeric cells (e.g. room 303 or a numeric memberCode).
  // Keep API text fields and join keys consistent across all sheets.
  var TEXT_FIELDS = [
    'memberCode', 'teacherMemberCode', 'rollNumber', 'classCode', 'subjectCode',
    'sessionId', 'recordId', 'slotCode', 'room', 'subjectName', 'fullName',
    'email', 'role', 'timeLabel', 'sessionStatus', 'status', 'qrSecret',
    'teacherIp', 'ipAddress', 'networkVerificationResult', 'note', 'updatedBy',
    'startTime', 'endTime', 'period'
  ];

  var REQUIRED_HEADERS = {
    Class_Section: ['classCode', 'subjectName', 'teacherMemberCode', 'slotCode'],
    Enrollment: ['rollNumber', 'classCode'],
    Slot: ['slotCode', 'startTime', 'endTime'],
    Users: ['memberCode']
  };

  function normalizeCell(field, value) {
    if (TEXT_FIELDS.indexOf(field) !== -1) {
      if (value == null) return '';
      if (Object.prototype.toString.call(value) === '[object Date]') {
        var year = value.getFullYear();
        if (year <= 1900) {
          var hh = ('0' + value.getUTCHours()).slice(-2);
          var mm = ('0' + value.getUTCMinutes()).slice(-2);
          return hh + ':' + mm;
        }
        var month = ('0' + (value.getMonth() + 1)).slice(-2);
        var day = ('0' + value.getDate()).slice(-2);
        var hh = ('0' + value.getHours()).slice(-2);
        var mm = ('0' + value.getMinutes()).slice(-2);
        return day + '/' + month + '/' + year + ' ' + hh + ':' + mm;
      }
      var str = String(value).trim();
      if (str.indexOf('GMT') !== -1 || str.indexOf('Indochina') !== -1 || str.indexOf('1899') !== -1) {
        var matches = str.match(/(\d{1,2}):(\d{2})(?::\d{2})?/g);
        if (matches && matches.length >= 2) {
          return matches[0].slice(0, 5) + ' - ' + matches[1].slice(0, 5);
        } else if (matches && matches.length === 1) {
          return matches[0].slice(0, 5);
        }
      }
      return str;
    }
    return value;
  }

  function getHeaders(data, sheetName) {
    var headers = data[0].map(function(header) { return String(header).trim(); });
    var required = REQUIRED_HEADERS[sheetName] || [];
    var missing = required.filter(function(header) { return headers.indexOf(header) === -1; });
    if (missing.length > 0) {
      throwError(
        'SHEET_SCHEMA_INVALID',
        'Bảng ' + sheetName + ' thiếu tiêu đề bắt buộc ở hàng 1: ' + missing.join(', ') + '.'
      );
    }
    return headers;
  }

  function subjectCodeFromClassCode(classCode) {
    var parts = String(classCode == null ? '' : classCode)
      .toUpperCase()
      .split(/[^A-Z0-9]+/);
    for (var i = 0; i < parts.length; i++) {
      // FAP subject codes use 2-5 letters followed by three digits, while
      // class groups such as SE1917 contain four digits.
      if (/^[A-Z]{2,5}\d{3}$/.test(parts[i])) return parts[i];
    }
    return '';
  }

  function enrichRow(sheetName, rowObj) {
    // The live Class_Section sheet stores composite keys such as
    // PRN232_SE1917 and does not have a separate subjectCode column. Expose a
    // derived subjectCode to every service without changing the sheet schema.
    if (sheetName === 'Class_Section' && !rowObj.subjectCode) {
      rowObj.subjectCode = subjectCodeFromClassCode(rowObj.classCode);
    }
    return rowObj;
  }

  function writeValue(field, value) {
    // Treat a teacher's note as literal text, never as a spreadsheet formula.
    if (field === 'note' && typeof value === 'string' && value.charAt(0) === '=') return "'" + value;
    return value;
  }
  
  function getSpreadsheet() {
    // Always use the configured data source, even when this script is bound
    // to another workbook (for example an old demo/template copy).
    return SpreadsheetApp.openById(SPREADSHEET_ID);
  }

  function getSheet(sheetName) {
    var ss = getSpreadsheet();
    var sheet = ss.getSheetByName(sheetName);
    if (!sheet) throwError('SHEET_NOT_FOUND', 'Không tìm thấy bảng: ' + sheetName);
    return sheet;
  }

  function getRowsAsObjects(sheetName) {
    var sheet = getSheet(sheetName);
    var range = sheet.getDataRange();
    var data = (typeof range.getDisplayValues === 'function')
        ? range.getDisplayValues()
        : range.getValues();
    if (data.length <= 1) return [];
    
    var headers = getHeaders(data, sheetName);
    var rows = [];
    for (var i = 1; i < data.length; i++) {
      if (data[i].every(function(value) { return value === '' || value == null; })) continue;
      var rowObj = {};
      for (var j = 0; j < headers.length; j++) {
        if (headers[j]) rowObj[headers[j]] = normalizeCell(headers[j], data[i][j]);
      }
      rows.push(enrichRow(sheetName, rowObj));
    }
    return rows;
  }

  function insertRow(sheetName, rowObj) {
    var sheet = getSheet(sheetName);
    var headers = getHeaders(sheet.getDataRange().getValues(), sheetName);
    var newRow = [];
    for (var i = 0; i < headers.length; i++) {
      newRow.push(rowObj[headers[i]] !== undefined ? writeValue(headers[i], rowObj[headers[i]]) : '');
    }
    sheet.appendRow(newRow);
    return rowObj;
  }

  function updateRow(sheetName, idField, idValue, updateObj) {
    var sheet = getSheet(sheetName);
    var data = sheet.getDataRange().getValues();
    if (data.length <= 1) return false;
    
    var headers = getHeaders(data, sheetName);
    var idIndex = headers.indexOf(idField);
    if (idIndex === -1) return false;
    
    for (var i = 1; i < data.length; i++) {
      if (normalizeCell(idField, data[i][idIndex]) === normalizeCell(idField, idValue)) {
        for (var key in updateObj) {
          var colIndex = headers.indexOf(key);
          if (colIndex !== -1) {
             sheet.getRange(i + 1, colIndex + 1).setValue(writeValue(key, updateObj[key]));
          }
        }
        return true;
      }
    }
    return false;
  }

  // Add optional history columns without changing existing rows or formatting.
  function ensureColumns(sheetName, columns) {
    var sheet = getSheet(sheetName);
    var headers = getHeaders(sheet.getDataRange().getValues(), sheetName);
    columns.forEach(function(column) {
      if (headers.indexOf(column) === -1) {
        var nextColumn = headers.length + 1;
        if (nextColumn > sheet.getMaxColumns()) sheet.insertColumnAfter(sheet.getMaxColumns());
        sheet.getRange(1, nextColumn).setValue(column);
        headers.push(column);
      }
    });
  }

  return {
    ensureSheet: function(name, columns) {
      var ss = getSpreadsheet();
      if (!ss.getSheetByName(name)) ss.insertSheet(name).appendRow(columns);
      else ensureColumns(name, columns);
    },
    getRowsAsObjects: getRowsAsObjects,
    insertRow: insertRow,
    updateRow: updateRow,
    ensureColumns: ensureColumns
  };
})();
