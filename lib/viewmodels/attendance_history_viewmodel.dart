import 'package:flutter/foundation.dart';
<<<<<<< HEAD
import '../core/network/api_result.dart';
import '../data/models/attendance_history_model.dart';
import '../data/models/class_section_model.dart';
import '../data/models/history_class.dart';
import '../data/models/history_student.dart';
import '../data/models/session_model.dart';
import '../data/models/student_checkin.dart';
import '../data/repositories/teacher_repository.dart';

class AttendanceHistoryViewModel extends ChangeNotifier {
  final TeacherRepository _repository;

  AttendanceHistoryViewModel(this._repository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Fallback / Initial classes
  List<HistoryClass> _classes = [
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
  ];
  List<HistoryClass> get classes => _classes;

  String? _selectedClassCode = 'SWP391';
  String? get selectedClassCode => _selectedClassCode;

  // Real session models from API
  List<SessionModel> _sessionModels = [];
  List<SessionModel> get sessionModels => _sessionModels;

  // Sessions formatted for UI
  List<Map<String, dynamic>> _sessions = [
    {'slot': 1, 'date': 'Buổi 1', 'sessionId': '', 'isActive': false},
  ];
  List<Map<String, dynamic>> get sessions => _sessions;

  int _selectedSessionSlot = 1;
  int get selectedSessionSlot => _selectedSessionSlot;
  String? _selectedSessionId;
  String? get selectedSessionId => _selectedSessionId;
=======

import '../core/network/api_result.dart';
import '../data/models/history_class.dart';
import '../data/models/history_detail.dart';
import '../data/models/history_student.dart';
import '../data/models/session_model.dart';
import '../data/repositories/attendance_history_repository.dart';

class AttendanceHistoryViewModel extends ChangeNotifier {
  final AttendanceHistoryRepository repository;
  AttendanceHistoryViewModel(this.repository);
  List<HistoryClass> classes = [];
  HistoryDetail? detail;
  String? selectedClassCode;
  String? errorMessage;
  String searchQuery = '', classQuery = '', statusFilter = 'all';
  bool loadingClasses = false,
      loadingDetail = false,
      saving = false,
      working = false;
  final Map<String, HistoryStudent> _edits = {};
  int _generation = 0;
  bool _disposed = false;
  String? _accountToken;
  bool get hasChanges => _edits.isNotEmpty;
  bool get busy => loadingClasses || loadingDetail || saving || working;
  List<HistoryClass> get visibleClasses => classes
      .where(
        (c) => '${c.classCode} ${c.subjectName}'.toLowerCase().contains(
          classQuery.toLowerCase(),
        ),
      )
      .toList();
  List<HistoryStudent> get students =>
      (detail?.students ?? []).map((s) => _edits[s.rollNumber] ?? s).toList();
  List<HistoryStudent> get filteredStudents => students
      .where(
        (s) =>
            (statusFilter == 'all' ||
                (statusFilter == 'Present'
                    ? ['Present', 'ManualByGV'].contains(s.status)
                    : s.status == statusFilter)) &&
            '${s.rollNumber} ${s.fullName} ${s.email}'.toLowerCase().contains(
              searchQuery.toLowerCase(),
            ),
      )
      .toList();
  int count(String status) => students
      .where(
        (s) => status == 'Present'
            ? ['Present', 'ManualByGV'].contains(s.status)
            : s.status == status,
      )
      .length;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void bindAccount(String? token) {
    if (_accountToken == token) return;
    _accountToken = token;
    _generation++;
    classes = [];
    detail = null;
    selectedClassCode = null;
    _edits.clear();
    loadingClasses = loadingDetail = saving = working = false;
    errorMessage = null;
    searchQuery = classQuery = '';
    statusFilter = 'all';
    _notify();
  }
>>>>>>> origin/dev

  void setSearch(String value) {
    searchQuery = value;
    _notify();
  }

<<<<<<< HEAD
  // Real students from API
  List<HistoryStudent> _students = [];
  List<HistoryStudent> get students => _students;

  /// Updates class list from Teacher's classes
  void setTeacherClasses(List<ClassSectionModel> teacherClasses) {
    if (teacherClasses.isEmpty) return;
    _classes = teacherClasses.map((c) {
      return HistoryClass(
        courseCode: c.classCode,
        className: c.classCode,
        courseName: c.subjectName,
        attendanceRate: 1.0,
        completedSessions: 0,
        totalSessions: 30,
        latestSessionDate: 'Học kỳ Fall 23',
        latestSessionName: 'Phòng ${c.room}',
        isActive: true,
      );
    }).toList();

    if (_selectedClassCode == null ||
        !_classes.any((c) => c.courseCode == _selectedClassCode)) {
      _selectedClassCode = _classes.first.courseCode;
    }
    notifyListeners();

    if (_selectedClassCode != null) {
      loadHistoryForClass(_selectedClassCode!);
    }
  }

  /// Select class and load its sessions + attendance history from API
  Future<void> selectClass(String code) async {
    _selectedClassCode = code;
    notifyListeners();
    await loadHistoryForClass(code);
  }

  /// Load sessions & attendance history for a given class
  Future<void> loadHistoryForClass(String classCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Fetch sessions for this class (getSessions API)
      final sessionResult = await _repository.getSessions(classCode: classCode);
      if (sessionResult is ApiSuccess<List<SessionModel>>) {
        _sessionModels = sessionResult.data;
        if (_sessionModels.isNotEmpty) {
          _sessions = _sessionModels.asMap().entries.map((entry) {
            final idx = entry.key;
            final s = entry.value;
            final slotNum = int.tryParse(s.slotCode) ?? (idx + 1);
            return {
              'slot': slotNum,
              'date': s.sessionDate.isNotEmpty ? s.sessionDate : 'Buổi $slotNum',
              'sessionId': s.sessionId,
              'isActive': s.isOpen,
            };
          }).toList();

          _selectedSessionId = _sessionModels.first.sessionId;
          _selectedSessionSlot = _sessions.first['slot'] as int;
        } else {
          _sessions = [
            {'slot': 1, 'date': 'Chưa có phiên', 'sessionId': '', 'isActive': false}
          ];
          _selectedSessionId = null;
          _selectedSessionSlot = 1;
        }
      }

      // 2. Fetch attendance history for this class + selected session (getAttendanceHistory API)
      final historyResult = await _repository.getAttendanceHistory(
        classCode: classCode,
        sessionId: _selectedSessionId,
      );

      if (historyResult is ApiSuccess<AttendanceHistoryResult>) {
        final data = historyResult.data;
        _students = data.students.asMap().entries.map((entry) {
          return entry.value.toHistoryStudent(entry.key + 1);
        }).toList();
      } else if (historyResult is ApiFailure<AttendanceHistoryResult>) {
        _errorMessage = historyResult.error.message;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select specific session slot and fetch history for that session
  Future<void> selectSession(int slot) async {
    _selectedSessionSlot = slot;
    final found = _sessions.firstWhere(
      (s) => s['slot'] == slot,
      orElse: () => <String, dynamic>{},
    );
    _selectedSessionId = found['sessionId'] as String?;
    notifyListeners();

    if (_selectedClassCode != null) {
      _isLoading = true;
      notifyListeners();

      try {
        final historyResult = await _repository.getAttendanceHistory(
          classCode: _selectedClassCode!,
          sessionId: _selectedSessionId,
        );

        if (historyResult is ApiSuccess<AttendanceHistoryResult>) {
          _students = historyResult.data.students.asMap().entries.map((entry) {
            return entry.value.toHistoryStudent(entry.key + 1);
          }).toList();
        }
      } catch (e) {
        _errorMessage = e.toString();
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  List<HistoryStudent> get filteredStudents {
    if (_statusFilter == 'all') return _students;
    if (_statusFilter == 'present') {
      return _students.where((s) => s.status == CheckinStatus.present).toList();
    }
    if (_statusFilter == 'late') {
      return _students.where((s) => s.status == CheckinStatus.late).toList();
    }
    if (_statusFilter == 'absent') {
      return _students
          .where((s) =>
              s.status == CheckinStatus.absent ||
              s.status == CheckinStatus.unchecked)
          .toList();
    }
    return _students;
=======
  void setClassSearch(String value) {
    classQuery = value;
    _notify();
  }

  void setStatusFilter(String value) {
    statusFilter = value;
    _notify();
  }

  void discardChanges() {
    _edits.clear();
    _notify();
  }

  void edit(HistoryStudent student, String status, String note) {
    if (busy || detail?.selectedSession == null) return;
    final original = detail!.students.firstWhere(
      (s) => s.rollNumber == student.rollNumber,
    );
    if (original.status == status && original.note == note) {
      _edits.remove(student.rollNumber);
    } else {
      _edits[student.rollNumber] = original.edit(status: status, note: note);
    }
    _notify();
  }

  Future<void> loadClasses() async {
    if (busy || hasChanges) return;
    final generation = ++_generation;
    loadingClasses = true;
    errorMessage = null;
    _notify();
    final result = await repository.getClasses();
    if (_disposed || generation != _generation) return;
    loadingClasses = false;
    switch (result) {
      case ApiSuccess<List<HistoryClass>>(:final data):
        classes = data;
        final code = data.any((c) => c.classCode == selectedClassCode)
            ? selectedClassCode
            : data.firstOrNull?.classCode;
        if (code == null) {
          detail = null;
          selectedClassCode = null;
        } else {
          await selectClass(code);
        }
      case ApiFailure<List<HistoryClass>>(:final error):
        errorMessage = error.message;
    }
    _notify();
  }

  Future<void> selectClass(String code) async {
    if (saving || working || hasChanges) return;
    selectedClassCode = code;
    searchQuery = '';
    statusFilter = 'all';
    await _loadDetail();
  }

  Future<void> selectSession(String id) async {
    if (busy || hasChanges) return;
    await _loadDetail(sessionId: id);
  }

  Future<void> _loadDetail({String? sessionId}) async {
    final code = selectedClassCode;
    if (code == null) return;
    final generation = ++_generation;
    loadingDetail = true;
    detail = null;
    errorMessage = null;
    _notify();
    final result = await repository.getDetail(code, sessionId: sessionId);
    if (_disposed || generation != _generation) return;
    loadingDetail = false;
    switch (result) {
      case ApiSuccess<HistoryDetail>(:final data):
        _accept(data);
      case ApiFailure<HistoryDetail>(:final error):
        errorMessage = error.message;
    }
    _notify();
  }

  void _accept(HistoryDetail data) {
    detail = data;
    classes = classes
        .map(
          (c) => c.classCode == data.classInfo.classCode ? data.classInfo : c,
        )
        .toList();
  }

  Future<bool> saveChanges() async {
    if (busy || !hasChanges || detail?.selectedSession == null) return false;
    final generation = _generation;
    saving = true;
    errorMessage = null;
    _notify();
    final result = await repository.save(
      selectedClassCode!,
      detail!.selectedSession!.sessionId,
      _edits.values
          .map(
            (s) => <String, dynamic>{
              'rollNumber': s.rollNumber,
              'status': s.status,
              'note': s.note,
              'revision': s.revision,
            },
          )
          .toList(),
    );
    if (_disposed || generation != _generation) return false;
    saving = false;
    switch (result) {
      case ApiSuccess<HistoryDetail>(:final data):
        _edits.clear();
        _accept(data);
        _notify();
        return true;
      case ApiFailure<HistoryDetail>(:final error):
        errorMessage = error.message;
        _notify();
        return false;
    }
    return false;
  }

  Future<T?> _operation<T>(Future<ApiResult<T>> Function() call) async {
    if (busy || hasChanges || selectedClassCode == null) return null;
    final generation = _generation;
    working = true;
    errorMessage = null;
    _notify();
    final result = await call();
    if (_disposed || generation != _generation) return null;
    working = false;
    switch (result) {
      case ApiSuccess<T>(:final data):
        _notify();
        return data;
      case ApiFailure<T>(:final error):
        errorMessage = error.message;
        _notify();
        return null;
    }
    return null;
  }

  Future<AttendanceMatrix?> loadMatrix() =>
      _operation(() => repository.getMatrix(selectedClassCode!));
  Future<HistoryExport?> export() => _operation(
    () => repository.export(
      selectedClassCode!,
      detail?.selectedSession?.sessionId,
    ),
  );
  Future<SessionModel?> startSession(String slot, String ip) =>
      _operation(() => repository.startSession(selectedClassCode!, slot, ip));
  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
>>>>>>> origin/dev
  }
}
