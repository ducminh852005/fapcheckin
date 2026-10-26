import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../firebase/firestore_json.dart';

/// Các truy vấn dùng chung của repository giảng viên.
///
/// Mọi truy vấn lọc theo `teacherMemberCode` (khóa sở hữu trong Security Rules);
/// thiếu điều kiện đó Firestore sẽ từ chối cả truy vấn.
typedef Json = Map<String, dynamic>;

/// Đổi tài liệu thành map kiểu JSON; `id` = doc id, và [idField] (nếu có) mặc định bằng doc id.
Json rowOf(DocumentSnapshot<Json> doc, [String? idField]) {
  final json = docToJson(doc);
  json['id'] = doc.id;
  if (idField != null && text(json[idField]).isEmpty) json[idField] = doc.id;
  return json;
}

Future<List<Json>> _query(Query<Json> query, [String? idField]) async =>
    (await query.get()).docs.map((d) => rowOf(d, idField)).toList();

/// Toàn bộ dữ liệu điểm danh của một giảng viên (đã đổi sang map kiểu JSON, có `id` = doc id).
class TeacherTables {
  TeacherTables({
    required this.classes,
    required this.sessions,
    required this.enrollments,
    required this.records,
  });

  final List<Json> classes;
  final List<Json> sessions;
  final List<Json> enrollments;
  final List<Json> records;

  static Future<TeacherTables> load(
    FirebaseFirestore db,
    String memberCode, {
    bool withRecords = true,
  }) async {
    Query<Json> mine(String collection) => db
        .collection(collection)
        .where('teacherMemberCode', isEqualTo: memberCode);
    final results = await Future.wait([
      _query(mine('classes'), 'classCode'),
      _query(mine('sessions'), 'sessionId'),
      _query(mine('enrollments')),
      if (withRecords) _query(mine('attendance_records'), 'recordId'),
    ]);
    return TeacherTables(
      classes: results[0],
      sessions: results[1],
      enrollments: results[2],
      records: withRecords ? results[3] : const [],
    );
  }
}

/// Khung giờ của slot (`slots` + `timeSlots`), cùng hình dạng như bảng Slot cũ.
Future<List<Json>> loadSlots(FirebaseFirestore db) async {
  final slotDocs = await db.collection('slots').get();
  final timeDocs = await db.collection('timeSlots').get();
  final times = {for (final d in timeDocs.docs) d.id: d.data()};
  const periodLabel = {'Morning': 'Morning (A)', 'Afternoon': 'Afternoon (P)'};
  final slots = slotDocs.docs.map((d) {
    final data = d.data();
    final block = times[text(data['timeSlotId'])] ?? const <String, dynamic>{};
    final period = text(block['period']);
    return <String, dynamic>{
      'slotCode': d.id,
      'period': periodLabel[period] ?? period,
      'startTime': text(block['startTime']),
      'endTime': text(block['endTime']),
    };
  }).toList()..sort((a, b) => a['slotCode'].compareTo(b['slotCode']));
  return slots;
}

/// Sắp xếp phiên mới nhất trước (ngày giảm dần, rồi sessionId giảm dần).
int newestFirst(Json a, Json b) {
  final byDate = fmtDate(b['sessionDate']).compareTo(fmtDate(a['sessionDate']));
  return byDate != 0 ? byDate : text(b['sessionId'] ?? b['id']).compareTo(text(a['sessionId'] ?? a['id']));
}

/// Chuỗi ngẫu nhiên an toàn, dùng làm `qrSecret` (≥ 16 ký tự theo Security Rules).
String randomSecret([int bytes = 16]) {
  final random = Random.secure();
  return List.generate(
    bytes,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}

List<List<T>> chunked<T>(List<T> items, int size) => [
  for (var i = 0; i < items.length; i += size)
    items.sublist(i, min(i + size, items.length)),
];

/// Ghi/xóa nhiều tài liệu theo từng batch ≤ [size] thao tác.
Future<void> commitInBatches(
  FirebaseFirestore db,
  List<void Function(WriteBatch batch)> operations, {
  int size = 400,
}) async {
  for (final group in chunked(operations, size)) {
    final batch = db.batch();
    for (final op in group) {
      op(batch);
    }
    await batch.commit();
  }
}
