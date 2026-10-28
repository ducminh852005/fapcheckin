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
    this.attendanceRate = 94.1,
    this.attendanceRateText = '94,1%',
    this.statusHeadline = 'Nhịp học tập\nđang rất tốt',
    this.detailText = '542/576 lượt có mặt\ntrong 18 buổi học',
    this.trendText = '↗ +2,3 điểm % so với tuần trước',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFE5D9), width: 1.2),
        boxShadow: [
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
                    trackColor: const Color(0xFFFFF0EB),
                    progressColor: ReportColors.orangePrimary,
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
                        style: const TextStyle(
                          color: ReportColors.textDark,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 1),
                    const Text(
                      'CÓ MẶT',
                      style: TextStyle(
                        color: ReportColors.orangePrimary,
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
                    style: const TextStyle(
                      color: ReportColors.textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  detailText,
                  style: const TextStyle(
                    color: ReportColors.textMuted,
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
                    style: const TextStyle(
                      color: ReportColors.statusGreen,
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

