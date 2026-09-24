import 'package:flutter/material.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';

class ReportKpis extends StatelessWidget {
  const ReportKpis({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 4;
        if (constraints.maxWidth < 600) {
          crossAxisCount = 1;
        } else if (constraints.maxWidth < 1100) {
          crossAxisCount = 2;
        }

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: constraints.maxWidth > 1100 ? 1.6 : 2.0,
          children: [
            _buildKpiCard(
              title: 'Tỷ lệ chuyên cần TB',
              value: '93.8%',
              icon: Icons.check_circle_outline,
              iconColor: AppColors.statusPresent,
              iconBg: AppColors.statusPresentBg,
              bottomLeft: Row(
                children: [
                  const Icon(
                    Icons.trending_up,
                    size: 16,
                    color: AppColors.statusPresent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '+1.4% so với Summer 2023',
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.statusPresent,
                    ),
                  ),
                ],
              ),
              badgeText: 'Tốt',
              badgeColor: AppColors.statusPresent,
              badgeBg: AppColors.statusPresentBg,
            ),
            _buildKpiCard(
              title: 'Tổng số lượt điểm danh',
              value: '4,820',
              icon: Icons.qr_code_scanner,
              iconColor: AppColors.primary,
              iconBg: AppColors.primaryLight,
              bottomLeft: Row(
                children: [
                  Text(
                    'QR động: ',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '96.2%',
                    style: AppTextStyles.code.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              bottomRight: Row(
                children: [
                  Text(
                    'Bù: ',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '3.8%',
                    style: AppTextStyles.code.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            _buildKpiCard(
              title: 'Nguy cơ cấm thi (>20%)',
              value: '14',
              valueSuffix: '/ 185 sinh viên',
              valueColor: AppColors.statusAbsent,
              icon: Icons.warning_amber_rounded,
              iconColor: AppColors.statusAbsent,
              iconBg: AppColors.statusAbsentBg,
              bottomLeft: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.statusAbsent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Cần gửi nhắc nhở gấp',
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.statusAbsent,
                    ),
                  ),
                ],
              ),
              badgeText: 'Báo động',
              badgeColor: AppColors.statusAbsent,
              badgeBg: AppColors.statusAbsentBg,
            ),
            _buildKpiCard(
              title: 'Tỷ lệ đi trễ TB',
              value: '4.2%',
              valueColor: AppColors.statusLate,
              icon: Icons.schedule,
              iconColor: AppColors.statusLate,
              iconBg: AppColors.statusLateBg,
              bottomLeft: Row(
                children: [
                  Text(
                    'Thời gian trễ TB: ',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '11 phút',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              badgeText: 'Chấp nhận',
              badgeColor: AppColors.statusLate,
              badgeBg: AppColors.statusLateBg,
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    String? valueSuffix,
    Color? valueColor,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required Widget bottomLeft,
    Widget? bottomRight,
    String? badgeText,
    Color? badgeColor,
    Color? badgeBg,
  }) {
    return Container(
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.toUpperCase(),
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              value,
                              style: AppTextStyles.headlineLg.copyWith(
                                color: valueColor ?? AppColors.textPrimary,
                              ),
                            ),
                            if (valueSuffix != null) ...[
                              const SizedBox(width: 4),
                              Text(valueSuffix, style: AppTextStyles.caption),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: Icon(icon, color: iconColor),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 8,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surfaceBright,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(AppSpacing.radiusXl),
                bottomRight: Radius.circular(AppSpacing.radiusXl),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                bottomLeft,
                if (bottomRight != null) bottomRight,
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                    ),
                    child: Text(
                      badgeText,
                      style: AppTextStyles.labelSm.copyWith(color: badgeColor),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
