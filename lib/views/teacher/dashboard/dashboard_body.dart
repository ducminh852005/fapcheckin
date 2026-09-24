import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';
import 'package:fapcheckin/data/models/class_section_model.dart';
import 'package:fapcheckin/data/models/class_session.dart';
import 'package:fapcheckin/core/network/json_values.dart';
import 'package:fapcheckin/viewmodels/dashboard_viewmodel.dart';
import 'package:fapcheckin/viewmodels/live_session_viewmodel.dart';

import 'components/class_card.dart';
import 'components/stat_card.dart';
import 'components/weekly_timetable.dart';

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

/// Main layout below the stats row: weekly timetable grid.
/// "Lịch dạy hôm nay", "Chuyên cần theo tuần" and "Nhật ký hoạt động"
/// were removed and replaced with WeeklyTimetable below.
///
/// LƯU Ý: DashboardViewModel.classes hiện chỉ chứa lịch của HÔM NAY
/// (từ getClasses API), không có field ngày-trong-tuần và chưa có API
/// lấy lịch cả tuần. Vì vậy bảng bên dưới chỉ điền được đúng cột "hôm
/// nay", các ngày khác trong tuần sẽ hiện "-" cho tới khi có API/field
/// tương ứng.
class _MainContent extends StatelessWidget {
  // Monday of the current week displayed in the grid.
  DateTime get _weekStart {
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardViewModel>(
      builder: (context, vm, _) {
        final todayWeekday = DateTime.now().weekday; // 1 = Mon .. 7 = Sun

        // TODO: vm.classes currently only holds TODAY's classes.
        // Replace this with your weekly schedule source (e.g. vm.weeklyClasses)
        // once available, mapping each item's real day-of-week below.
        final entries = <TimetableEntry>[
          for (final c in vm.classes)
            TimetableEntry(
              dayOfWeek: todayWeekday,
              slot: int.tryParse(c.slotCode) ?? 1,
              courseCode: c.classCode,
              room: c.room,
              timeRange: (c.startTime != null && c.endTime != null)
                  ? '${c.startTime}-${c.endTime}'
                  : c.timeLabel,
            ),
        ];

        return WeeklyTimetable(weekStart: _weekStart, entries: entries);
      },
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            message,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.statusAbsent),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Thử lại'),
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
            child: Icon(widget.icon, size: 18, color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}
