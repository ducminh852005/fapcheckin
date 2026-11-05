/// Cấu hình build-time (ghi đè bằng --dart-define).
class AppConfig {
  AppConfig._();

  /// Trang check-in của sinh viên trên Firebase Hosting (`https://<project>.web.app`).
  /// Mã QR có dạng `<checkinBaseUrl>/?s=<sessionId>&t=<qrSecret>&ic=<0|1>`.
  static const String _rawCheckinBaseUrl = String.fromEnvironment(
    'CHECKIN_BASE_URL',
    defaultValue: 'https://ducminh-41459.web.app',
  );

  static String get checkinBaseUrl => _rawCheckinBaseUrl.endsWith('/')
      ? _rawCheckinBaseUrl
      : '$_rawCheckinBaseUrl/';
}
