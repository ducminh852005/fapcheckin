import 'package:flutter/material.dart';
import '../data/models/class_session.dart';
import '../data/models/activity_log.dart';

class DashboardViewModel extends ChangeNotifier {
  // Teacher info
  final String teacherName = 'Nguyễn Văn An';
  final String teacherEmail = 'an.nguyenvan@fpt.edu.vn';
  final String teacherInitials = 'NA';
  final String semester = 'Fall 2023';
  final String campus = 'Hòa Lạc';
  final String todayLabel = 'Thứ Ba, 24/10/2023';

  // Countdown timer
  int _remainingSeconds = 18 * 60 + 42;
  int get remainingSeconds => _remainingSeconds;

  String get countdownDisplay {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void tickCountdown() {
    if (_remainingSeconds > 0) {
      _remainingSeconds--;
      notifyListeners();
    }
  }

  // Stats
  int get totalClassesToday => 4;
  int get morningClasses => 2;
  int get afternoonClasses => 2;
  int get completedSessions => 3;
  int get totalSessions => 4;
  double get sessionProgress => completedSessions / totalSessions;
  int get presentStudents => 126;
  int get totalStudents => 147;
  double get presentRate => presentStudents / totalStudents;
  double get avgAttendance => 0.914;
  double get prevWeekAttendance => 0.893;

  // Active session info
  String get activeSessionCourse => 'SWP391';
  String get activeSessionGroup => 'Nhóm SE1601';
  String get activeSessionRoom => '302';
  int get activeSessionScanned => 28;
  int get activeSessionTotal => 35;

  // Class sessions
  List<ClassSession> get classSessions => const [
    ClassSession(
      courseCode: 'SWP391',
      courseName: 'Dự án Phát triển Phần mềm ứng dụng',
      slot: '1-2',
      timeRange: '07:30 - 09:50',
      room: '302',
      studentCount: 35,
      status: SessionStatus.active,
      scannedCount: 28,
    ),
    ClassSession(
      courseCode: 'PRN212',
      courseName: 'Lập trình C# .NET ứng dụng',
      slot: '3-4',
      timeRange: '10:00 - 12:20',
      room: '405',
      studentCount: 32,
      status: SessionStatus.notStarted,
    ),
    ClassSession(
      courseCode: 'DBI202',
      courseName: 'Cơ sở dữ liệu nâng cao (SQL Server)',
      slot: '5-6',
      timeRange: '13:00 - 15:20',
      room: '201',
      roomType: 'Lab',
      studentCount: 38,
      status: SessionStatus.notStarted,
    ),
    ClassSession(
      courseCode: 'EXE201',
      courseName: 'Kỹ năng Khởi nghiệp và Đổi mới',
      slot: '7-8',
      timeRange: '15:30 - 17:50',
      room: 'A',
      roomType: 'Hội trường',
      studentCount: 42,
      status: SessionStatus.notStarted,
    ),
  ];

  // Weekly attendance chart data (T2 to T7)
  final List<WeeklyData> weeklyAttendance = const [
    WeeklyData('T2', 0.92, false),
    WeeklyData('T3', 0.89, true), // Today
    WeeklyData('T4', 0.94, false),
    WeeklyData('T5', 0.91, false),
    WeeklyData('T6', 0.88, false),
    WeeklyData('T7', 0.95, false),
  ];

  // Activity logs
  List<ActivityLog> get activityLogs => const [
    ActivityLog(
      title: 'Trần Hoàng Long',
      description: 'Quét QR thành công lớp SWP391',
      timeLabel: '08:14',
      type: ActivityType.qrScan,
      subDetail: 'MSSV: SE160342 • IP: 10.14.8.192',
    ),
    ActivityLog(
      title: 'Đồng bộ FAP Cloud',
      description: 'Hệ thống đồng bộ thành công 34 bản ghi lớp PRO192 lên FAP Portal',
      timeLabel: '08:12',
      type: ActivityType.cloudSync,
      subDetail: 'Trạng thái: 200 OK',
    ),
    ActivityLog(
      title: 'Khởi tạo phiên QR',
      description: 'GV. Nguyễn Văn An mở phiên QR lớp SWP391 (Hạn 30 phút)',
      timeLabel: '08:00',
      type: ActivityType.sessionStart,
    ),
    ActivityLog(
      title: 'Điểm danh thủ công',
      description: 'Đã lưu bảng điểm danh lớp MAS291',
      timeLabel: 'Hôm qua',
      type: ActivityType.manualEntry,
      subDetail: 'Ghi chú: 3 SV đi trễ có phép',
    ),
  ];

  // Navigation state
  String _currentRoute = 'tong-quan';
  String get currentRoute => _currentRoute;

  void navigate(String route) {
    _currentRoute = route;
    notifyListeners();
  }
}

/// Simple data holder for weekly attendance chart
class WeeklyData {
  final String label;
  final double rate;
  final bool isToday;
  const WeeklyData(this.label, this.rate, this.isToday);
}
