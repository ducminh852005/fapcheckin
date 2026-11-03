import 'package:flutter/material.dart';
import '../profile_colors.dart';

/// Header có nút quay lại (Back) dùng chung cho trang Thông tin cá nhân & Thông tin công tác:
/// - Nút quay lại bo góc nằm cùng hàng ngang với danh mục "HỒ SƠ" & Tiêu đề chính (đồng bộ với các màn hình con khác)
class ProfileSubHeader extends StatelessWidget {
  final String category;
  final String title;
  final VoidCallback onBack;

  const ProfileSubHeader({
    super.key,
    this.category = 'HỒ SƠ',
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? Theme.of(context).colorScheme.surface
        : Colors.white;
    final textColor = isDark
        ? Theme.of(context).colorScheme.onSurface
        : ProfileColors.textDark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Nút quay lại (chuẩn vùng chạm >= 44x44dp)
        Tooltip(
          message: 'Quay lại',
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              child: Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Theme.of(context).colorScheme.outline
                          : ProfileColors.borderSubtle,
                    ),
                    boxShadow: ProfileColors.cardShadow,
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 17,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

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
