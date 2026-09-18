import 'package:flutter/material.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';

class SubjectComparison extends StatelessWidget {
  const SubjectComparison({super.key});

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
          Text('So sánh mức độ chuyên cần 5 lớp', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.md),
          
          _buildSubjectBar('SWP391 (SE1704)', 94.2, AppColors.primaryContainer),
          const SizedBox(height: AppSpacing.sm),
          _buildSubjectBar('PRN211 (SE1712)', 96.8, AppColors.statusPresent),
          const SizedBox(height: AppSpacing.sm),
          _buildSubjectBar('PRJ301 (IA1701)', 92.5, AppColors.primaryContainer),
          const SizedBox(height: AppSpacing.sm),
          _buildSubjectBar('SWT301 (SE1709)', 95.0, AppColors.primaryContainer),
          const SizedBox(height: AppSpacing.sm),
          _buildSubjectBar('MAS291 (AI1702)', 89.4, AppColors.statusAbsent),
          
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceBright,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppColors.statusAbsent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'MAS291 có tỷ lệ vắng cao nhất do trùng đợt workshop AI.',
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTextStyles.code.copyWith(color: AppColors.textPrimary)),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: AppTextStyles.code.copyWith(
                fontWeight: FontWeight.w700,
                color: color == AppColors.primaryContainer ? AppColors.primary : color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage / 100,
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
