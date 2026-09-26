import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';
import 'package:fapcheckin/data/models/timetable_scan_model.dart';
import 'package:fapcheckin/viewmodels/dashboard_viewmodel.dart';
import 'package:fapcheckin/viewmodels/live_session_viewmodel.dart';
import 'package:fapcheckin/views/teacher/class_management/dialogs/import_timetable_dialog.dart';
import 'package:fapcheckin/views/teacher/dashboard/components/weekly_timetable.dart';

class ScheduleBody extends StatefulWidget {
  const ScheduleBody({super.key});

  @override
  State<ScheduleBody> createState() => _ScheduleBodyState();
}

class _ScheduleBodyState extends State<ScheduleBody> {
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _resetToCurrentWeek();
  }

  void _resetToCurrentWeek() {
    final now = DateTime.now();
    _weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
  }

  void _prevWeek() {
    setState(() {
      _weekStart = _weekStart.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _weekStart = _weekStart.add(const Duration(days: 7));
    });
  }

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
    final weekEnd = _weekStart.add(const Duration(days: 6));
    final weekRangeText =
        '${_weekStart.day.toString().padLeft(2, '0')}/${_weekStart.month.toString().padLeft(2, '0')} - '
        '${weekEnd.day.toString().padLeft(2, '0')}/${weekEnd.month.toString().padLeft(2, '0')}/${weekEnd.year}';

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top action bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Week navigation
                Row(
                  children: [
                    IconButton.outlined(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      tooltip: 'Tuần trước',
                      onPressed: _prevWeek,
                      style: IconButton.styleFrom(
                        side: const BorderSide(color: AppColors.surfaceContainerHigh),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _resetToCurrentWeek();
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.surfaceContainerHigh),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                      child: Text(
                        'Hiện tại',
                        style: AppTextStyles.labelMd.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    IconButton.outlined(
                      icon: const Icon(Icons.chevron_right, size: 20),
                      tooltip: 'Tuần sau',
                      onPressed: _nextWeek,
                      style: IconButton.styleFrom(
                        side: const BorderSide(color: AppColors.surfaceContainerHigh),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      'Tuần: $weekRangeText',
                      style: AppTextStyles.headlineSm.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                // Scan timetable button
                ElevatedButton.icon(
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
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Timetable Table
            Consumer<DashboardViewModel>(
              builder: (context, vm, _) {
                final entries = <TimetableEntry>[];

                for (final c in vm.classes) {
                  final info = SlotCodeParser.parse(c.slotCode);
                  final timeRange = (c.startTime != null && c.endTime != null)
                      ? '${c.startTime}-${c.endTime}'
                      : c.timeLabel;

                  if (info != null) {
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

                return WeeklyTimetable(
                  weekStart: _weekStart,
                  entries: entries,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
