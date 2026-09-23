import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';

class CheckinModality extends StatelessWidget {
  const CheckinModality({super.key});

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
          Text('Phương thức điểm danh', style: AppTextStyles.headlineSm),
          const SizedBox(height: 2),
          Text('Phân bổ kênh ghi nhận điểm danh', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.md),

          // Donut Chart
          Center(
            child: SizedBox(
              width: 144,
              height: 144,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(144, 144),
                    painter: _DonutChartPainter(),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('88%', style: AppTextStyles.headlineMd),
                      Text('QR Code', style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Legend
          _buildLegendRow(
            'Quét QR động 60 giây',
            '88%',
            AppColors.primaryContainer,
          ),
          const SizedBox(height: 8),
          _buildLegendRow('Đơn phép FAP hợp lệ', '8%', AppColors.statusManual),
          const SizedBox(height: 8),
          _buildLegendRow(
            'GV xác nhận bù thủ công',
            '4%',
            AppColors.statusLate,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: AppTextStyles.code.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 10;
    const strokeWidth = 14.0;

    final bgPaint = Paint()
      ..color = AppColors.surfaceContainer
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    final rect = Rect.fromCircle(center: center, radius: radius);

    // QR: 88%
    final qrPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // FAP: 8%
    final fapPaint = Paint()
      ..color = AppColors.statusManual
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Manual: 4%
    final manualPaint = Paint()
      ..color = AppColors.statusLate
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double startAngle = -pi / 2;

    // Draw QR
    double sweepAngle = 2 * pi * 0.88;
    canvas.drawArc(rect, startAngle, sweepAngle, false, qrPaint);
    startAngle += sweepAngle;

    // Draw FAP
    sweepAngle = 2 * pi * 0.08;
    canvas.drawArc(rect, startAngle, sweepAngle, false, fapPaint);
    startAngle += sweepAngle;

    // Draw Manual
    sweepAngle = 2 * pi * 0.04;
    canvas.drawArc(rect, startAngle, sweepAngle, false, manualPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
