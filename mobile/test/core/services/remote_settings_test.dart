import 'package:fapcheckin/core/services/remote_settings.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
}

class FakeRemoteSettingsSource implements RemoteSettingsSource {
  FakeRemoteSettingsSource({
    this.values = const {},
    this.failDuringConfiguration = false,
    this.failDuringRead = false,
  });

  final Map<String, Object> values;
  final bool failDuringConfiguration;
  final bool failDuringRead;
  Map<String, dynamic>? defaults;

  @override
  Future<void> setDefaults(Map<String, dynamic> values) async {
    if (failDuringConfiguration) throw StateError('configuration failed');
    defaults = values;
  }

  @override
  Future<void> setConfigSettings(RemoteConfigSettings settings) async {}

  @override
  Future<bool> fetchAndActivate() async => true;

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
