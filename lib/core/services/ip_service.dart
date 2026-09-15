import 'dart:convert';
import 'package:http/http.dart' as http;

/// Lấy địa chỉ IP công khai (public IP) của thiết bị hiện tại.
///
/// Vì sao cần: kiến trúc điểm danh so sánh IP công khai của GV lúc mở phiên
/// với IP công khai của SV lúc quét mã — nếu trùng nhau, nhiều khả năng cả
/// hai đang cùng dùng chung mạng Wi-Fi của trường. Đây KHÔNG phải định vị
/// GPS — chỉ là hỏi một dịch vụ công khai xem "request của mình đang đi ra
/// internet từ IP nào".
class IpService {
  static const _endpoint = 'https://api.ipify.org?format=json';

  Future<String> getPublicIp() async {
    final response = await http.get(Uri.parse(_endpoint));
    if (response.statusCode != 200) {
      throw Exception('Không lấy được IP công khai (HTTP ${response.statusCode})');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['ip'] as String;
  }
}
