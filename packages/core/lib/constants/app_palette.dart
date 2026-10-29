import 'package:flutter/material.dart';

/// Bảng màu trung tâm AppPalette (Trắng & Cam FPT) dùng chung cho mobile và core.
class AppPalette {
  AppPalette._();

  // Tone cam chủ đạo thương hiệu FAP Checkin (FPT Orange & Brand accents)
  static const Color primary = Color(0xFFFA5A1E);
  static const Color primaryDark = Color(0xFFE04408);
  static const Color orangeLight = Color(0xFFFFF0EB);
  static const Color orangeLighter = Color(0xFFFFF7F2);
  static const Color orangeBorder = Color(0xFFFFD8C7);
  static const Color orangeDivider = Color(0xFFFFE0D3);
  static const Color orangePastel = Color(0xFFA5B4CB);

  // Typography / Màu chữ (Slate tones)
  static const Color textDark = Color(0xFF0F172A);
  static const Color textBody = Color(0xFF334155);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textSubtle = Color(0xFF94A3B8);

  // Surfaces & Cards (Màu nền & Viền thẻ)
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color pageBg = Color(0xFFF8FAFC);
  static const Color cardBorder = Color(0xFFF1F5F9);
  static const Color borderSubtle = Color(0xFFE2E8F0);

  // Trạng thái thành công / Tích cực (Xanh lá)
  static const Color statusGreen = Color(0xFF16A34A);
  static const Color statusGreenBg = Color(0xFFDCFCE7);

  // Trạng thái cảnh báo / Nguy hiểm / Đăng xuất (Đỏ)
  static const Color statusRed = Color(0xFFEF4444);
  static const Color statusRedBg = Color(0xFFFEE2E2);

  // Gradient ấm áp cho vùng Header
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFEDE3),
      Color(0xFFFFF8F5),
      Color(0xFFF8FAFC),
    ],
  );

  // Gradient cho nút hành động nổi bật
  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFFA5A1E),
      Color(0xFFFF7235),
    ],
  );

  // Box shadow chuẩn cho các Card
  static final List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
}
