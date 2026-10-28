import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin_core/models/class_section_model.dart';
import '../../../../viewmodels/dashboard_viewmodel.dart';
import '../../../../viewmodels/live_session_viewmodel.dart';
import '../../live_session/components/manual_attendance_bottom_sheet.dart';
import '../dashboard_colors.dart';

/// Thẻ hiển thị ca học đang diễn ra kèm tiến độ điểm danh và 2 nút hành động nhanh.
class ActiveSessionCard extends StatelessWidget {
  const ActiveSessionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardVm = context.watch<DashboardViewModel>();
    final liveSessionVm = context.watch<LiveSessionViewModel>();

    // Tìm lớp đang diễn ra (hoặc lấy lớp đầu tiên / fallback dữ liệu mẫu từ mockup)
    ClassSectionModel? activeClass;
    for (final c in dashboardVm.classes) {
      if (c.isActive) {
        activeClass = c;
        break;
      }
    }
    activeClass ??= dashboardVm.classes.isNotEmpty
        ? dashboardVm.classes.first
        : null;

    final subjectCode = activeClass?.subjectCode.isNotEmpty == true
        ? activeClass!.subjectCode
        : 'PRN231';
    final classCode = activeClass?.classCode.isNotEmpty == true
        ? activeClass!.classCode
        : 'SE1801';
    final subjectName = activeClass?.subjectName.isNotEmpty == true
        ? activeClass!.subjectName
        : 'Lập trình ứng dụng .NET (C#)';
    final room = activeClass?.room.isNotEmpty == true
        ? activeClass!.room
        : 'AL-204';
    final slotLabel = activeClass?.slotCode.isNotEmpty == true
        ? 'Ca ${activeClass!.slotCode}: ${activeClass.timeLabel}'
        : 'Ca 2: 08:45 – 10:15';

    // Thống kê sinh viên điểm danh
    final totalStudents = activeClass?.studentCount != null &&
            activeClass!.studentCount > 0
        ? activeClass.studentCount
        : 32;

    int scannedStudents = 28;
    if (liveSessionVm.session != null &&
        liveSessionVm.classInfo?.classCode == classCode) {
      scannedStudents = liveSessionVm.roster.where((r) => r.isPresent).length;
    } else if (dashboardVm.activeSessionScanned > 0) {
      scannedStudents = dashboardVm.activeSessionScanned;
    }

    final double progress = (scannedStudents / totalStudents).clamp(0.0, 1.0);
    final percentText = '${(progress * 100).toStringAsFixed(1)}%';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DashboardColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DashboardColors.cardBorder, width: 1.2),
        boxShadow: DashboardColors.activeCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dòng trên cùng: Badge "Đang diễn ra" + Thời gian ca
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Badge "Đang diễn ra"
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: DashboardColors.statusGreenBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: DashboardColors.statusGreenDot,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Đang diễn ra',
                      style: TextStyle(
                        color: DashboardColors.statusGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Thông tin ca & giờ học
              Flexible(
                child: Text(
                  slotLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DashboardColors.textMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

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
                      color: DashboardColors.textDark,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const TextSpan(
                    text: '  •  ',
                    style: TextStyle(
                      color: DashboardColors.textSubtle,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: 'Lớp $classCode',
                    style: const TextStyle(
                      color: DashboardColors.orangePrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Tên chi tiết môn học & Phòng học
          Text(
            '$subjectName • Phòng $room',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: DashboardColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          // Thống kê tiến độ điểm danh
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: Text(
                        'Tiến độ điểm danh',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: DashboardColors.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '$scannedStudents',
                                style: const TextStyle(
                                  color: DashboardColors.orangePrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextSpan(
                                text: '/$totalStudents sinh viên ',
                                style: const TextStyle(
                                  color: DashboardColors.textDark,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(
                                text: '($percentText)',
                                style: const TextStyle(
                                  color: DashboardColors.textSubtle,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Thanh tiến độ cam (Progress Bar)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: DashboardColors.cardTrack,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      DashboardColors.orangePrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2 nút thao tác chính: [Mở Live QR] và [Điểm danh tay]
          Row(
            children: [
              // Nút 1: Mở Live QR (Chính - Cam nổi bật)
              Expanded(
                flex: 6,
                child: InkWell(
                  onTap: () {
                    // Chuyển sang màn hình điểm danh QR
                    dashboardVm.navigate('diem-danh-qr');
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      gradient: DashboardColors.primaryButtonGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: DashboardColors.orangePrimary.withValues(alpha: 0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
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
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Mở Live QR',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Nút 2: Điểm danh tay (Phụ - Viền xám)
              Expanded(
                flex: 5,
                child: InkWell(
                  onTap: () => ManualAttendanceBottomSheet.show(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                    ),
                    child: const Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.how_to_reg_outlined,
                              color: DashboardColors.textBody,
                              size: 20,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Điểm danh tay',
                              style: TextStyle(
                                color: DashboardColors.textDark,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

