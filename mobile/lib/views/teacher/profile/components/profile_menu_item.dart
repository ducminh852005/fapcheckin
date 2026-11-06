import 'package:flutter/material.dart';
import '../profile_colors.dart';

/// Mục chọn trong danh sách Cài đặt / Tài khoản:
/// - Icon nằm trong ô bo góc nền xám nhạt
/// - Tiêu đề & phụ đề
/// - Trailing: Văn bản giá trị (vd: "Sáng", "Bật") kèm icon mũi tên >
class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? valueText;
  final VoidCallback? onTap;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.valueText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFF8FAFC) : ProfileColors.textDark;
    final mutedColor = isDark
        ? const Color(0xFF94A3B8)
        : ProfileColors.textMuted;
    final iconBg = isDark
        ? ProfileColors.orangePrimary.withValues(alpha: 0.16)
        : ProfileColors.orangeLight;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            // Ô chứa icon tone cam ấm áp FAP Check-in
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: ProfileColors.orangePrimary,
              ),
            ),
            const SizedBox(width: 14),

            // Tiêu đề & phụ đề
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: mutedColor,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Giá trị phụ & Icon mũi tên
            if (valueText != null) ...[
              Text(
                valueText!,
                style: TextStyle(
                  fontSize: 12.5,
                  color: mutedColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: mutedColor,
            ),
          ],
        ),
      ),
    );
  }
}

