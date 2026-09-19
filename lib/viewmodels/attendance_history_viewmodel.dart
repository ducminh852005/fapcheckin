import 'package:flutter/foundation.dart';
import 'package:fapcheckin/data/models/history_class.dart';
import 'package:fapcheckin/data/models/history_student.dart';
import 'package:fapcheckin/data/models/student_checkin.dart';

class AttendanceHistoryViewModel extends ChangeNotifier {
  // Mock classes
  final List<HistoryClass> classes = [
    const HistoryClass(
      courseCode: 'SWP391',
      className: 'SE1704',
      courseName: 'Dự án Phát triển Phần mềm',
      attendanceRate: 0.942,
      completedSessions: 12,
      totalSessions: 30,
      latestSessionDate: 'Hôm nay 24/10',
      latestSessionName: 'Buổi 12',
      isActive: true,
    ),
    const HistoryClass(
      courseCode: 'PRN211',
      className: 'SE1706',
      courseName: 'Lập trình C# & .NET Platform',
      attendanceRate: 0.968,
      completedSessions: 8,
      totalSessions: 30,
      latestSessionDate: '20/10',
      latestSessionName: 'Buổi 08',
    ),
    const HistoryClass(
      courseCode: 'PRJ301',
      className: 'SE1612',
      courseName: 'Java Web Application',
      attendanceRate: 0.925,
      completedSessions: 14,
      totalSessions: 30,
      latestSessionDate: '19/10',
      latestSessionName: 'Buổi 14',
    ),
    const HistoryClass(
      courseCode: 'SWT301',
      className: 'SE1620',
      courseName: 'Software Testing & QA',
      attendanceRate: 0.95,
      completedSessions: 11,
      totalSessions: 30,
      latestSessionDate: '18/10',
      latestSessionName: 'Buổi 11',
    ),
    const HistoryClass(
      courseCode: 'MAS291',
      className: 'AI1701',
      courseName: 'Thống kê ứng dụng & Xác suất',
      attendanceRate: 0.894,
      completedSessions: 16,
      totalSessions: 30,
      latestSessionDate: '17/10',
      latestSessionName: 'Buổi 16',
      isWarning: true,
    ),
  ];

  String? _selectedClassCode = 'SWP391';
  String? get selectedClassCode => _selectedClassCode;

  void selectClass(String code) {
    _selectedClassCode = code;
    notifyListeners();
  }

  // Mock sessions
  final List<Map<String, dynamic>> sessions = [
    {'slot': 12, 'date': '24/10 (Hôm nay)', 'isActive': true},
    {'slot': 11, 'date': '21/10', 'isActive': false},
    {'slot': 10, 'date': '17/10', 'isActive': false},
    {'slot': 9, 'date': '14/10', 'isActive': false},
    {'slot': 8, 'date': '10/10', 'isActive': false},
    {'slot': 7, 'date': '07/10', 'isActive': false},
    {'slot': 6, 'date': '03/10', 'isActive': false},
  ];

  int _selectedSessionSlot = 12;
  int get selectedSessionSlot => _selectedSessionSlot;

  void selectSession(int slot) {
    _selectedSessionSlot = slot;
    notifyListeners();
  }

  String _statusFilter = 'all';
  String get statusFilter => _statusFilter;

  void setStatusFilter(String filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  // Mock students
  final List<HistoryStudent> students = [
    const HistoryStudent(
      index: 1,
      studentId: 'SE160124',
      fullName: 'Lê Hoàng Long',
      initials: 'LH',
      email: 'longlhse160124@fpt.edu.vn',
      checkInTime: '07:35:12',
      status: CheckinStatus.present,
      methodLabel: 'QR Động 20s',
      methodIcon: 'qr_code_2',
      absenceCount: 1,
      totalSessions: 30,
      absenceStatusText: 'An toàn',
    ),
    const HistoryStudent(
      index: 2,
      studentId: 'SE160892',
      fullName: 'Phạm Thùy Trang',
      initials: 'PT',
      email: 'trangptse160892@fpt.edu.vn',
      checkInTime: '07:48:20',
      status: CheckinStatus.late,
      methodLabel: 'QR Động 20s',
      methodIcon: 'qr_code_2',
      absenceCount: 2,
      totalSessions: 30,
      absenceStatusText: 'Bình thường',
      lateLabel: 'Đi trễ +18m',
    ),
    const HistoryStudent(
      index: 3,
      studentId: 'SE161045',
      fullName: 'Nguyễn Tiến Đạt',
      initials: 'NT',
      email: 'datntse161045@fpt.edu.vn',
      checkInTime: '08:05:14',
      status: CheckinStatus.present, // actually manual present
      methodLabel: 'Điểm danh bù bởi GV',
      methodIcon: 'how_to_reg',
      absenceCount: 0,
      totalSessions: 30,
      absenceStatusText: 'Tuyệt đối',
    ),
    const HistoryStudent(
      index: 4,
      studentId: 'SE160311',
      fullName: 'Trần Quang Huy',
      initials: 'TQ',
      email: 'huytqse160311@fpt.edu.vn',
      checkInTime: '--:--:--',
      status: CheckinStatus.absent,
      methodLabel: 'Không quét QR',
      methodIcon: 'block',
      absenceCount: 6,
      totalSessions: 30,
      absenceStatusText: 'Nguy cơ',
    ),
    const HistoryStudent(
      index: 5,
      studentId: 'SE150998',
      fullName: 'Hoàng Tuấn Anh',
      initials: 'HA',
      email: 'anhhtse150998@fpt.edu.vn',
      checkInTime: '--:--:--',
      status: CheckinStatus.unchecked, // Manual excused
      methodLabel: 'Đơn phép qua FAP',
      methodIcon: 'mail',
      absenceCount: 3,
      totalSessions: 30,
      absenceStatusText: 'Cho phép',
    ),
    const HistoryStudent(
      index: 6,
      studentId: 'SE160235',
      fullName: 'Đỗ Minh Khang',
      initials: 'ĐK',
      email: 'khangdmse160235@fpt.edu.vn',
      checkInTime: '07:32:41',
      status: CheckinStatus.present,
      methodLabel: 'QR Động 20s',
      methodIcon: 'qr_code_2',
      absenceCount: 0,
      totalSessions: 30,
      absenceStatusText: 'Tuyệt đối',
    ),
  ];

  List<HistoryStudent> get filteredStudents {
    if (_statusFilter == 'all') return students;
    if (_statusFilter == 'present') {
      return students.where((s) => s.status == CheckinStatus.present).toList();
    }
    if (_statusFilter == 'late') {
      return students.where((s) => s.status == CheckinStatus.late).toList();
    }
    if (_statusFilter == 'absent') {
      return students.where((s) => s.status == CheckinStatus.absent || s.status == CheckinStatus.unchecked).toList();
    }
    return students;
  }
}
