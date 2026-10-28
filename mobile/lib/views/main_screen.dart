import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin_core/constants/app_colors.dart';
import 'package:fapcheckin_core/responsive/breakpoints.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../viewmodels/live_session_viewmodel.dart';
import './teacher/schedule/schedule_body.dart';
import './teacher/live_session/live_session_body.dart';
import './teacher/class_management/class_management_body.dart';
import './teacher/attendance_history/attendance_history_body.dart';
import './teacher/report/report_body.dart';
import './teacher/profile/profile_body.dart';
import './teacher/profile/personal_info_body.dart';
import './teacher/profile/work_info_body.dart';
import './teacher/dashboard/dashboard_body.dart';
import '../viewmodels/auth_viewmodel.dart';
import './teacher/dashboard/components/sidebar.dart';
import './teacher/dashboard/components/nav_destinations.dart';
import './teacher/dashboard/components/top_bar.dart';

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
      case 'ho-so':
        body = const ProfileBody();
        break;
      case 'thong-tin-ca-nhan':
        body = const PersonalInfoBody();
        break;
      case 'thong-tin-cong-tac':
        body = const WorkInfoBody();
        break;
      case 'bao-cao':
        body = ReportBody();
        break;
      case 'tong-quan':
      default:
        body = const DashboardBody();
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
                      if (isDesktop ||
                          (currentRoute != 'tong-quan' &&
                              currentRoute != 'lich-hoc' &&
                              currentRoute != 'lop-hoc' &&
                              currentRoute != 'bao-cao' &&
                              currentRoute != 'cai-dat' &&
                              currentRoute != 'ho-so' &&
                              currentRoute != 'thong-tin-ca-nhan' &&
                              currentRoute != 'thong-tin-cong-tac' &&
                              currentRoute != 'diem-danh-qr'))
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          height: 64,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFFFF0EB),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFA5A1E),
              );
            }
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8898A4),
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(
                color: Color(0xFFFA5A1E),
                size: 23,
              );
            }
            return const IconThemeData(
              color: Color(0xFF8898A4),
              size: 22,
            );
          }),
        ),
        child: NavigationBar(
          height: 64,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          selectedIndex: selected < 0 ? 0 : selected,
          labelBehavior: context.screenWidth < 340
              ? NavigationDestinationLabelBehavior.onlyShowSelected
              : NavigationDestinationLabelBehavior.alwaysShow,
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
        ),
      ),
    );
  }
}
