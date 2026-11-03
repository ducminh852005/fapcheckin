import 'package:flutter/material.dart';
import 'package:fapcheckin_core/constants/app_palette.dart';

/// Bảng màu Báo cáo — Đồng bộ trực tiếp từ AppPalette (Trắng & Cam).
class ReportColors {
  ReportColors._();

  static const Color orangePrimary = AppPalette.primary;
  static const Color orangeLight = AppPalette.orangeLight;
  static const Color orangeLighter = AppPalette.orangeLighter;

  static const Color heroBannerBg = AppPalette.cardBg;
  static const Color gaugeTrack = AppPalette.orangeLight;
  static const Color gaugeOrange = AppPalette.primary;

  static const Color textDark = AppPalette.textDark;
  static const Color textMuted = AppPalette.textMuted;
  static const Color textSubtle = AppPalette.textSubtle;

  static const Color cardBg = AppPalette.cardBg;
  static const Color pageBg = AppPalette.pageBg;
  static const Color cardBorder = AppPalette.cardBorder;
  static const Color borderSubtle = AppPalette.borderSubtle;

  static const Color statusGreen = AppPalette.statusGreen;
  static const Color statusGreenLight = AppPalette.statusGreenBg;
  static const Color statusTrendGreen = AppPalette.statusGreen;

  static const Color barBlueMuted = AppPalette.orangePastel;
  static const Color barOrange = AppPalette.primary;

  static final List<BoxShadow> cardShadow = AppPalette.cardShadow;

  // Thuộc tính kế thừa tương thích
  static const primary = AppPalette.primary;
  static const primaryLight = AppPalette.orangeLight;
  static const teal = Color(0xFF1593A2);
  static const orange = AppPalette.primary;
  static const red = AppPalette.statusRed;
  static const green = AppPalette.statusGreen;
  static const text = AppPalette.textDark;
  static const muted = AppPalette.textMuted;
  static const border = AppPalette.cardBorder;
  static const background = AppPalette.pageBg;
  static const warningBackground = Color(0xFFFFFAF0);
  static const warningBorder = Color(0xFFF0DFB9);
}
