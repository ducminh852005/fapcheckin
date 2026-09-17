import 'package:flutter/material.dart';
import 'package:fapcheckin/data/models/student_checkin.dart';

class LiveSessionViewModel extends ChangeNotifier {
  // Session info
  final String courseCode = 'SWP391';
  final String courseName = 'Dự án phần mềm';
  final String courseCategory = 'Môn học chuyên ngành';
  final String room = '302';
  final String slot = 'Ca 1 (07:30 - 09:50)';
  final String dateLabel = 'Thứ 3, 24/10/2023';
  final String sessionId = 'FPT-SWP-231024-C1';
  final String teacherIp = '118.69.182.45';

  // Timers
  int _sessionRemainingSeconds = 18 * 60 + 42;
  int _qrRefreshSeconds = 14;
  static const int qrCycleDuration = 20;

  int get sessionRemainingSeconds => _sessionRemainingSeconds;
  int get qrRefreshSeconds => _qrRefreshSeconds;

  String get sessionTimeDisplay {
    final m = _sessionRemainingSeconds ~/ 60;
    final s = _sessionRemainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get qrProgress => _qrRefreshSeconds / qrCycleDuration;

  void tickTimers() {
    if (_sessionRemainingSeconds > 0) _sessionRemainingSeconds--;
    _qrRefreshSeconds--;
    if (_qrRefreshSeconds <= 0) _qrRefreshSeconds = qrCycleDuration;
    notifyListeners();
  }

  // Stats
  int get totalStudents => 35;
  int get presentCount => students.where((s) => s.status == CheckinStatus.present).length;
  int get lateCount => students.where((s) => s.status == CheckinStatus.late).length;
  int get checkedInCount => presentCount + lateCount;
  int get uncheckedCount => students.where((s) => s.status == CheckinStatus.unchecked).length;

  // Filter
  String _activeFilter = 'all';
  String get activeFilter => _activeFilter;

  void setFilter(String filter) {
    _activeFilter = filter;
    notifyListeners();
  }

  // Search
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<StudentCheckin> get filteredStudents {
    var list = students;
    // Apply filter
    switch (_activeFilter) {
      case 'checked':
        list = list
            .where((s) =>
                s.status == CheckinStatus.present ||
                s.status == CheckinStatus.late)
            .toList();
        break;
      case 'unchecked':
        list = list.where((s) => s.status == CheckinStatus.unchecked).toList();
        break;
    }
    // Apply search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((s) =>
              s.studentId.toLowerCase().contains(q) ||
              s.fullName.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  // Mock student data matching HTML
  final List<StudentCheckin> students = const [
    StudentCheckin(
      index: 1,
      studentId: 'SE160124',
      fullName: 'Trần Minh Đức',
      initials: 'TĐ',
      checkInTime: '07:35:12',
      status: CheckinStatus.present,
      ipAddress: '118.69.182.50',
      method: CheckinMethod.qrCode,
    ),
    StudentCheckin(
      index: 2,
      studentId: 'SE160892',
      fullName: 'Lê Thị Ngọc Ánh',
      initials: 'LÁ',
      checkInTime: '07:36:04',
      status: CheckinStatus.present,
      ipAddress: '118.69.182.52',
      method: CheckinMethod.qrCode,
    ),
    StudentCheckin(
      index: 3,
      studentId: 'SE161045',
      fullName: 'Nguyễn Hoàng Nam',
      initials: 'NN',
      checkInTime: '07:52:18',
      status: CheckinStatus.late,
      lateMinutes: '+22m',
      ipAddress: '118.69.182.49',
      method: CheckinMethod.qrCode,
    ),
    StudentCheckin(
      index: 4,
      studentId: 'SE160311',
      fullName: 'Phạm Quốc Bảo',
      initials: 'PB',
      checkInTime: '07:54:30',
      status: CheckinStatus.late,
      lateMinutes: '+24m',
      ipAddress: '118.69.182.45',
      method: CheckinMethod.qrCode,
    ),
    StudentCheckin(
      index: 5,
      studentId: 'SE150998',
      fullName: 'Đỗ Vũ Hà My',
      initials: 'ĐM',
      checkInTime: '--:--:--',
      status: CheckinStatus.unchecked,
      ipAddress: '--',
    ),
  ];

  // Toast state
  bool _showToast = true;
  bool get showToast => _showToast;

  void dismissToast() {
    _showToast = false;
    notifyListeners();
  }
}
