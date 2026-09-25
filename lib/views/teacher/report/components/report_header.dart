import 'package:flutter/material.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';
import 'package:fapcheckin/views/teacher/report/report_colors.dart';

class ReportHeader extends StatelessWidget {
  final String generatedAt;
  final String semester;
  final int classCount;

  const ReportHeader({
    super.key,
    required this.generatedAt,
    required this.semester,
    required this.classCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: ReportColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final controls = Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildDropdown(
                semester.isEmpty
                    ? 'Chưa xác định học kỳ'
                    : '$semester (Kỳ hiện tại)',
              ),
              _buildDropdown('Tất cả lớp phụ trách ($classCount lớp)'),

              // Divider
              Container(
                width: 1,
                height: 24,
                color: ReportColors.border,
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),

              _buildActionButton(
                icon: Icons.download_rounded,
                label: 'Xuất Dữ Liệu FAP (.xlsx)',
                isPrimary: false,
              ),
              _buildActionButton(
                icon: Icons.print_rounded,
                label: 'In Phiếu Điểm Danh (.pdf)',
                isPrimary: true,
              ),
            ],
          );

          return constraints.maxWidth < 900
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitle(),
                    const SizedBox(height: AppSpacing.md),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth,
                      ),
                      child: controls,
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _buildTitle()),
                    const SizedBox(width: AppSpacing.md),
                    Flexible(child: controls),
                  ],
                );
        },
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'Tổng quan',
      style: AppTextStyles.headlineLg.copyWith(letterSpacing: -0.5),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDropdown(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: ReportColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: AppTextStyles.labelMd),
          const SizedBox(width: 8),
          const Icon(Icons.expand_more, size: 18, color: ReportColors.muted),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isPrimary,
  }) {
    final bgColor = isPrimary ? AppColors.primaryContainer : Colors.white;
    final textColor = isPrimary ? Colors.white : ReportColors.text;
    final iconColor = isPrimary ? Colors.white : ReportColors.primary;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: isPrimary ? null : Border.all(color: ReportColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.labelMd.copyWith(color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
