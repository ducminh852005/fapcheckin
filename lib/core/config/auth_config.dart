class AuthConfig {
  AuthConfig._();

  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue:
        '222111384223-rk24tqqmdp7bof592plvogk5u2ng2ci0.apps.googleusercontent.com',
  );

  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '222111384223-rk24tqqmdp7bof592plvogk5u2ng2ci0.apps.googleusercontent.com',
  );

  static const String googleHostedDomain = String.fromEnvironment(
    'GOOGLE_HOSTED_DOMAIN',
    defaultValue: '',
  );

  static String? get resolvedGoogleClientId =>
      googleClientId.isEmpty ? null : googleClientId;

  static String? get resolvedGoogleServerClientId =>
      googleServerClientId.isEmpty ? null : googleServerClientId;

  static String? get resolvedGoogleHostedDomain =>
      googleHostedDomain.isEmpty ? null : googleHostedDomain;
}
