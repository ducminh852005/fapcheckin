import 'package:flutter/material.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';

class ReportHeader extends StatelessWidget {
  const ReportHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000), // shadow-sm roughly
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Left side: Title and context
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        'HỌC VỤ FAP',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text('•', style: AppTextStyles.caption),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Cập nhật lần cuối: 10:45 AM - Hôm nay',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Báo cáo & Thống kê Chuyên cần',
                  style: AppTextStyles.headlineLg.copyWith(
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tổng hợp dữ liệu chuyên cần, phân tích xu hướng vắng mặt và danh sách sinh viên chạm ngưỡng cảnh báo cấm thi theo quy chế đào tạo FPT University.',
                  style: AppTextStyles.bodySm,
                ),
              ],
            ),
          ),
          
          // Right side: Filters and Exports
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildDropdown('Fall 2023 (Kỳ hiện tại)'),
              _buildDropdown('Tất cả lớp phụ trách (5 lớp)'),
              
              // Divider
              Container(
                width: 1,
                height: 24,
                color: AppColors.surfaceContainerHigh,
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),
              
              _buildActionButton(
                icon: Icons.download_rounded,
                label: 'Xuất Báo Cáo FAP (.xlsx)',
                isPrimary: false,
              ),
              _buildActionButton(
                icon: Icons.print_rounded,
                label: 'In Phiếu Điểm Danh (.pdf)',
                isPrimary: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: AppTextStyles.labelMd),
          const SizedBox(width: 8),
          const Icon(Icons.expand_more, size: 18, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isPrimary,
  }) {
    final bgColor = isPrimary ? AppColors.primaryContainer : AppColors.surface;
    final textColor = isPrimary ? AppColors.onPrimary : AppColors.textPrimary;
    final iconColor = isPrimary ? AppColors.onPrimary : AppColors.primary;
    
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: isPrimary ? null : Border.all(color: AppColors.surfaceContainerHigh),
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
