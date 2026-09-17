import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';
import 'package:fapcheckin/viewmodels/dashboard_viewmodel.dart';
import 'components/activity_log_panel.dart';
import 'components/attendance_chart.dart';
import 'components/class_card.dart';
import 'components/stat_card.dart';

class DashboardBody extends StatelessWidget {
  const DashboardBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatsRow(),
            const SizedBox(height: AppSpacing.md),
            _MainContent(),
          ],
        ),
      ),
    );
  }
}


/// 4-column stats row
class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardViewModel>(
      builder: (context, vm, _) {
        return Row(
          children: [
            Expanded(
              child: TodayScheduleStatCard(
                totalClasses: vm.totalClassesToday,
                morningClasses: vm.morningClasses,
                afternoonClasses: vm.afternoonClasses,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: SessionProgressStatCard(
                completed: vm.completedSessions,
                total: vm.totalSessions,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: PresentStudentsStatCard(
                present: vm.presentStudents,
                total: vm.totalStudents,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AvgAttendanceStatCard(
                rate: vm.avgAttendance,
                prevRate: vm.prevWeekAttendance,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Two-column main layout: schedule list (left) + chart & logs (right)
class _MainContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardViewModel>(
      builder: (context, vm, _) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column: today's schedule (65% ~ 8/12)
            Expanded(
              flex: 8,
              child: _SchedulePanel(vm: vm),
            ),
            const SizedBox(width: AppSpacing.md),
            // Right column: chart + activity log (35% ~ 4/12)
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  const AttendanceChart(),
                  const SizedBox(height: AppSpacing.md),
                  const ActivityLogPanel(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Today's schedule panel with class list
class _SchedulePanel extends StatelessWidget {
  final DashboardViewModel vm;
  const _SchedulePanel({required this.vm});

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
          // Header
          Row(
            children: [
              Container(
                width: 10,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Lịch dạy hôm nay',
                style: AppTextStyles.headlineMd.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  '${vm.classSessions.length} lớp',
                  style: AppTextStyles.codeSm.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const Spacer(),
              _IconButton(
                icon: Icons.refresh,
                tooltip: 'Làm mới lịch',
                onTap: () {},
              ),
              const SizedBox(width: 4),
              _IconButton(
                icon: Icons.filter_list,
                tooltip: 'Bộ lọc',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Class cards
          ...vm.classSessions.map(
            (session) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClassCard(session: session),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_IconButton> createState() => _IconButtonState();
}

class _IconButtonState extends State<_IconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _hovered ? AppColors.surfaceMuted : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
