import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models/class_section_model.dart';
import '../data/models/roster_entry_model.dart';
import '../data/models/session_model.dart';
import '../data/models/stats_entry_model.dart';
import '../data/models/student_checkin.dart';
import '../data/repositories/teacher_repository.dart';
import '../core/network/api_result.dart';

// ---------------------------------------------------------------------------
// ViewStatus (shared with the rest of the project)
// ---------------------------------------------------------------------------
enum ViewStatus { idle, loading, success, error }

// ---------------------------------------------------------------------------
// LiveSessionViewModel
// ---------------------------------------------------------------------------

class LiveSessionViewModel extends ChangeNotifier {
  final TeacherRepository _repository;

  LiveSessionViewModel(this._repository);

  // ── Session metadata ────────────────────────────────────────────────────────

  SessionModel? _session;
  SessionModel? get session => _session;

  ClassSectionModel? _classInfo;
  ClassSectionModel? get classInfo => _classInfo;

  // ── Status ──────────────────────────────────────────────────────────────────

  ViewStatus _status = ViewStatus.idle;
  ViewStatus get status => _status;
  bool get isLoading => _status == ViewStatus.loading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ── QR / session timers ─────────────────────────────────────────────────────

  /// Seconds remaining until QR auto-refreshes (visual only)
  int _qrRefreshSeconds = qrCycleDuration;
  int get qrRefreshSeconds => _qrRefreshSeconds;
  static const int qrCycleDuration = 20;

  double get qrProgress => _qrRefreshSeconds / qrCycleDuration;

  /// Elapsed seconds since session started (displayed as countdown from 90 min)
  int _sessionElapsedSeconds = 0;
  static const int _sessionDurationSeconds = 90 * 60; // 90 min

  int get sessionRemainingSeconds =>
      (_sessionDurationSeconds - _sessionElapsedSeconds).clamp(
        0,
        _sessionDurationSeconds,
      );

  String get sessionTimeDisplay {
    final remaining = sessionRemainingSeconds;
    final m = remaining ~/ 60;
    final s = remaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // Derived from session
  String get courseCode => _classInfo?.classCode ?? _session?.classCode ?? '';
  String get courseName => _classInfo?.subjectName ?? '';
  String get courseCategory => 'MÔN HỌC CHUYÊN NGÀNH';
  String get room => _classInfo?.room ?? '';
  String get slot => _session?.slotCode ?? '';
  String get dateLabel => _session?.sessionDate ?? '';
  String get sessionId => _session?.sessionId ?? '';
  String get qrToken => _session?.qrToken ?? '';

  // Teacher IP (set when starting session)
  String _teacherIp = '';
  String get teacherIp => _teacherIp;

  // ── Roster ──────────────────────────────────────────────────────────────────

  List<RosterEntryModel> _roster = [];
  List<RosterEntryModel> get roster => _roster;

  // Derived stats from roster
  int get totalStudents => _classInfo?.studentCount ?? _roster.length;

  int get presentCount => _roster.where((s) => s.isPresent).length;

  int get lateCount => _roster.where((s) => s.isLate).length;

  int get checkedInCount => presentCount + lateCount;

  int get uncheckedCount => _roster.where((s) => s.isUnchecked).length;

  // ── Stats ────────────────────────────────────────────────────────────────────

  List<StatsEntryModel> _stats = [];
  List<StatsEntryModel> get stats => _stats;

  // ── Filter / Search ─────────────────────────────────────────────────────────

  String _activeFilter = 'all';
  String get activeFilter => _activeFilter;

  void setFilter(String filter) {
    _activeFilter = filter;
    notifyListeners();
  }

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Transforms roster into StudentCheckin list used by the UI
  List<StudentCheckin> get students {
    return _roster.asMap().entries.map((entry) {
      final i = entry.key;
      final r = entry.value;
      return StudentCheckin(
        index: i + 1,
        studentId: r.rollNumber,
        fullName: r.email.split('@').first,
        initials: r.initials,
        checkInTime: r.displayCheckinTime,
        status: _mapStatus(r.status),
        lateMinutes: r.isLate ? null : null,
        ipAddress: r.ipAddress ?? '--',
        method: r.status == 'ManualByGV'
            ? CheckinMethod.manual
            : CheckinMethod.qrCode,
      );
    }).toList();
  }

  CheckinStatus _mapStatus(String apiStatus) {
    switch (apiStatus) {
      case 'Present':
        return CheckinStatus.present;
      case 'Late':
        return CheckinStatus.late;
      case 'Absent':
        return CheckinStatus.absent;
      case 'ManualByGV':
        return CheckinStatus.present;
      default:
        return CheckinStatus.unchecked;
    }
  }

  List<StudentCheckin> get filteredStudents {
    var list = students;
    switch (_activeFilter) {
      case 'checked':
        list = list
            .where(
              (s) =>
                  s.status == CheckinStatus.present ||
                  s.status == CheckinStatus.late,
            )
            .toList();
        break;
      case 'unchecked':
        list = list.where((s) => s.status == CheckinStatus.unchecked).toList();
        break;
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where(
            (s) =>
                s.studentId.toLowerCase().contains(q) ||
                s.fullName.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  // ── Toast ────────────────────────────────────────────────────────────────────

  bool _showToast = false;
  bool get showToast => _showToast;

  void dismissToast() {
    _showToast = false;
    notifyListeners();
  }

  // ── Polling timer ────────────────────────────────────────────────────────────

  Timer? _pollTimer;
  static const Duration _pollInterval = Duration(seconds: 5);

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Called by the timer in MainScreen every second for UI countdown
  void tickTimers() {
    _sessionElapsedSeconds++;
    _qrRefreshSeconds--;
    if (_qrRefreshSeconds <= 0) _qrRefreshSeconds = qrCycleDuration;
    notifyListeners();
  }

  /// Start a session for a given class.
  /// classCode: the ClassSection's classCode
  /// slotCode: e.g. "1", "2", etc.
  /// teacherIp: fetched externally via ipify or similar
  Future<void> startSession({
    required ClassSectionModel classSection,
    required String slotCode,
    required String teacherIp,
  }) async {
    _status = ViewStatus.loading;
    _errorMessage = null;
    _classInfo = classSection;
    _teacherIp = teacherIp;
    notifyListeners();

    try {
      final result = await _repository.startSession(
        classCode: classSection.classCode,
        slotCode: slotCode,
        teacherIp: teacherIp,
      );

      switch (result) {
        case ApiSuccess<SessionModel>(:final data):
          _session = data;
          _status = ViewStatus.success;
          _sessionElapsedSeconds = 0;
          _startPolling();
        case ApiFailure<SessionModel>(:final error):
          _status = ViewStatus.error;
          _errorMessage = error.message;
      }
    } catch (e) {
      _status = ViewStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  /// Loads roster once (call manually or let polling handle it)
  void adoptSession(
    SessionModel session,
    ClassSectionModel classInfo,
    String teacherIp,
  ) {
    resetSession();
    _session = session;
    _classInfo = classInfo;
    _teacherIp = teacherIp;
    _status = ViewStatus.success;
    _startPolling();
    notifyListeners();
  }

  Future<void> loadRoster() async {
    if (_session == null) return;

    final result = await _repository.getRoster(sessionId: _session!.sessionId);
    switch (result) {
      case ApiSuccess<List<RosterEntryModel>>(:final data):
        final prevChecked = checkedInCount;
        _roster = data;
        if (checkedInCount > prevChecked) {
          _showToast = true;
        }
        notifyListeners();
      case ApiFailure<List<RosterEntryModel>>():
        // Silently fail on background polls to avoid disrupting UI
        break;
    }
  }

  /// Manually mark a student present (manualCheckin API)
  Future<void> manualCheckin(String rollNumber) async {
    if (_session == null) return;

    final result = await _repository.manualCheckin(
      sessionId: _session!.sessionId,
      rollNumber: rollNumber,
      status: 'ManualByGV',
    );

    switch (result) {
      case ApiSuccess<void>():
        // Immediately refresh the roster
        await loadRoster();
      case ApiFailure<void>(:final error):
        _errorMessage = error.message;
        notifyListeners();
    }
  }

  /// Load stats for a given class
  Future<void> loadStats(String classCode) async {
    final result = await _repository.getStats(classCode: classCode);
    switch (result) {
      case ApiSuccess<List<StatsEntryModel>>(:final data):
        _stats = data;
        notifyListeners();
      case ApiFailure<List<StatsEntryModel>>():
        break;
    }
  }

  /// Reset session state (e.g. when navigating away)
  void resetSession() {
    _stopPolling();
    _session = null;
    _classInfo = null;
    _roster = [];
    _stats = [];
    _status = ViewStatus.idle;
    _errorMessage = null;
    _sessionElapsedSeconds = 0;
    _qrRefreshSeconds = qrCycleDuration;
    _showToast = false;
    notifyListeners();
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  void _startPolling() {
    _stopPolling();
    // Initial load
    loadRoster();
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (_session != null) loadRoster();
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
