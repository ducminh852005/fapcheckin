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

  static const String googleDesktopClientId = String.fromEnvironment(
    'GOOGLE_DESKTOP_CLIENT_ID',
    defaultValue:
        '222111384223-bpv1gtbt3kqs8401b6ethio1gi69ahl1.apps.googleusercontent.com',
  );

  // Keep the desktop OAuth client secret outside source control and provide it
  // with --dart-define or --dart-define-from-file when running/building.
  static const String googleDesktopClientSecret = String.fromEnvironment(
    'GOOGLE_DESKTOP_CLIENT_SECRET',
    defaultValue: '',
  );

  static const String googleHostedDomain = String.fromEnvironment(
    'GOOGLE_HOSTED_DOMAIN',
    defaultValue: '',
  );

  static String? get resolvedGoogleClientId =>
      googleClientId.isEmpty ? null : googleClientId;

  static String? get resolvedGoogleServerClientId =>
      googleServerClientId.isEmpty ? null : googleServerClientId;

  static String? get resolvedGoogleDesktopClientId =>
      googleDesktopClientId.isEmpty ? null : googleDesktopClientId;

  static String? get resolvedGoogleDesktopClientSecret =>
      googleDesktopClientSecret.isEmpty ? null : googleDesktopClientSecret;

  static String? get resolvedGoogleHostedDomain =>
      googleHostedDomain.isEmpty ? null : googleHostedDomain;
}
