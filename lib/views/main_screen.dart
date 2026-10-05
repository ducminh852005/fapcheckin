import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/responsive/breakpoints.dart';
import 'package:fapcheckin/viewmodels/dashboard_viewmodel.dart';
import 'package:fapcheckin/viewmodels/live_session_viewmodel.dart';
import 'package:fapcheckin/views/teacher/schedule/schedule_body.dart';
import 'package:fapcheckin/views/teacher/live_session/live_session_body.dart';
import 'package:fapcheckin/views/teacher/class_management/class_management_body.dart';
import 'package:fapcheckin/views/teacher/attendance_history/attendance_history_body.dart';
import 'package:fapcheckin/views/teacher/report/report_body.dart';
import 'package:fapcheckin/views/teacher/settings/settings_body.dart';
import 'package:fapcheckin/viewmodels/auth_viewmodel.dart';
import 'package:fapcheckin/views/teacher/dashboard/components/sidebar.dart';
import 'package:fapcheckin/views/teacher/dashboard/components/nav_destinations.dart';
import 'package:fapcheckin/views/teacher/dashboard/components/top_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authVm = context.read<AuthViewModel>();
        final dashboardVm = context.read<DashboardViewModel>();

        if (authVm.session != null && dashboardVm.teacherMemberCode.isEmpty) {
          dashboardVm.setTeacherInfo(
            name: authVm.session!.user.fullName,
            email: authVm.session!.user.email,
            memberCode: authVm.session!.user.memberCode,
          );
        }

        dashboardVm.loadClasses();

        _timer = Timer.periodic(Duration(seconds: 1), (_) {
          if (mounted) {
            context.read<LiveSessionViewModel>().tickTimers();
            context.read<DashboardViewModel>().tickCountdown();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = context.watch<DashboardViewModel>().currentRoute;

    Widget body;
    switch (currentRoute) {
      case 'diem-danh-qr':
        body = LiveSessionBody();
        break;
      case 'lich-hoc':
        body = ScheduleBody();
        break;
      case 'lop-hoc':
        body = ClassManagementBody();
        break;
      case 'lich-su-diem-danh':
        body = AttendanceHistoryBody();
        break;
      case 'cai-dat':
        body = SettingsBody();
        break;
      case 'bao-cao':
      case 'tong-quan':
      default:
        body = ReportBody();
        break;
    }

    // Phone: bottom nav. 600-768: drawer. >= 768: permanent sidebar.
    final isMobile = context.isMobile;
    final isDesktop = context.screenWidth >= 768;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: isDesktop
          ? null
          : Drawer(
              width: math.min(304.0, context.screenWidth * 0.85),
              backgroundColor: AppColors.surface,
              child: SafeArea(child: Sidebar(width: double.infinity)),
            ),
      bottomNavigationBar: isMobile
          ? _MobileNavBar(currentRoute: currentRoute)
          : null,
      body: SafeArea(
        bottom: !isMobile,
        child: Stack(
          children: [
            Row(
              children: [
                if (isDesktop) Sidebar(),
                Expanded(
                  child: Column(
                    children: [
                      TopBar(isDesktop: isDesktop, currentRoute: currentRoute),
                      Expanded(child: body),
                    ],
                  ),
                ),
              ],
            ),
            ToastNotification(),
          ],
        ),
      ),
    );
  }
}

class _MobileNavBar extends StatelessWidget {
  final String currentRoute;

  const _MobileNavBar({required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final selected = kNavDestinations.indexWhere(
      (d) => d.isActive(currentRoute),
    );
    return NavigationBar(
      height: 64,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      selectedIndex: selected < 0 ? 0 : selected,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: (i) => context.read<DashboardViewModel>().navigate(
        kNavDestinations[i].route,
      ),
      destinations: [
        for (final d in kNavDestinations)
          NavigationDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: d.label,
          ),
      ],
    );
  }
}
