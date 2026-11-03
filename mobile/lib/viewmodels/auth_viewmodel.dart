import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:fapcheckin_core/result/api_result.dart';

import '../core/services/google_auth_service.dart';

import 'package:fapcheckin_core/models/auth_session_model.dart';
import 'package:fapcheckin_core/repositories/auth_repository.dart';

import './live_session_viewmodel.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repository;
  final GoogleAuthService _googleAuthService;

  AuthViewModel(
    this._repository,
    this._googleAuthService, {
    bool initialRestoring = false,
  }) : _isRestoringSession = initialRestoring;

  bool _isRestoringSession;
  bool get isRestoringSession => _isRestoringSession;

  AuthSessionModel? _session;
  AuthSessionModel? get session => _session;

  @visibleForTesting
  void setSessionForTesting(AuthSessionModel? session) {
    _session = session;
    _status = session != null ? ViewStatus.success : ViewStatus.idle;
    notifyListeners();
  }

  ViewStatus _status = ViewStatus.idle;
  ViewStatus get status => _status;
  bool get isLoading => _status == ViewStatus.loading;
  bool get isAuthenticated => _session != null;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Stream<GoogleSignInAuthenticationEvent> get googleAuthenticationEvents =>
      _googleAuthService.authenticationEvents;

  Future<void> initializeGoogleSignIn() {
    return _googleAuthService.initialize();
  }

  /// Khôi phục phiên Firebase đã lưu trên thiết bị (gọi một lần khi mở app).
  Future<void> restoreSession() async {
    _isRestoringSession = true;
    _status = ViewStatus.loading;
    notifyListeners();
    try {
      final result = await _repository.restoreSession();
      _status = ViewStatus.idle;
      if (result is ApiSuccess<AuthSessionModel?>) {
        final data = result.data;
        if (data != null && (data.user.isTeacher || data.user.role == 'user')) {
          _session = data;
          _status = ViewStatus.success;
        } else if (data != null) {
          await _repository.signOut();
        }
      }
      if (result is ApiFailure<AuthSessionModel?>) {
        _errorMessage = result.error.message;
        _status = ViewStatus.error;
      }
    } finally {
      _isRestoringSession = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithGoogle() async {
    _status = ViewStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final idToken = await _googleAuthService.signInAndGetIdToken();
      return await _loginWithIdToken(idToken);
    } on GoogleSignInException catch (e) {
      _status = ViewStatus.error;
      _errorMessage = _googleSignInErrorMessage(e);
      notifyListeners();
      return false;
    } catch (e) {
      _status = ViewStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithGoogleIdToken(String idToken) async {
    final trimmedToken = idToken.trim();
    if (trimmedToken.isEmpty) {
      _status = ViewStatus.error;
      _errorMessage = 'Vui lòng nhập Google ID Token để đăng nhập.';
      notifyListeners();
      return false;
    }

    return _loginWithIdToken(trimmedToken);
  }

  Future<bool> loginWithGoogleAccount(GoogleSignInAccount account) {
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      _status = ViewStatus.error;
      _errorMessage = 'Google không trả về idToken để xác thực.';
      notifyListeners();
      return Future.value(false);
    }

    return _loginWithIdToken(idToken);
  }

  Future<bool> _loginWithIdToken(String idToken) async {
    _status = ViewStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.loginWithGoogleIdToken(idToken: idToken);

    if (result is ApiSuccess<AuthSessionModel>) {
      final data = result.data;
      if (!data.user.isTeacher && data.user.role != 'user') {
        _status = ViewStatus.error;
        _errorMessage = 'Tài khoản này không có quyền sử dụng ứng dụng.';
        await _repository.signOut();
        notifyListeners();
        return false;
      }
      _session = data;
      _status = ViewStatus.success;
      notifyListeners();
      return true;
    }

    if (result is ApiFailure<AuthSessionModel>) {
      _status = ViewStatus.error;
      _errorMessage = result.error.message;
      notifyListeners();
      return false;
    }

    _status = ViewStatus.error;
    _errorMessage = 'Không thể xử lý phản hồi đăng nhập.';
    notifyListeners();
    return false;
  }

  Future<bool> updateName(String name) async {
    final account = _session?.token;
    final result = await _repository.updateName(name);
    if (account != _session?.token) return false;
    switch (result) {
      case ApiSuccess<AuthSessionModel>(:final data):
        _session = data;
        _errorMessage = null;
        notifyListeners();
        return true;
      case ApiFailure<AuthSessionModel>(:final error):
        _errorMessage = error.message;
        notifyListeners();
        return false;
    }
    return false;
  }

  Future<bool> updateProfile(String name, String phone, String birthDate) async {
    final account = _session?.token;
    final result = await _repository.updateProfile(name: name, phone: phone, birthDate: birthDate);
    if (account != _session?.token) return false;
    if (result is ApiSuccess<AuthSessionModel>) { _session = result.data; _errorMessage = null; notifyListeners(); return true; }
    if (result is ApiFailure<AuthSessionModel>) _errorMessage = result.error.message;
    notifyListeners();
    return false;
  }

  Future<void> signOut() async {
    _session = null;
    _status = ViewStatus.idle;
    _errorMessage = null;
    try {
      await _repository.signOut();
    } catch (_) {
      // Firebase sign-out lỗi cũng không được chặn việc xóa phiên cục bộ.
    }
    try {
      await _googleAuthService.signOut();
    } catch (_) {
      // Local session cleanup should still succeed if platform sign-out fails.
    }
    notifyListeners();
  }

  String _googleSignInErrorMessage(GoogleSignInException error) {
    if (error.code == GoogleSignInExceptionCode.canceled) {
      return 'Bạn đã hủy đăng nhập Google.';
    }
    return error.description ?? 'Không thể đăng nhập bằng Google.';
  }
}
