import 'package:flutter/material.dart';
import 'package:fapcheckin_core/constants/app_palette.dart';

/// Bảng màu Hồ sơ — Đồng bộ trực tiếp từ AppPalette (Trắng & Cam).
class ProfileColors {
  ProfileColors._();

  static const Color orangePrimary = AppPalette.primary;
  static const Color orangeLight = AppPalette.orangeLight;
  static const Color orangeLighter = AppPalette.orangeLighter;

  static const Color heroBannerBg = AppPalette.cardBg;
  static const Color heroDivider = AppPalette.orangeDivider;

  static const Color textDark = AppPalette.textDark;
  static const Color textMuted = AppPalette.textMuted;
  static const Color textSubtle = AppPalette.textSubtle;

  static const Color cardBg = AppPalette.cardBg;
  static const Color pageBg = AppPalette.pageBg;
  static const Color cardBorder = AppPalette.cardBorder;
  static const Color borderSubtle = AppPalette.borderSubtle;
  static const Color iconTileBg = AppPalette.orangeLight;

  static const Color statusGreen = AppPalette.statusGreen;
  static const Color statusGreenLight = AppPalette.statusGreenBg;

  static const Color logoutRed = AppPalette.statusRed;
  static const Color logoutBorder = AppPalette.statusRedBg;

  static final List<BoxShadow> cardShadow = AppPalette.cardShadow;
}
