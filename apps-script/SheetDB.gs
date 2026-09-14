// File: SheetDB.gs

var SheetDB = (function() {
  // Thay thế ID này bằng ID của Google Sheet thực tế của bạn
  var SPREADSHEET_ID = '1X342Hzd9_lwQeAwUZi80r1Zcs7_qyFZNDglUTw9y1l4'; 
  
  function getSpreadsheet() {
    try {
      var ss = SpreadsheetApp.getActiveSpreadsheet();
      if (ss) return ss;
    } catch (e) {}
    
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
    var data = sheet.getDataRange().getValues();
    if (data.length <= 1) return [];
    
    var headers = data[0];
    var rows = [];
    for (var i = 1; i < data.length; i++) {
      var rowObj = {};
      for (var j = 0; j < headers.length; j++) {
        rowObj[headers[j]] = data[i][j];
      }
      rows.push(rowObj);
    }
    return rows;
  }

  function insertRow(sheetName, rowObj) {
    var sheet = getSheet(sheetName);
    var headers = sheet.getDataRange().getValues()[0];
    var newRow = [];
    for (var i = 0; i < headers.length; i++) {
      newRow.push(rowObj[headers[i]] !== undefined ? rowObj[headers[i]] : '');
    }
    sheet.appendRow(newRow);
    return rowObj;
  }

  function updateRow(sheetName, idField, idValue, updateObj) {
    var sheet = getSheet(sheetName);
    var data = sheet.getDataRange().getValues();
    if (data.length <= 1) return false;
    
    var headers = data[0];
    var idIndex = headers.indexOf(idField);
    if (idIndex === -1) return false;
    
    for (var i = 1; i < data.length; i++) {
      if (data[i][idIndex] === idValue) {
        for (var key in updateObj) {
          var colIndex = headers.indexOf(key);
          if (colIndex !== -1) {
             sheet.getRange(i + 1, colIndex + 1).setValue(updateObj[key]);
          }
        }
        return true;
      }
    }
    return false;
  }

  return {
    getRowsAsObjects: getRowsAsObjects,
    insertRow: insertRow,
    updateRow: updateRow
  };
})();
