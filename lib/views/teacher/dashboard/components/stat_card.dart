import 'package:flutter/material.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';

class StatCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Widget valueWidget;
  final Widget? bottomWidget;

  const StatCard({
    super.key,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.valueWidget,
    this.bottomWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A142433),
            blurRadius: 4,
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
                label,
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          valueWidget,
          if (bottomWidget != null) ...[
            const SizedBox(height: 8),
            bottomWidget!,
          ],
        ],
      ),
    );
  }
}

/// Stat card for "Lịch dạy hôm nay"
class TodayScheduleStatCard extends StatelessWidget {
  final int totalClasses;
  final int morningClasses;
  final int afternoonClasses;

  const TodayScheduleStatCard({
    super.key,
    required this.totalClasses,
    required this.morningClasses,
    required this.afternoonClasses,
  });

  @override
  Widget build(BuildContext context) {
    return StatCard(
      label: 'Lịch dạy hôm nay',
      icon: Icons.calendar_month_outlined,
      iconColor: AppColors.primaryContainer,
      valueWidget: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            '$totalClasses',
            style: AppTextStyles.headlineLg.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'lớp học',
            style: AppTextStyles.bodySm.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      bottomWidget: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$morningClasses ca sáng',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$afternoonClasses ca chiều',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stat card for "Tiến độ điểm danh"
class SessionProgressStatCard extends StatelessWidget {
  final int completed;
  final int total;

  const SessionProgressStatCard({
    super.key,
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = total > 0 ? completed / total : 0;
    return StatCard(
      label: 'Tiến độ điểm danh',
      icon: Icons.check_circle_outline,
      iconColor: AppColors.statusPresent,
      valueWidget: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            '$completed / $total',
            style: AppTextStyles.headlineLg.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'phiên',
            style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
      bottomWidget: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.surfaceContainerHigh,
                valueColor: const AlwaysStoppedAnimation(
                  AppColors.primaryContainer,
                ),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(progress * 100).round()}%',
            style: AppTextStyles.codeSm.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Stat card for "SV có mặt hôm nay"
class PresentStudentsStatCard extends StatelessWidget {
  final int present;
  final int total;

  const PresentStudentsStatCard({
    super.key,
    required this.present,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final double rate = total > 0 ? present / total : 0;
    final String rateStr = '${(rate * 100).toStringAsFixed(1)}%';

    return StatCard(
      label: 'SV có mặt hôm nay',
      icon: Icons.groups_outlined,
      iconColor: AppColors.primary,
      valueWidget: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            '$present',
            style: AppTextStyles.headlineLg.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '/ $total SV',
            style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
      bottomWidget: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.statusPresentBg,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              rateStr,
              style: AppTextStyles.codeSm.copyWith(
                color: AppColors.statusPresent,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Đạt chỉ tiêu buổi học',
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Stat card for "Chuyên cần trung bình"
class AvgAttendanceStatCard extends StatelessWidget {
  final double rate;
  final double prevRate;

  const AvgAttendanceStatCard({
    super.key,
    required this.rate,
    required this.prevRate,
  });

  @override
  Widget build(BuildContext context) {
    final double delta = rate - prevRate;
    final bool positive = delta >= 0;
    final String deltaStr = '${positive ? '+' : ''}${(delta * 100).toStringAsFixed(1)}%';
    final String rateStr = '${(rate * 100).toStringAsFixed(1).replaceAll('.', ',')}%';
    final String prevStr = '${(prevRate * 100).toStringAsFixed(1)}%';

    return StatCard(
      label: 'Chuyên cần trung bình',
      icon: Icons.trending_up,
      iconColor: AppColors.statusPresent,
      valueWidget: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            rateStr,
            style: AppTextStyles.headlineLg.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              Icon(
                positive ? Icons.north_east : Icons.south_east,
                size: 16,
                color: positive ? AppColors.statusPresent : AppColors.statusAbsent,
              ),
              Text(
                deltaStr,
                style: AppTextStyles.labelSm.copyWith(
                  color: positive ? AppColors.statusPresent : AppColors.statusAbsent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
      bottomWidget: Text(
        'So với tuần trước ($prevStr)',
        style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
      ),
    );
  }
}
