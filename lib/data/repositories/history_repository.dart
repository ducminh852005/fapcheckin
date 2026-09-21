import '../../core/network/api_service.dart';
import '../../core/network/api_result.dart';
import '../models/history_models.dart';

/// Lỗi có cấu trúc từ Backend — tương ứng hàm `throwError(code, message)`
/// trong file .gs bạn cung cấp. Bọc riêng thành exception có [code] để UI
/// xử lý khác nhau theo từng loại lỗi, thay vì chỉ hiện chung 1 dòng text.
///
/// Các code đã thấy trong `AttendanceHistoryService`: VALIDATION_ERROR,
/// FORBIDDEN, SESSION_NOT_FOUND, CONFLICT, SAVE_FAILED, SESSION_ALREADY_OPEN.
class BackendException implements Exception {
  final String code;
  final String message;
  const BackendException(this.code, this.message);

  @override
  String toString() => '$code: $message';
}

/// Dữ liệu cho tính năng "Lịch sử điểm danh" — xem/sửa lại các buổi đã qua,
/// xem ma trận điểm danh cả lớp, xuất Excel, mở buổi học mới.
///
/// Tách hẳn khỏi `AttendanceRepository` (luồng QR sống) vì đây là 1 nhóm
/// tính năng độc lập, ứng với đúng 1 file Backend riêng
/// (`AttendanceHistoryService`) — không dùng chung vòng đời với
/// `TeacherSessionViewModel`.
abstract class HistoryRepository {
  Future<List<ClassSummaryModel>> fetchClasses();

  Future<ClassHistoryDetailModel> fetchDetail({
    required String classCode,
    String? sessionId,
  });

  Future<ClassHistoryDetailModel> saveChanges({
    required String classCode,
    required String sessionId,
    required List<AttendanceChange> changes,
  });

  Future<AttendanceMatrixModel> fetchMatrix({required String classCode});

  /// Trả về đường link để mở/tải file Excel vừa xuất.
  Future<HistoryExportModel> exportHistory({
    required String classCode,
    String? sessionId,
  });

  Future<void> startSession({
    required String classCode,
    required String slotCode,
    required String teacherIp,
  });
}

class ApiHistoryRepository implements HistoryRepository {
  ApiHistoryRepository({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  Future<T> _call<T>(
    String action, {
    Map<String, dynamic>? payload,
    required T Function(dynamic data) decode,
  }) async {
    final result = await _api.postAction<T>(
      action,
      payload: payload,
      fromJsonT: decode,
    );
    switch (result) {
      case ApiSuccess<T>(:final data):
        return data;
      case ApiFailure<T>(:final error):
        throw BackendException(error.code, error.message);
    }
    throw StateError('Unhandled API result');
  }

  @override
  Future<List<ClassSummaryModel>> fetchClasses() async {
    return _call(
      'getHistoryClasses',
      decode: (data) => (data as List<dynamic>)
          .map(
            (e) =>
                ClassSummaryModel.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
    );
  }

  @override
  Future<ClassHistoryDetailModel> fetchDetail({
    required String classCode,
    String? sessionId,
  }) async {
    return _call(
      'getHistoryDetail',
      payload: {'classCode': classCode, 'sessionId': ?sessionId},
      decode: (data) => ClassHistoryDetailModel.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  @override
  Future<ClassHistoryDetailModel> saveChanges({
    required String classCode,
    required String sessionId,
    required List<AttendanceChange> changes,
  }) async {
    return _call(
      'saveAttendanceChanges',
      payload: {
        'classCode': classCode,
        'sessionId': sessionId,
        'changes': changes.map((c) => c.toJson()).toList(),
      },
      decode: (data) => ClassHistoryDetailModel.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  @override
  Future<AttendanceMatrixModel> fetchMatrix({required String classCode}) async {
    return _call(
      'getAttendanceMatrix',
      payload: {'classCode': classCode},
      decode: (data) => AttendanceMatrixModel.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  @override
  Future<HistoryExportModel> exportHistory({
    required String classCode,
    String? sessionId,
  }) {
    return _call(
      'exportAttendanceHistory',
      payload: {'classCode': classCode, 'sessionId': ?sessionId},
      decode: (data) =>
          HistoryExportModel.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  @override
  Future<void> startSession({
    required String classCode,
    required String slotCode,
    required String teacherIp,
  }) async {
    await _call<Object?>(
      'startHistorySession',
      payload: {
        'classCode': classCode,
        'slotCode': slotCode,
        'teacherIp': teacherIp,
      },
      decode: (data) => data,
    );
  }
}

/// Bản giả lập — dữ liệu mẫu khớp đúng shape DTO thật, để dựng UI ngay khi
/// chưa xác nhận được quy ước gọi API ở trên.
class MockHistoryRepository implements HistoryRepository {
  final _classCode = 'PRN211_SE1708';

  final List<StudentHistoryModel> _students = [
    const StudentHistoryModel(
      rollNumber: 'SE171104',
      fullName: 'Doan Thu Trang',
      email: 'trangdt@fpt.edu.vn',
      status: 'Present',
      checkinTime: '09:47:05',
      networkVerificationResult: 'QR',
      note: '',
      absenceCount: 1,
      totalSessions: 6,
      revision: 'rev-1',
    ),
    const StudentHistoryModel(
      rollNumber: 'SE170450',
      fullName: 'Le Thi Mai',
      email: 'mailt@fpt.edu.vn',
      status: 'Late',
      checkinTime: '10:02:15',
      networkVerificationResult: 'QR',
      note: 'Tắc đường',
      absenceCount: 0,
      totalSessions: 6,
      revision: 'rev-2',
    ),
    const StudentHistoryModel(
      rollNumber: 'SE170982',
      fullName: 'Pham Quoc Bao',
      email: 'baopq@fpt.edu.vn',
      status: 'Absent',
      checkinTime: '',
      networkVerificationResult: '',
      note: '',
      absenceCount: 2,
      totalSessions: 6,
      revision: 'rev-3',
    ),
  ];

  @override
  Future<List<ClassSummaryModel>> fetchClasses() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      ClassSummaryModel(
        classCode: _classCode,
        subjectCode: 'PRN211',
        subjectName: '.NET Programming',
        room: 'BE-304',
        studentCount: _students.length,
        completedSessions: 5,
        totalSessions: 6,
        attendanceRate: 0.82,
        lateRate: 0.06,
        atRiskCount: 1,
        latestSession: const HistorySessionModel(
          sessionId: 'sess-005',
          sessionDate: '2024-10-24',
          slotCode: 'Slot2',
          sessionStatus: 'closed',
        ),
      ),
    ];
  }

  @override
  Future<ClassHistoryDetailModel> fetchDetail({
    required String classCode,
    String? sessionId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final sessions = [
      const HistorySessionModel(
        sessionId: 'sess-004',
        sessionDate: '2024-10-17',
        slotCode: 'Slot2',
        sessionStatus: 'closed',
      ),
      const HistorySessionModel(
        sessionId: 'sess-005',
        sessionDate: '2024-10-24',
        slotCode: 'Slot2',
        sessionStatus: 'closed',
      ),
    ];
    final selected = sessionId != null
        ? sessions.firstWhere(
            (s) => s.sessionId == sessionId,
            orElse: () => sessions.last,
          )
        : sessions.last;

    return ClassHistoryDetailModel(
      classInfo: (await fetchClasses()).first,
      teacherName: 'Dr. Nguyen',
      sessions: sessions,
      selectedSession: selected,
      slots: const [
        SlotModel(slotCode: 'Slot1', startTime: '07:30', endTime: '09:45'),
        SlotModel(slotCode: 'Slot2', startTime: '09:45', endTime: '12:00'),
        SlotModel(slotCode: 'Slot4', startTime: '13:30', endTime: '15:45'),
      ],
      students: _students,
    );
  }

  @override
  Future<ClassHistoryDetailModel> saveChanges({
    required String classCode,
    required String sessionId,
    required List<AttendanceChange> changes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    for (final change in changes) {
      final index = _students.indexWhere(
        (s) => s.rollNumber == change.rollNumber,
      );
      if (index != -1) {
        _students[index] = _students[index].copyWith(
          status: change.status,
          note: change.note,
        );
      }
    }
    return fetchDetail(classCode: classCode, sessionId: sessionId);
  }

  @override
  Future<AttendanceMatrixModel> fetchMatrix({required String classCode}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    const sessions = [
      HistorySessionModel(
        sessionId: 'sess-004',
        sessionDate: '2024-10-17',
        slotCode: 'Slot2',
        sessionStatus: 'closed',
      ),
      HistorySessionModel(
        sessionId: 'sess-005',
        sessionDate: '2024-10-24',
        slotCode: 'Slot2',
        sessionStatus: 'closed',
      ),
    ];
    return AttendanceMatrixModel(
      sessions: sessions,
      students: _students
          .map(
            (s) => MatrixStudentRow(
              rollNumber: s.rollNumber,
              fullName: s.fullName,
              statuses: [s.status, s.status],
            ),
          )
          .toList(),
    );
  }

  @override
  Future<HistoryExportModel> exportHistory({
    required String classCode,
    String? sessionId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const HistoryExportModel(
      filename: 'attendance-history.xlsx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      base64: '',
    );
  }

  @override
  Future<void> startSession({
    required String classCode,
    required String slotCode,
    required String teacherIp,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
