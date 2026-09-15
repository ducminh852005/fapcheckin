/// Xây dựng nội dung sẽ được mã hoá vào mã QR.
///
/// Mã QR KHÔNG chứa dữ liệu điểm danh — nó chỉ là một đường link (URL) trỏ
/// tới trang web check-in của sinh viên, kèm theo sessionId và qrToken hiện
/// tại. Token do Backend cấp và xoay vòng (xem SessionModel), nên class này
/// chỉ có nhiệm vụ ghép chuỗi URL, không tự "sinh" token.
class QrService {
  // TODO(Nền tảng/Backend): thay bằng URL deploy thật của Apps Script Web App
  // (Deploy > Web app > Copy URL) khi Thành viên 1 hoàn thành Backend.
  static const String checkinWebBaseUrl =
      'https://script.google.com/macros/s/REPLACE_WITH_DEPLOYMENT_ID/exec';

  String buildCheckinUrl({required String sessionId, required String qrToken}) {
    final uri = Uri.parse(checkinWebBaseUrl).replace(queryParameters: {
      'page': 'checkin',
      'sessionId': sessionId,
      'token': qrToken,
    });
    return uri.toString();
  }
}
