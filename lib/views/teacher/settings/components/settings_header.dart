import 'package:flutter/material.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';

class SettingsHeader extends StatelessWidget {
  const SettingsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;

        final titleSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    'CẤU HÌNH HỆ THỐNG',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '/',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Phiên bản v3.4.1 Build 2024',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Cài đặt & Cấu hình Hệ thống',
              style: AppTextStyles.headlineLg.copyWith(letterSpacing: -0.5),
            ),
            const SizedBox(height: 4),
            Text(
              'Quản lý mã QR động chu kỳ 60 giây, chính sách mạng giảng đường, đồng bộ hóa FAP Edu Portal và cảnh báo học vụ.',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );

        final actionSection = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBtn(
              icon: Icons.restart_alt,
              label: 'Khôi phục mặc định',
              isPrimary: false,
            ),
            const SizedBox(width: AppSpacing.sm),
            _buildBtn(
              icon: Icons.save,
              label: 'Lưu tất cả thay đổi',
              isPrimary: true,
            ),
          ],
        );

        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: titleSection),
              const SizedBox(width: AppSpacing.md),
              actionSection,
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleSection,
              const SizedBox(height: AppSpacing.md),
              actionSection,
            ],
          );
        }
      },
    );
  }

  Widget _buildBtn({
    required IconData icon,
    required String label,
    required bool isPrimary,
  }) {
    final bgColor = isPrimary ? AppColors.primaryContainer : AppColors.surface;
    final textColor = isPrimary ? AppColors.onPrimary : AppColors.textPrimary;
    final iconColor = isPrimary ? AppColors.onPrimary : AppColors.textSecondary;

    return Material(
      color: bgColor,
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
            boxShadow: const [
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
