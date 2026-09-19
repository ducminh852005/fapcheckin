import 'package:flutter/material.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';

class SettingsSectionProfile extends StatelessWidget {
  const SettingsSectionProfile({super.key});

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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: const Icon(Icons.manage_accounts, color: AppColors.textPrimary, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tài khoản & Khóa Bảo mật Giảng viên', style: AppTextStyles.headlineMd),
                      const SizedBox(height: 2),
                      Text('Thông tin định danh của giảng viên chủ nhiệm phiên điểm danh', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.statusPresentBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text('Tài khoản Hoạt động', style: AppTextStyles.caption.copyWith(color: AppColors.statusPresent, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Profile Info
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceBright,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.person, size: 40, color: AppColors.onPrimary),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TS. Nguyễn Văn An', style: AppTextStyles.headlineSm),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                          children: [
                            const TextSpan(text: 'Mã GV: '),
                            TextSpan(text: 'ANNV12', style: AppTextStyles.code.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                            const TextSpan(text: ' • Khoa Công nghệ Thông tin'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Email: an.nguyenvan@fpt.edu.vn • Đăng nhập SSO qua Google Workspace FPT', style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                  ),
                  child: const Text('Đổi mật khẩu FAP'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Security API Key
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Khóa ký số Giảng viên (Teacher Electronic Signature Key)', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('Dùng để ký xác thực bảng điểm danh trước khi đồng bộ lên phòng Khảo thí FPT.', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1))],
                        ),
                        child: Text('fpt_sec_9934810298a87b1c4e20918', style: AppTextStyles.code.copyWith(color: AppColors.textPrimary)),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.key, size: 18),
                      label: const Text('Cấp lại khóa'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.textPrimary,
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
