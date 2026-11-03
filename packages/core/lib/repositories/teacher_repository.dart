import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../firebase/firestore_json.dart';
import '../models/attendance_history_model.dart';
import '../models/class_section_model.dart';
import '../models/close_session_model.dart';
import '../models/roster_entry_model.dart';
import '../models/session_model.dart';
import '../models/stats_entry_model.dart';
import '../models/sync_result_model.dart';
import '../result/api_result.dart';
import '../result/guard.dart';
import '../session/current_user.dart';
import 'internal/session_ops.dart';
import 'internal/teacher_data.dart';

/// Repository phía giảng viên: đọc/ghi thẳng Cloud Firestore (không còn backend trung gian).
/// Quyền truy cập do `firebase/firestore.rules` quyết định; mọi truy vấn đều lọc theo
/// `teacherMemberCode` của người đăng nhập.
class TeacherRepository {
  TeacherRepository({
    required this.currentUser,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    DateTime Function()? now,
  }) : _injectedDb = firestore,
       _injectedFunctions = functions,
       _now = now ?? DateTime.now;

  final CurrentUser currentUser;
  final FirebaseFirestore? _injectedDb;
  final FirebaseFunctions? _injectedFunctions;

  /// Truy cập chậm để repository dựng được khi chưa khởi tạo Firebase (widget test);
  /// lỗi khi gọi sẽ được `guardApi` đổi thành `ApiFailure`.
  FirebaseFirestore get _db => _injectedDb ?? FirebaseFirestore.instance;
  FirebaseFunctions get _functions =>
      _injectedFunctions ??
      FirebaseFunctions.instanceFor(region: 'asia-southeast1');
  final DateTime Function() _now;

  static const int plannedSessionsPerClass = 30;

  String get _me => currentUser.memberCode;

  // ── getClasses ─────────────────────────────────────────────────────────────

  Future<ApiResult<List<ClassSectionModel>>> getClasses({
    required String teacherMemberCode,
  }) => guardApi(() async {
    if (teacherMemberCode.isEmpty) {
      throw ApiException('VALIDATION_ERROR', 'Thiếu teacherMemberCode.');
    }
    final tables = await TeacherTables.load(
      _db,
      teacherMemberCode,
      withRecords: false,
    );
    final slots = await loadSlots(_db);
    final schedules = await _db
        .collection('class_schedules')
        .where('teacherMemberCode', isEqualTo: teacherMemberCode)
        .get();
    final today = vnDate(_now());

    final plans = [
      for (final d in schedules.docs)
        if (d.data()['status'] != 'cancelled') docToJson(d)..['id'] = d.id,
    ];
    final todayPlans = plans.where((p) => fmtDate(p['scheduleDate']) == today);
    final classMap = {for (final c in tables.classes) text(c['classCode']): c};

    Json slotOf(String code) => slots.firstWhere(
      (s) => text(s['slotCode']) == code,
      orElse: () => const {},
    );

    Json? activeSessionOf(String classCode) {
      for (final s in tables.sessions) {
        if (text(s['classCode']) == classCode &&
            s['sessionStatus'] == 'open' &&
            fmtDate(s['sessionDate']) == today) {
          return s;
        }
      }
      return null;
    }

    int completedOf(String classCode) => tables.sessions
        .where(
          (s) =>
              text(s['classCode']) == classCode &&
              s['sessionStatus'] == 'closed',
        )
        .length;

    final result = <Json>[];
    for (final cls in tables.classes) {
      final classCode = text(cls['classCode']);
      final classSessions = tables.sessions
          .where((s) => text(s['classCode']) == classCode)
          .length;
      final studentCount = tables.enrollments
          .where((e) => text(e['classCode']) == classCode)
          .map((e) => text(e['rollNumber']))
          .where((r) => r.isNotEmpty)
          .toSet()
          .length;
      final present = await _presentCount(teacherMemberCode, classCode);
      final expected = classSessions * studentCount;
      final subjectName = text(cls['subjectName']);
      final slotCode = text(cls['slotCode']);
      final room = text(cls['room']);
      final slot = slotOf(slotCode);
      final start = text(slot['startTime']);
      final end = text(slot['endTime']);
      final active = activeSessionOf(classCode);

      result.add({
        'classCode': classCode,
        'subjectCode': text(cls['subjectCode']).isNotEmpty
            ? text(cls['subjectCode'])
            : (subjectName.isNotEmpty ? subjectName.split(' ').first : 'UNK'),
        'subjectName': subjectName,
        'room': room,
        'studentCount': studentCount,
        'teacherMemberCode': teacherMemberCode,
        'slotCode': slotCode,
        'startTime': start,
        'endTime': end,
        'period': text(slot['period']),
        'timeLabel': slotCode.isNotEmpty && start.isNotEmpty && end.isNotEmpty
            ? 'Slot $slotCode ($start - $end)'
            : (slotCode.isNotEmpty
                  ? 'Slot $slotCode'
                  : 'Lịch học chưa cập nhật'),
        'completedSessions': completedOf(classCode),
        'totalSessions': plannedSessionsPerClass,
        'averageAttendance': expected > 0 ? present / expected * 100 : 0.0,
        'isActive': active != null,
        'activeSessionId': active?['id'],
        'activeSessionIpCheck': active != null ? ipCheckEnabled(active) : null,
      });
    }

    // Mỗi buổi học bù/ngoài lịch hôm nay có thêm một thẻ riêng trên dashboard.
    for (final plan in todayPlans) {
      final classCode = text(plan['classCode']);
      final cls = classMap[classCode];
      if (cls == null) continue;
      final subjectName = text(cls['subjectName']);
      final slotCode = text(plan['slotCode']);
      final slot = slotOf(slotCode);
      final start = text(slot['startTime']);
      final end = text(slot['endTime']);
      final active = activeSessionOf(classCode);
      result.add({
        'classCode': classCode,
        'subjectCode': text(cls['subjectCode']).isNotEmpty
            ? text(cls['subjectCode'])
            : (subjectName.isNotEmpty ? subjectName.split(' ').first : 'UNK'),
        'subjectName': subjectName,
        'room': text(plan['room']).isNotEmpty
            ? text(plan['room'])
            : text(cls['room']),
        'studentCount': (cls['studentCount'] as num?)?.toInt() ?? 0,
        'teacherMemberCode': teacherMemberCode,
        'slotCode': slotCode,
        'startTime': start,
        'endTime': end,
        'period': '',
        'timeLabel': slotCode.isNotEmpty && start.isNotEmpty && end.isNotEmpty
            ? '[Học bù] Slot $slotCode ($start - $end)'
            : '[Học bù] ${slotCode.isEmpty ? 'Lịch chưa cập nhật' : slotCode}',
        'completedSessions': completedOf(classCode),
        'totalSessions': plannedSessionsPerClass,
        'averageAttendance': 0,
        'isActive': active != null,
        'activeSessionId': active?['id'],
        'activeSessionIpCheck': active != null ? ipCheckEnabled(active) : null,
        'isMakeup': true,
      });
    }
    return result.map(ClassSectionModel.fromJson).toList();
  });

  Future<int> _presentCount(String memberCode, String classCode) async {
    final agg = await _db
        .collection('attendance_records')
        .where('teacherMemberCode', isEqualTo: memberCode)
        .where('classCode', isEqualTo: classCode)
        .where('status', whereIn: presentStatuses)
        .count()
        .get();
    return agg.count ?? 0;
  }

  // ── startSession ────────────────────────────────────────────────────────────

  Future<ApiResult<SessionModel>> startSession({
    required String classCode,
    required String slotCode,
    String teacherIp = '',
    bool ipCheck = false,
  }) => guardApi(
    () => createSession(
      _db,
      memberCode: _me,
      classCode: classCode,
      slotCode: slotCode,
      ipCheck: ipCheck,
      teacherIp: teacherIp,
      now: _now(),
      rejectIfOpen: false,
    ),
  );

  Future<ApiResult<String>> syncSessionTeacherIp({
    required String sessionId,
    required String teacherIp,
  }) => guardApi(() async {
    final ip = teacherIp.trim();
    if (sessionId.isEmpty || ip.isEmpty) {
      throw ApiException('VALIDATION_ERROR', 'Thiếu sessionId hoặc teacherIp.');
    }
    await _openSession(sessionId);
    await _db.collection('sessions').doc(sessionId).update({'teacherIp': ip});
    return ip;
  });

  /// Phiên phải tồn tại, thuộc giảng viên và đang mở.
  Future<Json> _openSession(String sessionId) async {
    final session = await _session(sessionId);
    if (session['sessionStatus'] != 'open') {
      throw ApiException(
        'SESSION_NOT_FOUND',
        'Không tìm thấy phiên điểm danh đang mở.',
      );
    }
    return session;
  }

  Future<ApiResult<SessionModel>> getSession(String sessionId) =>
      guardApi(() async {
        final data = await _session(sessionId);
        return SessionModel(
          sessionId: sessionId,
          classCode: text(data['classCode']),
          sessionDate: fmtDate(data['sessionDate']),
          slotCode: text(data['slotCode']),
          sessionStatus: text(data['sessionStatus']),
          qrToken: text(data['qrSecret']),
          ipCheck: ipCheckEnabled(data),
        );
      });

  Future<Json> _session(String sessionId) async {
    if (sessionId.isEmpty) {
      throw ApiException('VALIDATION_ERROR', 'Thiếu sessionId.');
    }
    final snap = await _db.collection('sessions').doc(sessionId).get();
    if (!snap.exists) {
      throw ApiException('SESSION_NOT_FOUND', 'Không tìm thấy phiên.');
    }
    final data = docToJson(snap)..['id'] = snap.id;
    if (text(data['teacherMemberCode']) != _me) {
      throw ApiException(
        'FORBIDDEN',
        'Bạn không có quyền với phiên điểm danh này.',
      );
    }
    return data;
  }

  // ── closeSession ────────────────────────────────────────────────────────────

  Future<ApiResult<CloseSessionResult>> closeSession({
    required String sessionId,
  }) => guardApi(() async {
    final session = await _session(sessionId);
    final classCode = text(session['classCode']);

    final enrollments = await _db
        .collection('enrollments')
        .where('teacherMemberCode', isEqualTo: _me)
        .where('classCode', isEqualTo: classCode)
        .get();
    final existing = await _db
        .collection('attendance_records')
        .where('teacherMemberCode', isEqualTo: _me)
        .where('sessionId', isEqualTo: sessionId)
        .get();
    final done = {for (final r in existing.docs) text(r.data()['rollNumber'])};

    // Sinh viên chưa có bản ghi trong phiên được ghi Absent (AutoAbsent).
    final absent = <String>{
      for (final e in enrollments.docs)
        if (text(e.data()['rollNumber']).isNotEmpty &&
            !done.contains(text(e.data()['rollNumber'])))
          text(e.data()['rollNumber']),
    };

    final ops = <void Function(WriteBatch)>[
      (b) => b.update(_db.collection('sessions').doc(sessionId), {
        'sessionStatus': 'closed',
      }),
      for (final roll in absent)
        (b) => b.set(
          _db.collection('attendance_records').doc('${sessionId}_$roll'),
          {
            'sessionId': sessionId,
            'rollNumber': roll,
            'classCode': classCode,
            'teacherMemberCode': _me,
            'status': 'Absent',
            'networkVerificationResult': 'AutoAbsent',
            'ipAddress': '',
            'syncedToFap': false,
          },
        ),
    ];
    await commitInBatches(_db, ops);

    return CloseSessionResult(
      sessionId: sessionId,
      sessionStatus: 'closed',
      autoAbsentCount: absent.length,
    );
  });

  // ── rotateQr ────────────────────────────────────────────────────────────────

  Future<ApiResult<String>> rotateQr({required String sessionId}) =>
      guardApi(() async {
        final session = await _session(sessionId);
        if (session['sessionStatus'] != 'open') {
          throw ApiException(
            'SESSION_NOT_FOUND',
            'Phiên đã đóng, không thể làm mới QR.',
          );
        }
        final secret = randomSecret();
        await _db.collection('sessions').doc(sessionId).update({
          'qrSecret': secret,
        });
        return secret;
      });

  // ── getSessions ─────────────────────────────────────────────────────────────

  Future<ApiResult<List<SessionModel>>> getSessions({
    required String classCode,
  }) => guardApi(() async {
    if (classCode.isEmpty) {
      throw ApiException('VALIDATION_ERROR', 'Thiếu classCode.');
    }
    final sessionDocs = await _db
        .collection('sessions')
        .where('teacherMemberCode', isEqualTo: _me)
        .where('classCode', isEqualTo: classCode)
        .get();
    final sessions = <Json>[
      for (final d in sessionDocs.docs)
        {
          'sessionId': d.id,
          'classCode': classCode,
          'sessionDate': fmtDate(d.data()['sessionDate']),
          'slotCode': text(d.data()['slotCode']),
          'sessionStatus': text(d.data()['sessionStatus']),
          'ipCheck': ipCheckEnabled(d.data()),
          'qrToken': text(d.data()['qrSecret']),
        },
    ];

    // Lịch kế hoạch (class_schedules) chưa mở phiên được hiển thị là "planned".
    final taken = {
      for (final s in sessions) '${s['sessionDate']}|${s['slotCode']}',
    };
    final plans = await _db
        .collection('class_schedules')
        .where('teacherMemberCode', isEqualTo: _me)
        .where('classCode', isEqualTo: classCode)
        .get();
    for (final p in plans.docs) {
      final data = p.data();
      if (data['status'] == 'cancelled') continue;
      final date = fmtDate(data['scheduleDate']);
      final slot = text(data['slotCode']);
      if (taken.contains('$date|$slot')) continue;
      sessions.add({
        'sessionId': p.id,
        'classCode': classCode,
        'sessionDate': date,
        'slotCode': slot,
        'sessionStatus': 'planned',
        'qrToken': '',
      });
    }

    sessions.sort((a, b) {
      final byDate = text(a['sessionDate']).compareTo(text(b['sessionDate']));
      return byDate != 0
          ? byDate
          : text(a['slotCode']).compareTo(text(b['slotCode']));
    });
    return sessions.map(SessionModel.fromJson).toList();
  });

  // ── getRoster ──────────────────────────────────────────────────────────────

  Future<ApiResult<List<RosterEntryModel>>> getRoster({
    required String sessionId,
  }) => guardApi(() async {
    final session = await _session(sessionId);
    final classCode = text(session['classCode']);
    final enrollments = await _db
        .collection('enrollments')
        .where('teacherMemberCode', isEqualTo: _me)
        .where('classCode', isEqualTo: classCode)
        .get();
    final records = await _db
        .collection('attendance_records')
        .where('teacherMemberCode', isEqualTo: _me)
        .where('sessionId', isEqualTo: sessionId)
        .get();
    final byRoll = {
      for (final r in records.docs)
        text(r.data()['rollNumber']): docToJson(r)..['recordId'] = r.id,
    };

    final seen = <String>{};
    final roster = <Json>[];
    for (final e in enrollments.docs) {
      final data = e.data();
      final roll = text(data['rollNumber']);
      if (roll.isEmpty || !seen.add(roll)) continue;
      var record = byRoll[roll];
      if (record != null &&
          text(record['networkVerificationResult']).toLowerCase() ==
              'mismatch') {
        // Dữ liệu cũ có thể lưu Present + Mismatch: giữ bằng chứng mạng nhưng không tính là có mặt.
        record = {...record, 'status': '', 'checkinTime': ''};
      }
      roster.add({
        'student': {
          'rollNumber': roll,
          'memberCode': roll,
          'fullName': text(data['fullName']),
          'email': text(data['email']),
        },
        'record': record,
      });
    }
    roster.sort(
      (a, b) =>
          text(a['student']['rollNumber'])
              .compareTo(text(b['student']['rollNumber'])),
    );
    return roster.map(RosterEntryModel.fromJson).toList();
  });

  // ── getAttendanceHistory ────────────────────────────────────────────────────

  Future<ApiResult<AttendanceHistoryResult>> getAttendanceHistory({
    required String classCode,
    String? sessionId,
  }) => guardApi(() async {
    if (classCode.isEmpty) {
      throw ApiException('VALIDATION_ERROR', 'Thiếu classCode.');
    }
    final sessionDocs = await _db
        .collection('sessions')
        .where('teacherMemberCode', isEqualTo: _me)
        .where('classCode', isEqualTo: classCode)
        .get();
    final sessions = [
      for (final d in sessionDocs.docs) docToJson(d)..['sessionId'] = d.id,
    ]..sort(newestFirst);

    if (sessions.isEmpty) {
      return AttendanceHistoryResult.fromJson({
        'sessionId': sessionId ?? '',
        'classCode': classCode,
        'students': const [],
      });
    }
    final current = (sessionId == null || sessionId.isEmpty)
        ? text(sessions.first['sessionId'])
        : sessionId;

    final enrollments = await _db
        .collection('enrollments')
        .where('teacherMemberCode', isEqualTo: _me)
        .where('classCode', isEqualTo: classCode)
        .get();
    final recordDocs = await _db
        .collection('attendance_records')
        .where('teacherMemberCode', isEqualTo: _me)
        .where('classCode', isEqualTo: classCode)
        .get();
    final records = recordDocs.docs.map((d) => d.data()).toList();

    final students = <Json>[];
    final seen = <String>{};
    for (final e in enrollments.docs) {
      final data = e.data();
      final roll = text(data['rollNumber']);
      if (roll.isEmpty || !seen.add(roll)) continue;
      final record = records
          .where(
            (r) =>
                text(r['sessionId']) == current &&
                text(r['rollNumber']) == roll,
          )
          .firstOrNull;
      final absences = records
          .where(
            (r) => text(r['rollNumber']) == roll && r['status'] == 'Absent',
          )
          .length;
      students.add({
        'rollNumber': roll,
        'memberCode': roll,
        'fullName': text(data['fullName']),
        'email': text(data['email']),
        'checkinTime': record == null
            ? ''
            : text(firestoreToJson(record['checkinTime'])),
        'status': record == null ? 'Absent' : text(record['status']),
        'networkVerificationResult': record == null
            ? ''
            : text(record['networkVerificationResult']),
        'absenceCount': absences,
        'totalSessions': sessions.length,
      });
    }
    return AttendanceHistoryResult.fromJson({
      'sessionId': current,
      'classCode': classCode,
      'totalSessions': sessions.length,
      'students': students,
    });
  });

  // ── manualCheckin ──────────────────────────────────────────────────────────

  Future<ApiResult<void>> manualCheckin({
    required String sessionId,
    required String rollNumber,
    String status = 'ManualByGV',
  }) => guardApi(() async {
    if (sessionId.isEmpty || rollNumber.isEmpty || status.isEmpty) {
      throw ApiException('VALIDATION_ERROR', 'Thiếu dữ liệu.');
    }
    final session = await _session(sessionId);
    final batch = _db.batch();
    await _stageManualRecord(
      batch,
      session: session,
      rollNumber: rollNumber,
      status: status,
    );
    await batch.commit();
  });

  // ── manualCheckinBulk ──────────────────────────────────────────────────────

  Future<ApiResult<void>> manualCheckinBulk({
    required String sessionId,
    required List<Map<String, dynamic>> changes,
  }) => guardApi(() async {
    if (sessionId.isEmpty) {
      throw ApiException(
        'VALIDATION_ERROR',
        'Thiếu dữ liệu hoặc changes không hợp lệ.',
      );
    }
    final session = await _session(sessionId);
    for (final group in chunked(changes, 400)) {
      final batch = _db.batch();
      for (final change in group) {
        await _stageManualRecord(
          batch,
          session: session,
          rollNumber: text(change['rollNumber']),
          status: text(change['status']),
          note: change['reason']?.toString(),
        );
      }
      await batch.commit();
    }
  });

  /// Cập nhật bản ghi sẵn có hoặc tạo mới (điểm danh tay), đánh dấu `Manual`.
  Future<void> _stageManualRecord(
    WriteBatch batch, {
    required Json session,
    required String rollNumber,
    required String status,
    String? note,
  }) async {
    final sessionId = text(session['id']);
    final ref = _db
        .collection('attendance_records')
        .doc('${sessionId}_$rollNumber');
    final exists = (await ref.get()).exists;
    final base = <String, dynamic>{
      'status': status,
      'networkVerificationResult': 'Manual',
      'syncedToFap': false,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _me,
      'note': ?note,
    };
    if (exists) {
      batch.update(ref, base);
    } else {
      batch.set(ref, {
        ...base,
        'sessionId': sessionId,
        'rollNumber': rollNumber,
        'classCode': text(session['classCode']),
        'teacherMemberCode': _me,
        'checkinTime': FieldValue.serverTimestamp(),
        'ipAddress': '',
      });
    }
  }

  // ── getStats ───────────────────────────────────────────────────────────────

  Future<ApiResult<List<StatsEntryModel>>> getStats({
    required String classCode,
  }) => guardApi(() async {
    if (classCode.isEmpty) {
      throw ApiException('VALIDATION_ERROR', 'Thiếu classCode.');
    }
    final sessions = await _db
        .collection('sessions')
        .where('teacherMemberCode', isEqualTo: _me)
        .where('classCode', isEqualTo: classCode)
        .get();
    final enrollments = await _db
        .collection('enrollments')
        .where('teacherMemberCode', isEqualTo: _me)
        .where('classCode', isEqualTo: classCode)
        .get();
    final records = await _db
        .collection('attendance_records')
        .where('teacherMemberCode', isEqualTo: _me)
        .where('classCode', isEqualTo: classCode)
        .get();
    final total = sessions.docs.length;
    final presentByRoll = <String, int>{};
    for (final r in records.docs) {
      final data = r.data();
      if (isPresentStatus(data['status'])) {
        presentByRoll.update(
          text(data['rollNumber']),
          (n) => n + 1,
          ifAbsent: () => 1,
        );
      }
    }
    return [
      for (final e in enrollments.docs)
        StatsEntryModel.fromJson({
          'rollNumber': text(e.data()['rollNumber']),
          'attendancePercentage': total > 0
              ? (presentByRoll[text(e.data()['rollNumber'])] ?? 0) / total * 100
              : 0.0,
        }),
    ];
  });

  // ── syncToFap ───────────────────────────────────────────────────────────────

  /// Đồng bộ các bản ghi điểm danh chưa đồng bộ (`syncedToFap != true`) lên FAP.
  Future<ApiResult<SyncResult>> syncToFap({
    String? classCode,
    String? sessionId,
  }) => guardApi(() async {
    // Production uses the trusted callable backend, which owns the actual
    // FAP integration and authorization. An injected Firestore instance is
    // reserved for deterministic repository unit tests below.
    if (_injectedDb == null) {
      final response = await _functions.httpsCallable('syncToFap').call({
        if (classCode != null && classCode.trim().isNotEmpty)
          'classCode': classCode.trim(),
        if (sessionId != null && sessionId.trim().isNotEmpty)
          'sessionId': sessionId.trim(),
      });
      final raw = response.data;
      if (raw is! Map) {
        throw ApiException(
          'INVALID_RESPONSE',
          'Máy chủ trả về dữ liệu đồng bộ không hợp lệ.',
        );
      }
      return SyncResult.fromJson(Map<String, dynamic>.from(raw));
    }
    final memberCode = _me;
    if (memberCode.isEmpty) {
      throw ApiException('UNAUTHORIZED', 'Vui lòng đăng nhập lại.');
    }
    if (classCode != null && classCode.isNotEmpty) {
      final classSnap = await _db.collection('classes').doc(classCode).get();
      final cls = classSnap.data();
      if (cls == null || text(cls['teacherMemberCode']) != memberCode) {
        throw ApiException(
          'FORBIDDEN',
          'Lớp không thuộc giảng viên đang đăng nhập.',
        );
      }
    }
    Query<Map<String, dynamic>> query = _db
        .collection('attendance_records')
        .where('teacherMemberCode', isEqualTo: memberCode);
    if (classCode != null && classCode.isNotEmpty) {
      query = query.where('classCode', isEqualTo: classCode);
    }
    if (sessionId != null && sessionId.isNotEmpty) {
      query = query.where('sessionId', isEqualTo: sessionId);
    }
    final snap = await query.get();
    final unsynced = snap.docs
        .where((d) => d.data()['syncedToFap'] != true)
        .toList();
    if (unsynced.isNotEmpty) {
      final ops = <void Function(WriteBatch)>[
        for (final doc in unsynced)
          (b) => b.update(doc.reference, {
            'syncedToFap': true,
            'updatedAt': FieldValue.serverTimestamp(),
            'updatedBy': memberCode,
          }),
      ];
      await commitInBatches(_db, ops);
    }
    return SyncResult(
      syncedCount: unsynced.length,
      message: unsynced.isEmpty
          ? 'Tất cả bản ghi điểm danh đã được đồng bộ với FAP.'
          : 'Đã đồng bộ ${unsynced.length} bản ghi điểm danh lên hệ thống FAP.',
    );
  });
}
