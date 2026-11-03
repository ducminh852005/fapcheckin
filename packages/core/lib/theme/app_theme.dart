import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../constants/app_palette.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final textTheme = GoogleFonts.interTextTheme(
      const TextTheme(
        bodyMedium: TextStyle(fontSize: 14, color: AppPalette.textDark),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppPalette.pageBg,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppPalette.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppPalette.primary,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
        surface: AppPalette.cardBg,
        onSurface: AppPalette.textDark,
        surfaceContainerHighest: AppColors.surfaceContainerHighest,
        onSurfaceVariant: AppPalette.textBody,
        outline: AppPalette.borderSubtle,
        outlineVariant: AppColors.outlineVariant,
        inverseSurface: AppColors.inverseSurface,
        onInverseSurface: AppColors.inverseOnSurface,
        inversePrimary: AppColors.inversePrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppPalette.cardBg,
        foregroundColor: AppPalette.textDark,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppPalette.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppPalette.borderSubtle,
        thickness: 1,
      ),
    );
  }

  static ThemeData get dark {
    final textTheme = GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme.apply(
        bodyColor: const Color(0xFFF1F5F9),
        displayColor: const Color(0xFFF8FAFC),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      textTheme: textTheme,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      colorScheme: const ColorScheme.dark(
        primary: AppPalette.primary,
        onPrimary: Colors.white,
        primaryContainer: AppPalette.primaryDark,
        onPrimaryContainer: Colors.white,
        secondary: Color(0xFF38BDF8),
        onSecondary: Color(0xFF0F172A),
        surface: Color(0xFF1E293B),
        onSurface: Color(0xFFF8FAFC),
        onSurfaceVariant: Color(0xFF94A3B8),
        outline: Color(0xFF334155),
        error: Color(0xFFF87171),
        onError: Color(0xFF450A0A),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E293B),
        foregroundColor: Color(0xFFF8FAFC),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E293B),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF334155),
        thickness: 1,
      ),
    );
  }
}
