import 'package:flutter/material.dart';
import '../schedule_colors.dart';

/// Thẻ chọn tuần và chọn ngày học:
/// - Tiêu đề tháng/năm kèm 2 nút điều hướng `<` `>`
/// - Hàng 7 ngày trong tuần: T2, T3, T4, T5, T6, T7, CN
/// - Ngày được chọn nổi bật dạng viên nang màu cam (Capsule Pill)
/// - Dấu chấm cam đánh dấu những ngày có ca học
class ScheduleWeekPicker extends StatelessWidget {
  final DateTime selectedDate;
  final DateTime weekStart;
  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback onPrevWeek;
  final VoidCallback onNextWeek;
  final Set<int> daysWithClasses; // 1 = T2, ..., 7 = CN

  const ScheduleWeekPicker({
    super.key,
    required this.selectedDate,
    required this.weekStart,
    required this.onDaySelected,
    required this.onPrevWeek,
    required this.onNextWeek,
    this.daysWithClasses = const {1, 2, 3, 4, 5},
  });

  static const List<String> _dayNames = [
    'T2',
    'T3',
    'T4',
    'T5',
    'T6',
    'T7',
    'CN',
  ];

  @override
  Widget build(BuildContext context) {
    // Tháng và năm hiển thị (lấy theo ngày đang chọn)
    final monthYearText = 'Tháng ${selectedDate.month}, ${selectedDate.year}';

    // Tạo danh sách 7 ngày trong tuần tính từ weekStart (Thứ 2)
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ScheduleColors.cardBorder, width: 1.2),
        boxShadow: ScheduleColors.cardShadow,
      ),
      child: Column(
        children: [
          // Tiêu đề tháng + Nút chuyển tuần
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    monthYearText,
                    style: const TextStyle(
                      color: ScheduleColors.textDark,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildNavArrow(Icons.chevron_left_rounded, onPrevWeek),
                  const SizedBox(width: 8),
                  _buildNavArrow(Icons.chevron_right_rounded, onNextWeek),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Hàng 7 ngày trong tuần
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 0; i < 7; i++) ...[
                Expanded(
                  child: _buildDayCapsule(days[i], i),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavArrow(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 20,
          color: ScheduleColors.textDark,
        ),
      ),
    );
  }

  Widget _buildDayCapsule(DateTime date, int index) {
    final isSelected = date.year == selectedDate.year &&
        date.month == selectedDate.month &&
        date.day == selectedDate.day;

    final hasClass = daysWithClasses.contains(date.weekday);
    final dayLabel = _dayNames[index];
    final dayNum = date.day.toString();

    return InkWell(
      onTap: () => onDaySelected(date),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? ScheduleColors.orangePrimary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: ScheduleColors.orangePrimary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tên thứ (T2..CN)
            Text(
              dayLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.9)
                    : ScheduleColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),

            // Số ngày (5, 6, 7...)
            Text(
              dayNum,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : ScheduleColors.textDark,
              ),
            ),
            const SizedBox(height: 4),

            // Chấm trạng thái có lớp
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Colors.white
                    : (hasClass ? ScheduleColors.orangePrimary : Colors.transparent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
