import 'package:flutter/material.dart';
import '../report_colors.dart';

/// Thanh Mini KPI mỏng ghim cố định trên trang Báo cáo:
/// - Hiển thị nhanh % có mặt (ví dụ: 94.1%)
/// - Tóm tắt số lượt có mặt và vắng
/// - Thanh tiến độ mini 2 màu trực quan
class ReportMiniKpiBar extends StatelessWidget {
  final double attendanceRate;
  final String attendanceRateText;
  final int presentCount;
  final int absentCount;

  const ReportMiniKpiBar({
    super.key,
    required this.attendanceRate,
    required this.attendanceRateText,
    required this.presentCount,
    required this.absentCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = presentCount + absentCount;
    final presentFraction =
        total > 0 ? (presentCount / total).clamp(0.0, 1.0) : 0.0;
    final absentFraction =
        total > 0 ? (absentCount / total).clamp(0.0, 1.0) : 0.0;
    final isGood = attendanceRate >= 80;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(
              alpha: isDark ? 0.2 : 0.03,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Badge % tỉ lệ có mặt
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: isGood
                          ? (isDark
                                ? const Color(0xFF064E3B)
                                : const Color(0xFFE8FDF2))
                          : (isDark
                                ? const Color(0xFF7C2D12)
                                : const Color(0xFFFFF7ED)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.pie_chart_rounded,
                          size: 13,
                          color: isGood
                              ? (isDark
                                    ? const Color(0xFF34D399)
                                    : ReportColors.statusGreen)
                              : ReportColors.orangePrimary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          attendanceRateText,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: isGood
                                ? (isDark
                                      ? const Color(0xFF34D399)
                                      : const Color(0xFF047857))
                                : ReportColors.orangePrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Có mặt',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Số lượt có mặt
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: ReportColors.statusGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$presentCount',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : ReportColors.textDark,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'có mặt',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),

                  // Số lượt vắng
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: ReportColors.orangePrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$absentCount',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : ReportColors.textDark,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'vắng',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 7),

          // Mini 2-color Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 3.5,
              child: total == 0
                  ? Container(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    )
                  : Row(
                      children: [
                        if (presentFraction > 0)
                          Expanded(
                            flex: (presentFraction * 1000).toInt(),
                            child: Container(color: ReportColors.statusGreen),
                          ),
                        if (absentFraction > 0)
                          Expanded(
                            flex: (absentFraction * 1000).toInt(),
                            child: Container(color: ReportColors.orangePrimary),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
