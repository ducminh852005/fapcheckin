import '../../core/network/api_result.dart';
import '../../core/network/api_service.dart';
import '../models/auth_session_model.dart';

class AuthRepository {
  final ApiService _api;

  AuthRepository(this._api);

  Future<ApiResult<AuthSessionModel>> loginWithGoogleIdToken({
    required String idToken,
  }) {
    return _api.postAction<AuthSessionModel>(
      'login',
      payload: {'idToken': idToken},
      fromJsonT: (data) =>
          AuthSessionModel.fromJson(data as Map<String, dynamic>),
    );
  }

  void attachSessionToken(String token) {
    _api.setSessionToken(token);
  }

  void clearSessionToken() {
    _api.clearSessionToken();
  }
}
