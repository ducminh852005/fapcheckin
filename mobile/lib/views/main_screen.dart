import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin_core/constants/app_colors.dart';
import 'package:fapcheckin_core/constants/app_palette.dart';
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
import './teacher/settings/settings_help_body.dart';
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
        } else if (dashboardVm.teacherMemberCode.isEmpty) {
          dashboardVm.setTeacherInfo(
            name: 'Khoaaaa',
            email: 'khoale@fpt.edu.vn',
            memberCode: 'GV01234',
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
      case 'cai-dat-tro-giup':
        body = const SettingsHelpBody();
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
      extendBody: isMobile,
      backgroundColor: AppColors.background,
      drawer: isDesktop
          ? null
          : Drawer(
              width: math.min(304.0, context.screenWidth * 0.85),
              backgroundColor: AppColors.surface,
              child: SafeArea(child: Sidebar(width: double.infinity)),
            ),
      bottomNavigationBar:
          isMobile ? _MobileNavBar(currentRoute: currentRoute) : null,
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
                              currentRoute != 'cai-dat-tro-giup' &&
                              currentRoute != 'lich-su-diem-danh' &&
                              currentRoute != 'diem-danh-qr'))
                        TopBar(
                            isDesktop: isDesktop, currentRoute: currentRoute),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: isMobile ? 84.0 : 0.0,
                          ),
                          child: body,
                        ),
                      ),
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
    final activeIndex = selected < 0 ? 0 : selected;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Container(
          height: 66,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(38),
            boxShadow: [
              // Đổ bóng nổi đa tầng phong cách iOS 26 (Floating Drop Shadow)
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: const Color(0xFFFA5A1E).withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(38),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  // Nền trắng đục kính mờ (Frosted Glass) phong cách iOS 26
                  color: Colors.white.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(38),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.95),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                child: Row(
                  children: [
                    for (int i = 0; i < kNavDestinations.length; i++)
                      Expanded(
                        child: _NavBarItem(
                          destination: kNavDestinations[i],
                          isSelected: i == activeIndex,
                          onTap: () => context
                              .read<DashboardViewModel>()
                              .navigate(kNavDestinations[i].route),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final NavDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFEDE5).withValues(alpha: 0.95)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: isSelected
              ? Border.all(
                  color: const Color(0xFFFFD4C2).withValues(alpha: 0.8),
                  width: 1,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFA5A1E).withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? destination.selectedIcon : destination.icon,
              color: isSelected ? AppPalette.primary : const Color(0xFF64748B),
              size: 21,
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                destination.label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color:
                      isSelected ? AppPalette.primary : const Color(0xFF64748B),
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
