import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';
import 'package:fapcheckin/data/models/class_section_model.dart';
import 'package:fapcheckin/data/models/class_session.dart';
import 'package:fapcheckin/data/models/timetable_scan_model.dart';
import 'package:fapcheckin/core/network/json_values.dart';
import 'package:fapcheckin/viewmodels/dashboard_viewmodel.dart';
import 'package:fapcheckin/viewmodels/live_session_viewmodel.dart';
import 'package:fapcheckin/views/teacher/class_management/dialogs/import_timetable_dialog.dart';

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
            const _DashboardActions(),
            const SizedBox(height: AppSpacing.md),
            _StatsRow(),
            const SizedBox(height: AppSpacing.md),
            _MainContent(),
          ],
        ),
      ),
    );
  }
}

class _DashboardActions extends StatelessWidget {
  const _DashboardActions();

  Future<void> _scanTimetable(BuildContext context) async {
    final result = await showDialog<TimetableImportResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ImportTimetableDialog(),
    );
    if (!context.mounted || result == null) return;

    await context.read<DashboardViewModel>().loadClasses();
    if (!context.mounted) return;

    context.read<LiveSessionViewModel>().triggerToast(
      type: ToastType.custom,
      title: 'Đã cập nhật thời khóa biểu',
      message: 'Đã thêm giáo viên vào ${result.assignedCount} lớp.',
      icon: Icons.check_circle_outline,
      accentColor: AppColors.statusPresent,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        onPressed: () => _scanTimetable(context),
        icon: const Icon(Icons.document_scanner_outlined, size: 18),
        label: const Text('Quét thời khóa biểu'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: AppTextStyles.labelMd.copyWith(
            fontWeight: FontWeight.w600,
          ),
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
/// "Lịch dạy hôm nay", "Chuyên cần theo tuần" và "Nhật ký hoạt động"
/// đã bị bỏ, thay bằng WeeklyTimetable.
///
/// Mỗi lớp trong vm.classes lặp lại 2 buổi/tuần theo slotCode (A1..A6,
/// P1..P6,...) — xem SlotCodeParser trong weekly_timetable.dart để biết
/// quy tắc giải mã. Vì vậy mỗi lớp sẽ tự sinh ra 2 ô trên bảng tuần,
/// không cần API lấy lịch cả tuần riêng.
class _MainContent extends StatelessWidget {
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
        final entries = <TimetableEntry>[];

        for (final c in vm.classes) {
          final info = SlotCodeParser.parse(c.slotCode);
          final timeRange = (c.startTime != null && c.endTime != null)
              ? '${c.startTime}-${c.endTime}'
              : c.timeLabel;

          if (info != null) {
            // Tiết học lặp lại 2 buổi/tuần theo slotCode
            for (final day in info.weekdays) {
              entries.add(
                TimetableEntry(
                  dayOfWeek: day,
                  slot: info.slot,
                  courseCode: c.classCode,
                  room: c.room,
                  timeRange: timeRange,
                ),
              );
            }
          } else {
            // Không giải mã được slotCode -> tạm hiện đúng hôm nay
            entries.add(
              TimetableEntry(
                dayOfWeek: DateTime.now().weekday,
                slot:
                    int.tryParse(
                      c.slotCode.replaceAll(RegExp(r'[^0-9]'), ''),
                    ) ??
                    1,
                courseCode: c.classCode,
                room: c.room,
                timeRange: timeRange,
              ),
            );
          }
        }

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
