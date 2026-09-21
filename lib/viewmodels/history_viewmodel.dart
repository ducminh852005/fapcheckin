import 'package:flutter/foundation.dart';

import '../data/models/history_models.dart';
import '../data/repositories/history_repository.dart';

enum HistoryViewState { idle, loading, ready, error }

/// ViewModel cho trang "Lịch sử điểm danh".
///
/// Điểm khác biệt lớn nhất so với [TeacherSessionViewModel]: sửa dữ liệu ở
/// đây được gom lại thành 1 lần "Lưu" duy nhất (batch), KHÔNG gửi API ngay
/// mỗi khi GV gõ 1 ký tự hay đổi 1 dropdown. Lý do: Backend dùng
/// `LockService.getScriptLock()` — Google Apps Script chỉ cho phép 1 lần
/// ghi Sheet chạy tại 1 thời điểm cho cả script, các request khác phải xếp
/// hàng chờ. Nếu mỗi ô sửa gửi 1 request riêng, sửa 20 SV sẽ tạo ra 20 lần
/// xếp hàng chờ khoá, rất chậm. Gom thành 1 mảng `changes` rồi gửi 1 lần
/// (đúng như `saveChanges()` phía Backend được thiết kế để nhận) nhanh hơn
/// nhiều.
class HistoryViewModel extends ChangeNotifier {
  HistoryViewModel(this._repository);

  final HistoryRepository _repository;

  HistoryViewState state = HistoryViewState.idle;
  String? errorMessage;

  List<ClassSummaryModel> classes = [];
  String? selectedClassCode;
  ClassHistoryDetailModel? detail;

  bool isSavingChanges = false;
  bool isLoadingMatrix = false;
  AttendanceMatrixModel? matrix;
  bool showMatrix = false;

  /// Các dòng đang được GV sửa nhưng CHƯA lưu — key là rollNumber. Dùng
  /// Map riêng thay vì sửa thẳng vào `detail.students` để có thể huỷ
  /// (Hủy thay đổi) hoặc phát hiện "còn thay đổi chưa lưu" dễ dàng.
  final Map<String, StudentHistoryModel> _pendingEdits = {};

  bool get hasPendingChanges => _pendingEdits.isNotEmpty;

  /// Danh sách sinh viên để HIỂN THỊ — ưu tiên bản đang sửa (pending) nếu có,
  /// ngược lại lấy bản gốc từ [detail].
  List<StudentHistoryModel> get displayedStudents {
    final original = detail?.students ?? [];
    return original.map((s) => _pendingEdits[s.rollNumber] ?? s).toList();
  }

  Future<void> loadClasses() async {
    state = HistoryViewState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      classes = await _repository.fetchClasses();
      state = HistoryViewState.ready;
    } catch (e) {
      state = HistoryViewState.error;
      errorMessage = 'Không tải được danh sách lớp: $e';
    }
    notifyListeners();
  }

  Future<void> selectClass(String classCode) async {
    selectedClassCode = classCode;
    _pendingEdits.clear();
    showMatrix = false;
    matrix = null;
    await _loadDetail(classCode: classCode);
  }

  Future<void> selectSession(String sessionId) async {
    final classCode = selectedClassCode;
    if (classCode == null) return;
    _pendingEdits.clear();
    await _loadDetail(classCode: classCode, sessionId: sessionId);
  }

  Future<void> _loadDetail({
    required String classCode,
    String? sessionId,
  }) async {
    state = HistoryViewState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      detail = await _repository.fetchDetail(
        classCode: classCode,
        sessionId: sessionId,
      );
      state = HistoryViewState.ready;
    } catch (e) {
      state = HistoryViewState.error;
      errorMessage = 'Không tải được chi tiết lớp: $e';
    }
    notifyListeners();
  }

  /// Ghi nhận thay đổi TẠM THỜI khi GV đổi dropdown trạng thái — chưa gửi API.
  void editStatus(String rollNumber, String newStatus) {
    if (detail?.selectedSession == null || isSavingChanges) return;
    final original = detail?.students.firstWhere(
      (s) => s.rollNumber == rollNumber,
    );
    if (original == null) return;
    final current = _pendingEdits[rollNumber] ?? original;
    _pendingEdits[rollNumber] = current.copyWith(status: newStatus);
    notifyListeners();
  }

  /// Tương tự [editStatus] nhưng cho ô ghi chú.
  void editNote(String rollNumber, String newNote) {
    if (detail?.selectedSession == null || isSavingChanges) return;
    final original = detail?.students.firstWhere(
      (s) => s.rollNumber == rollNumber,
    );
    if (original == null) return;
    final current = _pendingEdits[rollNumber] ?? original;
    _pendingEdits[rollNumber] = current.copyWith(note: newNote);
    notifyListeners();
  }

  void discardPendingChanges() {
    _pendingEdits.clear();
    notifyListeners();
  }

  /// Gửi TẤT CẢ thay đổi đang chờ lên Backend trong 1 lần gọi `saveChanges`.
  Future<void> savePendingChanges() async {
    final classCode = selectedClassCode;
    final sessionId = detail?.selectedSession?.sessionId;
    if (classCode == null || sessionId == null || _pendingEdits.isEmpty) return;

    isSavingChanges = true;
    errorMessage = null;
    notifyListeners();

    // revision phải lấy từ bản GỐC (trước khi sửa) — đây chính là "vân tay"
    // Backend dùng để phát hiện xung đột, KHÔNG lấy từ bản đang sửa.
    final changes = _pendingEdits.entries.map((entry) {
      final original = detail!.students.firstWhere(
        (s) => s.rollNumber == entry.key,
      );
      return AttendanceChange(
        rollNumber: entry.key,
        status: entry.value.status,
        note: entry.value.note,
        revision: original.revision,
      );
    }).toList();

    try {
      detail = await _repository.saveChanges(
        classCode: classCode,
        sessionId: sessionId,
        changes: changes,
      );
      _pendingEdits.clear();
    } on BackendException catch (e) {
      if (e.code == 'CONFLICT') {
        // Ai đó (có thể chính GV mở 2 tab) đã sửa trong lúc mình đang xem —
        // KHÔNG được âm thầm ghi đè. Tải lại dữ liệu mới nhất và báo GV xem
        // lại thay vì cố lưu lần nữa với dữ liệu cũ.
        errorMessage = 'Dữ liệu đã bị thay đổi bởi nơi khác. Đã tải lại bản mới nhất, vui lòng kiểm tra và sửa lại.';
        _pendingEdits.clear();
        await _loadDetail(classCode: classCode, sessionId: sessionId);
      } else {
        errorMessage = e.message;
      }
    } catch (e) {
      errorMessage = 'Lưu thất bại: $e';
    }

    isSavingChanges = false;
    notifyListeners();
  }

  Future<void> toggleMatrix() async {
    showMatrix = !showMatrix;
    if (showMatrix && matrix == null && selectedClassCode != null) {
      isLoadingMatrix = true;
      notifyListeners();
      try {
        matrix = await _repository.fetchMatrix(classCode: selectedClassCode!);
      } catch (e) {
        errorMessage = 'Không tải được ma trận điểm danh: $e';
      }
      isLoadingMatrix = false;
    }
    notifyListeners();
  }

  Future<HistoryExportModel?> exportCurrentSession() async {
    final classCode = selectedClassCode;
    if (classCode == null) return null;
    try {
      return await _repository.exportHistory(
        classCode: classCode,
        sessionId: detail?.selectedSession?.sessionId,
      );
    } catch (e) {
      errorMessage = 'Xuất Excel thất bại: $e';
      notifyListeners();
      return null;
    }
  }

  Future<void> startNewSession(String slotCode, String teacherIp) async {
    final classCode = selectedClassCode;
    if (classCode == null || isSavingChanges || hasPendingChanges) return;

    try {
      await _repository.startSession(
        classCode: classCode,
        slotCode: slotCode,
        teacherIp: teacherIp,
      );
      await _loadDetail(classCode: classCode);
    } on BackendException catch (e) {
      errorMessage = e.code == 'SESSION_ALREADY_OPEN'
          ? 'Lớp này đang có 1 buổi học mở sẵn — kết thúc buổi đó trước khi mở buổi mới.'
          : e.message;
      notifyListeners();
    } catch (e) {
      errorMessage = 'Không mở được buổi học mới: $e';
      notifyListeners();
    }
  }
}
