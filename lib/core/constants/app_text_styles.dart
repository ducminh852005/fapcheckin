import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography system matching the HTML design
class AppTextStyles {
  AppTextStyles._();

  // Headline Large: 28px / 36px / -0.02em / 600
  static TextStyle headlineLg = GoogleFonts.inter(
    fontSize: 28,
    height: 36 / 28,
    letterSpacing: -0.56,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Headline Medium: 20px / 28px / 600
  static TextStyle headlineMd = GoogleFonts.inter(
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Headline Small: 16px / 24px / 600
  static TextStyle headlineSm = GoogleFonts.inter(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Body Medium: 15px / 22px / 400
  static TextStyle bodyMd = GoogleFonts.inter(
    fontSize: 15,
    height: 22 / 15,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
  );

  // Body Small: 14px / 20px / 400
  static TextStyle bodySm = GoogleFonts.inter(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // Label Medium: 14px / 20px / 500
  static TextStyle labelMd = GoogleFonts.inter(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurface,
  );

  // Label Small: 12px / 16px / 500
  static TextStyle labelSm = GoogleFonts.inter(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  // Caption: 12px / 16px / 400
  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
  );

  // Code: 13px / 18px / 400 (JetBrains Mono)
  static TextStyle code = GoogleFonts.jetBrainsMono(
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
  );

  // Code small: 11px (JetBrains Mono)
  static TextStyle codeSm = GoogleFonts.jetBrainsMono(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );
}
