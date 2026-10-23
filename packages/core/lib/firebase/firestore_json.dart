import 'package:cloud_firestore/cloud_firestore.dart';

/// Đổi dữ liệu Firestore thành map kiểu JSON mà các model (`fromJson`) đã quen:
/// [Timestamp] -> chuỗi ISO 8601, map/list lồng nhau được xử lý đệ quy.
Object? firestoreToJson(Object? value) {
  if (value is Timestamp) return value.toDate().toUtc().toIso8601String();
  if (value is DateTime) return value.toUtc().toIso8601String();
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), firestoreToJson(v)));
  }
  if (value is List) return value.map(firestoreToJson).toList();
  return value;
}

Map<String, dynamic> docToJson(DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data() ?? const <String, dynamic>{};
  return Map<String, dynamic>.from(firestoreToJson(data)! as Map);
}

String text(Object? v) => v == null ? '' : v.toString().trim();

/// `yyyy-MM-dd` theo giờ Việt Nam (UTC+7, không có DST).
String vnDate(DateTime moment) {
  final d = moment.toUtc().add(const Duration(hours: 7));
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// Chuẩn hóa ngày về `yyyy-MM-dd` (chấp nhận `yyyy-M-d`, ISO date-time, `yyyy/MM/dd`).
String fmtDate(Object? value) {
  if (value == null || value == '') return '';
  if (value is Timestamp) return vnDate(value.toDate());
  if (value is DateTime) return vnDate(value);
  final str = value.toString().trim();
  final m = RegExp(r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})').firstMatch(str);
  if (m != null) {
    return '${m[1]}-${m[2]!.padLeft(2, '0')}-${m[3]!.padLeft(2, '0')}';
  }
  return str.length > 10 ? str.substring(0, 10) : str;
}

const presentStatuses = ['Present', 'Late', 'ManualByGV'];
bool isPresentStatus(Object? status) => presentStatuses.contains(status?.toString());

/// Phiên cũ không có `ipCheck` được coi là có kiểm tra IP (như hành vi trước đây).
bool ipCheckEnabled(Map<String, dynamic>? session) {
  final v = session?['ipCheck'];
  if (v == null || v == '') return true;
  return v == true || v.toString().toUpperCase() == 'TRUE';
}
