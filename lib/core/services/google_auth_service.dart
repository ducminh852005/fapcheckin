import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/auth_config.dart';
import 'desktop_google_auth.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn;
  bool _isInitialized = false;

  GoogleAuthService({GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  Stream<GoogleSignInAuthenticationEvent> get authenticationEvents =>
      isDesktopGoogleAuthSupported
      ? const Stream<GoogleSignInAuthenticationEvent>.empty()
      : _googleSignIn.authenticationEvents;

  Future<void> initialize() => _ensureInitialized();

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    if (isDesktopGoogleAuthSupported) {
      _isInitialized = true;
      return;
    }
    await _googleSignIn.initialize(
      clientId: AuthConfig.resolvedGoogleClientId,
      serverClientId: kIsWeb ? null : AuthConfig.resolvedGoogleServerClientId,
      hostedDomain: AuthConfig.resolvedGoogleHostedDomain,
    );
    _isInitialized = true;
  }

  Future<String> signInAndGetIdToken() async {
    if (isDesktopGoogleAuthSupported) {
      final clientId = AuthConfig.resolvedGoogleDesktopClientId;
      if (clientId == null) {
        throw StateError('Chưa cấu hình GOOGLE_DESKTOP_CLIENT_ID.');
      }
      final clientSecret = AuthConfig.resolvedGoogleDesktopClientSecret;
      if (clientSecret == null) {
        throw StateError(
          'Thiếu GOOGLE_DESKTOP_CLIENT_SECRET. Hãy chạy ứng dụng với '
          '--dart-define=GOOGLE_DESKTOP_CLIENT_SECRET=...',
        );
      }
      if (_looksLikePlaceholderSecret(clientSecret)) {
        throw StateError(
          'GOOGLE_DESKTOP_CLIENT_SECRET dang la gia tri mau. '
          'Hay thay bang Desktop OAuth client secret that trong '
          'desktop_oauth.local.json.',
        );
      }
      return signInWithDesktopGoogle(clientId, clientSecret);
    }

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
    if (isDesktopGoogleAuthSupported) return;
    await _ensureInitialized();
    try {
      await _googleSignIn.disconnect();
    } catch (_) {
      await _googleSignIn.signOut();
    }
  }
}

bool _looksLikePlaceholderSecret(String value) {
  final normalized = value.trim().toLowerCase();
  return normalized.isEmpty ||
      normalized.contains('replace-with') ||
      normalized.contains('placeholder') ||
      normalized.contains('your-') ||
      normalized.contains('example');
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
