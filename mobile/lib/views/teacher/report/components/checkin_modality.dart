import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fapcheckin_core/constants/app_colors.dart';
import 'package:fapcheckin_core/constants/app_spacing.dart';
import 'package:fapcheckin_core/constants/app_text_styles.dart';
import '../report_colors.dart';
import 'package:fapcheckin_core/models/report_model.dart';
import 'package:fapcheckin_core/responsive/breakpoints.dart';

class CheckinModality extends StatelessWidget {
  final ReportData data;
  const CheckinModality({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.isMobile ? 16 : AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
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
          SizedBox(height: 2),
          Text('Phân bổ kênh ghi nhận điểm danh', style: AppTextStyles.caption),
          SizedBox(height: AppSpacing.md),

          // Donut Chart
          Center(
            child: SizedBox(
              width: 144,
              height: 144,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size(144, 144),
                    painter: _DonutChartPainter(
                      qrRate: _rate('qr'),
                      otherRate: _rate('other'),
                      manualRate: _rate('manual'),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        data.methods.isEmpty
                            ? '0%'
                            : '${(data.methods.first.rate * 100).toStringAsFixed(0)}%',
                        style: AppTextStyles.headlineMd,
                      ),
                      Text(
                        data.methods.isEmpty
                            ? 'Chưa có dữ liệu'
                            : data.methods.first.label,
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: AppSpacing.md),

          // Legend
          ...data.methods.map(
            (method) => Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: _buildLegendRow(
                method.label,
                '${(method.rate * 100).toStringAsFixed(1)}%',
                method.key == 'manual'
                    ? ReportColors.orange
                    : method.key == 'other'
                    ? ReportColors.red
                    : ReportColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _rate(String key) =>
      data.methods
          .where((method) => method.key == key)
          .map((method) => method.rate)
          .firstOrNull ??
      0;

  Widget _buildLegendRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Text(
          value,
          style: AppTextStyles.code.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final double qrRate;
  final double otherRate;
  final double manualRate;

  const _DonutChartPainter({
    required this.qrRate,
    required this.otherRate,
    required this.manualRate,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 10;
    const strokeWidth = 14.0;

    final bgPaint = Paint()
      ..color = ReportColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    final rect = Rect.fromCircle(center: center, radius: radius);

    // The report currently uses the real method split returned by the API.
    final qrPaint = Paint()
      ..color = ReportColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fapPaint = Paint()
      ..color = AppColors.statusManual
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final manualPaint = Paint()
      ..color = AppColors.statusLate
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double startAngle = -pi / 2;

    double sweepAngle = 2 * pi * qrRate;
    canvas.drawArc(rect, startAngle, sweepAngle, false, qrPaint);
    startAngle += sweepAngle;

    sweepAngle = 2 * pi * otherRate;
    canvas.drawArc(rect, startAngle, sweepAngle, false, fapPaint);
    startAngle += sweepAngle;

    sweepAngle = 2 * pi * manualRate;
    canvas.drawArc(rect, startAngle, sweepAngle, false, manualPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
