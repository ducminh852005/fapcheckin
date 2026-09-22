import 'package:flutter/material.dart';
import '../data/models/activity_log.dart';
import '../data/models/class_section_model.dart';
import '../data/models/sync_result_model.dart';
import '../data/repositories/teacher_repository.dart';
import '../core/network/api_result.dart';
import 'live_session_viewmodel.dart';

class DashboardViewModel extends ChangeNotifier {
  final TeacherRepository _repository;

  DashboardViewModel(this._repository);

  // ── Teacher info (filled after login / from auth state) ─────────────────────
  String _teacherName = '';
  String get teacherName => _teacherName.isNotEmpty ? _teacherName : 'Giảng viên';

  String _teacherEmail = '';
  String get teacherEmail => _teacherEmail;

  String get teacherInitials {
    if (_teacherName.isEmpty) return 'GV';
    final parts = _teacherName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return _teacherName.substring(0, 2).toUpperCase();
  }

  String _teacherMemberCode = '';
  String get teacherMemberCode => _teacherMemberCode;

  String semester = 'Fall 2023';
  String campus = 'Hòa Lạc';

  String get todayLabel {
    final now = DateTime.now();
    const days = ['Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'];
    final dayName = days[now.weekday - 1];
    return '$dayName, ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  // Set teacher info after login
  void setTeacherInfo({
    required String name,
    required String email,
    required String memberCode,
  }) {
    _teacherName = name;
    _teacherEmail = email;
    _teacherMemberCode = memberCode;
    notifyListeners();
  }

  void clearTeacherInfo() {
    _teacherName = '';
    _teacherEmail = '';
    _teacherMemberCode = '';
    _classes = [];
    _status = ViewStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  // ── Status ──────────────────────────────────────────────────────────────────

  ViewStatus _status = ViewStatus.idle;
  ViewStatus get status => _status;
  bool get isLoading => _status == ViewStatus.loading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ── Classes ─────────────────────────────────────────────────────────────────

  List<ClassSectionModel> _classes = [];
  List<ClassSectionModel> get classes => _classes;

  // Derived stats from classes list
  int get totalClassesToday => _classes.length;
  int get morningClasses =>
      _classes.where((c) => _isMorning(c)).length;
  int get afternoonClasses => totalClassesToday - morningClasses;

  // These come from LiveSessionViewModel in reality, but kept here for the
  // dashboard summary card
  int _completedSessions = 0;
  int get completedSessions => _completedSessions;
  int get totalSessions => totalClassesToday;
  double get sessionProgress =>
      totalSessions == 0 ? 0 : completedSessions / totalSessions;

  // Present students (aggregate from roster — updated when session loads)
  int _presentStudents = 0;
  int get presentStudents => _presentStudents;
  int get totalStudents =>
      _classes.fold(0, (sum, c) => sum + c.studentCount);
  double get presentRate =>
      totalStudents == 0 ? 0 : presentStudents / totalStudents;
  double get avgAttendance => 0.0; // requires historical data not in MVP
  double get prevWeekAttendance => 0.0;

  // Active session info (pass-through from LiveSessionViewModel if active)
  String _activeSessionCourse = '';
  String get activeSessionCourse => _activeSessionCourse;
  String _activeSessionGroup = '';
  String get activeSessionGroup => _activeSessionGroup;
  String _activeSessionRoom = '';
  String get activeSessionRoom => _activeSessionRoom;
  int _activeSessionScanned = 0;
  int get activeSessionScanned => _activeSessionScanned;
  int _activeSessionTotal = 0;
  int get activeSessionTotal => _activeSessionTotal;

  void updateActiveSession({
    required String course,
    required String group,
    required String room,
    required int scanned,
    required int total,
    required int present,
  }) {
    _activeSessionCourse = course;
    _activeSessionGroup = group;
    _activeSessionRoom = room;
    _activeSessionScanned = scanned;
    _activeSessionTotal = total;
    _presentStudents = present;
    notifyListeners();
  }

  // Countdown timer (kept for UI compat — ticks via MainScreen)
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

  // ── Weekly chart (static for now — requires historical API not in MVP) ──────

  final List<WeeklyData> weeklyAttendance = const [
    WeeklyData('T2', 0.92, false),
    WeeklyData('T3', 0.89, true),
    WeeklyData('T4', 0.94, false),
    WeeklyData('T5', 0.91, false),
    WeeklyData('T6', 0.88, false),
    WeeklyData('T7', 0.95, false),
  ];

  // ── Activity logs (static for now — no dedicated API endpoint in MVP) ───────

  List<ActivityLog> get activityLogs => const [
        ActivityLog(
          title: 'Hệ thống sẵn sàng',
          description: 'Kết nối API thành công. Sẵn sàng bắt đầu điểm danh.',
          timeLabel: 'Vừa xong',
          type: ActivityType.sessionStart,
        ),
      ];

  // ── Class sessions (for legacy ClassSession model used by DashboardBody) ────

  List<dynamic> get classSessions => _classes;

  // ── Load classes from API ────────────────────────────────────────────────────

  Future<void> loadClasses() async {
    if (_teacherMemberCode.isEmpty) return;
    _status = ViewStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getClasses(
        teacherMemberCode: _teacherMemberCode,
      );

      switch (result) {
        case ApiSuccess<List<ClassSectionModel>>(:final data):
          _classes = data;
          _status = data.isEmpty ? ViewStatus.idle : ViewStatus.success;
        case ApiFailure<List<ClassSectionModel>>(:final error):
          _status = ViewStatus.error;
          _errorMessage = error.message;
      }
    } catch (e) {
      _status = ViewStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  // ── Helper state updates ─────────────────────────────────────────────────

  void markClassInactive(String classCode) {
    for (int i = 0; i < _classes.length; i++) {
      if (_classes[i].classCode == classCode) {
        _classes[i] = _classes[i].copyWith(isActive: false, activeSessionId: null);
      }
    }
    notifyListeners();
  }

  // ── Sync to FAP ─────────────────────────────────────────────────────────────

  Future<ApiResult<SyncResult>> syncToFap({String? classCode}) async {
    return await _repository.syncToFap(classCode: classCode);
  }

  // ── Navigation ───────────────────────────────────────────────────────────────


  String _currentRoute = 'tong-quan';
  String get currentRoute => _currentRoute;

  void navigate(String route) {
    _currentRoute = route;
    notifyListeners();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  bool _isMorning(ClassSectionModel c) {
    if (c.period != null && c.period!.isNotEmpty) {
      final p = c.period!.toLowerCase();
      return p.contains('morning') || p.startsWith('a');
    }
    if (c.slotCode.isNotEmpty) {
      final s = c.slotCode.toUpperCase();
      return s.startsWith('a') || ['1', '2'].contains(s);
    }
    if (c.startTime != null && c.startTime!.isNotEmpty) {
      final hour = int.tryParse(c.startTime!.split(':').first);
      if (hour != null) return hour < 12;
    }
    return false;
  }
}

/// Simple data holder for weekly attendance chart
class WeeklyData {
  final String label;
  final double rate;
  final bool isToday;
  const WeeklyData(this.label, this.rate, this.isToday);
}
