import 'api_response.dart';

abstract class ApiResult<T> {}

class ApiSuccess<T> extends ApiResult<T> {
  final T data;
  ApiSuccess(this.data);
}

class ApiFailure<T> extends ApiResult<T> {
  final ApiError error;
  ApiFailure(this.error);
}
