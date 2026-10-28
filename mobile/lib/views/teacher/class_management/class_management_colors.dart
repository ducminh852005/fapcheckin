import 'package:flutter/material.dart';
import 'package:fapcheckin_core/constants/app_palette.dart';

/// Bảng màu Quản lý lớp — Đồng bộ trực tiếp từ AppPalette (Trắng & Cam).
class ClassManagementColors {
  ClassManagementColors._();

  static const Color orangePrimary = AppPalette.primary;
  static const Color orangeLight = AppPalette.orangeLight;
  static const Color orangeLighter = AppPalette.orangeLighter;
  static const Color orangeBadgeBg = AppPalette.orangeLight;

  static const Color bannerBg = AppPalette.cardBg;

  static const Color textDark = AppPalette.textDark;
  static const Color textMuted = AppPalette.textMuted;
  static const Color textSubtle = AppPalette.textSubtle;

  static const Color cardBg = AppPalette.cardBg;
  static const Color pageBg = AppPalette.pageBg;
  static const Color cardBorder = AppPalette.cardBorder;

  static const Color statusGreen = AppPalette.statusGreen;
  static const Color statusGreenBg = AppPalette.statusGreenBg;

  static const Color statusNextBg = AppPalette.textDark;

  static final List<BoxShadow> cardShadow = AppPalette.cardShadow;
  static final List<BoxShadow> activeCardShadow = AppPalette.cardShadow;
}
