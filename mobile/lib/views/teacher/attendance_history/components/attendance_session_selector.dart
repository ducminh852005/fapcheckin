import 'package:flutter/material.dart';
import '../attendance_history_colors.dart';

/// Thanh trượt chọn buổi học (Session Picker):
/// - Buổi 12 (Hôm nay) [Selected - Nền cam FPT, chữ trắng, icon mũi tên xuống]
/// - Buổi 11, Buổi 10, Buổi 09, ... [Nền trắng, viền nhẹ, chữ Slate]
class AttendanceSessionSelector extends StatelessWidget {
  final int selectedSession;
  final ValueChanged<int> onSelectSession;

  const AttendanceSessionSelector({
    super.key,
    required this.selectedSession,
    required this.onSelectSession,
  });

  @override
  Widget build(BuildContext context) {
    // Danh sách 12 buổi (hoặc tùy biến)
    final sessions = [12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: sessions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final sessionNum = sessions[index];
          final isSelected = sessionNum == selectedSession;
          final isToday = sessionNum == 12;

          final label = isToday
              ? 'Buổi $sessionNum (Hôm nay)'
              : sessionNum < 10
                  ? 'Buổi 0$sessionNum'
                  : 'Buổi $sessionNum';

          return InkWell(
            onTap: () => onSelectSession(sessionNum),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 14 : 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AttendanceHistoryColors.orangePrimary
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AttendanceHistoryColors.orangePrimary
                      : AttendanceHistoryColors.cardBorder,
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AttendanceHistoryColors.orangePrimary
                              .withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color:
                              const Color(0xFF0F172A).withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : AttendanceHistoryColors.textDark,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
