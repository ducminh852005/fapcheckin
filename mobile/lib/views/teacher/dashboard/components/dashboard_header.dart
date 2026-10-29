import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../viewmodels/auth_viewmodel.dart';
import '../../../../viewmodels/dashboard_viewmodel.dart';
import '../dashboard_colors.dart';
import 'notification_modal.dart';

/// Phần Header chào giảng viên với Avatar, trạng thái hoạt động và chuông thông báo.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final dashboardVm = context.watch<DashboardViewModel>();

    // Lấy thông tin giảng viên (Ưu tiên auth session -> dashboardVm -> Mặc định theo mockup)
    String teacherName = 'Thầy Minh';
    String initials = 'TM';

    final sessionName = authVm.session?.user.fullName;
    if (sessionName != null && sessionName.trim().isNotEmpty) {
      teacherName = sessionName;
      initials = dashboardVm.teacherInitials;
    } else if (dashboardVm.teacherName.isNotEmpty &&
        dashboardVm.teacherName != 'Giảng viên') {
      teacherName = dashboardVm.teacherName;
      initials = dashboardVm.teacherInitials;
    }

    // Học kỳ & Khoa
    final semesterText = dashboardVm.semester.isNotEmpty
        ? dashboardVm.semester
        : 'Fall 2026';
    final departmentText = 'Khoa CNTT • $semesterText';

    return Row(
      children: [
        // Avatar + Chấm xanh online
        GestureDetector(
          onTap: () {
            if (Scaffold.maybeOf(context)?.hasDrawer ?? false) {
              Scaffold.of(context).openDrawer();
            } else {
              dashboardVm.navigate('cai-dat');
            }
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFF7235),
                      Color(0xFFFA5A1E),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: DashboardColors.statusGreenDot,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Lời chào & Khoa/Học kỳ
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Xin chào, $teacherName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: DashboardColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                departmentText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: DashboardColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Nút chuông thông báo (Có chấm cam)
        InkWell(
          onTap: () => showNotificationModal(context),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: DashboardColors.cardBorder, width: 1),
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
                  color: DashboardColors.textDark,
                  size: 22,
                ),
                Positioned(
                  top: 9,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: DashboardColors.orangePrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

