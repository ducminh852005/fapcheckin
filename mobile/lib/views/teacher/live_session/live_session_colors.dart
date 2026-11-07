import 'package:flutter/material.dart';

/// Bảng màu chuyên biệt cho màn hình Điểm danh trực tiếp (Live QR Session).
class LiveSessionColors {
  LiveSessionColors._();

  // Tone cam chủ đạo FAP Checkin
  static const Color orangePrimary = Color(0xFFFA5A1E);
  static const Color orangeLight = Color(0xFFFFF0EB);
  static const Color orangeLighter = Color(0xFFFFF7F2);

  // Màu chữ & Icon
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textSubtle = Color(0xFF94A3B8);

  // Nền & Viền
  static const Color cardBg = Colors.white;
  static const Color pageBg = Color(0xFFF8FAFC);
  static const Color cardBorder = Color(0xFFF1F5F9);
  static const Color borderSubtle = Color(0xFFE2E8F0);

  // Helper hỗ trợ Dynamic Theme (Dark Mode)
  static Color getCardBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E293B)
          : cardBg;

  static Color getPageBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0F172A)
          : pageBg;

  static Color getBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF334155)
          : borderSubtle;

  static Color getTextDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : textDark;

  static Color getTextMuted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF94A3B8)
          : textMuted;

  // Trạng thái xanh & mạng
  static const Color statusGreen = Color(0xFF16A34A);
  static const Color statusGreenLight = Color(0xFFDCFCE7);
  static const Color tealNetwork = Color(0xFF0D9488);

  // Shadow dùng chung
  static final List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];
}

