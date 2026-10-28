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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            // Ô chứa icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ProfileColors.iconTileBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: const Color(0xFF334155),
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ProfileColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: ProfileColors.textMuted,
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
                style: const TextStyle(
                  fontSize: 12.5,
                  color: ProfileColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
            ],
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: ProfileColors.textSubtle,
            ),
          ],
        ),
      ),
    );
  }
}

