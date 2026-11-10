import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../viewmodels/dashboard_viewmodel.dart';
import '../dashboard_colors.dart';

/// Ba KPI vận hành ngắn gọn; tỷ lệ chuyên cần nằm ở phần phân tích phía dưới.
class WeeklyOverviewCards extends StatelessWidget {
  const WeeklyOverviewCards({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? Theme.of(context).colorScheme.surface
        : DashboardColors.cardBg;
    final border = isDark
        ? const Color(0xFF334155)
        : DashboardColors.cardBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TỔNG QUAN NHANH',
          style: TextStyle(
            color: DashboardColors.textMuted,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            letterSpacing: .5,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
            boxShadow: isDark ? null : DashboardColors.cardShadow,
          ),
          child: Row(
            children: [
              Expanded(
                child: _KpiItem(
                  icon: Icons.menu_book_outlined,
                  value: '${vm.classes.length}',
                  label: 'Lớp phụ trách',
                ),
              ),
              const _KpiDivider(),
              Expanded(
                child: _KpiItem(
                  icon: Icons.fact_check_outlined,
                  value: '${vm.completedSessions}',
                  label: 'Buổi đã dạy',
                ),
              ),
              const _KpiDivider(),
              Expanded(
                child: _KpiItem(
                  icon: Icons.groups_outlined,
                  value: '${vm.totalStudents}',
                  label: 'Sinh viên',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}

class _KpiItem extends StatelessWidget {
  const _KpiItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value, label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: DashboardColors.orangePrimary),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          style: TextStyle(
            color: isDark ? Colors.white : DashboardColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : DashboardColors.textMuted,
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _KpiDivider extends StatelessWidget {
  const _KpiDivider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 52,
    color: Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0),
  );
}
