import 'package:flutter/material.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';

/// One class entry to place on the timetable grid.
/// dayOfWeek: 1 = Mon ... 7 = Sun
/// slot: 1..8
class TimetableEntry {
  final int dayOfWeek;
  final int slot;
  final String courseCode;
  final String room;
  final String timeRange; // e.g. "7:00-9:15"

  const TimetableEntry({
    required this.dayOfWeek,
    required this.slot,
    required this.courseCode,
    required this.room,
    required this.timeRange,
  });
}

/// Weekly timetable grid: Mon..Sun columns x Slot 1..8 rows.
/// Cell shows "COURSE_CODE - at ROOM" + time range, or "-" if empty.
class WeeklyTimetable extends StatelessWidget {
  final DateTime weekStart; // Monday of the displayed week
  final List<TimetableEntry> entries;
  final int slotCount;

  const WeeklyTimetable({
    super.key,
    required this.weekStart,
    required this.entries,
    this.slotCount = 8,
  });

  static const _dayLabels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  TimetableEntry? _entryFor(int day, int slot) {
    for (final e in entries) {
      if (e.dayOfWeek == day && e.slot == slot) return e;
    }
    return null;
  }

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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          border: TableBorder.all(color: AppColors.surfaceMuted, width: 1),
          defaultColumnWidth: const FixedColumnWidth(150),
          columnWidths: const {0: FixedColumnWidth(70)},
          children: [
            // Header: day labels + dates
            TableRow(
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withOpacity(0.15),
              ),
              children: [
                const SizedBox(),
                for (int i = 0; i < 7; i++)
                  _HeaderCell(
                    label: _dayLabels[i],
                    date: weekStart.add(Duration(days: i)),
                  ),
              ],
            ),
            // Slot rows
            for (int slot = 1; slot <= slotCount; slot++)
              TableRow(
                children: [
                  _SlotLabelCell(slot: slot),
                  for (int day = 1; day <= 7; day++)
                    _ClassCell(entry: _entryFor(day, slot)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final DateTime date;
  const _HeaderCell({required this.label, required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotLabelCell extends StatelessWidget {
  final int slot;
  const _SlotLabelCell({required this.slot});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        'Slot $slot',
        style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ClassCell extends StatelessWidget {
  final TimetableEntry? entry;
  const _ClassCell({required this.entry});

  @override
  Widget build(BuildContext context) {
    if (entry == null) {
      return const Padding(padding: EdgeInsets.all(8), child: Text('-'));
    }
    return Padding(
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        width: 134, // matches defaultColumnWidth(150) minus padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              entry!.courseCode,
              softWrap: true,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.primaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'at ${entry!.room}',
              softWrap: true,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              entry!.timeRange,
              softWrap: true,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
