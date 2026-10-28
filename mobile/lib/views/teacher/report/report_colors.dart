import 'package:flutter/material.dart';

/// Bảng màu chuyên biệt cho màn hình Báo cáo chuyên cần (Attendance Report).
class ReportColors {
  ReportColors._();

  // Tone cam chủ đạo thương hiệu FAP Checkin
  static const Color orangePrimary = Color(0xFFFA5A1E);
  static const Color orangeLight = Color(0xFFFFF0EB);
  static const Color orangeLighter = Color(0xFFFFF7F2);

  // Thẻ Hero Dark Navy
  static const Color heroBannerBg = Color(0xFF142438);
  static const Color gaugeTrack = Color(0xFF22354A);
  static const Color gaugeOrange = Color(0xFFFA5A1E);

  // Màu chữ
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textSubtle = Color(0xFF94A3B8);

  // Nền & Viền
  static const Color cardBg = Colors.white;
  static const Color pageBg = Color(0xFFF8FAFC);
  static const Color cardBorder = Color(0xFFF1F5F9);
  static const Color borderSubtle = Color(0xFFE2E8F0);

  // Trạng thái xanh & cam
  static const Color statusGreen = Color(0xFF16A34A);
  static const Color statusGreenLight = Color(0xFFDCFCE7);
  static const Color statusTrendGreen = Color(0xFF34D399);

  // Biểu đồ cột
  static const Color barBlueMuted = Color(0xFFA5B4CB);
  static const Color barOrange = Color(0xFFFA5A1E);

  // Shadow dùng chung
  static final List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];

  // Giữ lại các thuộc tính cũ để tương thích hoàn toàn
  static const primary = Color(0xFF087C87);
  static const primaryLight = Color(0xFFE6F5F7);
  static const teal = Color(0xFF1593A2);
  static const orange = Color(0xFFF2A51D);
  static const red = Color(0xFFE56B57);
  static const green = Color(0xFF2FA88B);
  static const text = Color(0xFF26343D);
  static const muted = Color(0xFF7B8790);
  static const border = Color(0xFFE8ECEF);
  static const background = Color(0xFFF6F8F9);
  static const warningBackground = Color(0xFFFFFAF0);
  static const warningBorder = Color(0xFFF0DFB9);
}
