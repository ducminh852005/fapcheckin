import 'dart:convert';

import 'package:archive/archive.dart';

import '../models/history_detail.dart';

/// Tạo workbook .xlsx tối thiểu (OOXML). Chuỗi nằm inline nên nội dung do người dùng nhập
/// không bao giờ bị hiểu là công thức. Port từ HistoryExcel.gs của backend cũ.
HistoryExport buildHistoryWorkbook(List<List<Object?>> rows, String classCode) {
  const ns = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
  final sheetRows = StringBuffer();
  for (var i = 0; i < rows.length; i++) {
    sheetRows.write('<row r="${i + 1}">');
    for (var j = 0; j < rows[i].length; j++) {
      final ref = '${_column(j)}${i + 1}';
      final value = rows[i][j];
      if (value is num) {
        sheetRows.write('<c r="$ref"><v>$value</v></c>');
      } else {
        sheetRows.write(
          '<c r="$ref" t="inlineStr"><is><t xml:space="preserve">'
          '${_xml(value)}</t></is></c>',
        );
      }
    }
    sheetRows.write('</row>');
  }
  final parts = <String, String>{
    '[Content_Types].xml':
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
        '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
        '</Types>',
    '_rels/.rels':
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
        '</Relationships>',
    'xl/workbook.xml':
        '<workbook xmlns="$ns" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
        '<sheets><sheet name="Attendance" sheetId="1" r:id="rId1"/></sheets></workbook>',
    'xl/_rels/workbook.xml.rels':
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>'
        '</Relationships>',
    'xl/worksheets/sheet1.xml':
        '<worksheet xmlns="$ns"><sheetData>$sheetRows</sheetData></worksheet>',
  };

  final archive = Archive();
  parts.forEach((name, xml) {
    final bytes = utf8.encode(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>$xml',
    );
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  });
  final zipped = ZipEncoder().encode(archive);

  final safe = classCode.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  return HistoryExport.fromJson({
    'filename': 'Attendance_$safe.xlsx',
    'mimeType':
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'base64': base64Encode(zipped),
  });
}

String _column(int index) {
  var n = index;
  var name = '';
  do {
    name = String.fromCharCode(65 + n % 26) + name;
    n = n ~/ 26 - 1;
  } while (n >= 0);
  return name;
}

String _xml(Object? value) => (value ?? '')
    .toString()
    .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
