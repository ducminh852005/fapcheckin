import 'package:cloud_firestore/cloud_firestore.dart';

import '../firebase/firestore_json.dart';
import '../result/api_result.dart';
import '../result/guard.dart';
import '../session/current_user.dart';
import 'internal/teacher_data.dart';

/// Kế hoạch giảng dạy ngoài lịch (`class_schedules`): học bù, workshop, ôn tập.
/// Khác với phiên điểm danh (`sessions`, mở ngay lúc dạy).
///
/// Lưu ý so với backend cũ: chỉ phát hiện trùng lịch trong phạm vi dữ liệu của chính giảng viên
/// (Security Rules không cho đọc lịch/phòng của giảng viên khác).
class ScheduleRepository {
  ScheduleRepository({
    required this.currentUser,
    FirebaseFirestore? firestore,
    DateTime Function()? now,
  }) : _injectedDb = firestore,
       _now = now ?? DateTime.now;

  final CurrentUser currentUser;
  final FirebaseFirestore? _injectedDb;

  /// Truy cập chậm để repository dựng được khi chưa khởi tạo Firebase (widget test);
  /// lỗi khi gọi sẽ được `guardApi` đổi thành `ApiFailure`.
  FirebaseFirestore get _db => _injectedDb ?? FirebaseFirestore.instance;
  final DateTime Function() _now;

  static const _lessonTypes = ['makeup', 'workshop', 'review'];
  static const _columns = [
    'scheduleId', 'requestId', 'teacherMemberCode', 'classCode', 'scheduleDate',
    'slotCode', 'room', 'lessonType', 'teachingMethod', 'note', 'status', 'createdAt',
  ];

  /// Bảng slot chuẩn dùng khi Firestore chưa có `slots` (xem docs/03-du-lieu-firestore.md §3).
  static const _fallbackSlots = [
    ('A1', '07:00', '09:15'), ('A2', '09:30', '11:45'),
    ('A3', '07:00', '09:15'), ('A4', '09:30', '11:45'),
    ('A5', '07:00', '09:15'), ('A6', '09:30', '11:45'),
    ('P1', '12:30', '14:45'), ('P2', '15:00', '17:15'),
    ('P3', '12:30', '14:45'), ('P4', '15:00', '17:15'),
    ('P5', '12:30', '14:45'), ('P6', '15:00', '17:15'),
    ('Slot 1', '07:00', '08:30'), ('Slot 2', '08:45', '10:15'),
    ('Slot 3', '10:30', '12:00'), ('Slot 4', '12:30', '14:00'),
    ('Slot 5', '14:15', '15:45'), ('Slot 6', '16:00', '17:30'),
    ('1', '07:00', '08:30'), ('2', '08:45', '10:15'),
    ('3', '10:30', '12:00'), ('4', '12:30', '14:00'),
    ('5', '14:15', '15:45'), ('6', '16:00', '17:30'),
  ];

  String get _me => currentUser.memberCode;

  Future<ApiResult<Map<String, dynamic>>> options() => guardApi(() async {
    final me = currentUser.requireUser;
    final classDocs = await _db
        .collection('classes')
        .where('teacherMemberCode', isEqualTo: me.memberCode)
        .get();
    final enrollments = await _db
        .collection('enrollments')
        .where('teacherMemberCode', isEqualTo: me.memberCode)
        .get();
    final classes = [
      for (final c in classDocs.docs)
        () {
          final code = c.id;
          final rolls = {
            for (final e in enrollments.docs)
              if (text(e.data()['classCode']) == code &&
                  text(e.data()['rollNumber']).isNotEmpty)
                text(e.data()['rollNumber']),
          };
          return {
            'classCode': code,
            'subjectName': text(c.data()['subjectName']),
            'room': text(c.data()['room']),
            'studentCount': rolls.length,
            'slotCode': text(c.data()['slotCode']),
          };
        }(),
    ];
    final rooms = {
      for (final c in classes)
        if (text(c['room']).isNotEmpty) text(c['room']),
    }.toList()..sort();
    return {
      'teacherName': me.fullName,
      'today': vnDate(_now()),
      'classes': classes,
      'slots': await _slots(),
      'rooms': rooms,
      'capabilities': {'autoQR': false, 'sendEmail': false, 'syncFap': false},
      'schedules': await _listFor(_me),
    };
  });

  Future<ApiResult<List<Map<String, dynamic>>>> list() =>
      guardApi(() => _listFor(_me));

  Future<ApiResult<Map<String, dynamic>>> create(Map<String, dynamic> input) =>
      guardApi(() async {
        final me = _me;
        final classCode = text(input['classCode']);
        final classSnap = await _db.collection('classes').doc(classCode).get();
        final cls = classSnap.data();
        if (cls == null || text(cls['teacherMemberCode']) != me) {
          throw ApiException('FORBIDDEN', 'Lớp không thuộc giảng viên đang đăng nhập.');
        }
        final requestId = text(input['requestId']);
        if (!RegExp(r'^[a-zA-Z0-9_-]{8,100}$').hasMatch(requestId)) {
          throw ApiException('VALIDATION_ERROR', 'requestId không hợp lệ.');
        }
        if (input['autoQR'] == true || input['sendEmail'] == true || input['syncFap'] == true) {
          throw ApiException('NOT_SUPPORTED', 'QR tự động, email và đồng bộ FAP chưa được tích hợp.');
        }

        final allSlots = await _slots();
        final slot = allSlots
            .where((s) => s['slotCode'] == text(input['slotCode']) && s['available'] == true)
            .firstOrNull;
        if (slot == null) {
          throw ApiException(
            'VALIDATION_ERROR',
            'Ca học không hợp lệ. Kiểm tra giờ bắt đầu/kết thúc của slot (24 giờ).',
          );
        }
        final day = text(input['scheduleDate']);
        final parsed = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(day)
            ? DateTime.tryParse('${day}T00:00:00Z')
            : null;
        if (parsed == null || parsed.toIso8601String().substring(0, 10) != day) {
          throw ApiException('VALIDATION_ERROR', 'Ngày học không hợp lệ.');
        }
        final lessonType = text(input['lessonType']);
        if (!_lessonTypes.contains(lessonType) || input['teachingMethod'] != 'onCampus') {
          throw ApiException('VALIDATION_ERROR', 'Loại buổi học hoặc hình thức học không hợp lệ.');
        }
        final room = text(input['room']);
        final note = text(input['note']);
        final ownedRooms = await _db
            .collection('classes')
            .where('teacherMemberCode', isEqualTo: me)
            .get();
        if (room.isEmpty ||
            !ownedRooms.docs.any((c) => text(c.data()['room']) == room) ||
            note.length > 2000) {
          throw ApiException('VALIDATION_ERROR', 'Phòng học không hợp lệ hoặc ghi chú quá 2000 ký tự.');
        }

        final wanted = {
          'teacherMemberCode': me,
          'classCode': classCode,
          'scheduleDate': day,
          'slotCode': slot['slotCode'],
          'room': room,
          'lessonType': lessonType,
          'teachingMethod': 'onCampus',
          'note': note,
        };

        // Idempotent theo requestId: id tài liệu xác định nên retry không tạo trùng.
        final scheduleId = '${me}_$requestId';
        final ref = _db.collection('class_schedules').doc(scheduleId);
        final existingDoc = await ref.get();
        if (existingDoc.exists) {
          final saved = _dto({...docToJson(existingDoc), 'scheduleId': scheduleId});
          if (wanted.keys.any((k) => saved[k] != wanted[k])) {
            throw ApiException('CONFLICT', 'Yêu cầu đã được sử dụng cho một lịch khác.');
          }
          return saved;
        }

        final start = DateTime.parse('${day}T${slot['startTime']}:00+07:00');
        if (!start.isAfter(_now())) {
          throw ApiException('VALIDATION_ERROR', 'Chọn ca học chưa bắt đầu.');
        }

        bool overlaps(String? s, String? e) =>
            s == null || e == null || s.isEmpty || e.isEmpty ||
            (s.compareTo(slot['endTime']) < 0 && e.compareTo(slot['startTime']) > 0);
        Map<String, dynamic>? slotOf(String code) =>
            allSlots.where((s) => s['slotCode'] == code).firstOrNull;

        // Mọi lịch/phiên trong dữ liệu của giảng viên này đều thuộc cùng giảng viên,
        // nên chỉ cần trùng khoảng giờ trong ngày là xung đột.
        final plans = await _listFor(me);
        var conflict = plans.any((r) {
          if (r['status'] == 'cancelled' || r['scheduleDate'] != day) return false;
          final other = slotOf(text(r['slotCode']));
          return overlaps(other?['startTime'] as String?, other?['endTime'] as String?);
        });
        if (!conflict) {
          final sessions = await _db
              .collection('sessions')
              .where('teacherMemberCode', isEqualTo: me)
              .get();
          conflict = sessions.docs.any((d) {
            final s = d.data();
            if (fmtDate(s['sessionDate']) != day || s['sessionStatus'] == 'cancelled') {
              return false;
            }
            final other = slotOf(text(s['slotCode']));
            return overlaps(other?['startTime'] as String?, other?['endTime'] as String?);
          });
        }
        if (conflict) {
          throw ApiException(
            'SCHEDULE_CONFLICT',
            'Giảng viên, lớp hoặc phòng đã có lịch trong khoảng thời gian này.',
          );
        }

        final record = {
          ...wanted,
          'scheduleId': scheduleId,
          'requestId': requestId,
          'status': 'scheduled',
        };
        await ref.set({...record, 'createdAt': FieldValue.serverTimestamp()});
        return _dto({...record, 'createdAt': _now().toUtc().toIso8601String()});
      });

  // ── helpers ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _slots() async {
    final raw = await loadSlots(_db);
    String time(Object? v) {
      final m = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?$').firstMatch(text(v));
      if (m == null) return '';
      final h = int.parse(m[1]!), min = int.parse(m[2]!);
      return h < 24 && min < 60 ? '${m[1]!.padLeft(2, '0')}:${m[2]}' : '';
    }

    if (raw.isEmpty) {
      return [
        for (final (code, start, end) in _fallbackSlots)
          {'slotCode': code, 'startTime': start, 'endTime': end, 'available': true},
      ];
    }
    return [
      for (final s in raw)
        () {
          final start = time(s['startTime']), end = time(s['endTime']);
          return {
            'slotCode': text(s['slotCode']),
            'startTime': start,
            'endTime': end,
            'available': start.isNotEmpty && end.isNotEmpty && start.compareTo(end) < 0,
          };
        }(),
    ];
  }

  Future<List<Map<String, dynamic>>> _listFor(String memberCode) async {
    final slots = await _slots();
    String startOf(String code) =>
        slots.where((s) => s['slotCode'] == code).firstOrNull?['startTime'] as String? ?? '';
    final snap = await _db
        .collection('class_schedules')
        .where('teacherMemberCode', isEqualTo: memberCode)
        .get();
    final rows = [
      for (final d in snap.docs) _dto({...docToJson(d), 'scheduleId': d.id}),
    ]..sort(
        (a, b) => ('${a['scheduleDate']}${startOf(text(a['slotCode']))}')
            .compareTo('${b['scheduleDate']}${startOf(text(b['slotCode']))}'),
      );
    return rows;
  }

  Map<String, dynamic> _dto(Map<String, dynamic> r) => {
    for (final k in _columns) k: text(r[k]),
    'scheduleDate': fmtDate(r['scheduleDate']),
  };
}
