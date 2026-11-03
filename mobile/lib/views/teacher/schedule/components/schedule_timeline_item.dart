import 'package:flutter/material.dart';
import '../schedule_colors.dart';

enum ScheduleSessionStatus { completed, active, upcoming }

/// Một ca học trên trục Timeline:
/// - Bên trái: Trục dọc nối các ca + Vòng tròn đánh số ca (1, 2, 3...)
/// - Bên phải: Thẻ chi tiết ca học với 3 trạng thái:
///   1. [completed] - Đã xong (Huy hiệu xanh lá)
///   2. [active] - Đang dạy (Viền cam, huy hiệu cam, nút "Mở điểm danh ngay")
///   3. [upcoming] - Chưa bắt đầu (Huy hiệu xám)
class ScheduleTimelineItem extends StatelessWidget {
  final int slot;
  final String timeRange;
  final String subjectCode;
  final String classCode;
  final String subjectName;
  final String room;
  final String subtext;
  final ScheduleSessionStatus status;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onOpenAttendance;
  final VoidCallback? onTap;

  const ScheduleTimelineItem({
    super.key,
    required this.slot,
    required this.timeRange,
    required this.subjectCode,
    required this.classCode,
    required this.subjectName,
    required this.room,
    required this.subtext,
    required this.status,
    this.isFirst = false,
    this.isLast = false,
    this.onOpenAttendance,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = status == ScheduleSessionStatus.active;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Cột trái: Trục thời gian (Timeline) + Badge số ca ───────────────
          SizedBox(
            width: 38,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // Vạch kẻ dọc nối từ trên xuống dưới
                Positioned(
                  top: isFirst ? 16 : 0,
                  bottom: isLast ? null : 0,
                  height: isLast ? 16 : null,
                  child: Container(
                    width: 2,
                    color: ScheduleColors.timelineLine,
                  ),
                ),

                // Vòng tròn hiển thị số ca (1, 2, 3..)
                Positioned(
                  top: 10,
                  child: Container(
                    width: isActive ? 30 : 28,
                    height: isActive ? 30 : 28,
                    decoration: BoxDecoration(
                      color: isActive
                          ? ScheduleColors.orangePrimary
                          : ScheduleColors.slotBadgeBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive
                            ? Colors.white
                            : ScheduleColors.orangeBorder,
                        width: isActive ? 2 : 1.2,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: ScheduleColors.orangePrimary
                                    .withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: const Color(0xFFFA5A1E)
                                    .withValues(alpha: 0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$slot',
                      style: TextStyle(
                        fontSize: isActive ? 13 : 12,
                        fontWeight: FontWeight.w800,
                        color: isActive
                            ? Colors.white
                            : ScheduleColors.orangePrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // ── Cột phải: Thẻ thông tin ca học ──────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isActive
                          ? ScheduleColors.orangePrimary
                          : ScheduleColors.cardBorder,
                      width: isActive ? 1.6 : 1.2,
                    ),
                    boxShadow: isActive
                        ? ScheduleColors.activeCardShadow
                        : ScheduleColors.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Hàng trên cùng: Giờ học + Badge trạng thái
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              timeRange,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: ScheduleColors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _buildStatusBadge(),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Tên môn & Mã lớp
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: subjectCode,
                                style: const TextStyle(
                                  color: ScheduleColors.textDark,
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const TextSpan(
                                text: '  •  ',
                                style: TextStyle(
                                  color: ScheduleColors.textSubtle,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: classCode,
                                style: TextStyle(
                                  color: isActive
                                      ? ScheduleColors.orangePrimary
                                      : ScheduleColors.textDark,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),

                      // Tên môn chi tiết & Phòng học
                      Text(
                        '$subjectName • $room',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ScheduleColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Dòng phụ chú trạng thái điểm danh
                      Text(
                        subtext,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isActive
                              ? ScheduleColors.statusDone
                              : ScheduleColors.textMuted,
                          fontSize: 11.5,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),

                      // Nếu đang dạy -> Nút "Mở điểm danh ngay"
                      if (isActive) ...[
                        const SizedBox(height: 14),
                        InkWell(
                          onTap: onOpenAttendance,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 44,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Color(0xFFFA5A1E),
                                  Color(0xFFFF7235),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: ScheduleColors.orangePrimary
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.qr_code_scanner_rounded,
                                      color: Colors.white,
                                      size: 19,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Mở điểm danh ngay',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    switch (status) {
      case ScheduleSessionStatus.completed:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: ScheduleColors.statusDoneBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBBF7D0), width: 0.8),
          ),
          child: const Text(
            'Đã xong',
            style: TextStyle(
              color: ScheduleColors.statusDone,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        );

      case ScheduleSessionStatus.active:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: ScheduleColors.statusActiveBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ScheduleColors.orangeBorder, width: 0.8),
          ),
          child: const Text(
            'Đang dạy',
            style: TextStyle(
              color: ScheduleColors.statusActive,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        );

      case ScheduleSessionStatus.upcoming:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: ScheduleColors.statusPendingBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFE0D3), width: 0.8),
          ),
          child: const Text(
            'Chưa bắt đầu',
            style: TextStyle(
              color: ScheduleColors.statusPending,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
    }
  }
}
