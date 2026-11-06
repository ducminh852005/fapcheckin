import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../report_colors.dart';

/// Thẻ Hero Dark Navy:
/// - Vòng cung tiến độ tròn (Circular Gauge): tỷ lệ có mặt (vd 94.1%)
/// - Tiêu đề nhận xét: "Nhịp học tập đang rất tốt"
/// - Chi tiết: "542/576 lượt có mặt trong 18 buổi học"
/// - Xu hướng: "↗ +2,3 điểm % so với tuần trước"
class ReportHeroGaugeCard extends StatelessWidget {
  final double attendanceRate; // vd: 94.1
  final String attendanceRateText;
  final String statusHeadline;
  final String detailText;
  final String trendText;

  const ReportHeroGaugeCard({
    super.key,
    this.attendanceRate = 0,
    this.attendanceRateText = '0%',
    this.statusHeadline = 'Nhịp học tập\nđang rất tốt',
    this.detailText = '542/576 lượt có mặt\ntrong 18 buổi học',
    this.trendText = '↗ +2,3 điểm % so với tuần trước',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? Theme.of(context).colorScheme.surface : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFFFE5D9);
    final textColor = isDark ? const Color(0xFFF8FAFC) : ReportColors.textDark;
    final mutedColor = isDark
        ? const Color(0xFF94A3B8)
        : ReportColors.textMuted;

    final isZero = attendanceRate <= 0;
    final isWarning = attendanceRate > 0 && attendanceRate < 80;
    final semanticAccent = isZero
        ? mutedColor
        : (isWarning ? ReportColors.orangePrimary : ReportColors.statusGreen);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFFFA5A1E).withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular Progress Gauge
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(96, 96),
                  painter: _GaugePainter(
                    percentage: (attendanceRate / 100.0).clamp(0.0, 1.0),
                    trackColor: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF1F5F9),
                    progressColor: isZero
                        ? ReportColors.textSubtle
                        : ReportColors.orangePrimary,
                    strokeWidth: 9.0,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        attendanceRateText,
                        style: TextStyle(
                          color: isZero ? mutedColor : textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'CÓ MẶT',
                      style: TextStyle(
                        color: isZero
                            ? ReportColors.textSubtle
                            : ReportColors.orangePrimary,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Văn bản bên phải
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    statusHeadline,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  detailText,
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    trendText,
                    style: TextStyle(
                      color: semanticAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double percentage;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _GaugePainter({
    required this.percentage,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Vẽ track nền tròn
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, trackPaint);

    // Vẽ cung tròn tiến độ (bắt đầu từ góc 12h: -pi/2)
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final sweepAngle = 2 * math.pi * percentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
