class ApiError {
  final String code;
  final String message;

  ApiError({required this.code, required this.message});
}

abstract class ApiResult<T> {}

class ApiSuccess<T> extends ApiResult<T> {
  final T data;
  ApiSuccess(this.data);
}

class ApiFailure<T> extends ApiResult<T> {
  final ApiError error;
  ApiFailure(this.error);
}
