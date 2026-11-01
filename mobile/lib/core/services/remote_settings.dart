import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Tham số vận hành lấy từ Firebase Remote Config (xem `firebase/remoteconfig.template.json`).
/// Lỗi mạng/Remote Config không được chặn app: dùng giá trị mặc định.
class RemoteSettings {
  const RemoteSettings({
    this.qrRefreshSeconds = 60,
    this.ipCheckDefault = false,
    this.maintenanceMode = false,
  });

  final int qrRefreshSeconds;
  final bool ipCheckDefault;
  final bool maintenanceMode;

  static Future<RemoteSettings> load({FirebaseRemoteConfig? config}) async {
    return loadFrom(
      FirebaseRemoteSettingsSource(config ?? FirebaseRemoteConfig.instance),
    );
  }

  @visibleForTesting
  static Future<RemoteSettings> loadFrom(RemoteSettingsSource source) async {
    try {
      await source.setDefaults(const {
        'qr_refresh_seconds': 60,
        'ip_check_default': false,
        'maintenance_mode': false,
      });
      await source.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode
              ? Duration.zero
              : const Duration(hours: 1),
        ),
      );
      await source.fetchAndActivate();
      return RemoteSettings(
        qrRefreshSeconds: source.getInt('qr_refresh_seconds'),
        ipCheckDefault: source.getBool('ip_check_default'),
        maintenanceMode: source.getBool('maintenance_mode'),
      );
    } catch (e) {
      debugPrint('Remote Config không khả dụng, dùng giá trị mặc định: $e');
      return const RemoteSettings();
    }
  }
}

@visibleForTesting
abstract interface class RemoteSettingsSource {
  Future<void> setDefaults(Map<String, dynamic> defaults);
  Future<void> setConfigSettings(RemoteConfigSettings settings);
  Future<bool> fetchAndActivate();
  int getInt(String key);
  bool getBool(String key);
}

class FirebaseRemoteSettingsSource implements RemoteSettingsSource {
  const FirebaseRemoteSettingsSource(this._config);

  final FirebaseRemoteConfig _config;

  @override
  Future<void> setDefaults(Map<String, dynamic> defaults) =>
      _config.setDefaults(defaults);

  @override
  Future<void> setConfigSettings(RemoteConfigSettings settings) =>
      _config.setConfigSettings(settings);

  @override
  Future<bool> fetchAndActivate() => _config.fetchAndActivate();

  @override
  int getInt(String key) => _config.getInt(key);

  @override
  bool getBool(String key) => _config.getBool(key);
}
