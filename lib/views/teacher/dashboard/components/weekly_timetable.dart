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

  TimetableEntry({
    required this.dayOfWeek,
    required this.slot,
    required this.courseCode,
    required this.room,
    required this.timeRange,
  });
}

/// Decodes FPT-style slotCode (A1..A6, P1..P6, ...) into the real slot
/// number and the weekdays (1=Mon..7=Sun) that class meets on.
///
/// Confirmed rule (from teacher's note):
///  - A = ca sáng (AM)  -> slot 1-2
///  - P = ca chiều (PM) -> slot 3-4
///  - Digit picks the day-pair:
///      1,2 -> Thứ 2 & Thứ 5 (Mon, Thu)
///      3,4 -> Thứ 3 & Thứ 6 (Tue, Fri)
///      5,6 -> Thứ 4 & Thứ 7 (Wed, Sat)
///    Odd digit = first slot of the ca, even digit = second slot of the ca.
///
/// NOT CONFIRMED: evening ca (slot 5-6). Guessed letter 'E' below as a
/// placeholder since such classes are rare — update the letter/base slot
/// once you confirm the real code (e.g. it might not be 'E' at all).
class SlotCodeInfo {
  final int slot;
  final List<int> weekdays;
  SlotCodeInfo({required this.slot, required this.weekdays});
}

class SlotCodeParser {
  // letter -> base slot number (first slot of that ca)
  static const _letterBaseSlot = {
    'A': 1, // ca sáng: slot 1-2 (confirmed)
    'P': 3, // ca chiều: slot 3-4 (confirmed)
    'E': 5, // ca tối: slot 5-6 (UNCONFIRMED GUESS — sửa nếu sai)
  };

  static const _dayPairs = [
    [1, 4], // thứ 2, thứ 5
    [2, 5], // thứ 3, thứ 6
    [3, 6], // thứ 4, thứ 7
  ];

  static SlotCodeInfo? parse(String rawCode) {
    if (rawCode.isEmpty) return null;
    final letter = rawCode[0].toUpperCase();
    final numStr = rawCode.substring(1);
    final n = int.tryParse(numStr);
    if (n == null || n < 1) return null;

    final baseSlot = _letterBaseSlot[letter] ?? 1;
    final pairIndex = (n - 1) ~/ 2; // 0,1,2
    final offset = (n - 1) % 2; // 0 or 1
    if (pairIndex >= _dayPairs.length) return null;

    return SlotCodeInfo(
      slot: baseSlot + offset,
      weekdays: _dayPairs[pairIndex],
    );
  }
}

/// Weekly timetable grid: Mon..Sun columns x Slot 1..8 rows.
/// Cell shows "COURSE_CODE" + "at ROOM" + time range, or "-" if empty.
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
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A142433),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed Left Column
          SizedBox(
            width: 70,
            child: Table(
              border: TableBorder(
                top: BorderSide(color: AppColors.surfaceMuted, width: 1),
                left: BorderSide(color: AppColors.surfaceMuted, width: 1),
                bottom: BorderSide(color: AppColors.surfaceMuted, width: 1),
                right: BorderSide(color: AppColors.surfaceMuted, width: 1),
                horizontalInside: BorderSide(
                  color: AppColors.surfaceMuted,
                  width: 1,
                ),
              ),
              columnWidths: const {0: FlexColumnWidth(1)},
              children: [
                // Header
                TableRow(
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.15),
                  ),
                  children: [
                    SizedBox(
                      height: 60,
                      child: Center(
                        child: Text(
                          'SLOT',
                          style: AppTextStyles.bodySm.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Slots
                for (int slot = 1; slot <= slotCount; slot++)
                  TableRow(
                    children: [
                      SizedBox(
                        height: 110,
                        child: Center(child: _SlotLabelCell(slot: slot)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Scrollable Right Columns
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                border: TableBorder(
                  top: BorderSide(color: AppColors.surfaceMuted, width: 1),
                  bottom: BorderSide(color: AppColors.surfaceMuted, width: 1),
                  right: BorderSide(color: AppColors.surfaceMuted, width: 1),
                  horizontalInside: BorderSide(
                    color: AppColors.surfaceMuted,
                    width: 1,
                  ),
                  verticalInside: BorderSide(
                    color: AppColors.surfaceMuted,
                    width: 1,
                  ),
                ),
                defaultColumnWidth: FixedColumnWidth(135),
                children: [
                  // Header
                  TableRow(
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.15),
                    ),
                    children: [
                      for (int i = 0; i < 7; i++)
                        SizedBox(
                          height: 60,
                          child: Center(
                            child: _HeaderCell(
                              label: _dayLabels[i],
                              date: weekStart.add(Duration(days: i)),
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Slots
                  for (int slot = 1; slot <= slotCount; slot++)
                    TableRow(
                      children: [
                        for (int day = 1; day <= 7; day++)
                          SizedBox(
                            height: 110,
                            child: _ClassCell(entry: _entryFor(day, slot)),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
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
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
      padding: EdgeInsets.all(8),
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
      return Padding(padding: EdgeInsets.all(8), child: Text('-'));
    }
    return Padding(
      padding: EdgeInsets.all(8),
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
