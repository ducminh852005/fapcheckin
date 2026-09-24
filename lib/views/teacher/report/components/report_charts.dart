import 'package:flutter/material.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';
import 'package:fapcheckin/views/teacher/report/report_colors.dart';
import 'package:fapcheckin/data/models/report_model.dart';

class ReportCharts extends StatelessWidget {
  final ReportData data;
  const ReportCharts({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header & Legend
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Xu hướng chuyên cần theo tuần',
                    style: AppTextStyles.headlineSm,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tỷ lệ Có mặt, Đi trễ, Vắng mặt theo các tuần có phiên đã kết thúc',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendItem(ReportColors.primary, 'Có mặt'),
                  const SizedBox(width: AppSpacing.md),
                  _buildLegendItem(ReportColors.orange, 'Đi trễ'),
                  const SizedBox(width: AppSpacing.md),
                  _buildLegendItem(AppColors.statusAbsent, 'Vắng mặt'),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Chart Area
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                // Grid Lines
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(4, (index) {
                    return Container(height: 1, color: ReportColors.border);
                  }),
                ),
                // Bars
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ...data.weekly.map(
                      (week) => _buildBar(
                        week.presentRate,
                        week.lateRate,
                        week.absentRate,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // X Axis Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(data.weekly.length, (index) {
              final isCurrent = index == data.weekly.length - 1;
              return Text(
                data.weekly[index].label,
                style: AppTextStyles.code.copyWith(
                  fontSize: 12,
                  color: isCurrent ? ReportColors.primary : ReportColors.muted,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildBar(double present, double late, double absent) {
    const double maxHeight = 180.0;

    return SizedBox(
      width: 32,
      height: maxHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            height: maxHeight * absent,
            decoration: const BoxDecoration(
              color: ReportColors.red,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
              ),
            ),
          ),
          Container(height: maxHeight * late, color: ReportColors.orange),
          Container(
            height: maxHeight * present,
            decoration: const BoxDecoration(
              color: ReportColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(3),
                bottomRight: Radius.circular(3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
