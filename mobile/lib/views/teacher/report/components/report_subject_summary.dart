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
          const Text(
            'Tổng hợp theo môn',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: ReportColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          if (subjects.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Chưa có dữ liệu môn học trong phạm vi đã chọn.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: ReportColors.textMuted,
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
    final isZero = summary.rate <= 0;
    final isWarning = summary.rate > 0 && summary.rate < 0.8;
    final rateColor = isZero
        ? ReportColors.textMuted
        : (isWarning ? ReportColors.orangePrimary : ReportColors.statusGreen);
    final barColor = isZero
        ? const Color(0xFFCBD5E1)
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
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: ReportColors.textDark,
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
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              summary.checkinCountText,
              style: const TextStyle(
                fontSize: 11.5,
                color: ReportColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
