import 'package:flutter/material.dart';

import '../schedule_colors.dart';

/// Dòng tóm tắt ngày đang chọn và tổng số ca dạy:
/// Ví dụ: "Thứ Năm, 08/10"  ---  "6 ca dạy • Học kỳ Thu 2026"
class ScheduleDaySummary extends StatelessWidget {
  final DateTime date;
  final int sessionCount;
  final String semester;

  const ScheduleDaySummary({
    super.key,
    required this.date,
    required this.sessionCount,
    this.semester = '',
  });

  static const List<String> _dayFullNames = [
    'Thứ Hai',
    'Thứ Ba',
    'Thứ Tư',
    'Thứ Năm',
    'Thứ Sáu',
    'Thứ Bảy',
    'Chủ Nhật',
  ];

  @override
  Widget build(BuildContext context) {
    final dayName = _dayFullNames[date.weekday - 1];
    final dateFormatted =
        '$dayName, ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            dateFormatted,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ScheduleColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            '$sessionCount ca dạy • $semester',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ScheduleColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
