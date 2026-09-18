import 'package:flutter/material.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';

class SettingsSectionQr extends StatefulWidget {
  const SettingsSectionQr({super.key});

  @override
  State<SettingsSectionQr> createState() => _SettingsSectionQrState();
}

class _SettingsSectionQrState extends State<SettingsSectionQr> {
  int _refreshInterval = 20;
  String _displaySize = 'standard';
  bool _antiScreenshot = true;
  bool _showCountdown = true;

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
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: const Icon(Icons.qr_code_2, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cấu hình Cơ chế Mã QR Động (Dynamic QR)', style: AppTextStyles.headlineMd),
                      const SizedBox(height: 2),
                      Text('Chống gian lận và kiểm soát thuật toán sinh chuỗi token thời gian thực', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text('OTP: HMAC-SHA256', style: AppTextStyles.code.copyWith(fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Radio Groups
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Refresh Interval
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tần suất làm mới mã QR', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w600)),
                          const Icon(Icons.timer, size: 18, color: AppColors.textTertiary),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Chu kỳ đổi chuỗi mã hóa để ngăn chia sẻ ảnh chụp màn hình.', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(child: _buildRadioOption<int>(value: 15, groupValue: _refreshInterval, label: '15 giây', desc: 'Nghiêm ngặt', onChanged: (v) => setState(() => _refreshInterval = v!))),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(child: _buildRadioOption<int>(value: 20, groupValue: _refreshInterval, label: '20 giây', desc: 'Tối ưu', onChanged: (v) => setState(() => _refreshInterval = v!))),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(child: _buildRadioOption<int>(value: 30, groupValue: _refreshInterval, label: '30 giây', desc: 'Tiêu chuẩn', onChanged: (v) => setState(() => _refreshInterval = v!))),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(child: _buildRadioOption<int>(value: 60, groupValue: _refreshInterval, label: '60 giây', desc: 'Lớp đông', onChanged: (v) => setState(() => _refreshInterval = v!))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Display Size
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Kích thước hiển thị máy chiếu', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w600)),
                          const Icon(Icons.tv, size: 18, color: AppColors.textTertiary),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Độ tương phản và kích cỡ khung hình QR cho hội trường & lớp học.', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(child: _buildRadioOption<String>(value: 'standard', groupValue: _displaySize, label: 'Chuẩn Full HD', desc: 'Phòng 30-45 SV', onChanged: (v) => setState(() => _displaySize = v!))),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(child: _buildRadioOption<String>(value: 'large', groupValue: _displaySize, label: 'Siêu to phóng đại', desc: 'Hội trường > 80 SV', onChanged: (v) => setState(() => _displaySize = v!))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Toggles
          _buildToggleItem(
            icon: Icons.phonelink_lock,
            iconColor: AppColors.statusAbsent,
            iconBg: AppColors.statusAbsentBg,
            title: 'Chặn ảnh chụp màn hình (Time-based Token OTP)',
            desc: 'Mã QR nhúng mã bí mật tự tiêu hủy sau 5 giây. Nếu chụp màn hình gửi cho bạn bè, mã sẽ mất hiệu lực khi đến lượt quét.',
            value: _antiScreenshot,
            onChanged: (v) => setState(() => _antiScreenshot = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildToggleItem(
            icon: Icons.hourglass_top,
            iconColor: AppColors.primary,
            iconBg: AppColors.primaryLight,
            title: 'Hiển thị đồng hồ đếm ngược trực tiếp trên máy chiếu',
            desc: 'Hiển thị vòng tròn nhịp quét (Radar timer) giúp sinh viên nắm bắt thời gian đổi chu kỳ mã QR.',
            value: _showCountdown,
            onChanged: (v) => setState(() => _showCountdown = v),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption<T>({
    required T value,
    required T groupValue,
    required String label,
    required String desc,
    required ValueChanged<T?> onChanged,
  }) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1))],
        ),
        child: Column(
          children: [
            Text(label, style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w600, color: isSelected ? AppColors.onPrimary : AppColors.textPrimary)),
            Text(desc, style: AppTextStyles.caption.copyWith(color: isSelected ? AppColors.onPrimary.withOpacity(0.8) : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String desc,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(desc, style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.onPrimary,
            activeTrackColor: AppColors.primaryContainer,
            inactiveThumbColor: AppColors.surface,
            inactiveTrackColor: AppColors.surfaceMuted,
          ),
        ],
      ),
    );
  }
}
