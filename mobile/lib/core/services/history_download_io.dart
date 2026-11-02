import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

Future<String> downloadHistory(
  String filename,
  String base64,
  String mimeType,
) async {
  final safeName = filename.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
  final bytes = base64Decode(base64);
  if (Platform.isAndroid) {
    final uri = await const MethodChannel(
      'fapcheckin/export',
    ).invokeMethod<String>('saveXlsx', {'filename': safeName, 'bytes': bytes});
    return uri == null ? 'Đã hủy lưu file.' : 'Đã lưu file XLSX tại $uri';
  }
  final destination = await FilePicker.platform.saveFile(
    dialogTitle: 'Lưu báo cáo điểm danh',
    fileName: safeName,
    type: FileType.custom,
    allowedExtensions: ['xlsx'],
    bytes: bytes,
  );
  if (destination == null) return 'Đã hủy lưu file.';
  // iOS writes bytes through the native document picker. Desktop returns a path.
  if (!Platform.isAndroid && !Platform.isIOS) {
    await File(destination).writeAsBytes(bytes, flush: true);
  }
  return 'Đã lưu file XLSX tại $destination';
}
