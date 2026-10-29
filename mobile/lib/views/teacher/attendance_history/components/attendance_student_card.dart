import 'package:flutter/material.dart';
import '../attendance_history_colors.dart';

enum StudentAttendanceState {
  presentQr, // Có mặt qua QR (✓ 08:48 • QR)
  presentManual, // Có mặt xác nhận tay (✓ 08:55 • Thủ công)
  absentUnscanned, // Chưa quét (Có nút [🖐 Điểm danh])
  absentExcused, // Vắng có phép (Badge [Vắng phép] + nút [Đổi])
}

class StudentAttendanceModel {
  final String rollNumber;
  final String fullName;
  final String initials;
  final Color avatarBgColor;
  final Color avatarTextColor;
  final String? seatOrNote;
  final StudentAttendanceState state;
  final String? checkinTime;
  final String? warningText; // Ví dụ: "Cảnh báo 20%"

  const StudentAttendanceModel({
    required this.rollNumber,
    required this.fullName,
    required this.initials,
    required this.avatarBgColor,
    required this.avatarTextColor,
    this.seatOrNote,
    required this.state,
    this.checkinTime,
    this.warningText,
  });

  bool get isPresent =>
      state == StudentAttendanceState.presentQr ||
      state == StudentAttendanceState.presentManual;

  bool get isAbsent => !isPresent;
}

/// Thẻ hiển thị một sinh viên trong danh sách điểm danh buổi học:
/// - Avatar tròn kèm dấu chấm trạng thái (xanh lá / đỏ / vàng)
/// - Tên sinh viên + Nhãn cảnh báo (nếu có, e.g. "Cảnh báo 20%")
/// - MSSV + Bàn / Ghi chú
/// - Nút hành động hoặc Badge trạng thái:
///   + QR / Thủ công: Badge xanh "✓ 08:48 • QR" + menu ⋮
///   + Chưa quét: Nút cam "🖐 Điểm danh"
///   + Vắng phép: Badge vàng "Vắng phép" + nút "Đổi"
class AttendanceStudentCard extends StatelessWidget {
  final StudentAttendanceModel student;
  final VoidCallback? onManualCheckin;
  final VoidCallback? onChangeStatus;
  final VoidCallback? onOptions;

  const AttendanceStudentCard({
    super.key,
    required this.student,
    this.onManualCheckin,
    this.onChangeStatus,
    this.onOptions,
  });

  @override
  Widget build(BuildContext context) {
    // Viền đặc biệt nếu vắng hoặc vắng phép
    Color borderColor = AttendanceHistoryColors.cardBorder;
    if (student.state == StudentAttendanceState.absentUnscanned) {
      borderColor = const Color(0xFFFFD8C7); // Viền cam nhạt
    } else if (student.state == StudentAttendanceState.absentExcused) {
      borderColor = AttendanceHistoryColors.warningAmberBorder; // Viền vàng nhạt
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: AttendanceHistoryColors.cardShadow,
      ),
      child: Row(
        children: [
          // ── Avatar tròn + Chấm trạng thái ──────────────────────────────────
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: student.avatarBgColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  student.initials,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: student.avatarTextColor,
                  ),
                ),
              ),
              // Chấm trạng thái góc dưới phải avatar
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: _getStatusDotColor(student.state),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 8),

          // ── Tên sinh viên + Cảnh báo + MSSV ─────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  runSpacing: 2,
                  children: [
                    Text(
                      student.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AttendanceHistoryColors.textDark,
                      ),
                    ),
                    if (student.warningText != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: AttendanceHistoryColors.warningRoseBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          student.warningText!,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AttendanceHistoryColors.warningRose,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _buildSubtitleText(student),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: student.state ==
                            StudentAttendanceState.absentUnscanned
                        ? AttendanceHistoryColors.orangePrimary
                        : AttendanceHistoryColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 4),

          // ── Cột phải: Badge trạng thái hoặc Nút hành động ────────────────────
          _buildTrailingAction(context),
        ],
      ),
    );
  }

  Color _getStatusDotColor(StudentAttendanceState state) {
    switch (state) {
      case StudentAttendanceState.presentQr:
      case StudentAttendanceState.presentManual:
        return AttendanceHistoryColors.statusGreen;
      case StudentAttendanceState.absentUnscanned:
        return AttendanceHistoryColors.statusRed;
      case StudentAttendanceState.absentExcused:
        return const Color(0xFFF59E0B); // Amber
    }
  }

  String _buildSubtitleText(StudentAttendanceModel student) {
    final seat = student.seatOrNote ?? '';
    switch (student.state) {
      case StudentAttendanceState.presentQr:
        return seat.isNotEmpty
            ? '${student.rollNumber} • $seat'
            : student.rollNumber;
      case StudentAttendanceState.presentManual:
        return '${student.rollNumber} • Xác nhận tay';
      case StudentAttendanceState.absentUnscanned:
        return '${student.rollNumber} • Chưa quét';
      case StudentAttendanceState.absentExcused:
        return '${student.rollNumber} • Đơn phép FAP';
    }
  }

  Widget _buildTrailingAction(BuildContext context) {
    switch (student.state) {
      case StudentAttendanceState.presentQr:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
              decoration: BoxDecoration(
                color: AttendanceHistoryColors.statusGreenBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 11,
                    color: AttendanceHistoryColors.statusGreen,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${student.checkinTime ?? '08:48'} • QR',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AttendanceHistoryColors.statusGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 2),
            _MoreVertButton(onTap: onOptions),
          ],
        );

      case StudentAttendanceState.presentManual:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
              decoration: BoxDecoration(
                color: AttendanceHistoryColors.statusGreenBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 11,
                    color: AttendanceHistoryColors.statusGreen,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${student.checkinTime ?? '08:55'} • Thủ công',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AttendanceHistoryColors.statusGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 2),
            _MoreVertButton(onTap: onOptions),
          ],
        );

      case StudentAttendanceState.absentUnscanned:
        return InkWell(
          onTap: onManualCheckin,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: AttendanceHistoryColors.orangePrimary,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AttendanceHistoryColors.orangePrimary
                      .withValues(alpha: 0.28),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.pan_tool_outlined,
                  size: 11,
                  color: Colors.white,
                ),
                SizedBox(width: 3),
                Text(
                  'Điểm danh',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );

      case StudentAttendanceState.absentExcused:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
              decoration: BoxDecoration(
                color: AttendanceHistoryColors.warningAmberBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Vắng phép',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AttendanceHistoryColors.warningAmber,
                ),
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: onChangeStatus,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AttendanceHistoryColors.borderSubtle,
                    width: 1,
                  ),
                ),
                child: const Text(
                  'Đổi',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AttendanceHistoryColors.textDark,
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }
}

class _MoreVertButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _MoreVertButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: const Padding(
        padding: EdgeInsets.all(2),
        child: Icon(
          Icons.more_vert_rounded,
          size: 15,
          color: AttendanceHistoryColors.textSubtle,
        ),
      ),
    );
  }
}
