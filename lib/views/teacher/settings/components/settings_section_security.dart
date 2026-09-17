import 'package:flutter/material.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';

class SettingsSectionSecurity extends StatefulWidget {
  const SettingsSectionSecurity({super.key});

  @override
  State<SettingsSectionSecurity> createState() => _SettingsSectionSecurityState();
}

class _SettingsSectionSecurityState extends State<SettingsSectionSecurity> {
  bool _enforceWifi = true;
  bool _lockBssid = true;
  double _gpsRadius = 25;

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
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: const Icon(Icons.satellite_alt, color: AppColors.primaryDark, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bảo vệ & Giới hạn Phòng học (Geofencing)', style: AppTextStyles.headlineMd),
                      const SizedBox(height: 2),
                      Text('Xác thực vị trí vật lý và trạm phát sóng Wi-Fi', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_user, size: 14, color: AppColors.statusPresent),
                    const SizedBox(width: 4),
                    Text('Giám sát Lớp 2', style: AppTextStyles.caption.copyWith(color: AppColors.statusPresent, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Wi-Fi Enforcement
          Container(
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
                  decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                  child: const Icon(Icons.wifi_tethering, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bắt buộc kết nối Wi-Fi Giảng đường', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('Chỉ sinh viên sử dụng SSID hợp lệ mới có thể điểm danh.', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildTag('FPT-Staff'),
                          const SizedBox(width: AppSpacing.xs),
                          _buildTag('FPT-Student'),
                          const SizedBox(width: AppSpacing.xs),
                          _buildTag('Alpha-Block-IoT'),
                        ],
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _enforceWifi,
                  onChanged: (v) => setState(() => _enforceWifi = v),
                  activeColor: AppColors.onPrimary,
                  activeTrackColor: AppColors.primaryContainer,
                  inactiveThumbColor: AppColors.surface,
                  inactiveTrackColor: AppColors.surfaceMuted,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          // BSSID Locking
          Container(
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
                    Row(
                      children: [
                        const Icon(Icons.router, size: 20, color: AppColors.textSecondary),
                        const SizedBox(width: AppSpacing.sm),
                        Text('Khóa địa chỉ MAC AP (BSSID P.302)', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Switch(
                      value: _lockBssid,
                      onChanged: (v) => setState(() => _lockBssid = v),
                      activeColor: AppColors.onPrimary,
                      activeTrackColor: AppColors.primaryContainer,
                      inactiveThumbColor: AppColors.surface,
                      inactiveTrackColor: AppColors.surfaceMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Chỉ chấp nhận điểm danh khi tín hiệu kết nối xuất phát từ đúng cục phát Access Point gắn tại trần phòng học.', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1))],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.dns, size: 18, color: AppColors.textTertiary),
                            const SizedBox(width: AppSpacing.sm),
                            Text('3C:84:6A:F9:21:40', style: AppTextStyles.code.copyWith(color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.sensors, size: 18),
                      label: const Text('Tự động nhận diện'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.primary,
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
          const SizedBox(height: AppSpacing.md),
          
          // GPS Distance
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceBright,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dung sai khoảng cách GPS', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('Khoảng cách tối đa từ P.302', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1))],
                      ),
                      child: Row(
                        children: [
                          Text(_gpsRadius.toInt().toString(), style: AppTextStyles.headlineSm.copyWith(color: AppColors.primary)),
                          const SizedBox(width: 4),
                          Text('mét', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.surfaceMuted,
                    thumbColor: AppColors.primary,
                    overlayColor: AppColors.primary.withOpacity(0.2),
                    trackHeight: 8,
                  ),
                  child: Slider(
                    value: _gpsRadius,
                    min: 10,
                    max: 50,
                    divisions: 8,
                    onChanged: (v) => setState(() => _gpsRadius = v),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('10m (Rất hẹp)', style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
                    Text('25m (Khuyên dùng)', style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    Text('50m (Bán kính tầng)', style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: AppTextStyles.code.copyWith(fontSize: 12)),
    );
  }
}
