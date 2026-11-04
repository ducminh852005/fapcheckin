
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Crashlytics + Analytics chỉ hỗ trợ Android/iOS; các nền tảng khác bỏ qua.
bool get telemetrySupported =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

Future<void> initTelemetry() async {
  if (!telemetrySupported) return;
  try {
    // Keep Crashlytics enabled in test builds as well so the in-app demo can
    // upload its fatal report after the application is opened again.
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(!kDebugMode);
  } catch (e) {
    debugPrint('Telemetry không khả dụng: $e');
  }
}

/// Records context for the Crashlytics demo, then intentionally terminates the
/// native application. The fatal report is uploaded on the next app launch.
Future<void> triggerCrashlyticsDemo() async {
  if (!telemetrySupported) {
    throw UnsupportedError('Crashlytics chỉ hỗ trợ Android và iOS.');
  }

  final crashlytics = FirebaseCrashlytics.instance;
  await crashlytics.setCrashlyticsCollectionEnabled(true);
  await crashlytics.setCustomKey('is_demo_crash', true);
  await crashlytics.setCustomKey('demo_source', 'teacher_settings');
  crashlytics.log('Crashlytics demo triggered from the Flutter application');
  crashlytics.crash();
}
