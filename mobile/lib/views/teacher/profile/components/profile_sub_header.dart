import 'package:flutter/material.dart';
import '../profile_colors.dart';

/// Header dùng chung cho trang Thông tin cá nhân & Thông tin công tác.
class ProfileSubHeader extends StatelessWidget {
  final String category;
  final String title;

  const ProfileSubHeader({
    super.key,
    this.category = 'HỒ SƠ',
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? Theme.of(context).colorScheme.onSurface
        : ProfileColors.textDark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Danh mục uppercase & Tiêu đề lớn
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                category,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: ProfileColors.orangePrimary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
