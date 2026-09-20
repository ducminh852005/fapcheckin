import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/auth_config.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn;
  bool _isInitialized = false;

  GoogleAuthService({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  Stream<GoogleSignInAuthenticationEvent> get authenticationEvents =>
      _googleSignIn.authenticationEvents;

  Future<void> initialize() => _ensureInitialized();

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    await _googleSignIn.initialize(
      clientId: AuthConfig.resolvedGoogleClientId,
      serverClientId:
          kIsWeb ? null : AuthConfig.resolvedGoogleServerClientId,
      hostedDomain: AuthConfig.resolvedGoogleHostedDomain,
    );
    _isInitialized = true;
  }

  Future<String> signInAndGetIdToken() async {
    await _ensureInitialized();

    if (!_googleSignIn.supportsAuthenticate()) {
      throw GoogleSignInUnavailableException();
    }

    final account = await _googleSignIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw GoogleIdTokenMissingException();
    }

    return idToken;
  }

  Future<void> signOut() async {
    await _ensureInitialized();
    try {
      await _googleSignIn.disconnect();
    } catch (_) {
      await _googleSignIn.signOut();
    }
  }
}

class GoogleSignInUnavailableException implements Exception {
  @override
  String toString() {
    return 'Thiết bị này chưa hỗ trợ luồng Google Sign-In trong app.';
  }
}

class GoogleIdTokenMissingException implements Exception {
  @override
  String toString() {
    return 'Google không trả về idToken để xác thực với hệ thống.';
  }
}

class GoogleSignInCanceledException implements Exception {
  @override
  String toString() {
    return 'Bạn đã hủy đăng nhập Google.';
  }
}
