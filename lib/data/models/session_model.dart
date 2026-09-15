enum SessionStatus { open, closed, expired }

extension SessionStatusX on SessionStatus {
  static SessionStatus fromSheetValue(String value) {
    switch (value.toLowerCase()) {
      case 'open':
        return SessionStatus.open;
      case 'closed':
        return SessionStatus.closed;
      case 'expired':
        return SessionStatus.expired;
      default:
        throw ArgumentError('Giá trị status không hợp lệ: $value');
    }
  }
}

/// Đại diện cho một buổi điểm danh (1 dòng trong sheet "Sessions").
///
/// Lưu ý: [qrToken] là giá trị NGẮN HẠN, đổi mỗi 20 giây do Backend cấp lại
/// (không phải app tự sinh) — đây là điểm quan trọng về bảo mật: nếu app tự
/// tính token, ai đọc được code app cũng đoán được token kế tiếp. Vì vậy
/// việc "xoay QR" ở phía Flutter chỉ là hỏi lại Backend token mới, chứ không
/// tự sinh ra token.
class SessionModel {
  final String sessionId;
  final String classId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final SessionStatus status;
  final String qrToken;
  final String teacherIp;

  const SessionModel({
    required this.sessionId,
    required this.classId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.qrToken,
    required this.teacherIp,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      sessionId: json['sessionId'] as String,
      classId: json['classId'] as String,
      date: DateTime.parse(json['date'] as String),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      status: SessionStatusX.fromSheetValue(json['status'] as String),
      qrToken: json['qrToken'] as String,
      teacherIp: json['teacherIp'] as String,
    );
  }

  /// Tạo bản sao với vài trường được thay đổi — dùng khi xoay QR (chỉ đổi
  /// qrToken) hoặc đóng phiên (chỉ đổi status), thay vì tạo lại object từ
  /// đầu và phải gõ lại toàn bộ các trường không đổi.
  SessionModel copyWith({String? qrToken, SessionStatus? status}) {
    return SessionModel(
      sessionId: sessionId,
      classId: classId,
      date: date,
      startTime: startTime,
      endTime: endTime,
      status: status ?? this.status,
      qrToken: qrToken ?? this.qrToken,
      teacherIp: teacherIp,
    );
  }
}
