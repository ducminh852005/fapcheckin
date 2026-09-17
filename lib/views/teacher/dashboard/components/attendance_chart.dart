import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';
import 'package:fapcheckin/viewmodels/dashboard_viewmodel.dart';

class AttendanceChart extends StatelessWidget {
  const AttendanceChart({super.key});

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
                    Icons.bar_chart_outlined,
                    size: 20,
                    color: AppColors.primaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Chuyên cần theo tuần',
                      style: AppTextStyles.headlineSm.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.statusPresentBg,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      'TB: 92.2%',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.statusPresent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Tỷ lệ tham dự lớp của sinh viên tuần W43 (T2 - T7)',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              // Bar chart
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: SizedBox(
                  height: 160,
                  child: _BarChart(data: vm.weeklyAttendance),
                ),
              ),
              const SizedBox(height: 12),
              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '* Đang ghi nhận phiên hiện thời',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  Text(
                    'Mục tiêu: >90%',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<WeeklyData> data;

  const _BarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: data.map((d) => _Bar(data: d)).toList(),
    );
  }
}

class _Bar extends StatefulWidget {
  final WeeklyData data;
  const _Bar({required this.data});

  @override
  State<_Bar> createState() => _BarState();
}

class _BarState extends State<_Bar> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final WeeklyData d = widget.data;
    final Color barColor = d.isToday
        ? AppColors.primaryContainer
        : (_hovered ? AppColors.primary : AppColors.secondaryFixedDim);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Percentage label
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: d.isToday || _hovered ? 1.0 : 0.0,
            child: Text(
              '${(d.rate * 100).round()}%',
              style: AppTextStyles.codeSm.copyWith(
                color: d.isToday ? AppColors.primary : AppColors.textSecondary,
                fontWeight: d.isToday ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Bar
          Expanded(
            child: FractionallySizedBox(
              heightFactor: d.rate,
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: 28,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                    boxShadow: d.isToday
                        ? [
                            BoxShadow(
                              color: AppColors.primaryContainer.withOpacity(0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Day label
          Text(
            d.isToday ? '${d.label}*' : d.label,
            style: AppTextStyles.caption.copyWith(
              color: d.isToday ? AppColors.primaryContainer : AppColors.textSecondary,
              fontWeight: d.isToday ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
