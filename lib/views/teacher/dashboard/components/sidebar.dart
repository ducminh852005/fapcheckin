import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin/app/app_router.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';
import 'package:fapcheckin/viewmodels/auth_viewmodel.dart';
import 'package:fapcheckin/viewmodels/dashboard_viewmodel.dart';
import 'package:fapcheckin/views/teacher/dashboard/components/nav_destinations.dart';

class Sidebar extends StatelessWidget {
  /// Fixed width on desktop; pass `double.infinity` to fill a Drawer.
  final double width;

  const Sidebar({super.key, this.width = AppSpacing.sidebarWidth});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardViewModel>(
      builder: (context, vm, _) {
        return Container(
          width: width,
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Color(0x0F142433),
                blurRadius: 8,
                offset: Offset(1, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Logo header
              _SidebarHeader(),
              Divider(height: 1, color: AppColors.surfaceVariant),
              // Nav items
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: AppSpacing.sm),
                      for (final d in kNavDestinations)
                        _NavItem(
                          icon: d.isActive(vm.currentRoute)
                              ? d.selectedIcon
                              : d.icon,
                          label: d.label,
                          route: d.route,
                          activeRoutes: d.activeRoutes,
                          currentRoute: vm.currentRoute,
                          onTap: () => vm.navigate(d.route),
                        ),
                      /*
                      _NavItem(
                        icon: Icons.settings_outlined,
                        label: 'Cài đặt',
                        route: 'cai-dat',
                        currentRoute: vm.currentRoute,
                        onTap: () => vm.navigate('cai-dat'),
                      ),
                      */
                    ],
                  ),
                ),
              ),
              // User profile card
              _UserCard(vm: vm),
            ],
          ),
        );
      },
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.topBarHeight,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      color: AppColors.surface,
      child: Row(
        children: [
          Image.asset(
            'assets/images/logo_fap_check-in.png',
            height: 40,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final Set<String> activeRoutes;
  final String currentRoute;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    this.activeRoutes = const {},
    required this.currentRoute,
    required this.onTap,
  });

  bool get isActive =>
      currentRoute == route || activeRoutes.contains(currentRoute);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: () {
            onTap();
            if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
              Navigator.of(context).pop(); // Close drawer
            }
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.primaryContainer.withValues(
                          alpha: 0.3,
                        ),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive
                      ? AppColors.onPrimary
                      : AppColors.textSecondary,
                ),
                SizedBox(width: 12),
                Text(
                  label,
                  style: AppTextStyles.labelMd.copyWith(
                    color: isActive
                        ? AppColors.onPrimary
                        : AppColors.textSecondary,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
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

class _UserCard extends StatelessWidget {
  final DashboardViewModel vm;

  const _UserCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(AppSpacing.sm),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F142433),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                alignment: Alignment.center,
                child: Text(
                  vm.teacherInitials,
                  style: AppTextStyles.headlineSm.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vm.teacherName,
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      vm.teacherEmail,
                      style: AppTextStyles.code.copyWith(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Divider(height: 1, color: AppColors.surfaceContainerHigh),
          SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 4,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  'Giảng viên',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSecondaryContainer,
                  ),
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppColors.error,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
                icon: Icon(Icons.logout, size: 16),
                label: Text(
                  'Đăng xuất',
                  style: AppTextStyles.caption.copyWith(color: AppColors.error),
                ),
                onPressed: () async {
                  context.read<DashboardViewModel>().clearTeacherInfo();
                  await context.read<AuthViewModel>().signOut();
                  if (!context.mounted) return;
                  context.go(AppRoutes.login);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
