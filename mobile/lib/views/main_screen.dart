import './teacher/requests/requests_body.dart';

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin_core/constants/app_palette.dart';
import 'package:fapcheckin_core/responsive/breakpoints.dart';

import '../viewmodels/dashboard_viewmodel.dart';
import '../viewmodels/live_session_viewmodel.dart';
import './teacher/schedule/schedule_body.dart';
import './teacher/live_session/live_session_body.dart';
import './teacher/class_management/class_management_body.dart';
import './teacher/attendance_history/attendance_history_body.dart';
import './teacher/ai/ai_body.dart';
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
  final String? initialRoute;

  const MainScreen({super.key, this.initialRoute});

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

        if (widget.initialRoute != null && widget.initialRoute!.isNotEmpty) {
          dashboardVm.navigate(widget.initialRoute!);
        }

        if (authVm.session != null && dashboardVm.teacherMemberCode.isEmpty) {
          dashboardVm.setTeacherInfo(
            name: authVm.session!.user.fullName,
            email: authVm.session!.user.email,
            memberCode: authVm.session!.user.memberCode,
          );
        }

        dashboardVm.loadClasses();

        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) {
            context.read<LiveSessionViewModel>().tickTimers();
            context.read<DashboardViewModel>().tickCountdown();
          }
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant MainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialRoute != null &&
        widget.initialRoute!.isNotEmpty &&
        widget.initialRoute != oldWidget.initialRoute) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<DashboardViewModel>().navigate(widget.initialRoute!);
        }
      });
    }
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
      case 'yeu-cau':
        body = const RequestsBody();
        break;
      case 'ai':
        body = const AiBody();
        break;
      // 'bao-cao' (cũ) rơi về Tổng quan — báo cáo nay nằm trong Tổng quan.
      case 'bao-cao':
      case 'tong-quan':
      default:
        body = const DashboardBody();
        break;
    }

    // < 768: bottom nav (mobile & small tablet). >= 768: permanent sidebar.
    final isDesktop = context.screenWidth >= 768;
    final showBottomNav = !isDesktop;
    final dashboardVm = context.watch<DashboardViewModel>();

    return PopScope(
      canPop: !dashboardVm.canNavigateBack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          dashboardVm.navigateBack();
        }
      },
      child: Scaffold(
        extendBody: showBottomNav,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        bottomNavigationBar: showBottomNav
            ? _MobileNavBar(currentRoute: currentRoute)
            : null,
        body: SafeArea(
          bottom: !showBottomNav,
          child: Stack(
            children: [
              Row(
                children: [
                  if (isDesktop) const Sidebar(),
                  Expanded(
                    child: Column(
                      children: [
                        if (isDesktop)
                          TopBar(
                            isDesktop: isDesktop,
                            currentRoute: currentRoute,
                          ),
                        Expanded(child: body),
                      ],
                    ),
                  ),
                ],
              ),
              const ToastNotification(),
            ],
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                  // Nền kính mờ (Frosted Glass) thích ứng Sáng / Tối
                  color: isDark
                      ? const Color(0xFF1E293B).withValues(alpha: 0.88)
                      : Colors.white.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(38),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155).withValues(alpha: 0.9)
                        : Colors.white.withValues(alpha: 0.95),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      selected: isSelected,
      button: true,
      label: destination.label,
      child: Tooltip(
        message: destination.label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark
                        ? AppPalette.primary.withValues(alpha: 0.22)
                        : const Color(0xFFFFEDE5).withValues(alpha: 0.95))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(30),
              border: isSelected
                  ? Border.all(
                      color: isDark
                          ? AppPalette.primary.withValues(alpha: 0.45)
                          : const Color(0xFFFFD4C2).withValues(alpha: 0.8),
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
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? destination.selectedIcon : destination.icon,
                  color: isSelected
                      ? AppPalette.primary
                      : (isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B)),
                  size: 21,
                ),
                const SizedBox(height: 3),
                Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppPalette.primary
                        : (isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B)),
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
