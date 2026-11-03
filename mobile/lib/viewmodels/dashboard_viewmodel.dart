import 'package:flutter/material.dart';

import 'package:fapcheckin_core/models/activity_log.dart';
import 'package:fapcheckin_core/models/class_section_model.dart';
import 'package:fapcheckin_core/models/sync_result_model.dart';
import 'package:fapcheckin_core/repositories/teacher_repository.dart';
import 'package:fapcheckin_core/result/api_result.dart';

import './live_session_viewmodel.dart';

class DashboardViewModel extends ChangeNotifier {
  final TeacherRepository _repository;
  final DateTime Function() _now;

  DashboardViewModel(this._repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  // ── Teacher info (filled after login / from auth state) ─────────────────────
  String _teacherName = '';
  String get teacherName =>
      _teacherName.isNotEmpty ? _teacherName : 'Giảng viên';

  String _teacherEmail = '';
  String get teacherEmail => _teacherEmail;

  String get teacherInitials {
    if (_teacherName.isEmpty) return 'GV';
    final parts = _teacherName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return _teacherName
        .substring(0, _teacherName.length < 2 ? 1 : 2)
        .toUpperCase();
  }

  String _teacherMemberCode = '';
  String get teacherMemberCode => _teacherMemberCode;

  String semester = '';
  String campus = '';

  String get todayLabel {
    final now = _now();
    const days = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
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
    _generation++;
    _currentRoute = 'tong-quan';
    _classes = [];
    _status = ViewStatus.idle;
    _errorMessage = null;
    _errorCode = null;
    notifyListeners();
  }

  // ── Status ──────────────────────────────────────────────────────────────────

  ViewStatus _status = ViewStatus.idle;
  ViewStatus get status => _status;
  bool get isLoading => _status == ViewStatus.loading;

  String? _errorCode;
  String? get errorCode => _errorCode;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ── Classes ─────────────────────────────────────────────────────────────────

  List<ClassSectionModel> _classes = [];
  List<ClassSectionModel> get classes => _classes;

  // Derived stats from classes list
  int get totalClassesToday => _classes.length;
  int get morningClasses => _classes.where((c) => _isMorning(c)).length;
  int get afternoonClasses => totalClassesToday - morningClasses;

  // These come from LiveSessionViewModel in reality, but kept here for the
  // dashboard summary card
  int get _completedSessions =>
      _classes.fold(0, (sum, c) => sum + c.completedSessions);
  int get completedSessions => _completedSessions;
  int get totalSessions => totalClassesToday;
  double get sessionProgress =>
      totalSessions == 0 ? 0 : completedSessions / totalSessions;

  // Present students (aggregate from roster — updated when session loads)
  int _presentStudents = 0;
  int get presentStudents => _presentStudents;
  int get totalStudents => _classes.fold(0, (sum, c) => sum + c.studentCount);
  double get presentRate =>
      totalStudents == 0 ? 0 : presentStudents / totalStudents;
  double get avgAttendance => _classes.isEmpty
      ? 0
      : _classes.fold<double>(0, (sum, c) => sum + c.averageAttendance) /
            _classes.length /
            100;
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
  int _remainingSeconds = 0;
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

  final List<WeeklyData> weeklyAttendance = const [];

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

  int _generation = 0;
  Future<void> loadClasses() async {
    if (_teacherMemberCode.isEmpty) return;
    final generation = ++_generation;
    _status = ViewStatus.loading;
    _errorMessage = null;
    _errorCode = null;
    notifyListeners();

    try {
      final result = await _repository.getClasses(
        teacherMemberCode: _teacherMemberCode,
      );

      if (generation != _generation) return;
      switch (result) {
        case ApiSuccess<List<ClassSectionModel>>(:final data):
          _classes = _sortClassesByCheckinPriority(
            data.where((c) => !c.isMakeup).toList(),
          );
          _status = ViewStatus.success;
        case ApiFailure<List<ClassSectionModel>>(:final error):
          _status = ViewStatus.error;
          _errorCode = error.code;
          _errorMessage = error.message;
      }
    } catch (e) {
      if (generation != _generation) return;
      _status = ViewStatus.error;
      _errorCode = 'UNKNOWN_ERROR';
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  // ── Helper state updates ─────────────────────────────────────────────────

  void markClassInactive(String classCode) {
    for (int i = 0; i < _classes.length; i++) {
      if (_classes[i].classCode == classCode) {
        _classes[i] = _classes[i].copyWith(
          isActive: false,
          activeSessionId: null,
        );
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

  List<ClassSectionModel> _sortClassesByCheckinPriority(
    List<ClassSectionModel> classes,
  ) {
    final indexed = classes.indexed.toList();
    final now = _now();
    indexed.sort((a, b) {
      final priorityCompare = _checkinPriority(
        a.$2,
        now,
      ).compareTo(_checkinPriority(b.$2, now));
      if (priorityCompare != 0) return priorityCompare;

      final startCompare = (_startMinute(a.$2) ?? 24 * 60).compareTo(
        _startMinute(b.$2) ?? 24 * 60,
      );
      if (startCompare != 0) return startCompare;

      return a.$1.compareTo(b.$1);
    });
    return indexed.map((entry) => entry.$2).toList();
  }

  int _checkinPriority(ClassSectionModel c, DateTime now) {
    if (c.isActive) return 0;
    final startMinute = _startMinute(c);
    var endMinute = _endMinute(c);
    if (startMinute != null && endMinute != null && endMinute <= startMinute) {
      endMinute += 24 * 60;
    }
    final nowMinute = now.hour * 60 + now.minute;
    if (endMinute != null && nowMinute > endMinute) return 2;
    return 1;
  }

  int? _startMinute(ClassSectionModel c) {
    return _firstMinute(c.startTime) ?? _firstMinute(c.timeLabel);
  }

  int? _endMinute(ClassSectionModel c) {
    return _firstMinute(c.endTime) ?? _lastMinute(c.timeLabel);
  }

  int? _firstMinute(String? value) {
    final matches = _minuteMatches(value);
    return matches.isEmpty ? null : matches.first;
  }

  int? _lastMinute(String? value) {
    final matches = _minuteMatches(value);
    return matches.isEmpty ? null : matches.last;
  }

  List<int> _minuteMatches(String? value) {
    if (value == null || value.trim().isEmpty) return const [];
    return RegExp(r'(\d{1,2}):(\d{2})')
        .allMatches(value)
        .map((match) {
          final hour = int.tryParse(match.group(1)!);
          final minute = int.tryParse(match.group(2)!);
          if (hour == null || minute == null || hour > 23 || minute > 59) {
            return null;
          }
          return hour * 60 + minute;
        })
        .whereType<int>()
        .toList();
  }
}

/// Simple data holder for weekly attendance chart
class WeeklyData {
  final String label;
  final double rate;
  final bool isToday;
  const WeeklyData(this.label, this.rate, this.isToday);
}
