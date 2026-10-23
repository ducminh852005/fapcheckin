import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'api_result.dart';

/// Lỗi nghiệp vụ do repository ném ra; [code] giữ nguyên các mã của API cũ
/// (VALIDATION_ERROR, FORBIDDEN, CONFLICT, ...) để ViewModel/View không đổi.
class ApiException implements Exception {
  ApiException(this.code, this.message);
  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}

/// Chạy [body] và đổi mọi lỗi thành [ApiFailure] (repository không bao giờ ném).
Future<ApiResult<T>> guardApi<T>(Future<T> Function() body) async {
  try {
    return ApiSuccess<T>(await body());
  } on ApiException catch (e) {
    return ApiFailure<T>(ApiError(code: e.code, message: e.message));
  } on FirebaseFunctionsException catch (e) {
    final details = e.details;
    final code = details is Map && details['code'] is String
        ? details['code'] as String
        : 'FUNCTION_ERROR';
    return ApiFailure<T>(
      ApiError(code: code, message: e.message ?? 'Không thể xử lý yêu cầu.'),
    );
  } on FirebaseAuthException catch (e) {
    return ApiFailure<T>(
      ApiError(code: 'INVALID_TOKEN', message: e.message ?? 'Đăng nhập không hợp lệ.'),
    );
  } on FirebaseException catch (e) {
    return ApiFailure<T>(_fromFirebase(e));
  } catch (e) {
    return ApiFailure<T>(ApiError(code: 'UNKNOWN_ERROR', message: e.toString()));
  }
}

ApiError _fromFirebase(FirebaseException e) {
  switch (e.code) {
    case 'permission-denied':
      return ApiError(
        code: 'FORBIDDEN',
        message: 'Bạn không có quyền thực hiện thao tác này.',
      );
    case 'unavailable':
    case 'deadline-exceeded':
      return ApiError(
        code: 'NETWORK_ERROR',
        message: 'Không kết nối được máy chủ. Kiểm tra mạng rồi thử lại.',
      );
    case 'already-exists':
      return ApiError(code: 'CONFLICT', message: 'Dữ liệu đã tồn tại.');
    case 'not-found':
      return ApiError(code: 'NOT_FOUND', message: 'Không tìm thấy dữ liệu.');
    case 'failed-precondition':
      return ApiError(
        code: 'DB_ERROR',
        message: e.message ?? 'Thiếu chỉ mục Firestore hoặc điều kiện không thỏa.',
      );
    default:
      return ApiError(code: 'DB_ERROR', message: e.message ?? e.code);
  }
}
