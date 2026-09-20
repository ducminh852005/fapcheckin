import 'package:flutter/foundation.dart';

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

  void setSearch(String value) {
    searchQuery = value;
    _notify();
  }

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
  }
}
