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
    this.weekLabel = 'Tuần này - 05-11/10/2026',
    this.subtitle = 'Tất cả 6 lớp • Chỉ tính 18 buổi đã kết thúc',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: ReportColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ReportColors.borderSubtle),
          boxShadow: ReportColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  size: 18,
                  color: Color(0xFF334155),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      weekLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ReportColors.textDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: ReportColors.textMuted,
                ),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: ReportColors.textMuted,
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

