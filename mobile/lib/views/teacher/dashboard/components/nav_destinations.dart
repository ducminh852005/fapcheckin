import 'package:flutter/material.dart';

/// A top-level navigation destination shared by the Sidebar (desktop/tablet)
/// and the bottom NavigationBar (mobile).
class NavDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;

  /// Other routes that should highlight this destination.
  final Set<String> activeRoutes;

  const NavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
    this.activeRoutes = const {},
  });

  bool isActive(String currentRoute) =>
      currentRoute == route || activeRoutes.contains(currentRoute);
}

const List<NavDestination> kNavDestinations = [
  NavDestination(
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
    label: 'Trang chủ',
    route: 'tong-quan',
  ),
  NavDestination(
    icon: Icons.calendar_today_outlined,
    selectedIcon: Icons.calendar_today_rounded,
    label: 'Lịch dạy',
    route: 'lich-hoc',
  ),
  NavDestination(
    icon: Icons.groups_outlined,
    selectedIcon: Icons.groups_rounded,
    label: 'Quản lý lớp',
    route: 'lop-hoc',
    activeRoutes: {'diem-danh-qr'},
  ),
  NavDestination(
    icon: Icons.bar_chart_outlined,
    selectedIcon: Icons.bar_chart_rounded,
    label: 'Báo cáo',
    route: 'bao-cao',
  ),
  NavDestination(
    icon: Icons.person_outline_rounded,
    selectedIcon: Icons.person_rounded,
    label: 'Hồ sơ',
    route: 'cai-dat',
    activeRoutes: {'ho-so', 'thong-tin-ca-nhan', 'thong-tin-cong-tac'},
  ),
];
