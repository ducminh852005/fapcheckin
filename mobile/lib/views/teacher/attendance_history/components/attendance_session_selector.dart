import 'package:flutter/material.dart';
import 'package:fapcheckin_core/models/session_model.dart';
import '../attendance_history_colors.dart';

/// Thanh trượt chọn buổi học (Session Picker) từ danh sách phiên thực tế trên Firebase:
/// - Buổi mới nhất / Đang mở [Selected - Nền cam FPT, chữ trắng]
/// - Các buổi trước [Nền trắng, viền nhẹ, chữ Slate]
class AttendanceSessionSelector extends StatelessWidget {
  final List<SessionModel> sessions;
  final String? selectedSessionId;
  final ValueChanged<String> onSelectSession;

  const AttendanceSessionSelector({
    super.key,
    required this.sessions,
    required this.selectedSessionId,
    required this.onSelectSession,
  });

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) return const SizedBox.shrink();

    final total = sessions.length;

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: sessions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final session = sessions[index];
          final sessionNum = total - index;
          final isSelected = session.sessionId == selectedSessionId;

          final numLabel = sessionNum < 10 ? '0$sessionNum' : '$sessionNum';
          final dateShort = _shortDate(session.sessionDate);
          final label = session.isOpen
              ? 'Buổi $numLabel (Đang mở)'
              : dateShort.isNotEmpty
                  ? 'Buổi $numLabel ($dateShort)'
                  : 'Buổi $numLabel';

          return InkWell(
            onTap: () => onSelectSession(session.sessionId),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 13 : 11,
                vertical: 6,
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
                      fontSize: 12,
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
                      size: 15,
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

  String _shortDate(String value) {
    if (value.isEmpty) return '';
    final dt = DateTime.tryParse(value)?.toLocal();
    if (dt != null) {
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
    }
    return value;
  }
}
