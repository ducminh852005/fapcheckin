import 'package:flutter/material.dart';
import '../report_colors.dart';

/// 2 thẻ thống kê nhanh:
/// - Lượt có mặt: số lượng màu xanh lá
/// - Lượt vắng mặt: số lượng màu cam
class ReportStatCards extends StatelessWidget {
  final int presentCount;
  final int absentCount;

  const ReportStatCards({
    super.key,
    this.presentCount = 542,
    this.absentCount = 34,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Lượt có mặt',
            count: presentCount,
            color: ReportColors.statusGreen,
            icon: Icons.how_to_reg_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Lượt vắng mặt',
            count: absentCount,
            color: ReportColors.orangePrimary,
            icon: Icons.person_remove_outlined,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ReportColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ReportColors.borderSubtle),
        boxShadow: ReportColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: ReportColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                icon,
                size: 18,
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

