import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Service for fetching real public IP address of the device
class IpService {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  static String? _cachedIp;

  /// Fetches the public IP address of the teacher using external IP lookup APIs.
  /// Falls back through multiple providers if any service is down or times out.
  static Future<String> getPublicIp({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedIp != null && _cachedIp!.isNotEmpty) {
      return _cachedIp!;
    }

    final endpoints = [
      'https://api.ipify.org?format=json',
      'https://api64.ipify.org?format=json',
      'https://api.ip.sb/json',
    ];

    for (final url in endpoints) {
      try {
        final response = await _dio.get(url);
        if (response.statusCode == 200) {
          final data = response.data is String
              ? jsonDecode(response.data as String)
              : response.data;
          if (data is Map && data.containsKey('ip')) {
            final ip = data['ip'].toString().trim();
            if (ip.isNotEmpty) {
              _cachedIp = ip;
              debugPrint('IpService: Fetched public IP -> $ip');
              return ip;
            }
          }
        }
      } catch (e) {
        debugPrint('IpService: Failed to fetch IP from $url: $e');
      }
    }

    // Secondary fallback (plain text endpoint)
    try {
      final response = await _dio.get('https://icanhazip.com');
      if (response.statusCode == 200 && response.data != null) {
        final ip = response.data.toString().trim();
        if (ip.isNotEmpty) {
          _cachedIp = ip;
          debugPrint('IpService: Fetched public IP (fallback) -> $ip');
          return ip;
        }
      }
    } catch (e) {
      debugPrint('IpService: Fallback ip fetch failed: $e');
    }

    // Default fallback if completely offline or blocked
    return _cachedIp ?? '127.0.0.1';
  }
}
