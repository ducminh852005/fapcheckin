import 'package:flutter/material.dart';
import 'package:fapcheckin_core/constants/app_palette.dart';

/// Bảng màu chuyên biệt cho màn hình Lịch dạy (Schedule Timeline),
/// đồng bộ tuyệt đối với tone Trắng & Cam FPT (AppPalette).
class ScheduleColors {
  ScheduleColors._();

  static const Color orangePrimary = AppPalette.primary;
  static const Color orangeLight = AppPalette.orangeLight;
  static const Color orangeLighter = AppPalette.orangeLighter;
  static const Color orangeBadgeBg = AppPalette.orangeLight;
  static const Color orangeBorder = AppPalette.orangeBorder;

  static const Color textDark = AppPalette.textDark;
  static const Color textMuted = AppPalette.textMuted;
  static const Color textSubtle = AppPalette.textSubtle;

  static const Color cardBg = AppPalette.cardBg;
  static const Color pageBg = AppPalette.pageBg;
  static const Color cardBorder = AppPalette.orangeBorder;
  static const Color timelineLine = Color(0xFFFFE0D3);
  static const Color slotBadgeBg = Color(0xFFFFF4EE);

  static const Color statusDone = AppPalette.statusGreen;
  static const Color statusDoneBg = AppPalette.statusGreenBg;

  static const Color statusActive = AppPalette.primary;
  static const Color statusActiveBg = Color(0xFFFFEDE5);

  static const Color statusPending = Color(0xFF64748B);
  static const Color statusPendingBg = Color(0xFFFFF4EE);

  static final List<BoxShadow> cardShadow = AppPalette.cardShadow;

  static final List<BoxShadow> activeCardShadow = [
    BoxShadow(
      color: const Color(0xFFFA5A1E).withValues(alpha: 0.16),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];
}
