import 'package:flutter/material.dart';

import '../live_session_colors.dart';

/// Header của màn hình Điểm danh trực tiếp:
/// - Title: "Điểm danh trực tiếp" + Nút menu (...)
/// - Thông tin môn & lớp: Icon quyển sách cam, "PRN231 · SE1801", giờ học, phòng học, chấm xanh trực tuyến
class LiveSessionCustomHeader extends StatelessWidget {
  final String classTitle;
  final String timeAndRoom;
  final VoidCallback? onMoreTap;

  const LiveSessionCustomHeader({
    super.key,
    this.classTitle = '',
    this.timeAndRoom = '',
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : LiveSessionColors.textDark;
    final subtextColor =
        isDark ? const Color(0xFF94A3B8) : LiveSessionColors.textMuted;
    final iconColor = isDark ? Colors.white : const Color(0xFF334155);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề chính + Nút Back (nếu có) + Nút 3 chấm
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Text(
                  'Điểm danh trực tiếp',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Tuỳ chọn phiên điểm danh',
              child: IconButton(
                onPressed: onMoreTap,
                icon: Icon(
                  Icons.more_horiz_rounded,
                  size: 26,
                  color: iconColor,
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
                color: isDark
                    ? LiveSessionColors.orangePrimary.withValues(alpha: 0.22)
                    : LiveSessionColors.orangeLight,
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeAndRoom,
                    style: TextStyle(
                      fontSize: 12,
                      color: subtextColor,
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
