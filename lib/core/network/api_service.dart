import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_response.dart';
import 'api_result.dart';

class ApiService {
  final Dio _dio;
  String? _sessionToken;

  // Override when using a different Apps Script deployment; requires a restart.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://script.google.com/macros/s/AKfycbwhbrv6Y76dGETuwDeMqObH1Dvf9RwQ5obDkxuuR-x5m2T3JoCByY0EuuB4ptuTHC3cwA/exec',
  );

  ApiService({Dio? client})
    : _dio =
          client ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl,
              // Dio tracks connectTimeout with an XHR upload listener on web.
              // That forces a CORS preflight even for text/plain POST requests,
              // which the Apps Script endpoint cannot handle.
              connectTimeout: kIsWeb ? null : const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              // Bắt buộc text/plain để né lỗi với Google Apps Script (e.postData.contents)
              contentType: 'text/plain;charset=utf-8',
              // Google Script luôn redirect 302 sau khi nhận POST
              followRedirects: true,
              validateStatus: (status) => status != null && status < 500,
            ),
          );

  void setSessionToken(String token) {
    _sessionToken = token;
  }

  void clearSessionToken() {
    _sessionToken = null;
  }

  Future<ApiResult<T>> postAction<T>(
    String action, {
    Map<String, dynamic>? payload,
    T Function(dynamic)? fromJsonT,
  }) async {
    try {
      final requestBody = {
        'action': action,
        if (_sessionToken != null) 'sessionToken': _sessionToken,
        if (payload != null) ...payload,
      };

      // Đảm bảo gửi chuỗi JSON thô
      const historyActions = {
        'getScheduleOptions',
        'getClassSchedules',
        'createClassSchedule',
        'getHistoryClasses',
        'getHistoryDetail',
        'getAttendanceMatrix',
        'saveAttendanceChanges',
        'exportAttendanceHistory',
        'startHistorySession',
      };
      final response = await _dio.post(
        '',
        data: jsonEncode(requestBody),
        options: historyActions.contains(action)
            ? Options(receiveTimeout: const Duration(seconds: 60))
            : null,
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        // Dữ liệu từ Google thường là String, ta ép parse JSON
        final data = response.data is String
            ? jsonDecode(response.data)
            : response.data;
        final apiResponse = ApiResponse<T>.fromJson(data, fromJsonT: fromJsonT);

        if (apiResponse.success) {
          // Trường hợp API trả về null data nhưng vẫn success (VD: logout)
          if (apiResponse.data == null && fromJsonT == null) {
            return ApiSuccess(null as T);
          }
          if (apiResponse.data != null) {
            return ApiSuccess(apiResponse.data as T);
          }
          return ApiFailure(
            ApiError(
              code: 'PARSE_ERROR',
              message: 'Không thể xử lý dữ liệu trả về',
            ),
          );
        } else {
          if (apiResponse.error?.code == 'UNKNOWN_ACTION') {
            return ApiFailure(
              ApiError(
                code: 'BACKEND_UPDATE_REQUIRED',
                message:
                    'Backend đang chạy chưa có API "$action". '
                    'Cần cập nhật source Apps Script và Deploy → Manage deployments '
                    '→ Edit → New version → Deploy trên đúng URL ứng dụng đang dùng. '
                    'Sau đó khởi động lại ứng dụng và đăng nhập lại.',
              ),
            );
          }
          return ApiFailure(
            apiResponse.error ??
                ApiError(
                  code: 'API_ERROR',
                  message: 'Lỗi không xác định từ server',
                ),
          );
        }
      } else {
        return ApiFailure(
          ApiError(
            code: 'HTTP_ERROR_${response.statusCode}',
            message: 'Không thể kết nối máy chủ',
          ),
        );
      }
    } on DioException catch (e) {
      return ApiFailure(
        ApiError(
          code: 'NETWORK_ERROR',
          message: e.message ?? 'Lỗi mạng hoặc kết nối',
        ),
      );
    } catch (e) {
      return ApiFailure(ApiError(code: 'EXCEPTION', message: e.toString()));
    }
  }
}
