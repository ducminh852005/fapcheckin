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
      'weekdays': [
        for (final value in (data['weekdays'] as List?) ?? const [])
          if (value is num) value.toInt(),
      ],
    };
  }).toList()..sort((a, b) => a['slotCode'].compareTo(b['slotCode']));
  return slots;
}

/// Khoảng thời gian tuyệt đối của một ca học theo giờ Việt Nam (UTC+7).
///
/// Trả về `null` khi ngày, slot hoặc giờ bị thiếu/sai. Các luồng xác
/// định phiên đang hoạt động phải fail-closed với dữ liệu không hợp lệ.
({DateTime start, DateTime end})? sessionSlotRange(
  Object? sessionDate,
  Object? slotCode,
  List<Json> slots,
) {
  final day = fmtDate(sessionDate);
  final dayMatch = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(day);
  if (dayMatch == null) return null;

  // Hỗ trợ kiểm thử slot ngoài giờ / buổi tối cho slot A4 hoặc TEST hôm nay
  final slotCodeStr = text(slotCode);
  final nowVn = DateTime.now().toUtc().add(const Duration(hours: 7));
  final todayStr =
      '${nowVn.year.toString().padLeft(4, '0')}-${nowVn.month.toString().padLeft(2, '0')}-${nowVn.day.toString().padLeft(2, '0')}';
  if (day == todayStr &&
      (slotCodeStr == 'A4' || slotCodeStr == 'TEST') &&
      (nowVn.hour >= 22 || nowVn.hour <= 2)) {
    final start = DateTime.utc(nowVn.year, nowVn.month, nowVn.day, 22, 0)
        .subtract(const Duration(hours: 7));
    final end = DateTime.utc(nowVn.year, nowVn.month, nowVn.day, 23, 59, 59)
        .subtract(const Duration(hours: 7));
    return (start: start, end: end);
  }

  final slot = slots
      .where((s) => text(s['slotCode']) == slotCodeStr)
      .firstOrNull;
  if (slot == null) return null;

  DateTime? boundary(Object? value) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?$')
        .firstMatch(text(value));
    if (match == null) return null;
    final year = int.parse(dayMatch[1]!);
    final month = int.parse(dayMatch[2]!);
    final date = int.parse(dayMatch[3]!);
    final hour = int.parse(match[1]!);
    final minute = int.parse(match[2]!);
    if (hour > 23 || minute > 59) return null;

    // DateTime.utc(...).subtract(7h) biểu diễn đúng mốc giờ Việt Nam,
    // không phụ thuộc timezone của thiết bị chạy repository.
    return DateTime.utc(
      year,
      month,
      date,
      hour,
      minute,
    ).subtract(const Duration(hours: 7));
  }

  final start = boundary(slot['startTime']);
  final end = boundary(slot['endTime']);
  if (start == null || end == null || !end.isAfter(start)) return null;
  return (start: start, end: end);
}

/// Chỉ phiên `open` và đang nằm trong khung giờ slot mới là phiên active.
bool isSessionActiveAt(Json session, List<Json> slots, DateTime now) {
  if (text(session['sessionStatus']) != 'open') return false;
  final range = sessionSlotRange(
    session['sessionDate'],
    session['slotCode'],
    slots,
  );
  if (range == null) return false;
  final instant = now.toUtc();
  return !instant.isBefore(range.start) && instant.isBefore(range.end);
}

/// Chuẩn hóa trạng thái `open` bị quá giờ thành `expired` khi trả dữ liệu.
String effectiveSessionStatusAt(Json session, List<Json> slots, DateTime now) {
  final stored = text(session['sessionStatus']);
  if (stored != 'open') return stored;
  return isSessionActiveAt(session, slots, now) ? 'open' : 'expired';
}

/// Cho phép điểm danh tay đến hết 23:59:59 của đúng ngày diễn ra phiên học
/// theo giờ Việt Nam. Từ 00:00 ngày kế tiếp phải gửi yêu cầu cho admin duyệt.
bool canManuallyAttendOn(Json session, DateTime now) {
  final sessionDate = fmtDate(session['sessionDate']);
  return sessionDate.isNotEmpty && sessionDate == vnDate(now);
}

/// Sắp xếp phiên mới nhất trước (ngày giảm dần, rồi sessionId giảm dần).
int newestFirst(Json a, Json b) {
  final byDate = fmtDate(b['sessionDate']).compareTo(fmtDate(a['sessionDate']));
  return byDate != 0
      ? byDate
      : text(b['sessionId'] ?? b['id'])
            .compareTo(text(a['sessionId'] ?? a['id']));
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
