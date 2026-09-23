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
              connectTimeout: kIsWeb ? null : const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 60),
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
        ...?payload,
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
      var response = await _dio.post(
        '',
        data: jsonEncode(requestBody),
        options: Options(
          // Dart's native HttpClient does not reliably follow a 302 after a
          // POST. Apps Script returns the JSON result through the Location URL,
          // so native platforms must follow that redirect with a GET.
          followRedirects: kIsWeb,
          responseType: kIsWeb ? null : ResponseType.plain,
          receiveTimeout: historyActions.contains(action)
              ? const Duration(seconds: 60)
              : null,
        ),
      );

      if (!kIsWeb &&
          response.statusCode != null &&
          response.statusCode! >= 300 &&
          response.statusCode! < 400) {
        final location = response.headers.value('location');
        if (location == null || location.trim().isEmpty) {
          return ApiFailure(
            ApiError(
              code: 'EMPTY_REDIRECT',
              message: 'Apps Script trả về redirect nhưng thiếu URL kết quả.',
            ),
          );
        }
        response = await _dio.getUri(
          Uri.parse(location),
          options: Options(
            followRedirects: true,
            responseType: ResponseType.plain,
            receiveTimeout: const Duration(seconds: 60),
          ),
        );
      }

      if (response.statusCode == 200) {
        // Dữ liệu từ Google thường là String, ta ép parse JSON
        final rawData = response.data;
        if (rawData == null || (rawData is String && rawData.trim().isEmpty)) {
          return ApiFailure(
            ApiError(
              code: 'EMPTY_RESPONSE',
              message: 'Apps Script không trả về dữ liệu. Vui lòng thử lại.',
            ),
          );
        }

        final data = rawData is String ? jsonDecode(rawData) : rawData;
        if (data is! Map<String, dynamic>) {
          return ApiFailure(
            ApiError(
              code: 'INVALID_RESPONSE',
              message: 'Apps Script trả về dữ liệu không đúng định dạng JSON.',
            ),
          );
        }
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
