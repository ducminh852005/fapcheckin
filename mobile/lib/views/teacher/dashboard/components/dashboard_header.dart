import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../viewmodels/auth_viewmodel.dart';
import '../../../../viewmodels/dashboard_viewmodel.dart';
import '../../profile/account_dialogs.dart';
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
    String teacherName = 'Giảng viên';
    String initials = 'GV';
    final avatarPath = authVm.session?.user.avatarPath ?? '';

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
        : '';
    final departmentText = semesterText.isEmpty
        ? dashboardVm.teacherEmail
        : semesterText;

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
              avatarPath.isNotEmpty
                  ? AccountAvatar(
                      key: ValueKey(avatarPath),
                      path: avatarPath,
                      initials: initials,
                      radius: 24,
                      backgroundColor: const Color(0xFFFA5A1E),
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    )
                  : Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFF7235), Color(0xFFFA5A1E)],
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
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF0F172A)
                          : Colors.white,
                      width: 2,
                    ),
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
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFF8FAFC)
                      : DashboardColors.textDark,
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
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF94A3B8)
                      : DashboardColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Nút chuông thông báo (Có chấm cam)
        Tooltip(
          message: 'Thông báo',
          child: IconButton(
            onPressed: () => showNotificationModal(context),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFF8FAFC)
                      : DashboardColors.textDark,
                  size: 25,
                ),
                Positioned(
                  top: -1,
                  right: -1,
                  child: Container(
                    width: 7,
                    height: 7,
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
