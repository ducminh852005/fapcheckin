import 'dart:convert';
import 'dart:io';

Future<String> downloadHistory(
  String filename,
  String base64,
  String mimeType,
) async {
  final safeName = filename.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
  final folder = await Directory.systemTemp.createTemp('fap_attendance_');
  final file = File('${folder.path}${Platform.pathSeparator}$safeName');
  await file.writeAsBytes(base64Decode(base64), flush: true);
  return 'Đã lưu tại ${file.path}';
}
