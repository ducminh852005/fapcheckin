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

        // Nút Scan TKB
        if (onScanTimetable != null)
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: ScheduleColors.orangeBorder,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFA5A1E).withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.document_scanner_outlined,
                size: 20,
                color: ScheduleColors.textDark,
              ),
              tooltip: 'Quét thời khóa biểu',
              onPressed: onScanTimetable,
              padding: EdgeInsets.zero,
            ),
          ),
      ],
    );
  }
}
