import 'dart:convert';

import 'package:dio/dio.dart';

import 'api_response.dart';
import 'api_result.dart';

class ApiService {
  final Dio _dio;
  String? _sessionToken;

  // Thay bằng URL Web App thực tế
  static const String _baseUrl =
      'https://script.google.com/macros/s/AKfycbwhbrv6Y76dGETuwDeMqObH1Dvf9RwQ5obDkxuuR-x5m2T3JoCByY0EuuB4ptuTHC3cwA/exec';

  ApiService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 15),
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
      final response = await _dio.post('', data: jsonEncode(requestBody));

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
