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
    final rc = config ?? FirebaseRemoteConfig.instance;
    try {
      await rc.setDefaults(const {
        'qr_refresh_seconds': 60,
        'ip_check_default': false,
        'maintenance_mode': false,
      });
      await rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode
              ? Duration.zero
              : const Duration(hours: 1),
        ),
      );
      await rc.fetchAndActivate();
    } catch (e) {
      debugPrint('Remote Config không khả dụng, dùng giá trị mặc định: $e');
    }
    return RemoteSettings(
      qrRefreshSeconds: rc.getInt('qr_refresh_seconds'),
      ipCheckDefault: rc.getBool('ip_check_default'),
      maintenanceMode: rc.getBool('maintenance_mode'),
    );
  }
}
