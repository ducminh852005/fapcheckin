import 'package:flutter/foundation.dart';

import 'package:fapcheckin_core/result/api_result.dart';
import 'package:fapcheckin_core/models/history_class.dart';
import 'package:fapcheckin_core/models/history_detail.dart';
import 'package:fapcheckin_core/models/history_summary.dart';
import 'package:fapcheckin_core/models/session_model.dart';
import 'package:fapcheckin_core/repositories/attendance_history_repository.dart';

class AttendanceHistoryViewModel extends ChangeNotifier {
  final AttendanceHistoryRepository repository;
  AttendanceHistoryViewModel(this.repository);
  List<HistoryClass> classes = [];
  HistorySummary? summary;
  String? selectedClassCode;
  String? errorMessage;
  String searchQuery = '', classQuery = '', riskFilter = 'all';
  bool loadingClasses = false,
      loadingSummary = false,
      saving = false,
      working = false;
  List<HistoryClass>? _visibleClassesCache;
  List<StudentSummary>? _filteredStudentsCache;
  int _atRiskCount = 0;
  bool _derivedDirty = true;
  int _generation = 0;
  bool _disposed = false;
  String? _accountToken;
  bool get busy => loadingClasses || loadingSummary || saving || working;
  List<HistoryClass> get visibleClasses {
    _ensureDerived();
    return _visibleClassesCache!;
  }

  List<StudentSummary> get students => summary?.students ?? const [];

  List<StudentSummary> get filteredStudents {
    _ensureDerived();
    return _filteredStudentsCache!;
  }

  int get atRiskCount {
    _ensureDerived();
    return _atRiskCount;
  }

  void _markDerivedDirty() {
    _derivedDirty = true;
  }

  void _ensureDerived() {
    if (!_derivedDirty) return;
    final normalizedClassQuery = classQuery.trim().toLowerCase();
    final normalizedSearchQuery = searchQuery.trim().toLowerCase();
    final currentStudents = summary?.students ?? const <StudentSummary>[];

    _visibleClassesCache = classes
        .where(
          (c) => '${c.classCode} ${c.subjectName}'.toLowerCase().contains(
            normalizedClassQuery,
          ),
        )
        .toList(growable: false);
    _atRiskCount = currentStudents
        .where((student) => student.absenceRate > .2)
        .length;
    _filteredStudentsCache = currentStudents
        .where((student) {
          final matchesRisk = riskFilter == 'all' || student.absenceRate > .2;
          final matchesSearch =
              '${student.rollNumber} ${student.fullName} ${student.email}'
                  .toLowerCase()
                  .contains(normalizedSearchQuery);
          return matchesRisk && matchesSearch;
        })
        .toList(growable: false);
    _derivedDirty = false;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void bindAccount(String? token) {
    if (_accountToken == token) return;
    _accountToken = token;
    _generation++;
    classes = [];
    summary = null;
    selectedClassCode = null;
    loadingClasses = loadingSummary = saving = working = false;
    errorMessage = null;
    searchQuery = classQuery = '';
    riskFilter = 'all';
    _markDerivedDirty();
    _notify();
  }

  void setSearch(String value) {
    searchQuery = value;
    _markDerivedDirty();
    _notify();
  }

  void setClassSearch(String value) {
    classQuery = value;
    _markDerivedDirty();
    _notify();
  }

  void setRiskFilter(String value) {
    riskFilter = value;
    _markDerivedDirty();
    _notify();
  }

  Future<void> loadClasses({bool force = false}) async {
    if (busy) return;
    if (!force && classes.isNotEmpty && summary != null) return;
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
        _markDerivedDirty();
        final code = data.any((c) => c.classCode == selectedClassCode)
            ? selectedClassCode
            : data.firstOrNull?.classCode;
        if (code == null) {
          summary = null;
          selectedClassCode = null;
          _markDerivedDirty();
        } else {
          await selectClass(code);
        }
      case ApiFailure<List<HistoryClass>>(:final error):
        errorMessage = error.message;
    }
    _notify();
  }

  Future<void> selectClass(String code) async {
    // Deliberately not gated on loadingSummary/loadingClasses: switching
    // classes while a previous class's summary is still in flight must be
    // allowed so the generation check in _loadSummary can discard the
    // stale response instead of this call being silently dropped.
    if (saving || working) return;
    selectedClassCode = code;
    searchQuery = '';
    riskFilter = 'all';
    _markDerivedDirty();
    await _loadSummary();
  }

  void clearSelectedClass() {
    if (saving || working) return;
    selectedClassCode = null;
    summary = null;
    _markDerivedDirty();
    _notify();
  }

  Future<void> _loadSummary() async {
    final code = selectedClassCode;
    if (code == null) return;
    final generation = ++_generation;
    loadingSummary = true;
    errorMessage = null;
    _notify();
    final result = await repository.getSummary(code);
    if (_disposed || generation != _generation) return;
    loadingSummary = false;
    switch (result) {
      case ApiSuccess<HistorySummary>(:final data):
        _accept(data);
      case ApiFailure<HistorySummary>(:final error):
        errorMessage = error.message;
    }
    _notify();
  }

  void _accept(HistorySummary data) {
    summary = data;
    _markDerivedDirty();
    classes = classes
        .map(
          (c) => c.classCode == data.classInfo.classCode ? data.classInfo : c,
        )
        .toList();
    _markDerivedDirty();
  }

  Future<void> refreshSummary() async {
    if (busy || selectedClassCode == null) return;
    await _loadSummary();
  }

  Future<T?> _operation<T>(Future<ApiResult<T>> Function() call) async {
    if (busy || selectedClassCode == null) return null;
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

  /// Saves a single (session, student) attendance edit made from the matrix
  /// dialog, then refreshes both the matrix and the class-wide summary so
  /// the aggregate table reflects the change.
  Future<AttendanceMatrix?> saveMatrixCell({
    required String sessionId,
    required String rollNumber,
    required String status,
    required String note,
    required String revision,
  }) async {
    if (busy || selectedClassCode == null) return null;
    final classCode = selectedClassCode!;
    final generation = _generation;
    saving = true;
    errorMessage = null;
    _notify();
    final result = await repository.save(classCode, sessionId, [
      {
        'rollNumber': rollNumber,
        'status': status,
        'note': note,
        'revision': revision,
      },
    ]);
    if (_disposed || generation != _generation) return null;
    saving = false;
    switch (result) {
      case ApiSuccess<HistoryDetail>():
        // Calling _loadSummary() bumps the shared generation counter, so
        // the original `generation` captured above is no longer the right
        // token to gate on; only _disposed matters for these follow-ups.
        await _loadSummary();
        if (_disposed) return null;
        final matrix = await repository.getMatrix(classCode);
        if (_disposed) return null;
        _notify();
        switch (matrix) {
          case ApiSuccess<AttendanceMatrix>(:final data):
            return data;
          case ApiFailure<AttendanceMatrix>(:final error):
            errorMessage = error.message;
            _notify();
            return null;
        }
        return null;
      case ApiFailure<HistoryDetail>(:final error):
        errorMessage = error.message;
        _notify();
        return null;
    }
    return null;
  }

  Future<HistoryExport?> export() =>
      _operation(() => repository.export(selectedClassCode!, null));
  Future<SessionModel?> startSession(
    String slot,
    String ip, {
    bool ipCheck = false,
  }) => _operation(
    () =>
        repository.startSession(selectedClassCode!, slot, ip, ipCheck: ipCheck),
  );

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
