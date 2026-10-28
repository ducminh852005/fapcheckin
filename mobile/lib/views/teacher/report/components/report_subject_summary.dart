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
/// - Danh sách các môn giảng dạy kèm số lượt điểm danh, tỷ lệ % màu xanh lá
/// - Thanh tiến độ ngang màu cam
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              summary.code,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: ReportColors.textDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Text(
                  summary.checkinCountText,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: ReportColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              summary.rateText,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: ReportColors.statusGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: summary.rate.clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: const AlwaysStoppedAnimation<Color>(
              ReportColors.orangePrimary,
            ),
          ),
        ),
      ],
    );
  }
}

