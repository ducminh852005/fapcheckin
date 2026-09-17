import 'package:flutter/material.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';

class SettingsSidebar extends StatelessWidget {
  final String activeTab;
  final Function(String) onTabSelect;

  const SettingsSidebar({
    super.key,
    required this.activeTab,
    required this.onTabSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Navigation Side Panel
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
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
            children: [
              _buildTabBtn('qr', 'Quy tắc & Mã QR', Icons.qr_code_scanner),
              const SizedBox(height: 4),
              _buildTabBtn('security', 'Bảo mật & Giảng đường', Icons.security),
              const SizedBox(height: 4),
              _buildTabBtn('sync', 'Đồng bộ FAP Edu', Icons.sync),
              const SizedBox(height: 4),
              _buildTabBtn('alerts', 'Thông báo & Email', Icons.notifications_active),
              const SizedBox(height: 4),
              _buildTabBtn('profile', 'Tài khoản Giảng viên', Icons.badge),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        
        // Quick Session Live Status Widget
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TRẠNG THÁI PHIÊN',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.statusPresentBg,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.statusPresent, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text('Trực tiếp', style: AppTextStyles.caption.copyWith(color: AppColors.statusPresent, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('P.302 • Tòa Alpha', style: AppTextStyles.headlineSm.copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text('Môn: Lập trình Web (PRJ301)', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.wifi, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text('AP-ALPHA-302', style: AppTextStyles.code.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                    Text('98.4% On-time', style: AppTextStyles.code.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        
        // Hardware Spec Information
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Khuyến nghị Giảng đường', style: AppTextStyles.labelSm.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      'Mã QR 20 giây kết hợp bộ lọc Wi-Fi Alpha giúp loại trừ 99.8% hành vi điểm danh hộ.',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBtn(String id, String label, IconData icon) {
    final isActive = activeTab == id;
    
    return Material(
      color: isActive ? AppColors.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: () => onTabSelect(id),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: isActive ? AppColors.onPrimary : AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    label,
                    style: AppTextStyles.labelMd.copyWith(color: isActive ? AppColors.onPrimary : AppColors.textSecondary),
                  ),
                ],
              ),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: isActive ? AppColors.onPrimary : AppColors.textSecondary.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
