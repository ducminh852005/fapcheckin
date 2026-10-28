import 'package:flutter/material.dart';
import 'package:fapcheckin_core/constants/app_palette.dart';

/// Bảng màu chuyên biệt cho màn hình Dashboard (Tổng quan) theo thiết kế.
/// Kế thừa và đồng bộ từ AppPalette (Trắng & Cam).
class DashboardColors {
  DashboardColors._();

  // Cam chủ đạo (FPT Orange & Brand accents)
  static const Color orangePrimary = AppPalette.primary;
  static const Color orangeDark = AppPalette.primaryDark;
  static const Color orangeLight = AppPalette.orangeLight;
  static const Color orangeLighter = AppPalette.orangeLighter;
  static const Color orangeBorder = AppPalette.orangeBorder;

  // Gradient ấm áp cho vùng Header trên cùng
  static const LinearGradient headerGradient = AppPalette.headerGradient;

  // Gradient cho nút hành động nổi bật (Mở Live QR)
  static const LinearGradient primaryButtonGradient = AppPalette.primaryButtonGradient;

  // Màu chữ (Typography)
  static const Color textDark = AppPalette.textDark;
  static const Color textBody = AppPalette.textBody;
  static const Color textMuted = AppPalette.textMuted;
  static const Color textSubtle = AppPalette.textSubtle;

  // Màu nền & Thẻ (Surfaces & Cards)
  static const Color pageBg = AppPalette.pageBg;
  static const Color cardBg = AppPalette.cardBg;
  static const Color cardBorder = AppPalette.cardBorder;
  static const Color cardTrack = Color(0xFFE2E8F0);

  // Màu trạng thái
  static const Color statusGreen = AppPalette.statusGreen;
  static const Color statusGreenBg = AppPalette.statusGreenBg;
  static const Color statusGreenDot = Color(0xFF22C55E);

  static const Color statusNeutral = AppPalette.textMuted;
  static const Color statusNeutralBg = Color(0xFFF1F5F9);

  // Màu các biểu tượng chức năng chính (Quick actions)
  static const Color quickActionCalendar = Color(0xFFF97316);
  static const Color quickActionCalendarBg = Color(0xFFFFF7ED);

  static const Color quickActionClasses = Color(0xFF3B82F6);
  static const Color quickActionClassesBg = Color(0xFFEFF6FF);

  static const Color quickActionReport = Color(0xFF10B981);
  static const Color quickActionReportBg = Color(0xFFECFDF5);

  static const Color quickActionHistory = Color(0xFF8B5CF6);
  static const Color quickActionHistoryBg = Color(0xFFF5F3FF);

  // Box shadow chuẩn cho các Card
  static final List<BoxShadow> cardShadow = AppPalette.cardShadow;
  static final List<BoxShadow> activeCardShadow = AppPalette.cardShadow;
}
