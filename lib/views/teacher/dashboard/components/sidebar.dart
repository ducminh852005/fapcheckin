import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';
import 'package:fapcheckin/viewmodels/dashboard_viewmodel.dart';
import 'package:fapcheckin/views/auth/login_screen.dart' as fap_login;

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardViewModel>(
      builder: (context, vm, _) {
        return Container(
          width: AppSpacing.sidebarWidth,
          decoration: const BoxDecoration(
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
              const Divider(height: 1, color: AppColors.surfaceVariant),
              // Nav items
              const SizedBox(height: AppSpacing.sm),
              _NavItem(
                icon: Icons.dashboard_outlined,
                label: 'Tổng quan',
                route: 'tong-quan',
                currentRoute: vm.currentRoute,
                onTap: () => vm.navigate('tong-quan'),
              ),
              _NavItem(
                icon: Icons.school_outlined,
                label: 'Lớp học',
                route: 'lop-hoc',
                currentRoute: vm.currentRoute,
                onTap: () => vm.navigate('lop-hoc'),
              ),
              _NavItem(
                icon: Icons.history_outlined,
                label: 'Lịch sử điểm danh',
                route: 'lich-su-diem-danh',
                currentRoute: vm.currentRoute,
                onTap: () => vm.navigate('lich-su-diem-danh'),
              ),
              _NavItem(
                icon: Icons.bar_chart_outlined,
                label: 'Báo cáo',
                route: 'bao-cao',
                currentRoute: vm.currentRoute,
                onTap: () => vm.navigate('bao-cao'),
              ),
              _NavItem(
                icon: Icons.settings_outlined,
                label: 'Cài đặt',
                route: 'cai-dat',
                currentRoute: vm.currentRoute,
                onTap: () => vm.navigate('cai-dat'),
              ),
              const Spacer(),
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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
  final String currentRoute;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentRoute,
    required this.onTap,
  });

  bool get isActive => currentRoute == route;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.primaryContainer.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? AppColors.onPrimary : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: AppTextStyles.labelMd.copyWith(
                    color: isActive ? AppColors.onPrimary : AppColors.textSecondary,
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
      margin: const EdgeInsets.all(AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: const [
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
              const SizedBox(width: 12),
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
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.surfaceContainerHigh),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const fap_login.LoginScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppColors.error,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
                icon: const Icon(Icons.logout, size: 16),
                label: Text(
                  'Đăng xuất',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
