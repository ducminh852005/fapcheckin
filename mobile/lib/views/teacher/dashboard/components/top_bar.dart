import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin_core/constants/app_colors.dart';
import 'package:fapcheckin_core/constants/app_spacing.dart';
import 'package:fapcheckin_core/constants/app_text_styles.dart';
import 'package:fapcheckin_core/responsive/breakpoints.dart';
import './nav_destinations.dart';
import '../../../../viewmodels/dashboard_viewmodel.dart';

class TopBar extends StatelessWidget {
  final bool isDesktop;
  final String currentRoute;

  const TopBar({super.key, this.isDesktop = true, this.currentRoute = ''});

  String get _title {
    for (final d in kNavDestinations) {
      if (d.isActive(currentRoute)) return d.label;
    }
    return 'FAP Check-in';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardViewModel>(
      builder: (context, vm, _) {
        return Container(
          height: AppSpacing.topBarHeight,
          decoration: BoxDecoration(
            color: Color(0xF5FFFFFF), // surface/95
            boxShadow: [
              BoxShadow(
                color: Color(0x0D142433),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: context.pagePadding),
          child: Row(
            children: [
              if (!isDesktop) ...[
                _TopBarIconButton(
                  icon: context.isMobile
                      ? Icons.account_circle_outlined
                      : Icons.menu,
                  onTap: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
                SizedBox(width: AppSpacing.sm),
              ],
              if (context.isMobile)
                Expanded(
                  child: Text(
                    _title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headlineSm,
                  ),
                )
              else
                Spacer(),
              // Right: notifications + profile + window controls
              Row(
                children: [
                  // Notification bell
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _TopBarIconButton(
                        icon: Icons.notifications_outlined,
                        onTap: () {},
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TopBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopBarIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Icon(icon, size: 22, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
