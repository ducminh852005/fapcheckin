import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/services/ip_service.dart';
import '../data/models/class_section_model.dart';
import '../data/models/close_session_model.dart';
import '../data/models/roster_entry_model.dart';
import '../data/models/session_model.dart';
import '../data/models/stats_entry_model.dart';
import '../data/models/student_checkin.dart';
import '../data/repositories/teacher_repository.dart';
import '../core/network/api_result.dart';
import '../views/teacher/live_session/components/qr_panel.dart';

// ---------------------------------------------------------------------------
// ViewStatus & Toast Types
// ---------------------------------------------------------------------------
enum ViewStatus { idle, loading, success, error }

enum ToastType { checkin, startSession, closeSession, custom }

class LiveSessionToastData {
  final ToastType type;
  final String title;
  final String message;
  final IconData icon;
  final Color accentColor;

  const LiveSessionToastData({
    required this.type,
    required this.title,
    required this.message,
    required this.icon,
    required this.accentColor,
  });
}

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

  /// QR token rotation interval. One minute gives students enough time to scan
  /// and complete Google sign-in before the displayed token changes.
  static const int qrCycleDuration = 60;
  int _qrRefreshSeconds = qrCycleDuration;
  int get qrRefreshSeconds => _qrRefreshSeconds;
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

  String get checkinUrl =>
      qrToken.isEmpty ? '' : '$kCheckinBaseUrl?page=checkin&token=$qrToken';

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

  int get absentCount => _roster.where((s) => s.isAbsent).length;

  bool get isClosed => _session?.sessionStatus == 'closed';

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
        fullName: r.displayName,
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
        list = list
            .where(
              (s) =>
                  s.status == CheckinStatus.unchecked ||
                  s.status == CheckinStatus.absent,
            )
            .toList();
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
  bool get showToast => _showToast && _toastData != null;

  LiveSessionToastData? _toastData;
  LiveSessionToastData? get toastData => _toastData;

  RosterEntryModel? _lastCheckedInStudent;
  RosterEntryModel? get lastCheckedInStudent => _lastCheckedInStudent;

  Timer? _toastTimer;

  void triggerToast({
    required ToastType type,
    required String title,
    required String message,
    required IconData icon,
    required Color accentColor,
    Duration duration = const Duration(seconds: 4),
  }) {
    _toastData = LiveSessionToastData(
      type: type,
      title: title,
      message: message,
      icon: icon,
      accentColor: accentColor,
    );
    _showToast = true;
    _toastTimer?.cancel();
    _toastTimer = Timer(duration, () {
      dismissToast();
    });
    notifyListeners();
  }

  void dismissToast() {
    _showToast = false;
    _toastData = null;
    _toastTimer?.cancel();
    _toastTimer = null;
    notifyListeners();
  }

  // ── Polling timer ────────────────────────────────────────────────────────────

  Timer? _pollTimer;
  static const Duration _pollInterval = Duration(seconds: 5);

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Called by MainScreen every second to update session and QR countdowns.
  void tickTimers() {
    _sessionElapsedSeconds++;
    _qrRefreshSeconds--;
    if (_qrRefreshSeconds <= 0) {
      _qrRefreshSeconds = qrCycleDuration;
      _rotateQr();
    }
    notifyListeners();
  }

  /// Start or resume a session for a given class.
  /// If the class already has an open active session, resumes it without closing existing records.
  Future<void> startSession({
    required ClassSectionModel classSection,
    required String slotCode,
    String? teacherIp,
    bool forceNew = false,
  }) async {
    _status = ViewStatus.loading;
    _errorMessage = null;
    _classInfo = classSection;

    // Use provided IP or fetch real public IP via IpService
    String realIp = teacherIp ?? '';
    if (realIp.isEmpty || realIp == '127.0.0.1' || realIp == '192.168.1.100') {
      realIp = await IpService.getPublicIp();
    }
    _teacherIp = realIp;
    notifyListeners();

    // 1. Check if we already have this session active in memory
    if (!forceNew &&
        _session != null &&
        _session!.classCode == classSection.classCode &&
        !isClosed) {
      _status = ViewStatus.success;
      _startPolling();
      notifyListeners();
      return;
    }

    // 2. Check if classSection is active and has an activeSessionId on backend
    final activeId = classSection.activeSessionId;
    if (!forceNew &&
        classSection.isActive &&
        activeId != null &&
        activeId.isNotEmpty) {
      _session = SessionModel(
        sessionId: activeId,
        classCode: classSection.classCode,
        sessionDate: classSection.timeLabel,
        slotCode: slotCode.isNotEmpty ? slotCode : classSection.slotCode,
        sessionStatus: 'open',
        qrToken: '',
      );
      _status = ViewStatus.success;
      _startPolling();
      await _rotateQr();
      notifyListeners();
      return;
    }

    // 3. Otherwise, create a brand new session on backend
    try {
      final result = await _repository.startSession(
        classCode: classSection.classCode,
        slotCode: slotCode,
        teacherIp: realIp,
      );

      switch (result) {
        case ApiSuccess<SessionModel>(:final data):
          _session = data;
          _status = ViewStatus.success;
          _sessionElapsedSeconds = 0;
          _startPolling();
          triggerToast(
            type: ToastType.startSession,
            title: 'Đã mở phiên điểm danh!',
            message:
                'Phiên điểm danh lớp ${classSection.classCode} (${classSection.subjectCode}) đã sẵn sàng.',
            icon: Icons.qr_code_scanner,
            accentColor: AppColors.statusPresent,
          );
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

        if (checkedInCount > prevChecked ||
            (_roster.isEmpty && data.where((s) => s.hasCheckedIn).isNotEmpty)) {
          // Find newly checked in student
          final newPresent = data
              .where(
                (s) =>
                    s.hasCheckedIn &&
                    !_roster.any(
                      (old) =>
                          old.rollNumber == s.rollNumber && old.hasCheckedIn,
                    ),
              )
              .toList();
          if (newPresent.isNotEmpty) {
            _lastCheckedInStudent = newPresent.first;
          } else if (data.isNotEmpty) {
            _lastCheckedInStudent = data.firstWhere(
              (s) => s.hasCheckedIn,
              orElse: () => data.first,
            );
          }

          if (_lastCheckedInStudent != null) {
            triggerToast(
              type: ToastType.checkin,
              title:
                  '${_lastCheckedInStudent!.displayName} (${_lastCheckedInStudent!.rollNumber})',
              message:
                  'Vừa điểm danh thành công lúc ${_lastCheckedInStudent!.displayCheckinTime}',
              icon: Icons.check_circle_outline,
              accentColor: AppColors.statusPresent,
              duration: const Duration(seconds: 3),
            );
          }
        }
        _roster = data;
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

  Future<void> _rotateQr() async {
    if (_session == null || isClosed) return;
    final result = await _repository.rotateQr(sessionId: _session!.sessionId);
    switch (result) {
      case ApiSuccess<String>(:final data):
        _session = SessionModel(
          sessionId: _session!.sessionId,
          classCode: _session!.classCode,
          sessionDate: _session!.sessionDate,
          slotCode: _session!.slotCode,
          sessionStatus: _session!.sessionStatus,
          qrToken: data,
        );
        notifyListeners();
      case ApiFailure<String>():
        // Keep the current QR when a background rotation request fails.
        break;
    }
  }

  Future<void> refreshQrNow() async {
    _qrRefreshSeconds = qrCycleDuration;
    await _rotateQr();
  }

  /// Manually mark multiple students
  Future<void> manualCheckinBulk(List<Map<String, dynamic>> changes) async {
    if (_session == null) return;
    _status = ViewStatus.loading;
    notifyListeners();

    final result = await _repository.manualCheckinBulk(
      sessionId: _session!.sessionId,
      changes: changes,
    );

    switch (result) {
      case ApiSuccess<void>():
        _status = ViewStatus.success;
        await loadRoster();
      case ApiFailure<void>(:final error):
        _errorMessage = error.message;
        _status = ViewStatus.error;
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

  /// Close the session on backend (closeSession API)
  /// Automatically marks absent students and updates sessionStatus to closed
  Future<bool> closeCurrentSession() async {
    if (_session == null) {
      return true;
    }

    _stopPolling();
    final sId = _session!.sessionId;
    _status = ViewStatus.loading;
    notifyListeners();

    try {
      final result = await _repository.closeSession(sessionId: sId);
      switch (result) {
        case ApiSuccess<CloseSessionResult>():
          if (_session != null) {
            _session = SessionModel(
              sessionId: _session!.sessionId,
              classCode: _session!.classCode,
              sessionDate: _session!.sessionDate,
              slotCode: _session!.slotCode,
              sessionStatus: 'closed',
              qrToken: _session!.qrToken,
            );
          }
          // Update all unchecked students in local roster to 'Absent'
          _roster = _roster.map((student) {
            if (student.isUnchecked) {
              return RosterEntryModel(
                rollNumber: student.rollNumber,
                memberCode: student.memberCode,
                email: student.email,
                fullName: student.fullName,
                recordId: student.recordId,
                sessionId: student.sessionId,
                checkinTime: student.checkinTime,
                status: 'Absent',
                networkVerificationResult: 'AutoAbsent',
                ipAddress: student.ipAddress,
                note: student.note,
              );
            }
            return student;
          }).toList();

          _status = ViewStatus.success;
          triggerToast(
            type: ToastType.closeSession,
            title: 'Đã kết thúc phiên điểm danh!',
            message: 'Hệ thống đã tự động ghi nhận Vắng mặt cho các sinh viên chưa check-in.',
            icon: Icons.check_circle_outline,
            accentColor: AppColors.statusPresent,
            duration: const Duration(seconds: 5),
          );

          // Reload roster to fetch actual saved records from backend
          await loadRoster();
          return true;
        case ApiFailure<CloseSessionResult>(:final error):
          _errorMessage = error.message;
          _status = ViewStatus.error;
          notifyListeners();
          return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = ViewStatus.error;
      notifyListeners();
      return false;
    }
    return false;
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
