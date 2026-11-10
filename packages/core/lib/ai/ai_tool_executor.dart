import '../firebase/firestore_json.dart' show vnDate;
import '../models/history_detail.dart';
import '../models/history_summary.dart';
import '../models/session_model.dart';
import '../repositories/ai_assistant_repository.dart';
import '../repositories/attendance_history_repository.dart';
import '../repositories/report_repository.dart';
import '../repositories/teacher_repository.dart';
import '../result/api_result.dart';
import '../session/current_user.dart';

/// Trạng thái app/Security Rules chấp nhận cho điểm danh tay.
const aiAttendanceStatuses = [
  'Present',
  'Late',
  'Absent',
  'ManualByGV',
  'Unchecked',
];

const aiStatusLabels = {
  'Present': 'Có mặt',
  'Late': 'Đi muộn',
  'Absent': 'Vắng',
  'ManualByGV': 'Có mặt (GV điểm danh)',
  'Unchecked': 'Chưa điểm danh',
  '': 'Chưa điểm danh',
};

/// Một sinh viên trong thẻ xác nhận. Họ tên/lớp/trạng thái cũ lấy từ dữ liệu thật, không từ lời model.
class AiPendingStudent {
  const AiPendingStudent({
    required this.rollNumber,
    required this.fullName,
    required this.status,
    required this.previousStatus,
  });

  final String rollNumber;
  final String fullName;
  final String status;
  final String previousStatus;
}

/// Thao tác ghi đã được kiểm tra hợp lệ, chờ giảng viên bấm Xác nhận.
class AiPendingAction {
  const AiPendingAction({
    required this.toolName,
    required this.classCode,
    required this.subjectName,
    required this.sessionId,
    required this.sessionDate,
    required this.slotCode,
    required this.students,
    this.note = '',
  });

  final String toolName;
  final String classCode;
  final String subjectName;
  final String sessionId;
  final String sessionDate;
  final String slotCode;
  final List<AiPendingStudent> students;
  final String note;
}

/// Kết quả chạy một tool: [result] gửi lại cho model, hoặc [pending] nếu cần GV xác nhận.
class AiToolOutcome {
  const AiToolOutcome.result(Map<String, dynamic> this.result) : pending = null;
  const AiToolOutcome.pending(AiPendingAction this.pending) : result = null;

  final Map<String, dynamic>? result;
  final AiPendingAction? pending;
}

/// Thực thi tool do model đề xuất bằng repository sẵn có, dưới quyền của chính giảng viên
/// (Security Rules vẫn áp dụng). Không bao giờ ném lỗi: lỗi trả về dạng `{error, code}` để model giải thích.
class AiToolExecutor {
  AiToolExecutor({
    required this.teacher,
    required this.history,
    required this.report,
    required this.currentUser,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final TeacherRepository teacher;
  final AttendanceHistoryRepository history;
  final ReportRepository report;
  final CurrentUser currentUser;
  final DateTime Function() _now;

  static const maxStudentsPerAction = 100;
  static const _maxClassesForSearch = 15;
  static const _maxRows = 60;

  Future<AiToolOutcome> run(AiToolCall call) async {
    try {
      switch (call.name) {
        case 'list_my_classes':
          return AiToolOutcome.result(await _listMyClasses());
        case 'find_student':
          return AiToolOutcome.result(await _findStudent(call.args));
        case 'get_session_attendance':
          return AiToolOutcome.result(await _sessionAttendance(call.args));
        case 'get_attendance_stats':
          return AiToolOutcome.result(await _stats(call.args));
        case 'get_attendance_report':
          return AiToolOutcome.result(await _report(call.args));
        case 'mark_attendance':
          return await _prepareMark(call.args);
        default:
          return AiToolOutcome.result(_error('UNKNOWN_TOOL', 'Tool không được hỗ trợ.'));
      }
    } catch (e) {
      return AiToolOutcome.result(_error('UNKNOWN_ERROR', e.toString()));
    }
  }

  /// Ghi điểm danh sau khi GV xác nhận.
  Future<Map<String, dynamic>> confirm(AiPendingAction action) async {
    try {
      final result = await teacher.manualCheckinBulk(
        sessionId: action.sessionId,
        changes: [
          for (final s in action.students)
            {
              'rollNumber': s.rollNumber,
              'status': s.status,
              if (action.note.isNotEmpty) 'reason': action.note,
            },
        ],
      );
      return switch (result) {
        ApiSuccess<void>() => {
          'ok': true,
          'marked': action.students.length,
          'classCode': action.classCode,
          'sessionDate': action.sessionDate,
          'slotCode': action.slotCode,
          'students': [
            for (final s in action.students)
              {'rollNumber': s.rollNumber, 'fullName': s.fullName, 'status': s.status},
          ],
        },
        ApiFailure<void>(:final error) => _error(error.code, error.message),
        _ => _error('UNKNOWN_ERROR', 'Không ghi được điểm danh.'),
      };
    } catch (e) {
      return _error('UNKNOWN_ERROR', e.toString());
    }
  }

  /// Kết quả gửi cho model khi GV bấm Huỷ.
  Map<String, dynamic> cancelled() => {
    'ok': false,
    'cancelled': true,
    'message': 'Giảng viên đã huỷ, chưa ghi gì cả.',
  };

  // ── tools đọc ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _listMyClasses() async {
    final result = await teacher.getClasses(
      teacherMemberCode: currentUser.memberCode,
    );
    switch (result) {
      case ApiSuccess(:final data):
        return {
          'today': vnDate(_now()),
          'classes': [
            for (final c in data)
              {
                'classCode': c.classCode,
                'subject': c.subjectName,
                'slotCode': c.slotCode,
                'time': c.timeLabel,
                'room': c.room,
                'studentCount': c.studentCount,
                'hasOpenSession': c.isActive,
                'isMakeup': c.isMakeup,
              },
          ],
        };
      case ApiFailure(:final error):
        return _error(error.code, error.message);
      default:
        return _error('UNKNOWN_ERROR', 'Không tải được danh sách lớp.');
    }
  }

  Future<Map<String, dynamic>> _findStudent(Map<String, dynamic> args) async {
    final query = _str(args['query']);
    if (query.isEmpty) return _error('VALIDATION_ERROR', 'Thiếu MSSV hoặc tên sinh viên.');
    var classCodes = <String>[];
    final only = _str(args['classCode']);
    if (only.isNotEmpty) {
      classCodes = [only];
    } else {
      final classes = await history.getClasses();
      switch (classes) {
        case ApiSuccess(:final data):
          classCodes = [for (final c in data) c.classCode];
        case ApiFailure(:final error):
          return _error(error.code, error.message);
        default:
          break;
      }
    }
    final needle = _fold(query);
    final tokens = needle.split(' ').where((t) => t.isNotEmpty).toList();
    final matches = <Map<String, dynamic>>[];
    for (final code in classCodes.take(_maxClassesForSearch)) {
      final summary = await history.getSummary(code);
      if (summary is ApiFailure<HistorySummary>) {
        if (only.isNotEmpty) return _error(summary.error.code, summary.error.message);
        continue;
      }
      for (final s in (summary as ApiSuccess<HistorySummary>).data.students) {
        final roll = s.rollNumber.toLowerCase();
        final name = _fold(s.fullName);
        final exact = roll == query.toLowerCase();
        final hit = exact ||
            roll.contains(needle) ||
            (tokens.isNotEmpty && tokens.every(name.contains));
        if (hit) {
          matches.add({
            'rollNumber': s.rollNumber,
            'fullName': s.fullName,
            'classCode': code,
            'exactRollMatch': exact,
          });
        }
      }
    }
    matches.sort((a, b) => (b['exactRollMatch'] == true ? 1 : 0).compareTo(a['exactRollMatch'] == true ? 1 : 0));
    return {
      'query': query,
      'count': matches.length,
      'students': matches.take(10).toList(),
      if (matches.length > 10) 'truncated': true,
    };
  }

  Future<Map<String, dynamic>> _sessionAttendance(Map<String, dynamic> args) async {
    final classCode = _str(args['classCode']);
    if (classCode.isEmpty) return _error('VALIDATION_ERROR', 'Thiếu mã lớp.');
    final summary = await history.getSummary(classCode);
    if (summary is ApiFailure<HistorySummary>) return _error(summary.error.code, summary.error.message);
    final sessions = (summary as ApiSuccess<HistorySummary>).data.sessions;
    final date = _str(args['date']);
    final slot = _str(args['slotCode']);
    final today = vnDate(_now());
    Iterable<SessionModel> pool = sessions;
    if (slot.isNotEmpty) pool = pool.where((s) => s.slotCode.toLowerCase() == slot.toLowerCase());
    SessionModel? picked;
    if (date.isNotEmpty) {
      picked = pool.where((s) => s.sessionDate == date).firstOrNull;
    } else {
      picked = pool.where((s) => s.sessionDate == today).firstOrNull ??
          (pool.toList()..sort((a, b) => b.sessionDate.compareTo(a.sessionDate))).firstOrNull;
    }
    if (picked == null) {
      return _error('NO_SESSION', 'Không tìm thấy buổi học phù hợp của lớp $classCode.');
    }
    final detail = await history.getDetail(classCode, sessionId: picked.sessionId);
    if (detail is ApiFailure<HistoryDetail>) return _error(detail.error.code, detail.error.message);
    final students = (detail as ApiSuccess<HistoryDetail>).data.students;
    final counts = <String, int>{};
    for (final s in students) {
      counts[s.status] = (counts[s.status] ?? 0) + 1;
    }
    return {
      'classCode': classCode,
      'session': {
        'sessionId': picked.sessionId,
        'date': picked.sessionDate,
        'slotCode': picked.slotCode,
        'status': picked.sessionStatus,
      },
      'total': students.length,
      'countsByStatus': counts,
      'students': [
        for (final s in students.take(_maxRows))
          {'rollNumber': s.rollNumber, 'fullName': s.fullName, 'status': s.status},
      ],
      if (students.length > _maxRows) 'truncated': true,
    };
  }

  Future<Map<String, dynamic>> _stats(Map<String, dynamic> args) async {
    final classCode = _str(args['classCode']);
    if (classCode.isEmpty) return _error('VALIDATION_ERROR', 'Thiếu mã lớp.');
    final summary = await history.getSummary(classCode);
    if (summary is ApiFailure<HistorySummary>) return _error(summary.error.code, summary.error.message);
    final data = (summary as ApiSuccess<HistorySummary>).data;
    final rows = [...data.students]..sort((a, b) => a.attendanceRate.compareTo(b.attendanceRate));
    double pct(double v) => double.parse((v * 100).toStringAsFixed(1));
    return {
      'classCode': classCode,
      'subject': data.classInfo.subjectName,
      'closedSessions': data.classInfo.completedSessions,
      'classAttendancePercent': pct(data.classInfo.attendanceRate),
      'studentCount': rows.length,
      'students': [
        for (final s in rows.take(_maxRows))
          {
            'rollNumber': s.rollNumber,
            'fullName': s.fullName,
            'attendancePercent': pct(s.attendanceRate),
            'present': s.presentCount,
            'late': s.lateCount,
            'absent': s.absentCount,
            'closedSessions': s.closedSessions,
          },
      ],
      if (rows.length > _maxRows) 'truncated': true,
      'note': 'Sắp xếp từ chuyên cần thấp đến cao.',
    };
  }

  Future<Map<String, dynamic>> _report(Map<String, dynamic> args) async {
    final from = DateTime.tryParse(_str(args['from']));
    final to = DateTime.tryParse(_str(args['to']));
    if ((from == null) != (to == null)) {
      return _error('VALIDATION_ERROR', 'Cần cả ngày bắt đầu và kết thúc (yyyy-MM-dd), hoặc bỏ trống cả hai.');
    }
    final result = from == null
        ? await report.getReport()
        : await report.getReportForRange(from, to!);
    switch (result) {
      case ApiSuccess(:final data):
        double pct(double v) => double.parse((v * 100).toStringAsFixed(1));
        return {
          'range': from == null
              ? 'Toàn bộ lịch sử'
              : '${_str(args['from'])} → ${_str(args['to'])}',
          'classCount': data.classCount,
          'closedSessionCount': data.closedSessionCount,
          'kpis': {
            'attendancePercent': pct(data.kpis.attendanceRate),
            'latePercent': pct(data.kpis.lateRate),
            'totalCheckins': data.kpis.totalCheckins,
            'absentCount': data.kpis.absentCount,
            'studentCount': data.kpis.studentCount,
            'atRiskStudents': data.kpis.atRiskCount,
          },
          'subjects': [
            for (final s in data.subjects)
              {
                'classCode': s.classCode,
                'subject': s.subjectName,
                'attendancePercent': pct(s.attendanceRate),
                'present': s.presentCount,
                'expected': s.expectedCount,
                'studentCount': s.studentCount,
              },
          ],
          'weekly': [
            for (final w in data.weekly)
              {'week': w.label, 'presentPercent': pct(w.presentRate), 'absentPercent': pct(w.absentRate)},
          ],
          'atRisk': [
            for (final w in data.warnings.take(20))
              {
                'rollNumber': w.rollNumber,
                'fullName': w.fullName,
                'classCode': w.classCode,
                'absent': w.absent,
                'total': w.total,
                'absencePercent': pct(w.absenceRate),
                'level': w.status,
              },
          ],
        };
      case ApiFailure(:final error):
        return _error(error.code, error.message);
      default:
        return _error('UNKNOWN_ERROR', 'Không tạo được báo cáo.');
    }
  }

  // ── tool ghi: kiểm tra rồi chờ xác nhận ────────────────────────────────────

  Future<AiToolOutcome> _prepareMark(Map<String, dynamic> args) async {
    AiToolOutcome fail(String code, String message, [Map<String, dynamic>? extra]) =>
        AiToolOutcome.result({..._error(code, message), ...?extra});

    final classCode = _str(args['classCode']);
    final slot = _str(args['slotCode']);
    final note = _str(args['note']);
    final rawStudents = args['students'];
    if (classCode.isEmpty) return fail('VALIDATION_ERROR', 'Thiếu mã lớp.');
    if (rawStudents is! List || rawStudents.isEmpty) {
      return fail('VALIDATION_ERROR', 'Thiếu danh sách sinh viên cần điểm danh.');
    }
    if (rawStudents.length > maxStudentsPerAction) {
      return fail('VALIDATION_ERROR', 'Mỗi lần chỉ điểm danh tối đa $maxStudentsPerAction sinh viên.');
    }
    final wanted = <String, String>{}; // rollNumber (in hoa) -> status
    for (final item in rawStudents) {
      if (item is! Map) return fail('VALIDATION_ERROR', 'Danh sách sinh viên không hợp lệ.');
      final roll = _str(item['rollNumber']).toUpperCase();
      final status = _str(item['status']);
      if (roll.isEmpty) return fail('VALIDATION_ERROR', 'Có sinh viên thiếu MSSV.');
      if (!aiAttendanceStatuses.contains(status)) {
        return fail('VALIDATION_ERROR', 'Trạng thái "$status" không hợp lệ.');
      }
      wanted[roll] = status;
    }

    final summaryResult = await history.getSummary(classCode);
    if (summaryResult is ApiFailure<HistorySummary>) {
      return fail(summaryResult.error.code, summaryResult.error.message);
    }
    final summary = (summaryResult as ApiSuccess<HistorySummary>).data;

    // Phiên của hôm nay (điểm danh tay chỉ cho phép trong ngày diễn ra phiên).
    final today = vnDate(_now());
    var todays = [
      for (final s in summary.sessions)
        if (s.sessionDate == today &&
            (slot.isEmpty || s.slotCode.toLowerCase() == slot.toLowerCase()))
          s,
    ];
    if (todays.isEmpty) {
      return fail(
        'NO_SESSION_TODAY',
        'Hôm nay lớp $classCode ${slot.isEmpty ? '' : '(slot $slot) '}chưa có phiên điểm danh. '
            'Hãy mở phiên ở mục Quản lý lớp trước.',
      );
    }
    if (todays.length > 1) {
      final open = todays.where((s) => s.isOpen).toList();
      if (open.length == 1) {
        todays = open;
      } else {
        return fail(
          'AMBIGUOUS_SESSION',
          'Lớp $classCode có nhiều buổi hôm nay, cần chỉ rõ slot.',
          {'slots': [for (final s in todays) s.slotCode]},
        );
      }
    }
    final session = todays.single;

    final known = {for (final s in summary.students) s.rollNumber.toUpperCase(): s};
    final unknown = [for (final r in wanted.keys) if (!known.containsKey(r)) r];
    if (unknown.isNotEmpty) {
      return fail(
        'STUDENT_NOT_ENROLLED',
        'MSSV ${unknown.join(', ')} không thuộc lớp $classCode.',
        {'unknown': unknown},
      );
    }

    // Trạng thái hiện tại để hiện "trước → sau" trong thẻ xác nhận.
    final previous = <String, String>{};
    final detail = await history.getDetail(classCode, sessionId: session.sessionId);
    if (detail is ApiSuccess<HistoryDetail>) {
      for (final s in detail.data.students) {
        previous[s.rollNumber.toUpperCase()] = s.status;
      }
    }

    return AiToolOutcome.pending(
      AiPendingAction(
        toolName: 'mark_attendance',
        classCode: classCode,
        subjectName: summary.classInfo.subjectName,
        sessionId: session.sessionId,
        sessionDate: session.sessionDate,
        slotCode: session.slotCode,
        note: note,
        students: [
          for (final e in wanted.entries)
            AiPendingStudent(
              rollNumber: known[e.key]!.rollNumber,
              fullName: known[e.key]!.fullName,
              status: e.value,
              previousStatus: previous[e.key] ?? 'Unchecked',
            ),
        ],
      ),
    );
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  static Map<String, dynamic> _error(String code, String message) => {
    'error': message,
    'code': code,
  };

  static String _str(Object? v) => v?.toString().trim() ?? '';

  static const _foldGroups = {
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
  };
  static final Map<String, String> _foldMap = {
    for (final e in _foldGroups.entries)
      for (final ch in e.value.split('')) ch: e.key,
  };

  /// Chữ thường, bỏ dấu tiếng Việt, gộp khoảng trắng — để so tên sinh viên theo lời nói.
  static String _fold(String input) {
    final buffer = StringBuffer();
    for (final ch in input.toLowerCase().split('')) {
      buffer.write(_foldMap[ch] ?? ch);
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
