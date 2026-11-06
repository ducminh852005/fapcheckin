import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../live_session_colors.dart';

/// Thẻ QR Điểm danh trực tiếp:
/// - Badge cam "• ĐANG MỞ ĐIỂM DANH" + Nút phóng to toàn màn hình
/// - Mã QR chính giữa kèm chú thích "Sinh viên quét mã bằng FAP Check-in"
/// - Hộp đếm ngược: Vòng tròn 42s, "Mã mới sau 42 giây", nút làm mới ngay
class LiveSessionQrCard extends StatelessWidget {
  final String qrData;
  final int refreshSeconds;
  final int totalCycleSeconds;
  final VoidCallback? onRefresh;
  final VoidCallback? onFullscreen;

  const LiveSessionQrCard({
    super.key,
    required this.qrData,
    this.refreshSeconds = 42,
    this.totalCycleSeconds = 60,
    this.onRefresh,
    this.onFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = LiveSessionColors.getCardBg(context);
    final cardBorder = LiveSessionColors.getBorder(context);
    final textDark = LiveSessionColors.getTextDark(context);
    final textMuted = LiveSessionColors.getTextMuted(context);
    final countdownBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final trackColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorder),
        boxShadow: isDark ? null : LiveSessionColors.cardShadow,
      ),
      child: Column(
        children: [
          // Header: Đang mở điểm danh + Nút phóng to
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        '•',
                        style: TextStyle(
                          color: LiveSessionColors.orangePrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(width: 5),
                      Text(
                        'ĐANG MỞ ĐIỂM DANH',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: LiveSessionColors.orangePrimary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Trình chiếu toàn màn hình',
                child: InkWell(
                  onTap: onFullscreen,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.crop_free_rounded,
                      size: 22,
                      color: textDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Mã QR chính giữa (Luôn giữ nền trắng cho QR reader quét được)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: qrData.isEmpty
                ? const SizedBox(
                    width: 190,
                    height: 190,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 190,
                    padding: EdgeInsets.zero,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                  ),
          ),
          const SizedBox(height: 8),

          // Chú thích dưới QR
          Text(
            'Sinh viên quét mã bằng FAP Check-in',
            style: TextStyle(
              fontSize: 11.5,
              color: textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),

          // Hộp đếm ngược làm mới mã QR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: countdownBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              children: [
                // Vòng tròn tiến độ thời gian (vd: 42s)
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(44, 44),
                        painter: _CountdownPainter(
                          progress: (refreshSeconds / totalCycleSeconds).clamp(
                            0.0,
                            1.0,
                          ),
                          trackColor: trackColor,
                          progressColor: LiveSessionColors.orangePrimary,
                          strokeWidth: 3.5,
                        ),
                      ),
                      Text(
                        '${refreshSeconds}s',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Thông tin làm mới
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        alignment: Alignment.centerLeft,
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Mã mới sau $refreshSeconds giây',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        alignment: Alignment.centerLeft,
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Tự làm mới mỗi $totalCycleSeconds giây',
                          style: TextStyle(
                            fontSize: 11,
                            color: textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Nút xoay làm mới ngay
                Tooltip(
                  message: 'Làm mới mã QR ngay',
                  child: InkWell(
                    onTap: onRefresh,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.refresh_rounded,
                        size: 24,
                        color: LiveSessionColors.orangePrimary,
                      ),
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

class _CountdownPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _CountdownPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track nền
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, trackPaint);

    // Cung tiến độ
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CountdownPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
