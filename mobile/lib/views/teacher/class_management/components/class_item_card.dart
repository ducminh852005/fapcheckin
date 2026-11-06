import 'package:flutter/material.dart';
import '../class_management_colors.dart';

enum ClassCardStatus { active, next, normal }

/// Thẻ hiển thị một lớp học trong danh sách Quản lý lớp:
/// - Bên trái: Khối giờ học (Thứ/Hôm nay, Giờ bắt đầu, Số slot)
/// - Ở giữa: Mã môn, Mã lớp, Tên môn, Giờ chi tiết, Phòng, Sĩ số, Tỉ lệ có mặt
/// - Bên phải: Badge trạng thái (Đang dạy / Tiếp theo / Mũi tên >)
/// - Viền cam nổi bật kèm thanh thao tác nhanh khi lớp đang trong ca dạy
class ClassItemCard extends StatelessWidget {
  final String dayLabel; // "Hôm nay", "Thứ 6", "Thứ 2"
  final String startTime; // "07:30", "12:50"
  final String slotLabel; // "Slot 1", "Slot 3"
  final String subjectCode; // "PRN231"
  final String classCode; // "SE1801"
  final String subjectName; // "Lập trình ứng dụng .NET"
  final String timeDetail; // "07:30–09:50 • AL-204 • 32 SV"
  final String attendanceRate; // "92.5%" hoặc "0.0%"
  final ClassCardStatus status;
  final String? activeScannedInfo; // "28/32 có mặt"
  final VoidCallback? onOpenCheckin;
  final VoidCallback? onTap;

  const ClassItemCard({
    super.key,
    required this.dayLabel,
    required this.startTime,
    required this.slotLabel,
    required this.subjectCode,
    required this.classCode,
    required this.subjectName,
    required this.timeDetail,
    required this.attendanceRate,
    this.status = ClassCardStatus.normal,
    this.activeScannedInfo,
    this.onOpenCheckin,
    this.onTap,
  });

  Color _resolveRateColor(String rateText) {
    final cleaned = rateText.replaceAll('%', '').replaceAll(',', '.').trim();
    final val = double.tryParse(cleaned);
    if (val == null || val <= 0) {
      return ClassManagementColors.textMuted;
    }
    if (val < 80) {
      return ClassManagementColors.orangePrimary;
    }
    return ClassManagementColors.statusGreen;
  }

  @override
  Widget build(BuildContext context) {
    final isActive = status == ClassCardStatus.active;
    final isNext = status == ClassCardStatus.next;
    final rateColor = _resolveRateColor(attendanceRate);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? Theme.of(context).colorScheme.surface : Colors.white;
    final cardBorder = isActive
        ? ClassManagementColors.orangePrimary
        : (isDark ? const Color(0xFF334155) : ClassManagementColors.cardBorder);
    final textColor = isDark
        ? const Color(0xFFF8FAFC)
        : ClassManagementColors.textDark;
    final mutedColor = isDark
        ? const Color(0xFF94A3B8)
        : ClassManagementColors.textMuted;
    final subtleColor = isDark
        ? const Color(0xFF64748B)
        : ClassManagementColors.textSubtle;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: cardBorder,
                width: isActive ? 1.5 : 1,
              ),
              boxShadow: isActive
                  ? ClassManagementColors.activeCardShadow
                  : (isDark ? null : ClassManagementColors.cardShadow),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Cột trái: Khối giờ học ──────────────────────────────────
                    Container(
                      width: 64,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? (isDark
                                  ? ClassManagementColors.orangePrimary
                                        .withValues(alpha: 0.16)
                                  : ClassManagementColors.orangeLight)
                            : (isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? ClassManagementColors.orangePrimary
                                  : mutedColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            startTime,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isActive
                                  ? ClassManagementColors.orangePrimary
                                  : textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            slotLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isActive
                                  ? ClassManagementColors.orangePrimary
                                  : mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),

                    // ── Cột giữa: Chi tiết môn & lớp ────────────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hàng: Mã môn + Mã lớp
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: subjectCode,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: '  ',
                                  ),
                                  TextSpan(
                                    text: classCode,
                                    style: TextStyle(
                                      color: mutedColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),

                          // Tên môn học
                          Text(
                            subjectName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: mutedColor,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 3),

                          // Giờ - Phòng - Sĩ số (FittedBox chống cắt chữ trên màn hẹp)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              timeDetail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: subtleColor,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Tỉ lệ có mặt tuần này
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Có mặt tuần này: ',
                                  style: TextStyle(
                                    color: mutedColor,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                TextSpan(
                                  text: attendanceRate,
                                  style: TextStyle(
                                    color: rateColor,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Cột phải: Badge trạng thái hoặc mũi tên ─────────────────
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? ClassManagementColors.orangePrimary.withValues(
                                  alpha: 0.16,
                                )
                              : ClassManagementColors.orangeBadgeBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: ClassManagementColors.orangePrimary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Đang dạy',
                              style: TextStyle(
                                color: ClassManagementColors.orangePrimary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (isNext)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: ClassManagementColors.statusNextBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Tiếp theo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFFCBD5E1),
                          size: 22,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
