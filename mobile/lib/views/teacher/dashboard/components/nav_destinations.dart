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
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    label: 'Tổng quan',
    route: 'tong-quan',
    activeRoutes: {'bao-cao'},
  ),
  NavDestination(
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month,
    label: 'Lịch học',
    route: 'lich-hoc',
  ),
  NavDestination(
    icon: Icons.school_outlined,
    selectedIcon: Icons.school,
    label: 'Tiết học',
    route: 'lop-hoc',
    activeRoutes: {'diem-danh-qr'},
  ),
  NavDestination(
    icon: Icons.menu_book_outlined,
    selectedIcon: Icons.menu_book,
    label: 'Khóa học',
    route: 'lich-su-diem-danh',
  ),
];
