import 'package:flutter/material.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';
import 'package:fapcheckin/views/teacher/report/report_colors.dart';
import 'package:fapcheckin/data/models/report_model.dart';

class SubjectComparison extends StatelessWidget {
  final ReportData data;
  const SubjectComparison({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Tỷ lệ theo môn học', style: AppTextStyles.headlineSm),
          const SizedBox(height: 2),
          Text(
            'So sánh tỷ lệ tham gia theo lớp phụ trách',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.md),

          ...data.subjects.expand(
            (subject) => [
              _buildSubjectBar(
                '${subject.subjectName} (${subject.classCode})',
                subject.attendanceRate * 100,
                subject.absentRate > .15
                    ? ReportColors.red
                    : ReportColors.primary,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ReportColors.background,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.statusAbsent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data.subjects.isEmpty
                        ? 'Chưa có dữ liệu phiên đã kết thúc.'
                        : 'Tỷ lệ được tính từ các phiên điểm danh đã kết thúc.',
                    style: AppTextStyles.caption,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectBar(String title, double percentage, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.code.copyWith(color: ReportColors.text),
                softWrap: true,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 64,
              child: Text(
                '${percentage.toStringAsFixed(1)}%',
                textAlign: TextAlign.right,
                maxLines: 1,
                style: AppTextStyles.code.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color == ReportColors.primary
                      ? ReportColors.primary
                      : color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: ReportColors.border,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (percentage / 100).clamp(0, 1).toDouble(),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
