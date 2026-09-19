import 'package:flutter/material.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';

class ReportCharts extends StatelessWidget {
  const ReportCharts({super.key});

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
                  Text('Xu hướng chuyên cần theo tuần', style: AppTextStyles.headlineSm),
                  const SizedBox(height: 2),
                  Text('Diễn biến tỷ lệ Có mặt, Đi trễ, Vắng mặt qua 10 tuần học (Slot 1 - Slot 30)', style: AppTextStyles.caption),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendItem(AppColors.primaryContainer, 'Có mặt'),
                  const SizedBox(width: AppSpacing.md),
                  _buildLegendItem(AppColors.statusLate, 'Đi trễ'),
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
                    return Container(
                      height: 1,
                      color: AppColors.surfaceContainerHigh,
                    );
                  }),
                ),
                // Bars
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildBar(96, 3, 1),
                    _buildBar(95, 3, 2),
                    _buildBar(94, 4, 2),
                    _buildBar(93, 4, 3),
                    _buildBar(91, 5, 4),
                    _buildBar(92, 4, 4),
                    _buildBar(95, 3, 2),
                    _buildBar(93, 4, 3),
                    _buildBar(89, 5, 6), // W9 assignment
                    _buildBar(94, 4, 2),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // X Axis Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(10, (index) {
              final isCurrent = index == 9;
              return Text(
                'W${index + 1}${isCurrent ? '*' : ''}',
                style: AppTextStyles.code.copyWith(
                  fontSize: 12,
                  color: isCurrent ? AppColors.primary : AppColors.textTertiary,
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

  Widget _buildBar(int present, int late, int absent) {
    // Total should be 100
    // Height factor: total height is ~180px, so we scale.
    const double maxHeight = 180.0;
    
    return SizedBox(
      width: 32,
      height: maxHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            height: maxHeight * (absent / 100),
            decoration: const BoxDecoration(
              color: AppColors.statusAbsent,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(3), topRight: Radius.circular(3)),
            ),
          ),
          Container(
            height: maxHeight * (late / 100),
            color: AppColors.statusLate,
          ),
          Container(
            height: maxHeight * (present / 100),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(3), bottomRight: Radius.circular(3)),
            ),
          ),
        ],
      ),
    );
  }
}
