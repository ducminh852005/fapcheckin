import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../viewmodels/dashboard_viewmodel.dart';
import '../dashboard_colors.dart';

/// Mục "CHỨC NĂNG CHÍNH": Lịch dạy, Quản lý lớp và Lịch sử ca.
class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardVm = context.read<DashboardViewModel>();

    final actions = [
      _QuickActionItem(
        icon: Icons.calendar_today_rounded,
        label: 'Lịch dạy',
        iconColor: DashboardColors.quickActionCalendar,
        bgColor: DashboardColors.quickActionCalendarBg,
        onTap: () => dashboardVm.navigate('lich-hoc'),
      ),
      _QuickActionItem(
        icon: Icons.groups_rounded,
        label: 'Quản lý lớp',
        iconColor: DashboardColors.quickActionClasses,
        bgColor: DashboardColors.quickActionClassesBg,
        onTap: () => dashboardVm.navigate('lop-hoc'),
      ),
      _QuickActionItem(
        icon: Icons.access_time_rounded,
        label: 'Lịch sử ca',
        iconColor: DashboardColors.quickActionHistory,
        bgColor: DashboardColors.quickActionHistoryBg,
        onTap: () => dashboardVm.navigate('lich-su-diem-danh'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề mục: CHỨC NĂNG CHÍNH & Tất cả
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'CHỨC NĂNG CHÍNH',
              style: TextStyle(
                color: DashboardColors.textMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            InkWell(
              onTap: () => dashboardVm.navigate('lop-hoc'),
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  'Tất cả',
                  style: TextStyle(
                    color: DashboardColors.orangePrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Hàng 4 thẻ phím tắt
        Row(
          children: [
            for (int i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: _buildActionCard(actions[i])),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(_QuickActionItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: DashboardColors.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: DashboardColors.cardBorder, width: 1),
          boxShadow: DashboardColors.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Container bo tròn màu pastel cho icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(item.icon, color: item.iconColor, size: 22),
            ),
            const SizedBox(height: 10),

            // Nhãn tên chức năng
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: DashboardColors.textDark,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionItem {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.bgColor,
    required this.onTap,
  });
}
