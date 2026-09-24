import 'package:dio/dio.dart';

/// Service to fetch the device's public IP address.
/// Uses ipify.org with a fallback to api64.ipify.org — same as the Apps Script frontend.
class NetworkService {
  NetworkService._();

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  static const _primaryUrl = 'https://api.ipify.org?format=json';
  static const _fallbackUrl = 'https://api64.ipify.org?format=json';

  /// Returns the public IP address of the current network.
  /// Throws [NetworkServiceException] if both providers fail.
  static Future<String> getPublicIp() async {
    try {
      return await _fetchFrom(_primaryUrl);
    } catch (_) {
      try {
        return await _fetchFrom(_fallbackUrl);
      } catch (e) {
        throw NetworkServiceException(
          'Không thể lấy địa chỉ IP công khai. Vui lòng kiểm tra kết nối mạng.',
        );
      }
    }
  }

  static Future<String> _fetchFrom(String url) async {
    final response = await _dio.get<Map<String, dynamic>>(url);
    final ip = response.data?['ip'] as String?;
    if (ip == null || ip.isEmpty) throw Exception('Empty IP response');
    return ip;
  }
}

class NetworkServiceException implements Exception {
  final String message;
  const NetworkServiceException(this.message);

  @override
  String toString() => message;
}
