import 'package:flutter/material.dart';

import '../live_session_colors.dart';

/// Header của màn hình Điểm danh trực tiếp:
/// - Subtitle: "CA 2 · THỨ NĂM, 08/10/2026"
/// - Title: "Điểm danh trực tiếp" + Nút menu (...)
/// - Thông tin môn & lớp: Icon quyển sách cam, "PRN231 · SE1801", giờ học, phòng học, chấm xanh trực tuyến
class LiveSessionCustomHeader extends StatelessWidget {
  final String sessionSubtitle;
  final String classTitle;
  final String timeAndRoom;
  final VoidCallback? onMoreTap;

  const LiveSessionCustomHeader({
    super.key,
    this.sessionSubtitle = '',
    this.classTitle = '',
    this.timeAndRoom = '',
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dòng phụ đề thời gian ca học
        Text(
          sessionSubtitle,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: LiveSessionColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),

        // Tiêu đề chính + Nút 3 chấm
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Flexible(
              child: FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Text(
                  'Điểm danh trực tiếp',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: LiveSessionColors.textDark,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: onMoreTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: LiveSessionColors.borderSubtle),
                  boxShadow: LiveSessionColors.cardShadow,
                ),
                child: const Icon(
                  Icons.more_horiz_rounded,
                  size: 22,
                  color: Color(0xFF334155),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Banner thông tin môn học & lớp
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: LiveSessionColors.orangeLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 22,
                color: LiveSessionColors.orangePrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      classTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: LiveSessionColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeAndRoom,
                    style: const TextStyle(
                      fontSize: 12,
                      color: LiveSessionColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: LiveSessionColors.statusGreen,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
