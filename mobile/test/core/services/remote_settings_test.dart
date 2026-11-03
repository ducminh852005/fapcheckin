import 'package:fapcheckin/core/services/remote_settings.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'CR-04: returns safe defaults when Firebase is not initialized',
    () async {
      final settings = await RemoteSettings.load();
      expect(settings.qrRefreshSeconds, 60);
      expect(settings.ipCheckDefault, isFalse);
      expect(settings.maintenanceMode, isFalse);
    },
  );

  test('returns fetched Remote Config values', () async {
    final source = FakeRemoteSettingsSource(
      values: {
        'qr_refresh_seconds': 30,
        'ip_check_default': true,
        'maintenance_mode': true,
      },
    );

    final settings = await RemoteSettings.loadFrom(source);

    expect(settings.qrRefreshSeconds, 30);
    expect(settings.ipCheckDefault, isTrue);
    expect(settings.maintenanceMode, isTrue);
    expect(source.defaults?['qr_refresh_seconds'], 60);
  });

  test('CR-04: returns safe defaults when configuration fails', () async {
    final settings = await RemoteSettings.loadFrom(
      FakeRemoteSettingsSource(failDuringConfiguration: true),
    );

    expect(settings.qrRefreshSeconds, 60);
    expect(settings.ipCheckDefault, isFalse);
    expect(settings.maintenanceMode, isFalse);
  });

  test('CR-04: returns safe defaults when reading values fails', () async {
    final settings = await RemoteSettings.loadFrom(
      FakeRemoteSettingsSource(failDuringRead: true),
    );

    expect(settings.qrRefreshSeconds, 60);
    expect(settings.ipCheckDefault, isFalse);
    expect(settings.maintenanceMode, isFalse);
  });

  for (final stage in ['settings', 'fetch']) {
    test('CR-04: returns safe defaults when $stage fails', () async {
      final settings = await RemoteSettings.loadFrom(
        FakeRemoteSettingsSource(failAt: stage),
      );
      expect(settings.qrRefreshSeconds, 60);
      expect(settings.ipCheckDefault, isFalse);
      expect(settings.maintenanceMode, isFalse);
    });
  }
}

class FakeRemoteSettingsSource implements RemoteSettingsSource {
  FakeRemoteSettingsSource({
    this.values = const {},
    this.failDuringConfiguration = false,
    this.failDuringRead = false,
    this.failAt,
  });

  final Map<String, Object> values;
  final bool failDuringConfiguration;
  final bool failDuringRead;
  final String? failAt;
  Map<String, dynamic>? defaults;

  @override
  Future<void> setDefaults(Map<String, dynamic> values) async {
    if (failDuringConfiguration) throw StateError('configuration failed');
    defaults = values;
  }

  @override
  Future<void> setConfigSettings(RemoteConfigSettings settings) async {
    if (failAt == 'settings') throw StateError('settings failed');
  }

  @override
  Future<bool> fetchAndActivate() async {
    if (failAt == 'fetch') throw StateError('fetch failed');
    return true;
  }

  @override
  int getInt(String key) {
    if (failDuringRead) throw StateError('read failed');
    return values[key] as int? ?? 0;
  }

  @override
  bool getBool(String key) {
    if (failDuringRead) throw StateError('read failed');
    return values[key] as bool? ?? false;
  }
}
