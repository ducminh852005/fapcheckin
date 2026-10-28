import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../viewmodels/auth_viewmodel.dart';
import '../../../../viewmodels/dashboard_viewmodel.dart';
import '../schedule_colors.dart';

/// Phần Header của trang Lịch dạy:
/// - Lời chào "XIN CHÀO, THẦY MINH"
/// - Tiêu đề lớn "Lịch dạy của tôi"
/// - Nút chuông thông báo & Nút quét TKB
class ScheduleHeader extends StatelessWidget {
  final VoidCallback? onScanTimetable;

  const ScheduleHeader({super.key, this.onScanTimetable});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final dashboardVm = context.watch<DashboardViewModel>();

    // Tên giảng viên
    String teacherName = 'THẦY MINH';
    final sessionName = authVm.session?.user.fullName;
    if (sessionName != null && sessionName.trim().isNotEmpty) {
      teacherName = sessionName.toUpperCase();
    } else if (dashboardVm.teacherName.isNotEmpty &&
        dashboardVm.teacherName != 'Giảng viên') {
      teacherName = dashboardVm.teacherName.toUpperCase();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'XIN CHÀO, $teacherName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ScheduleColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Lịch dạy của tôi',
                style: TextStyle(
                  color: ScheduleColors.textDark,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),

        // Nút Scan TKB & Nút chuông
        Row(
          children: [
            if (onScanTimetable != null) ...[
              IconButton.outlined(
                icon: const Icon(
                  Icons.document_scanner_outlined,
                  size: 20,
                  color: ScheduleColors.textDark,
                ),
                tooltip: 'Quét thời khóa biểu',
                onPressed: onScanTimetable,
                style: IconButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: const CircleBorder(),
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Nút chuông
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    color: ScheduleColors.textDark,
                    size: 22,
                  ),
                  Positioned(
                    top: 9,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: ScheduleColors.orangePrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
