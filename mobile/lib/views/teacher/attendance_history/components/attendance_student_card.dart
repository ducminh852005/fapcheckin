import 'package:flutter/material.dart';

import '../attendance_history_colors.dart';

enum StudentAttendanceState {
  presentQr, // Có mặt qua QR (✓ 08:48 · QR)
  presentManual, // Có mặt xác nhận tay (✓ 08:55 · Thủ công)
  absentUnscanned, // Chưa quét (Có nút [Điểm danh])
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

  StudentAttendanceModel copyWith({
    String? rollNumber,
    String? fullName,
    String? initials,
    Color? avatarBgColor,
    Color? avatarTextColor,
    String? seatOrNote,
    StudentAttendanceState? state,
    String? checkinTime,
    String? warningText,
  }) {
    return StudentAttendanceModel(
      rollNumber: rollNumber ?? this.rollNumber,
      fullName: fullName ?? this.fullName,
      initials: initials ?? this.initials,
      avatarBgColor: avatarBgColor ?? this.avatarBgColor,
      avatarTextColor: avatarTextColor ?? this.avatarTextColor,
      seatOrNote: seatOrNote ?? this.seatOrNote,
      state: state ?? this.state,
      checkinTime: checkinTime ?? this.checkinTime,
      warningText: warningText ?? this.warningText,
    );
  }
}

/// Thẻ hiển thị một sinh viên trong danh sách điểm danh buổi học:
/// - Avatar tròn kèm dấu chấm trạng thái (xanh lá / đỏ / vàng)
/// - Tên sinh viên + Nhãn cảnh báo (nếu có, e.g. "Cảnh báo 20%")
/// - MSSV · Bàn / Ghi chú
/// - Nút hành động hoặc Badge trạng thái:
///   + QR / Thủ công: Badge xanh "✓ 08:48 · QR" + menu ⋮
///   + Chưa quét: Nút cam "Điểm danh"
///   + Vắng phép: Badge vàng "Vắng phép" + nút "Đổi"
class AttendanceStudentCard extends StatelessWidget {
  final StudentAttendanceModel student;
  final VoidCallback? onManualCheckin;
  final VoidCallback? onChangeStatus;
  final VoidCallback? onOptions;
  final VoidCallback? onTap;

  const AttendanceStudentCard({
    super.key,
    required this.student,
    this.onManualCheckin,
    this.onChangeStatus,
    this.onOptions,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Viền đặc biệt nếu vắng hoặc vắng phép
    Color borderColor = isDark
        ? Theme.of(context).colorScheme.outline
        : const Color(0xFFF1F5F9);
    if (student.state == StudentAttendanceState.absentUnscanned) {
      borderColor = isDark
          ? const Color(0xFF7C2D12)
          : const Color(0xFFFFE0D2); // Viền cam nhạt
    } else if (student.state == StudentAttendanceState.absentExcused) {
      borderColor = isDark
          ? const Color(0xFF713F12)
          : const Color(0xFFFEF08A); // Viền vàng nhạt
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.2),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              children: [
                // ── Avatar tròn + Chấm trạng thái ──────────────────────────────────
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
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
                        width: 9.5,
                        height: 9.5,
                        decoration: BoxDecoration(
                          color: _getStatusDotColor(student.state),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 10),

                // ── Tên sinh viên + Cảnh báo + MSSV ─────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              student.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : AttendanceHistoryColors.textDark,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          if (student.warningText != null) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE4E6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                student.warningText!,
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFE11D48),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2.5),
                      Text(
                        _buildSubtitleText(student),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color:
                              student.state ==
                                  StudentAttendanceState.absentUnscanned
                              ? AttendanceHistoryColors.orangePrimary
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // ── Cột phải: Badge trạng thái hoặc Nút hành động ────────────────────
                _buildTrailingAction(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusDotColor(StudentAttendanceState state) {
    switch (state) {
      case StudentAttendanceState.presentQr:
      case StudentAttendanceState.presentManual:
        return const Color(0xFF10B981);
      case StudentAttendanceState.absentUnscanned:
        return const Color(0xFFEF4444);
      case StudentAttendanceState.absentExcused:
        return const Color(0xFFF59E0B);
    }
  }

  String _buildSubtitleText(StudentAttendanceModel student) {
    final seat = student.seatOrNote ?? '';
    switch (student.state) {
      case StudentAttendanceState.presentQr:
        return seat.isNotEmpty
            ? '${student.rollNumber} · $seat'
            : student.rollNumber;
      case StudentAttendanceState.presentManual:
        return seat.isNotEmpty
            ? '${student.rollNumber} · $seat'
            : '${student.rollNumber} · Xác nhận tay';
      case StudentAttendanceState.absentUnscanned:
        return seat.isNotEmpty
            ? '${student.rollNumber} · $seat'
            : '${student.rollNumber} · Chưa quét';
      case StudentAttendanceState.absentExcused:
        return seat.isNotEmpty
            ? '${student.rollNumber} · $seat'
            : '${student.rollNumber} · Đơn phép FAP';
    }
  }

  Widget _buildTrailingAction(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (student.state) {
      case StudentAttendanceState.presentQr:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8FDF2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFA7F3D0), width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_rounded,
                    size: 13,
                    color: Color(0xFF059669),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${student.checkinTime ?? '08:48'} · QR',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            _MoreVertButton(onTap: onOptions),
          ],
        );

      case StudentAttendanceState.presentManual:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8FDF2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFA7F3D0), width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_rounded,
                    size: 13,
                    color: Color(0xFF059669),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${student.checkinTime ?? '08:55'} · Thủ công',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            _MoreVertButton(onTap: onOptions),
          ],
        );

      case StudentAttendanceState.absentUnscanned:
        return InkWell(
          onTap: onManualCheckin,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AttendanceHistoryColors.orangePrimary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AttendanceHistoryColors.orangePrimary.withValues(
                    alpha: 0.28,
                  ),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.how_to_reg_rounded, size: 14, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'Điểm danh',
                  style: TextStyle(
                    fontSize: 11,
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF9C3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFEF08A)),
              ),
              child: const Text(
                'Vắng phép',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB45309),
                ),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: onChangeStatus,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4.5,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF475569)
                        : const Color(0xFFCBD5E1),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Đổi',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
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
        padding: EdgeInsets.all(4),
        child: Icon(
          Icons.more_vert_rounded,
          size: 16,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }
}
