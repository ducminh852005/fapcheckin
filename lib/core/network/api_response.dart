class ApiResponse<T> {
  final bool success;
  final T? data;
  final ApiError? error;

  ApiResponse({required this.success, this.data, this.error});

  factory ApiResponse.fromJson(Map<String, dynamic> json, {T Function(dynamic)? fromJsonT}) {
    return ApiResponse(
      success: json['success'] ?? false,
      data: (json['data'] != null && fromJsonT != null) ? fromJsonT(json['data']) : json['data'],
      error: json['error'] != null ? ApiError.fromJson(json['error']) : null,
    );
  }
}

class ApiError {
  final String code;
  final String message;

  ApiError({required this.code, required this.message});

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json['code'] ?? 'UNKNOWN_ERROR',
      message: json['message'] ?? 'Đã xảy ra lỗi không xác định',
    );
  }
}
