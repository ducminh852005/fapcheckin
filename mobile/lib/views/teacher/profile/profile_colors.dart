import 'package:flutter/material.dart';

/// Bảng màu chuyên biệt cho màn hình Hồ sơ giảng viên (Profile).
class ProfileColors {
  ProfileColors._();

  // Tone cam chủ đạo FAP Checkin
  static const Color orangePrimary = Color(0xFFFA5A1E);
  static const Color orangeLight = Color(0xFFFFF0EB);
  static const Color orangeLighter = Color(0xFFFFF7F2);

  // Thẻ Hero Dark Navy
  static const Color heroBannerBg = Color(0xFF142438);
  static const Color heroDivider = Color(0xFF22354A);

  // Màu chữ
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textSubtle = Color(0xFF94A3B8);

  // Nền & Viền
  static const Color cardBg = Colors.white;
  static const Color pageBg = Color(0xFFF8FAFC);
  static const Color cardBorder = Color(0xFFF1F5F9);
  static const Color borderSubtle = Color(0xFFE2E8F0);
  static const Color iconTileBg = Color(0xFFF1F5F9);

  // Màu trạng thái công tác
  static const Color statusGreen = Color(0xFF16A34A);
  static const Color statusGreenLight = Color(0xFFDCFCE7);

  // Màu nút Đăng xuất
  static const Color logoutRed = Color(0xFFEF4444);
  static const Color logoutBorder = Color(0xFFFEE2E2);

  // Shadow dùng chung
  static final List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];
}
