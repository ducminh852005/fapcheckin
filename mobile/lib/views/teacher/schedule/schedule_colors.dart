import 'package:flutter/material.dart';

/// Bảng màu chuyên biệt cho màn hình Lịch dạy (Schedule Timeline).
class ScheduleColors {
  ScheduleColors._();

  static const Color orangePrimary = Color(0xFFFA5A1E);
  static const Color orangeLight = Color(0xFFFFF0EB);
  static const Color orangeLighter = Color(0xFFFFF7F2);
  static const Color orangeBadgeBg = Color(0xFFFFEDE5);

  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textSubtle = Color(0xFF94A3B8);

  static const Color cardBg = Colors.white;
  static const Color pageBg = Color(0xFFF8FAFC);
  static const Color cardBorder = Color(0xFFF1F5F9);
  static const Color timelineLine = Color(0xFFE2E8F0);
  static const Color slotBadgeBg = Color(0xFFEEF2F6);

  static const Color statusDone = Color(0xFF16A34A);
  static const Color statusDoneBg = Color(0xFFDCFCE7);

  static const Color statusActive = Color(0xFFFA5A1E);
  static const Color statusActiveBg = Color(0xFFFFEDE5);

  static const Color statusPending = Color(0xFF64748B);
  static const Color statusPendingBg = Color(0xFFF1F5F9);

  static final List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];

  static final List<BoxShadow> activeCardShadow = [
    BoxShadow(
      color: const Color(0xFFFA5A1E).withValues(alpha: 0.12),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];
}

