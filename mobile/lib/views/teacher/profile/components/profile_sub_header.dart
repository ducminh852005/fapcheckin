import 'package:flutter/material.dart';
import '../profile_colors.dart';

/// Header có nút quay lại (Back) dùng chung cho trang Thông tin cá nhân & Thông tin công tác:
/// - Nút quay lại bo góc viền xám nhạt
/// - Danh mục uppercase: "HỒ SƠ"
/// - Tiêu đề chính lớn (vd: "Thông tin cá nhân", "Thông tin công tác")
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nút quay lại
        InkWell(
          onTap: onBack,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ProfileColors.borderSubtle),
              boxShadow: ProfileColors.cardShadow,
            ),
            child: const Icon(
              Icons.chevron_left_rounded,
              size: 24,
              color: Color(0xFF334155),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Danh mục uppercase
        Text(
          category,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: ProfileColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),

        // Tiêu đề lớn
        FittedBox(
          alignment: Alignment.centerLeft,
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: ProfileColors.textDark,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }
}

