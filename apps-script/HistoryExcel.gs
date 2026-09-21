// Minimal OOXML workbook: inline strings keep user text from becoming formulas.
var HistoryExcel = (function() {
  function xml(value) {
    return String(value == null ? '' : value).replace(/[\x00-\x08\x0B\x0C\x0E-\x1F]/g, '')
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }
  function create(rows, classCode) {
    var ns = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
    var sheet = '<worksheet xmlns="' + ns + '"><sheetData>' + rows.map(function(row, i) {
      return '<row r="' + (i + 1) + '">' + row.map(function(value, j) {
        var ref = String.fromCharCode(65 + j) + (i + 1);
        return typeof value === 'number' ? '<c r="' + ref + '"><v>' + value + '</v></c>' :
          '<c r="' + ref + '" t="inlineStr"><is><t xml:space="preserve">' + xml(value) + '</t></is></c>';
      }).join('') + '</row>';
    }).join('') + '</sheetData></worksheet>';
    var parts = {
      '[Content_Types].xml': '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/></Types>',
      '_rels/.rels': '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>',
      'xl/workbook.xml': '<workbook xmlns="' + ns + '" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="Attendance" sheetId="1" r:id="rId1"/></sheets></workbook>',
      'xl/_rels/workbook.xml.rels': '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/></Relationships>',
      'xl/worksheets/sheet1.xml': sheet
    };
    var blobs = Object.keys(parts).map(function(name) {
      return Utilities.newBlob('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' + parts[name], 'application/xml', name);
    });
    var filename = 'Attendance_' + String(classCode).replace(/[^a-zA-Z0-9_-]/g, '_') + '.xlsx';
    return { filename: filename, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      base64: Utilities.base64Encode(Utilities.zip(blobs, filename).getBytes()) };
  }
  return { create: create };
})();
