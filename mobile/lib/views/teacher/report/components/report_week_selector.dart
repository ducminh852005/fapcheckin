import 'package:flutter/material.dart';

import '../report_colors.dart';

/// Thẻ chọn phạm vi tuần báo cáo:
/// - "Tuần này - 05-11/10/2026" kèm icon lịch & mũi tên dropdown
/// - Ghi chú phụ: "Tất cả 6 lớp • Chỉ tính 18 buổi đã kết thúc"
class ReportWeekSelector extends StatelessWidget {
  final String weekLabel;
  final String subtitle;
  final VoidCallback? onTap;

  const ReportWeekSelector({
    super.key,
    this.weekLabel = '',
    this.subtitle = 'Tất cả 6 lớp • Chỉ tính 18 buổi đã kết thúc',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : ReportColors.cardBg;
    final cardBorder = isDark ? const Color(0xFF334155) : ReportColors.borderSubtle;
    final textDark = isDark ? Colors.white : ReportColors.textDark;
    final textMuted = isDark ? const Color(0xFF94A3B8) : ReportColors.textMuted;
    final iconColor = isDark ? Colors.white70 : const Color(0xFF334155);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
          boxShadow: isDark ? null : ReportColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 18,
                  color: iconColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      weekLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 6),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: textMuted,
                ),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  color: textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
