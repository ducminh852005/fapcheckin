import 'package:flutter/material.dart';
import 'package:fapcheckin_core/constants/app_palette.dart';

/// Bảng màu chuyên biệt cho màn hình Điểm danh sinh viên / Lịch sử điểm danh
class AttendanceHistoryColors {
  AttendanceHistoryColors._();

  static const Color orangePrimary = AppPalette.primary;
  static const Color orangeLight = AppPalette.orangeLight;
  static const Color orangeLighter = AppPalette.orangeLighter;
  static const Color orangeBorder = AppPalette.orangeBorder;

  static const Color textDark = AppPalette.textDark;
  static const Color textMuted = AppPalette.textMuted;
  static const Color textSubtle = AppPalette.textSubtle;

  static const Color pageBg = AppPalette.pageBg;
  static const Color cardBg = AppPalette.cardBg;
  static const Color cardBorder = AppPalette.cardBorder;
  static const Color borderSubtle = AppPalette.borderSubtle;

  // Trạng thái có mặt / QR hợp lệ / Thủ công
  static const Color statusGreen = AppPalette.statusGreen;
  static const Color statusGreenBg = AppPalette.statusGreenBg;
  static const Color progressGreen = Color(0xFF10B981);

  // Trạng thái vắng / cảnh báo
  static const Color statusRed = AppPalette.statusRed;
  static const Color statusRedBg = AppPalette.statusRedBg;
  static const Color warningRose = Color(0xFFE11D48);
  static const Color warningRoseBg = Color(0xFFFFE4E6);

  // Vắng phép / Cảnh báo vàng
  static const Color warningAmber = Color(0xFFB45309);
  static const Color warningAmberBg = Color(0xFFFEF9C3);
  static const Color warningAmberBorder = Color(0xFFFEF08A);

  // Shadow
  static final List<BoxShadow> cardShadow = AppPalette.cardShadow;
}

