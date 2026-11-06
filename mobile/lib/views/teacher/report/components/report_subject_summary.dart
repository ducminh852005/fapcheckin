import 'package:flutter/material.dart';
import '../report_colors.dart';

class SubjectAttendanceSummary {
  final String code;
  final String checkinCountText; // vd: "238/256 lượt"
  final String rateText; // vd: "93,0%"
  final double rate; // vd: 0.93

  const SubjectAttendanceSummary({
    required this.code,
    required this.checkinCountText,
    required this.rateText,
    required this.rate,
  });
}

/// Thẻ "Tổng hợp theo môn":
/// - Danh sách các môn giảng dạy kèm số lượt điểm danh, tỷ lệ % theo ngưỡng chuyên cần
/// - Thanh tiến độ ngang đồng bộ màu trạng thái
class ReportSubjectSummary extends StatelessWidget {
  final List<SubjectAttendanceSummary> subjects;

  const ReportSubjectSummary({
    super.key,
    this.subjects = const [
      SubjectAttendanceSummary(
        code: 'PRN231',
        checkinCountText: '238/256 lượt',
        rateText: '93,0%',
        rate: 0.930,
      ),
      SubjectAttendanceSummary(
        code: 'SWP391',
        checkinCountText: '244/256 lượt',
        rateText: '95,3%',
        rate: 0.953,
      ),
      SubjectAttendanceSummary(
        code: 'SWT301',
        checkinCountText: '30/32 lượt',
        rateText: '93,8%',
        rate: 0.938,
      ),
      SubjectAttendanceSummary(
        code: 'PRM392',
        checkinCountText: '30/32 lượt',
        rateText: '93,8%',
        rate: 0.938,
      ),
    ],
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? Theme.of(context).colorScheme.surface
        : ReportColors.cardBg;
    final borderColor = isDark
        ? const Color(0xFF334155)
        : ReportColors.borderSubtle;
    final textColor = isDark ? const Color(0xFFF8FAFC) : ReportColors.textDark;
    final mutedColor = isDark
        ? const Color(0xFF94A3B8)
        : ReportColors.textMuted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: isDark ? null : ReportColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tổng hợp theo môn',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 14),
          if (subjects.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Chưa có dữ liệu môn học trong phạm vi đã chọn.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: mutedColor,
                ),
              ),
            )
          else
            for (int i = 0; i < subjects.length; i++) ...[
              if (i > 0) const SizedBox(height: 14),
              _SubjectItem(summary: subjects[i]),
            ],
        ],
      ),
    );
  }
}

class _SubjectItem extends StatelessWidget {
  final SubjectAttendanceSummary summary;

  const _SubjectItem({required this.summary});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFF8FAFC) : ReportColors.textDark;
    final mutedColor = isDark
        ? const Color(0xFF94A3B8)
        : ReportColors.textMuted;

    final isZero = summary.rate <= 0;
    final isWarning = summary.rate > 0 && summary.rate < 0.8;
    final rateColor = isZero
        ? mutedColor
        : (isWarning ? ReportColors.orangePrimary : ReportColors.statusGreen);
    final barColor = isZero
        ? (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1))
        : (isWarning ? ReportColors.orangePrimary : ReportColors.statusGreen);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                summary.code,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  height: 1.25,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              summary.rateText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: rateColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: summary.rate.clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              summary.checkinCountText,
              style: TextStyle(
                fontSize: 11.5,
                color: mutedColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
