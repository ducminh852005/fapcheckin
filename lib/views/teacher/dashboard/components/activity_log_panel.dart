import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';
import 'package:fapcheckin/data/models/activity_log.dart';
import 'package:fapcheckin/viewmodels/dashboard_viewmodel.dart';

class ActivityLogPanel extends StatelessWidget {
  const ActivityLogPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardViewModel>(
      builder: (context, vm, _) {
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
              // Header
              Row(
                children: [
                  const Icon(
                    Icons.history_outlined,
                    size: 20,
                    color: AppColors.primaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Nhật ký hoạt động',
                      style: AppTextStyles.headlineSm.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      'Xem tất cả',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Timeline items
              ...vm.activityLogs.map(
                (log) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _ActivityItem(log: log),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final ActivityLog log;
  const _ActivityItem({required this.log});

  @override
  Widget build(BuildContext context) {
    final (Color bgColor, Color fgColor, IconData icon) = _typeConfig(log.type);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: fgColor),
        ),
        const SizedBox(width: 12),
        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      log.title,
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    log.timeLabel,
                    style: AppTextStyles.code.copyWith(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                log.description,
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (log.subDetail != null) ...[
                const SizedBox(height: 2),
                _SubDetail(text: log.subDetail!, type: log.type),
              ],
            ],
          ),
        ),
      ],
    );
  }

  (Color bg, Color fg, IconData icon) _typeConfig(ActivityType type) {
    switch (type) {
      case ActivityType.qrScan:
        return (
          AppColors.statusPresentBg,
          AppColors.statusPresent,
          Icons.qr_code_scanner,
        );
      case ActivityType.cloudSync:
        return (
          AppColors.statusManualBg,
          AppColors.statusManual,
          Icons.cloud_sync_outlined,
        );
      case ActivityType.sessionStart:
        return (
          AppColors.primaryLight,
          AppColors.primaryDark,
          Icons.play_circle_outline,
        );
      case ActivityType.manualEntry:
        return (
          AppColors.statusLateBg,
          AppColors.statusLate,
          Icons.edit_note_outlined,
        );
    }
  }
}

class _SubDetail extends StatelessWidget {
  final String text;
  final ActivityType type;

  const _SubDetail({required this.text, required this.type});

  @override
  Widget build(BuildContext context) {
    // Special rendering for cloud sync status
    if (type == ActivityType.cloudSync) {
      return Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.statusPresent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.code.copyWith(
              fontSize: 11,
              color: AppColors.statusPresent,
            ),
          ),
        ],
      );
    }

    // Default sub-detail style
    Color textColor = type == ActivityType.manualEntry
        ? AppColors.statusLate
        : AppColors.textTertiary;

    return Text(
      text,
      style: AppTextStyles.code.copyWith(
        fontSize: 11,
        color: textColor,
      ),
    );
  }
}
