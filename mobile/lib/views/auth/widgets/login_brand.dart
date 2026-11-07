import 'package:flutter/material.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Image.asset(
            'assets/images/Logo_FPT_Education-Photoroom.png',
            width: 92,
            height: 42,
            fit: BoxFit.contain,
            semanticLabel: 'Đại học FPT',
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'DÀNH CHO GIẢNG VIÊN',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: Color(0xFF475569),
              ),
            ),
          ),
        ],
      );
}

/// Logo Icon của ứng dụng FAP Check-in:
/// Hình vuông bo góc màu cam chuyển sắc (squircle gradient),
/// bên trong là khung quét QR đa sắc kèm dấu tích hoàn thành.
class FapCheckinLogoBadge extends StatelessWidget {
  const FapCheckinLogoBadge({super.key, this.size = 112});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/logos/logo-fap.png',
        fit: BoxFit.contain,
        semanticLabel: 'Logo FAP Check-in',
        errorBuilder: (_, __, ___) => Center(
          child: CustomPaint(
            size: Size(size * 0.55, size * 0.55),
            painter: const _FapLogoPainter(),
          ),
        ),
      ),
    );
  }
}

class _FapLogoPainter extends CustomPainter {
  const _FapLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 48.0;

    // 1. Góc trên - trái (Xanh dương: #2563EB)
    final blueStroke = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path1 = Path()
      ..moveTo(4 * scale, 17 * scale)
      ..lineTo(4 * scale, 7 * scale)
      ..arcToPoint(
        Offset(7 * scale, 4 * scale),
        radius: Radius.circular(3 * scale),
      )
      ..lineTo(17 * scale, 4 * scale);
    canvas.drawPath(path1, blueStroke);

    final blueFill = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(11.5 * scale, 11.5 * scale, 5.5 * scale, 5.5 * scale),
        Radius.circular(1.5 * scale),
      ),
      blueFill,
    );

    // 2. Góc trên - phải (Trắng: Colors.white)
    final whiteStroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path2 = Path()
      ..moveTo(31 * scale, 4 * scale)
      ..lineTo(41 * scale, 4 * scale)
      ..arcToPoint(
        Offset(44 * scale, 7 * scale),
        radius: Radius.circular(3 * scale),
      )
      ..lineTo(44 * scale, 17 * scale);
    canvas.drawPath(path2, whiteStroke);

    // 3. Góc dưới - trái (Xanh lá: #16A34A)
    final greenStroke = Paint()
      ..color = const Color(0xFF16A34A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path3 = Path()
      ..moveTo(4 * scale, 31 * scale)
      ..lineTo(4 * scale, 41 * scale)
      ..arcToPoint(
        Offset(7 * scale, 44 * scale),
        radius: Radius.circular(3 * scale),
      )
      ..lineTo(17 * scale, 44 * scale);
    canvas.drawPath(path3, greenStroke);

    final greenFill = Paint()
      ..color = const Color(0xFF16A34A)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(11.5 * scale, 31 * scale, 5.5 * scale, 5.5 * scale),
        Radius.circular(1.5 * scale),
      ),
      greenFill,
    );

    // 4. Dấu tích dưới - phải (Trắng: Colors.white)
    final checkStroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path4 = Path()
      ..moveTo(23.5 * scale, 30 * scale)
      ..lineTo(29.0 * scale, 36.5 * scale)
      ..lineTo(42.0 * scale, 21.5 * scale);
    canvas.drawPath(path4, checkStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Khối hiển thị Logo & Tên ứng dụng nổi trực tiếp trên nền (không dùng khung trắng).
class LoginBrandCard extends StatelessWidget {
  const LoginBrandCard({super.key});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          FapCheckinLogoBadge(size: 112),
          SizedBox(height: 18),
          Text(
            'FAP Check-in',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.6,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Quick & Easy Attendance',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
              letterSpacing: 0.2,
            ),
          ),
        ],
      );
}
