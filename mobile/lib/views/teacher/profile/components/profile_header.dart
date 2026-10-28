import 'package:flutter/material.dart';
import '../profile_colors.dart';

/// Header của màn hình Hồ sơ:
/// - Subtitle uppercase: "TÀI KHOẢN GIẢNG VIÊN"
/// - Title: "Hồ sơ"
/// - Nút chỉnh sửa (pencil icon) bên phải
class ProfileHeader extends StatelessWidget {
  final VoidCallback? onEdit;

  const ProfileHeader({
    super.key,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TÀI KHOẢN GIẢNG VIÊN',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: ProfileColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Flexible(
              child: FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Text(
                  'Hồ sơ',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: ProfileColors.textDark,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ProfileColors.borderSubtle),
                  boxShadow: ProfileColors.cardShadow,
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: Color(0xFF334155),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

