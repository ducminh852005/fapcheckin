import 'package:flutter/material.dart';

/// Bảng màu chuyên biệt cho màn hình Dashboard (Tổng quan) theo thiết kế.
class DashboardColors {
  DashboardColors._();

  // Cam chủ đạo (FPT Orange & Brand accents)
  static const Color orangePrimary = Color(0xFFFA5A1E);
  static const Color orangeDark = Color(0xFFE04408);
  static const Color orangeLight = Color(0xFFFFF0EB);
  static const Color orangeLighter = Color(0xFFFFF7F2);
  static const Color orangeBorder = Color(0xFFFFD8C7);

  // Gradient ấm áp cho vùng Header trên cùng
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFEDE3),
      Color(0xFFFFF8F5),
      Color(0xFFF8FAFC),
    ],
  );

  // Gradient cho nút hành động nổi bật (Mở Live QR)
  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFFA5A1E),
      Color(0xFFFF7235),
    ],
  );

  // Màu chữ (Typography)
  static const Color textDark = Color(0xFF1E293B); // Slate 800
  static const Color textBody = Color(0xFF334155); // Slate 700
  static const Color textMuted = Color(0xFF64748B); // Slate 500
  static const Color textSubtle = Color(0xFF94A3B8); // Slate 400

  // Màu nền & Thẻ (Surfaces & Cards)
  static const Color pageBg = Color(0xFFF8FAFC);
  static const Color cardBg = Colors.white;
  static const Color cardBorder = Color(0xFFF1F5F9);
  static const Color cardTrack = Color(0xFFE2E8F0);

  // Màu trạng thái
  // Đang diễn ra / Tích cực (Xanh lá)
  static const Color statusGreen = Color(0xFF16A34A);
  static const Color statusGreenBg = Color(0xFFDCFCE7);
  static const Color statusGreenDot = Color(0xFF22C55E);

  // Chưa bắt đầu / Trung tính
  static const Color statusNeutral = Color(0xFF64748B);
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
  static final List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static final List<BoxShadow> activeCardShadow = [
    BoxShadow(
      color: const Color(0xFFFA5A1E).withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];
}

