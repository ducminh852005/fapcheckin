import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/services/ip_service.dart';
import '../core/services/qr_service.dart';
import '../data/models/attendance_model.dart';
import '../data/models/class_model.dart';
import '../data/models/session_model.dart';
import '../data/repositories/attendance_repository.dart';

/// Trạng thái tải dữ liệu tổng quát — View dựa vào đây để quyết định hiển
/// thị loading/error/nội dung, thay vì phải tự suy luận qua nhiều cờ
/// boolean rời rạc (isLoading, hasError, hasData...) rất dễ mâu thuẫn nhau.
enum ViewState { idle, loading, ready, error }

/// ViewModel cho toàn bộ luồng điểm danh phía Giảng viên:
/// tạo phiên → xoay QR mỗi 20 giây → theo dõi roster gần-thời-gian-thực →
/// điểm danh tay dự phòng → thống kê chuyên cần.
///
/// ĐÚNG RANH GIỚI MVVM của tài liệu kiến trúc: class này KHÔNG import bất cứ
/// thứ gì liên quan tới Google Sheet/Apps Script — nó chỉ nói chuyện với
/// [AttendanceRepository] (một interface trừu tượng). Nhờ vậy:
///  - Bạn code & chạy thử toàn bộ 4 màn hình ngay hôm nay bằng
///    [MockAttendanceRepository], không cần chờ Backend.
///  - Khi Backend xong, chỉ đổi 1 dòng (dùng [ApiAttendanceRepository])
///    ở nơi khởi tạo ViewModel — không sửa gì trong file này.
///
/// Ghi chú phạm vi: phần "thống kê chuyên cần" theo sơ đồ thư mục gốc đáng
/// lẽ thuộc `history_viewmodel.dart`, nhưng vì yêu cầu công việc giới hạn ở
/// đúng file này + views/teacher/, nên `loadStats()` được gộp tạm vào đây.
/// Nếu sau này có thời gian, nên tách sang HistoryViewModel riêng cho đúng
/// nguyên tắc "mỗi ViewModel một trách nhiệm".
class TeacherSessionViewModel extends ChangeNotifier {
  TeacherSessionViewModel({
    required AttendanceRepository attendanceRepository,
    IpService? ipService,
    QrService? qrService,
    Duration qrRotationInterval = const Duration(seconds: 20),
    Duration rosterPollInterval = const Duration(seconds: 4),
  })  : _repository = attendanceRepository,
        _ipService = ipService ?? IpService(),
        _qrService = qrService ?? QrService(),
        _qrRotationInterval = qrRotationInterval,
        _rosterPollInterval = rosterPollInterval;

  final AttendanceRepository _repository;
  final IpService _ipService;
  final QrService _qrService;
  final Duration _qrRotationInterval;
  final Duration _rosterPollInterval;

  Timer? _qrTimer;
  Timer? _countdownTimer;
  Timer? _rosterTimer;

  ViewState state = ViewState.idle;
  String? errorMessage;

  SessionModel? _session;
  SessionModel? get session => _session;

  bool get isSessionOpen => _session?.status == SessionStatus.open;

  String? _qrPayload; // Chuỗi URL đã sẵn sàng để đưa vào QrImageView.
  String? get qrPayload => _qrPayload;

  int _secondsUntilNextRotation = 0;
  int get secondsUntilNextRotation => _secondsUntilNextRotation;

  List<AttendanceModel> _roster = [];
  List<AttendanceModel> get roster => List.unmodifiable(_roster);

  List<ClassAttendanceStat> _stats = [];
  List<ClassAttendanceStat> get stats => List.unmodifiable(_stats);

  /// Bước đầu của luồng "GV bấm điểm danh": lấy IP công khai của GV, nhờ
  /// Repository mở phiên mới, rồi khởi động 2 timer chạy song song —
  /// 1 timer xoay QR, 1 timer polling roster.
  Future<void> startSession(ClassModel classModel) async {
    state = ViewState.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final teacherIp = await _ipService.getPublicIp();
      final newSession = await _repository.startSession(
        classId: classModel.classId,
        teacherIp: teacherIp,
      );

      _session = newSession;
      _roster = [];
      _updateQrPayload(newSession.qrToken);
      state = ViewState.ready;
      notifyListeners();

      _startQrRotation();
      _startRosterPolling();
    } catch (e) {
      state = ViewState.error;
      errorMessage = 'Không thể mở phiên điểm danh: $e';
      notifyListeners();
    }
  }

  void _updateQrPayload(String qrToken) {
    final session = _session;
    if (session == null) return;
    _qrPayload = _qrService.buildCheckinUrl(
      sessionId: session.sessionId,
      qrToken: qrToken,
    );
  }

  /// Vì sao dùng `Timer.periodic` thay vì tính lại QR mỗi lần widget build:
  /// việc đổi token chỉ nên xảy ra đúng theo chu kỳ cố định (20 giây), không
  /// phụ thuộc vào việc UI có rebuild hay không. Tách timer khỏi UI giúp
  /// logic xoay QR sống độc lập trong ViewModel — test được bằng cách gọi
  /// thẳng các method, không cần dựng widget thật.
  void _startQrRotation() {
    _qrTimer?.cancel();
    _qrTimer = Timer.periodic(_qrRotationInterval, (_) => _rotateQr());
    _startCountdown();
  }

  Future<void> _rotateQr() async {
    final session = _session;
    if (session == null || session.status != SessionStatus.open) return;

    try {
      final newToken = await _repository.refreshQrToken(sessionId: session.sessionId);
      _session = session.copyWith(qrToken: newToken);
      _updateQrPayload(newToken);
      _secondsUntilNextRotation = _qrRotationInterval.inSeconds;
      notifyListeners();
    } catch (e) {
      // Xoay QR lỗi (mất mạng thoáng qua...) không nên làm sập cả màn hình —
      // giữ nguyên QR cũ, thử lại ở chu kỳ kế tiếp. SV vẫn quét được QR cũ
      // cho tới khi Backend thật sự coi nó hết hạn.
      debugPrint('Xoay QR thất bại, giữ token cũ: $e');
    }
  }

  /// Đếm ngược hiển thị cho GV biết còn bao lâu QR sẽ đổi. Đây thuần là
  /// hiệu ứng UI, KHÔNG quyết định thời điểm xoay token thật (việc đó do
  /// `_qrTimer` phụ trách) — tách riêng để nếu sau này đổi UI đếm ngược,
  /// không đụng vào logic bảo mật.
  void _startCountdown() {
    _countdownTimer?.cancel();
    _secondsUntilNextRotation = _qrRotationInterval.inSeconds;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _secondsUntilNextRotation =
          (_secondsUntilNextRotation - 1).clamp(0, _qrRotationInterval.inSeconds);
      notifyListeners();
    });
  }

  /// "Real-time" ở đây thực chất là POLLING (hỏi lại Backend theo chu kỳ
  /// ngắn), KHÔNG phải WebSocket/stream thật sự. Lý do: Apps Script Web App
  /// không giữ được kết nối mở lâu dài, nên "roster cập nhật dần" trong tài
  /// liệu kiến trúc được hiện thực bằng cách hỏi lại backend mỗi vài giây —
  /// đơn giản, đủ dùng cho quy mô 1 lớp học (~vài chục SV), không cần thêm
  /// hạ tầng (Firebase, socket server...).
  void _startRosterPolling() {
    _rosterTimer?.cancel();
    _rosterTimer = Timer.periodic(_rosterPollInterval, (_) => _refreshRoster());
    unawaited(_refreshRoster());
  }

  Future<void> _refreshRoster() async {
    final session = _session;
    if (session == null) return;
    try {
      final updated = await _repository.fetchRoster(sessionId: session.sessionId);
      _roster = updated;
      notifyListeners();
    } catch (e) {
      debugPrint('Không tải được roster: $e');
    }
  }

  /// Điểm danh tay dự phòng — dùng khi trang web check-in lỗi hoặc SV không
  /// có điện thoại (ưu tiên "PHẢI CÓ" theo tài liệu). Ghi method = manual để
  /// phân biệt rõ với method = qr khi xem lại lịch sử.
  Future<void> manualCheckIn({required String studentId, required String studentName}) async {
    final session = _session;
    if (session == null) return;

    try {
      await _repository.manualCheckIn(
        sessionId: session.sessionId,
        studentId: studentId,
        studentName: studentName,
      );
      await _refreshRoster();
    } catch (e) {
      errorMessage = 'Điểm danh tay thất bại: $e';
      notifyListeners();
    }
  }

  /// Kết thúc buổi học: dừng cả 2 timer trước, rồi mới báo Backend đóng
  /// phiên (để Backend tự sinh các dòng "Absent" cho SV chưa điểm danh).
  /// Dừng timer trước khi gọi API tránh trường hợp _rotateQr()/_refreshRoster()
  /// vẫn kịp chạy 1 lần nữa ngay sau khi phiên đã đóng.
  Future<void> closeSession() async {
    final session = _session;
    if (session == null) return;

    _qrTimer?.cancel();
    _countdownTimer?.cancel();
    _rosterTimer?.cancel();

    try {
      await _repository.closeSession(sessionId: session.sessionId);
      _session = session.copyWith(status: SessionStatus.closed);
      notifyListeners();
    } catch (e) {
      errorMessage = 'Không thể đóng phiên: $e';
      notifyListeners();
    }
  }

  /// Nạp dữ liệu cho ClassStatsScreen — % chuyên cần theo từng buổi của lớp.
  Future<void> loadStats(String classId) async {
    state = ViewState.loading;
    notifyListeners();
    try {
      _stats = await _repository.fetchAttendanceStats(classId: classId);
      state = ViewState.ready;
    } catch (e) {
      state = ViewState.error;
      errorMessage = 'Không tải được thống kê: $e';
    }
    notifyListeners();
  }

  /// BẮT BUỘC huỷ mọi Timer khi ViewModel bị dispose (ví dụ GV thoát màn
  /// hình điểm danh giữa chừng). Đây là lỗi rất phổ biến khi mới học Flutter:
  /// quên cancel() khiến Timer vẫn chạy ngầm dù màn hình đã đóng, vừa rò rỉ
  /// bộ nhớ vừa tốn API call vô ích (thậm chí gọi setState/notifyListeners
  /// trên 1 object đã "chết", có thể gây lỗi runtime).
  @override
  void dispose() {
    _qrTimer?.cancel();
    _countdownTimer?.cancel();
    _rosterTimer?.cancel();
    super.dispose();
  }
}
