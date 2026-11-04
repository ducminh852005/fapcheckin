import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../firebase/firestore_json.dart';
import '../models/history_class.dart';
import '../models/history_detail.dart';
import '../models/history_summary.dart';
import '../models/session_model.dart';
import '../result/api_result.dart';
import '../result/guard.dart';
import '../session/current_user.dart';
import '../utils/history_excel.dart';
import 'internal/session_ops.dart';
import 'internal/teacher_data.dart';

/// Lịch sử điểm danh của giảng viên: tổng hợp, chi tiết từng buổi, ma trận, chỉnh sửa
/// (có kiểm soát xung đột bằng `revision`) và xuất Excel — tất cả tính phía client từ Firestore.
class AttendanceHistoryRepository {
  AttendanceHistoryRepository({
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

  static const _editableStatuses = [
    'Present',
    'Late',
    'Absent',
    'ManualByGV',
    'Unchecked',
  ];

  String get _me => currentUser.memberCode;

  // ── public API ────────────────────────────────────────────────────────────

  Future<ApiResult<List<HistoryClass>>> getClasses() => guardApi(() async {
    final tables = await TeacherTables.load(_db, _me);
    return [
      for (final cls in tables.classes)
        HistoryClass.fromJson(_classDto(cls, _ClassData.of(cls, tables))),
    ];
  });

  Future<ApiResult<HistorySummary>> getSummary(String classCode) =>
      guardApi(() async {
        final (cls, data) = await _loadOwned(classCode);
        final slots = await _slotDtos();
        return HistorySummary.fromJson({
          'classInfo': _classDto(cls, data),
          'teacherName': currentUser.requireUser.fullName,
          'sessions': data.sessions.map(_sessionDto).toList(),
          'slots': slots,
          'students': [for (final s in data.students) _studentSummary(data, s)],
        });
      });

  Future<ApiResult<HistoryDetail>> getDetail(
    String classCode, {
    String? sessionId,
  }) => guardApi(() => _detail(classCode, sessionId));

  Future<ApiResult<HistoryDetail>> save(
    String classCode,
    String sessionId,
    List<Map<String, dynamic>> changes,
  ) => guardApi(() async {
    if (sessionId.isEmpty || changes.isEmpty || changes.length > 500) {
      throw ApiException(
        'VALIDATION_ERROR',
        'Chọn buổi học và ít nhất một thay đổi (tối đa 500).',
      );
    }
    final (cls, data) = await _loadOwned(classCode);
    final selectedSession = data.sessions
        .where((s) => text(s['sessionId']) == sessionId)
        .firstOrNull;
    if (selectedSession == null) {
      throw ApiException(
        'SESSION_NOT_FOUND',
        'Buổi học không thuộc lớp được chọn.',
      );
    }
    if (!canManuallyAttendOn(selectedSession, _now())) {
      throw ApiException(
        'MANUAL_ATTENDANCE_EXPIRED',
        'Đã quá hạn điểm danh tay cho buổi học này. Hãy vào Cài đặt & Trợ giúp → Yêu cầu điểm danh / nghỉ phép để gửi admin duyệt.',
      );
    }
    final seen = <String>{};
    for (final change in changes) {
      final roll = text(change['rollNumber']);
      if (!data.students.any((s) => s.rollNumber == roll) || !seen.add(roll)) {
        throw ApiException(
          'VALIDATION_ERROR',
          'Sinh viên không thuộc lớp hoặc bị trùng.',
        );
      }
      final note = change['note'];
      if (!_editableStatuses.contains(change['status']) ||
          note is! String ||
          note.length > 2000) {
        throw ApiException(
          'VALIDATION_ERROR',
          'Trạng thái hoặc ghi chú không hợp lệ (tối đa 2000 ký tự).',
        );
      }
    }

    // Transaction: đọc lại từng bản ghi, so `revision`, rồi mới ghi — phát hiện cả thay đổi
    // đến từ SV điểm danh hoặc từ thiết bị khác trong lúc GV đang chỉnh.
    final existingRolls = {
      for (final student in data.students)
        if (data.record(selectedSession, student) != null) student.rollNumber,
    };
    await _db.runTransaction((tx) async {
      final refs = {
        for (final change in changes)
          text(change['rollNumber']): _db
              .collection('attendance_records')
              .doc('${sessionId}_${text(change['rollNumber'])}'),
      };
      final existing = <String, DocumentSnapshot<Json>>{};
      for (final entry in refs.entries) {
        // Chỉ đọc document đã tồn tại. Đọc trực tiếp một document chưa tồn
        // tại bị Firestore Rules từ chối vì không có resource.data để xác
        // thực quyền sở hữu.
        if (existingRolls.contains(entry.key)) {
          existing[entry.key] = await tx.get(entry.value);
        }
      }
      for (final change in changes) {
        final roll = text(change['rollNumber']);
        final snap = existing[roll];
        final current = snap == null ? '' : _revision(snap.id, docToJson(snap));
        if (text(change['revision']) != current) {
          throw ApiException(
            'CONFLICT',
            'Dữ liệu đã thay đổi. Tải lại trước khi chỉnh sửa.',
          );
        }
      }
      for (final change in changes) {
        final roll = text(change['rollNumber']);
        final snap = existing[roll];
        final status = text(change['status']);
        final update = <String, dynamic>{
          'status': status,
          'note': change['note'],
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': _me,
          'syncedToFap': false,
          if (snap == null || text(snap.data()!['status']) != status)
            'networkVerificationResult': 'Manual',
        };
        if (snap != null) {
          tx.update(refs[roll]!, update);
        } else {
          tx.set(refs[roll]!, {
            ...update,
            'sessionId': sessionId,
            'rollNumber': roll,
            'classCode': text(cls['classCode']),
            'teacherMemberCode': _me,
            'checkinTime': FieldValue.serverTimestamp(),
            'ipAddress': '',
          });
        }
      }
    });
    return _detail(classCode, sessionId);
  });

  Future<ApiResult<AttendanceMatrix>> getMatrix(String classCode) =>
      guardApi(() async {
        final (_, data) = await _loadOwned(classCode);
        return AttendanceMatrix.fromJson({
          'sessions': data.sessions.map(_sessionDto).toList(),
          'students': [
            for (final student in data.students)
              {
                'rollNumber': student.rollNumber,
                'fullName': student.fullName,
                'cells': [
                  for (final s in data.sessions)
                    () {
                      final record = data.record(s, student);
                      return {
                        'sessionId': text(s['sessionId']),
                        'status': _statusFor(data, s, student),
                        'checkinTime': text(record?['checkinTime']),
                        'note': text(record?['note']),
                        'revision': record == null
                            ? ''
                            : _revision(text(record['recordId']), record),
                      };
                    }(),
                ],
              },
          ],
        });
      });

  Future<ApiResult<HistoryExport>> export(
    String classCode,
    String? sessionId,
  ) => guardApi(() async {
    if (sessionId != null && sessionId.isNotEmpty) {
      final detail = await _detailJson(classCode, sessionId);
      final info = detail['classInfo'] as Json;
      final selected = detail['selectedSession'] as Json?;
      final rows = <List<Object?>>[
        [
          'Mã lớp',
          'Buổi học',
          'MSSV',
          'Họ và tên',
          'Email',
          'Trạng thái',
          'Thời gian điểm danh',
          'Số buổi vắng',
          'Số buổi đã kết thúc',
          'Ghi chú',
        ],
        for (final s in detail['students'] as List)
          [
            info['classCode'],
            selected == null ? '' : text(selected['sessionDate']),
            s['rollNumber'],
            s['fullName'],
            s['email'],
            s['status'],
            text(s['checkinTime']),
            s['absenceCount'],
            s['totalSessions'],
            s['note'],
          ],
      ];
      return buildHistoryWorkbook(rows, text(info['classCode']));
    }
    final (cls, data) = await _loadOwned(classCode);
    final rows = <List<Object?>>[
      [
        'Mã lớp',
        'MSSV',
        'Họ và tên',
        'Email',
        'Số buổi có mặt',
        'Số buổi đi trễ',
        'Số buổi vắng',
        'Số buổi đã kết thúc',
        'Tổng số buổi',
        'Tỷ lệ có mặt (%)',
        'Tỷ lệ vắng (%)',
      ],
      for (final s in data.students)
        () {
          final x = _studentSummary(data, s);
          final closed = x['closedSessions'] as int;
          double pct(num n) =>
              closed == 0 ? 0 : (n / closed * 1000).round() / 10;
          return [
            text(cls['classCode']),
            s.rollNumber,
            s.fullName,
            s.email,
            x['presentCount'],
            x['lateCount'],
            x['absentCount'],
            closed,
            x['totalSessions'],
            pct((x['presentCount'] as int) + (x['lateCount'] as int)),
            pct(x['absentCount'] as int),
          ];
        }(),
    ];
    return buildHistoryWorkbook(rows, text(cls['classCode']));
  });

  Future<ApiResult<SessionModel>> startSession(
    String classCode,
    String slotCode,
    String teacherIp, {
    bool ipCheck = false,
  }) => guardApi(() async {
    await _loadOwned(classCode, withRecords: false);
    final slots = await loadSlots(_db);
    if (!slots.any((s) => text(s['slotCode']) == slotCode)) {
      throw ApiException('VALIDATION_ERROR', 'Chọn ca học hợp lệ.');
    }
    if (ipCheck && teacherIp.trim().isEmpty) {
      throw ApiException(
        'VALIDATION_ERROR',
        'Nhập IP mạng giảng viên để bật kiểm tra IP.',
      );
    }
    return createSession(
      _db,
      memberCode: _me,
      classCode: classCode,
      slotCode: slotCode,
      ipCheck: ipCheck,
      teacherIp: teacherIp,
      now: _now(),
      rejectIfOpen: true,
    );
  });

  // ── loading ───────────────────────────────────────────────────────────────

  Future<(Json, _ClassData)> _loadOwned(
    String classCode, {
    bool withRecords = true,
  }) async {
    if (classCode.isEmpty) {
      throw ApiException('VALIDATION_ERROR', 'Thiếu classCode.');
    }
    final snap = await _db.collection('classes').doc(classCode).get();
    final cls = snap.data();
    if (cls == null || text(cls['teacherMemberCode']) != _me) {
      throw ApiException(
        'FORBIDDEN',
        'Lớp không thuộc giảng viên đang đăng nhập.',
      );
    }
    final base = <String, dynamic>{
      ...Map<String, dynamic>.from(firestoreToJson(cls)! as Map),
      'classCode': classCode,
    };
    Query<Json> mine(String c) => _db
        .collection(c)
        .where('teacherMemberCode', isEqualTo: _me)
        .where('classCode', isEqualTo: classCode);
    Future<List<Json>> rows(Query<Json> q, [String? idField]) async =>
        (await q.get()).docs.map((d) => rowOf(d, idField)).toList();
    final sessions = await rows(mine('sessions'), 'sessionId');
    final enrollments = await rows(mine('enrollments'));
    final records = withRecords
        ? await rows(mine('attendance_records'), 'recordId')
        : <Json>[];
    final tables = TeacherTables(
      classes: [base],
      sessions: sessions,
      enrollments: enrollments,
      records: records,
    );
    return (base, _ClassData.of(base, tables));
  }

  Future<List<Json>> _slotDtos() async => [
    for (final s in await loadSlots(_db))
      {
        'slotCode': text(s['slotCode']),
        'startTime': s['startTime'],
        'endTime': s['endTime'],
      },
  ];

  Future<HistoryDetail> _detail(String classCode, String? sessionId) async =>
      HistoryDetail.fromJson(await _detailJson(classCode, sessionId));

  Future<Json> _detailJson(String classCode, String? sessionId) async {
    final (cls, data) = await _loadOwned(classCode);
    Json? selected;
    if (sessionId != null && sessionId.isNotEmpty) {
      selected = data.sessions
          .where((s) => text(s['sessionId']) == sessionId)
          .firstOrNull;
      if (selected == null) {
        throw ApiException(
          'SESSION_NOT_FOUND',
          'Buổi học không thuộc lớp được chọn.',
        );
      }
    } else {
      selected = data.sessions.firstOrNull;
    }
    final closed = data.sessions
        .where((s) => s['sessionStatus'] == 'closed')
        .toList();
    return {
      'classInfo': _classDto(cls, data),
      'teacherName': currentUser.requireUser.fullName,
      'sessions': data.sessions.map(_sessionDto).toList(),
      'selectedSession': selected == null ? null : _sessionDto(selected),
      'slots': await _slotDtos(),
      'students': [
        for (final student in data.students)
          () {
            final record = selected == null
                ? null
                : data.record(selected, student);
            final absences = closed
                .where((s) => _statusFor(data, s, student) == 'Absent')
                .length;
            return {
              'rollNumber': student.rollNumber,
              'fullName': student.fullName,
              'email': student.email,
              'status': _statusFor(data, selected, student),
              'checkinTime': text(record?['checkinTime']),
              'networkVerificationResult': text(
                record?['networkVerificationResult'],
              ),
              'note': text(record?['note']),
              'absenceCount': absences,
              'totalSessions': closed.length,
              'revision': record == null
                  ? ''
                  : _revision(text(record['recordId']), record),
            };
          }(),
      ],
    };
  }

  // ── pure helpers (port của AttendanceHistoryService.gs) ───────────────────

  static String _revision(String recordId, Json record) => jsonEncode([
    recordId,
    record['status'],
    text(record['note']),
    text(record['updatedAt']),
    text(record['checkinTime']),
  ]);

  static Json _sessionDto(Json s) => {
    'sessionId': text(s['sessionId']),
    'sessionDate': fmtDate(s['sessionDate']),
    'slotCode': text(s['slotCode']),
    'sessionStatus': text(s['sessionStatus']),
  };

  static String _statusFor(_ClassData data, Json? session, _Student student) {
    if (session == null) return 'Unchecked';
    final record = data.record(session, student);
    if (record != null && text(record['status']).isNotEmpty) {
      return text(record['status']);
    }
    return session['sessionStatus'] == 'closed' ? 'Absent' : 'Unchecked';
  }

  static Json _summary(_ClassData data) {
    final closed = data.sessions
        .where((s) => s['sessionStatus'] == 'closed')
        .toList();
    var present = 0, late = 0, atRisk = 0;
    for (final student in data.students) {
      var absences = 0;
      for (final session in closed) {
        final status = _statusFor(data, session, student);
        if (isPresentStatus(status)) present++;
        if (status == 'Late') late++;
        if (status == 'Absent') absences++;
      }
      if (closed.isNotEmpty && absences / closed.length > 0.2) atRisk++;
    }
    final expected = closed.length * data.students.length;
    return {
      'studentCount': data.students.length,
      'completedSessions': closed.length,
      'totalSessions': data.sessions.length,
      'attendanceRate': expected > 0 ? present / expected : 0.0,
      'lateRate': expected > 0 ? late / expected : 0.0,
      'atRiskCount': atRisk,
    };
  }

  static Json _classDto(Json cls, _ClassData data) {
    final classCode = text(cls['classCode']);
    return {
      ..._summary(data),
      'classCode': classCode,
      'subjectCode': text(cls['subjectCode']).isNotEmpty
          ? text(cls['subjectCode'])
          : classCode.split('_').first,
      'subjectName': text(cls['subjectName']),
      'room': text(cls['room']),
      'slotCode': text(cls['slotCode']),
      'latestSession': data.sessions.isEmpty
          ? null
          : _sessionDto(data.sessions.first),
    };
  }

  static Json _studentSummary(_ClassData data, _Student student) {
    final closed = data.sessions
        .where((s) => s['sessionStatus'] == 'closed')
        .toList();
    var present = 0, late = 0, absent = 0;
    for (final session in closed) {
      final status = _statusFor(data, session, student);
      if (status == 'Late') {
        late++;
      } else if (status == 'Absent') {
        absent++;
      } else if (isPresentStatus(status)) {
        present++;
      }
    }
    return {
      'rollNumber': student.rollNumber,
      'fullName': student.fullName,
      'email': student.email,
      'presentCount': present,
      'lateCount': late,
      'absentCount': absent,
      'closedSessions': closed.length,
      'totalSessions': data.sessions.length,
    };
  }
}

class _Student {
  _Student(this.rollNumber, this.fullName, this.email);
  final String rollNumber, fullName, email;
}

/// Dữ liệu một lớp: phiên (mới nhất trước), sinh viên (theo ghi danh) và bản ghi theo `sessionId|rollNumber`.
class _ClassData {
  _ClassData(this.sessions, this.students, this._records);

  final List<Json> sessions;
  final List<_Student> students;
  final Map<String, Json> _records;

  Json? record(Json session, _Student student) =>
      _records['${text(session['sessionId'])}|${student.rollNumber}'];

  factory _ClassData.of(Json cls, TeacherTables t) {
    final classCode = text(cls['classCode']);
    final sessions =
        t.sessions.where((s) => text(s['classCode']) == classCode).toList()
          ..sort(newestFirst);
    final seen = <String>{};
    final students = <_Student>[];
    for (final e in t.enrollments) {
      final roll = text(e['rollNumber']);
      if (text(e['classCode']) != classCode ||
          roll.isEmpty ||
          !seen.add(roll)) {
        continue;
      }
      students.add(_Student(roll, text(e['fullName']), text(e['email'])));
    }
    students.sort((a, b) => a.rollNumber.compareTo(b.rollNumber));
    final ids = sessions.map((s) => text(s['sessionId'])).toSet();
    final records = <String, Json>{};
    for (final r in t.records) {
      if (ids.contains(text(r['sessionId'])) &&
          seen.contains(text(r['rollNumber']))) {
        records['${text(r['sessionId'])}|${text(r['rollNumber'])}'] = r;
      }
    }
    return _ClassData(sessions, students, records);
  }
}
