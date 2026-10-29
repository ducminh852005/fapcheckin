import 'package:flutter/material.dart';
import '../attendance_history_colors.dart';

/// Thẻ thống kê tóm tắt buổi điểm danh:
/// - Sĩ số lớp: 32 Sinh viên
/// - Huy hiệu "● Đang diễn ra"
/// - Tỉ lệ phần trăm "87.5%"
/// - Thanh đo tiến độ 2 màu (Xanh lá 87.5% & Cam 12.5%)
/// - Chi tiết: "● Có mặt: 28 SV" & "● Vắng: 4 SV (1 có phép)"
class AttendanceSummaryCard extends StatelessWidget {
  final int totalStudents;
  final int presentCount;
  final int absentCount;
  final int excusedAbsentCount;
  final double attendanceRate;
  final bool isOngoing;

  const AttendanceSummaryCard({
    super.key,
    this.totalStudents = 32,
    this.presentCount = 28,
    this.absentCount = 4,
    this.excusedAbsentCount = 1,
    this.attendanceRate = 87.5,
    this.isOngoing = true,
  });

  @override
  Widget build(BuildContext context) {
    final rateFraction = (attendanceRate / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AttendanceHistoryColors.cardBorder),
        boxShadow: AttendanceHistoryColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Hàng 1: Sĩ số + Badge đang diễn ra + Tỉ lệ % (Dùng Wrap chống tràn)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text(
                      'Sĩ số: $totalStudents SV',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AttendanceHistoryColors.textDark,
                      ),
                    ),
                    if (isOngoing)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AttendanceHistoryColors.statusGreenBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: AttendanceHistoryColors.statusGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Đang diễn ra',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AttendanceHistoryColors.statusGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${attendanceRate.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AttendanceHistoryColors.textDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Hàng 2: Thanh tiến độ 2 màu (Xanh lá & Cam FPT) ─────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Expanded(
                    flex: (rateFraction * 1000).toInt(),
                    child: Container(
                      color: AttendanceHistoryColors.progressGreen,
                    ),
                  ),
                  Expanded(
                    flex: ((1 - rateFraction) * 1000).toInt(),
                    child: Container(
                      color: AttendanceHistoryColors.orangePrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Hàng 3: Chi tiết Có mặt / Vắng (Dùng Wrap chống tràn trên màn hẹp) ─
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              // Có mặt
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AttendanceHistoryColors.statusGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Có mặt: ',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AttendanceHistoryColors.textMuted,
                    ),
                  ),
                  Text(
                    '$presentCount SV',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AttendanceHistoryColors.textDark,
                    ),
                  ),
                ],
              ),

              // Vắng
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 3,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AttendanceHistoryColors.orangePrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Vắng: ',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AttendanceHistoryColors.textMuted,
                        ),
                      ),
                      Text(
                        '$absentCount SV',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AttendanceHistoryColors.orangePrimary,
                        ),
                      ),
                    ],
                  ),
                  if (excusedAbsentCount > 0)
                    Text(
                      '($excusedAbsentCount có phép)',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AttendanceHistoryColors.textSubtle,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
