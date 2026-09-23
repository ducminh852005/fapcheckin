import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:url_launcher/url_launcher.dart';

bool get isDesktopGoogleAuthSupported => Platform.isWindows || Platform.isLinux;

Future<String> signInWithDesktopGoogle(
  String clientId,
  String clientSecret,
) async {
  if (!isDesktopGoogleAuthSupported) {
    throw UnsupportedError('Google Desktop OAuth chỉ hỗ trợ Windows và Linux.');
  }

  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final redirectUri = Uri.parse(
    'http://127.0.0.1:${server.port}/oauth2/callback',
  );
  final codeVerifier = _randomUrlSafeString(64);
  final grant = oauth2.AuthorizationCodeGrant(
    clientId,
    Uri.parse('https://accounts.google.com/o/oauth2/v2/auth'),
    Uri.parse('https://oauth2.googleapis.com/token'),
    secret: clientSecret,
    basicAuth: false,
    codeVerifier: codeVerifier,
  );

  try {
    final authorizationUri = grant.getAuthorizationUrl(
      redirectUri,
      scopes: const ['openid', 'email', 'profile'],
      state: _randomUrlSafeString(32),
    );
    final launched = await launchUrl(
      authorizationUri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      throw StateError('Không thể mở trình duyệt để đăng nhập Google.');
    }

    final request = await server.first.timeout(const Duration(minutes: 3));
    final parameters = request.uri.queryParameters;
    final hasError = parameters.containsKey('error');
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.html
      ..write(
        hasError
            ? _callbackHtml('Đăng nhập không thành công. Bạn có thể đóng cửa sổ này.')
            : _callbackHtml('Đăng nhập thành công. Bạn có thể quay lại FAP Check-in.'),
      );
    await request.response.close();

    final client = await grant.handleAuthorizationResponse(parameters);
    try {
      final idToken = client.credentials.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Google không trả về ID token cho ứng dụng desktop.');
      }
      return idToken;
    } finally {
      client.close();
    }
  } on TimeoutException {
    throw StateError('Đăng nhập Google đã hết thời gian chờ.');
  } finally {
    grant.close();
    await server.close(force: true);
  }
}

String _randomUrlSafeString(int length) {
  const chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
  final random = Random.secure();
  return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
}

String _callbackHtml(String message) => '''
<!doctype html>
<html lang="vi">
  <head><meta charset="utf-8"><title>FAP Check-in</title></head>
  <body style="font-family:Arial,sans-serif;padding:40px;text-align:center">
    <h2>$message</h2>
  </body>
</html>
''';
