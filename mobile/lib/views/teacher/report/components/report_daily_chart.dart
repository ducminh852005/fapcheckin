import 'package:flutter/material.dart';

import '../report_colors.dart';

class DailyAttendanceItem {
  final String dayLabel; // vd: "T2 - 05"
  final double rate; // vd: 93.8
  final String rateText; // vd: "93,8"
  final bool isHighlighted;

  const DailyAttendanceItem({
    required this.dayLabel,
    required this.rate,
    required this.rateText,
    this.isHighlighted = false,
  });
}

/// Thẻ "Chuyên cần theo tuần":
/// - Header: "Chuyên cần theo tuần" & "Tỷ lệ có mặt (%)"
/// - Biểu đồ cột thể hiện tỷ lệ điểm danh theo ngày trong tuần
/// - Cột ngày đang chọn/hiện tại có màu cam nổi bật
/// - Ghi chú: "T6–CN: chưa có buổi học kết thúc."
class ReportDailyChart extends StatelessWidget {
  final List<DailyAttendanceItem> items;
  final String note;

  const ReportDailyChart({
    super.key,
    this.items = const [
      DailyAttendanceItem(dayLabel: 'T2 - 05', rate: 93.8, rateText: '93,8'),
      DailyAttendanceItem(dayLabel: 'T3 - 06', rate: 95.1, rateText: '95,1'),
      DailyAttendanceItem(dayLabel: 'T4 - 07', rate: 92.7, rateText: '92,7'),
      DailyAttendanceItem(
        dayLabel: 'T5 - 08',
        rate: 93.8,
        rateText: '93,8',
        isHighlighted: true,
      ),
    ],
    this.note = 'T6–CN: chưa có buổi học kết thúc.',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ReportColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ReportColors.borderSubtle),
        boxShadow: ReportColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (đảm bảo không bị overflow với font kiểm thử)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Chuyên cần theo tuần',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: ReportColors.textDark,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Tỷ lệ có mặt (%)',
                    style: TextStyle(
                      fontSize: 11,
                      color: ReportColors.textSubtle,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bar chart
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: _DailyBarItem(item: items[i])),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Footnote
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              note,
              style: const TextStyle(
                fontSize: 11.5,
                color: ReportColors.textSubtle,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyBarItem extends StatelessWidget {
  final DailyAttendanceItem item;

  const _DailyBarItem({required this.item});

  @override
  Widget build(BuildContext context) {
    // Chiều cao tối đa của thanh cột là 80dp (tương ứng ~100%)
    const maxBarHeight = 80.0;
    final fillHeight = (item.rate / 100.0 * maxBarHeight).clamp(
      10.0,
      maxBarHeight,
    );
    final barColor = item.isHighlighted
        ? ReportColors.barOrange
        : ReportColors.barBlueMuted;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Value text
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            item.rateText,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: ReportColors.textDark,
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Bar container
        Container(
          height: fillHeight,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ),
        const SizedBox(height: 8),

        // Day label
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            item.dayLabel,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: ReportColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}
