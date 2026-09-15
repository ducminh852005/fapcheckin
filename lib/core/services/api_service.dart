import 'package:dio/dio.dart';

/// Client Dio dùng chung để gọi Backend (Apps Script Web App).
///
/// Việc dựng client dùng chung (base URL, timeout, interceptor gắn token...)
/// đúng ra thuộc phần "Mobile GV — Nền tảng & Xác thực" (Thành viên 2). Đây
/// chỉ là bản tối giản để [AttendanceRepository]/[ClassRepository] của luồng
/// điểm danh có chỗ gọi vào ngay, không phải chờ Thành viên 2 xong mới code
/// được. Khi Thành viên 2 hoàn thiện bản thật, chỉ cần thay file này.
class ApiService {
  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }

  static final ApiService instance = ApiService._internal();
  late final Dio _dio;

  // TODO(Backend): thay bằng URL deploy thật của Apps Script Web App.
  static const String baseUrl =
      'https://script.google.com/macros/s/REPLACE_WITH_DEPLOYMENT_ID/exec';

  Dio get client => _dio;
}
