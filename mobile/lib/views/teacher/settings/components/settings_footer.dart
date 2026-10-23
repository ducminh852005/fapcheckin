import 'package:flutter/material.dart';
import 'package:fapcheckin_core/constants/app_colors.dart';
import 'package:fapcheckin_core/constants/app_spacing.dart';
import 'package:fapcheckin_core/constants/app_text_styles.dart';

class SettingsFooter extends StatelessWidget {
  const SettingsFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000), // shadow-lg
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                size: 18,
                color: AppColors.statusPresent,
              ),
              SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  'Tất cả các thay đổi sẽ tự động áp dụng ngay vào buổi học tiếp theo.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBtn(label: 'Hủy bỏ', isPrimary: false),
              SizedBox(width: AppSpacing.sm),
              _buildBtn(
                label: 'Lưu tất cả thay đổi',
                isPrimary: true,
                icon: Icons.save,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBtn({
    required String label,
    required bool isPrimary,
    IconData? icon,
  }) {
    return Material(
      color: isPrimary ? AppColors.primaryContainer : AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isPrimary ? AppSpacing.lg : AppSpacing.md,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            boxShadow: [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: isPrimary
                      ? AppColors.onPrimary
                      : AppColors.textSecondary,
                ),
                SizedBox(width: 6),
              ],
              Text(
                label,
                style: AppTextStyles.labelMd.copyWith(
                  color: isPrimary
                      ? AppColors.onPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
