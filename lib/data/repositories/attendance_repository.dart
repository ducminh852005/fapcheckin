import 'dart:math';

import 'package:dio/dio.dart';

import '../../core/services/api_service.dart';
import '../models/attendance_model.dart';
import '../models/session_model.dart';

/// 1 điểm dữ liệu cho biểu đồ thống kê chuyên cần: % SV có mặt trong 1 buổi.
class ClassAttendanceStat {
  final String sessionLabel; // Ví dụ: "01/09"
  final double presentPercent; // 0..100

  const ClassAttendanceStat({required this.sessionLabel, required this.presentPercent});
}

/// Toàn bộ dữ liệu điểm danh của app GV phải đi qua interface này.
///
/// Đây chính là ranh giới MVVM quan trọng nhất trong tài liệu kiến trúc:
/// [TeacherSessionViewModel] chỉ biết tới các method dưới đây — nó KHÔNG
/// biết dữ liệu thật sự nằm ở Google Sheet, gọi qua Apps Script, hay thậm
/// chí đang chạy giả lập (Mock). Nhờ vậy bạn có thể code xong toàn bộ UI +
/// ViewModel bằng [MockAttendanceRepository], rồi khi Backend xong chỉ cần
/// đổi sang [ApiAttendanceRepository] — không phải sửa 1 dòng nào ở
/// ViewModel hay các màn hình.
abstract class AttendanceRepository {
  Future<SessionModel> startSession({required String classId, required String teacherIp});

  Future<String> refreshQrToken({required String sessionId});

  Future<List<AttendanceModel>> fetchRoster({required String sessionId});

  Future<void> manualCheckIn({
    required String sessionId,
    required String studentId,
    required String studentName,
  });

  Future<void> closeSession({required String sessionId});

  Future<List<ClassAttendanceStat>> fetchAttendanceStats({required String classId});
}

/// Bản triển khai thật, gọi qua Apps Script Web App.
///
/// LƯU Ý: tài liệu kiến trúc (mục 08) mới thống nhất tên 3 endpoint
/// /session/start, /session/token, /checkin. Các endpoint còn lại
/// (roster, checkin/manual, session/close, stats) là do mình tạm đặt tên
/// hợp lý theo đúng REST convention — cần chốt lại với Thành viên 1 (Backend)
/// trước khi bật cờ dùng repository này thay cho Mock.
class ApiAttendanceRepository implements AttendanceRepository {
  ApiAttendanceRepository({Dio? dio}) : _dio = dio ?? ApiService.instance.client;

  final Dio _dio;

  @override
  Future<SessionModel> startSession({required String classId, required String teacherIp}) async {
    try {
      final response = await _dio.post('/session/start', data: {
        'classId': classId,
        'teacherIp': teacherIp,
      });
      return SessionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Mở phiên thất bại: ${e.message}');
    }
  }

  @override
  Future<String> refreshQrToken({required String sessionId}) async {
    try {
      final response = await _dio.get('/session/token', queryParameters: {
        'sessionId': sessionId,
      });
      return (response.data as Map<String, dynamic>)['qrToken'] as String;
    } on DioException catch (e) {
      throw Exception('Xoay QR thất bại: ${e.message}');
    }
  }

  @override
  Future<List<AttendanceModel>> fetchRoster({required String sessionId}) async {
    try {
      // TODO(Backend): thống nhất endpoint roster, ví dụ GET /session/roster.
      final response = await _dio.get('/session/roster', queryParameters: {
        'sessionId': sessionId,
      });
      final list = response.data as List<dynamic>;
      return list
          .map((e) => AttendanceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception('Tải danh sách điểm danh thất bại: ${e.message}');
    }
  }

  @override
  Future<void> manualCheckIn({
    required String sessionId,
    required String studentId,
    required String studentName,
  }) async {
    try {
      // TODO(Backend): thống nhất endpoint điểm danh tay, ví dụ POST /checkin/manual.
      await _dio.post('/checkin/manual', data: {
        'sessionId': sessionId,
        'studentId': studentId,
        'studentName': studentName,
      });
    } on DioException catch (e) {
      throw Exception('Điểm danh tay thất bại: ${e.message}');
    }
  }

  @override
  Future<void> closeSession({required String sessionId}) async {
    try {
      // TODO(Backend): thống nhất endpoint đóng phiên, ví dụ POST /session/close.
      await _dio.post('/session/close', data: {'sessionId': sessionId});
    } on DioException catch (e) {
      throw Exception('Đóng phiên thất bại: ${e.message}');
    }
  }

  @override
  Future<List<ClassAttendanceStat>> fetchAttendanceStats({required String classId}) async {
    try {
      // TODO(Backend): thống nhất endpoint thống kê, ví dụ GET /class/stats.
      final response = await _dio.get('/class/stats', queryParameters: {
        'classId': classId,
      });
      final list = response.data as List<dynamic>;
      return list
          .map((e) => ClassAttendanceStat(
                sessionLabel: e['sessionLabel'] as String,
                presentPercent: (e['presentPercent'] as num).toDouble(),
              ))
          .toList();
    } on DioException catch (e) {
      throw Exception('Tải thống kê thất bại: ${e.message}');
    }
  }
}

/// Bản giả lập (không gọi mạng) — dùng để code & test UI/ViewModel ngay khi
/// Backend chưa xong, hoặc để demo offline.
///
/// Cách hoạt động: mỗi lần [fetchRoster] được gọi (ViewModel polling mỗi
/// vài giây), Mock sẽ "thêm" ngẫu nhiên 1 sinh viên mới vào danh sách, mô
/// phỏng việc sinh viên lần lượt quét QR theo thời gian thực.
class MockAttendanceRepository implements AttendanceRepository {
  final _random = Random();
  final List<AttendanceModel> _roster = [];
  int _nextStudentIndex = 1;
  int _tokenVersion = 0;

  static const _mockStudentNames = [
    'Nguyễn Văn An',
    'Trần Thị Bích',
    'Lê Hoàng Cường',
    'Phạm Thị Duyên',
    'Đỗ Minh Đức',
    'Vũ Thị Hoa',
  ];

  @override
  Future<SessionModel> startSession({required String classId, required String teacherIp}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _roster.clear();
    _nextStudentIndex = 1;
    return SessionModel(
      sessionId: 'mock-session-${DateTime.now().millisecondsSinceEpoch}',
      classId: classId,
      date: DateTime.now(),
      startTime: '07:00',
      endTime: '09:30',
      status: SessionStatus.open,
      qrToken: 'mock-token-0',
      teacherIp: teacherIp,
    );
  }

  @override
  Future<String> refreshQrToken({required String sessionId}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _tokenVersion++;
    return 'mock-token-$_tokenVersion';
  }

  @override
  Future<List<AttendanceModel>> fetchRoster({required String sessionId}) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Cứ khoảng 60% số lần gọi thì "có thêm 1 SV quét QR" — mô phỏng roster
    // tăng dần theo thời gian thay vì hiện hết ngay từ đầu.
    if (_nextStudentIndex <= _mockStudentNames.length && _random.nextDouble() < 0.6) {
      final name = _mockStudentNames[_nextStudentIndex - 1];
      _roster.add(AttendanceModel(
        logId: 'mock-log-$_nextStudentIndex',
        sessionId: sessionId,
        studentId: 'SV${_nextStudentIndex.toString().padLeft(3, '0')}',
        studentName: name,
        checkinTime: DateTime.now(),
        status: AttendanceStatus.present,
        method: CheckinMethod.qr,
        studentIp: '10.0.0.${_nextStudentIndex}',
        ipMatch: true,
        syncedToFap: false,
      ));
      _nextStudentIndex++;
    }

    return List.unmodifiable(_roster);
  }

  @override
  Future<void> manualCheckIn({
    required String sessionId,
    required String studentId,
    required String studentName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _roster.add(AttendanceModel(
      logId: 'mock-log-manual-${_roster.length + 1}',
      sessionId: sessionId,
      studentId: studentId,
      studentName: studentName.isEmpty ? studentId : studentName,
      checkinTime: DateTime.now(),
      status: AttendanceStatus.manualByGV,
      method: CheckinMethod.manual,
      studentIp: null,
      ipMatch: false,
      syncedToFap: false,
    ));
  }

  @override
  Future<void> closeSession({required String sessionId}) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<List<ClassAttendanceStat>> fetchAttendanceStats({required String classId}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      ClassAttendanceStat(sessionLabel: '01/09', presentPercent: 92),
      ClassAttendanceStat(sessionLabel: '08/09', presentPercent: 85),
      ClassAttendanceStat(sessionLabel: '15/09', presentPercent: 76),
      ClassAttendanceStat(sessionLabel: '22/09', presentPercent: 88),
    ];
  }
}
