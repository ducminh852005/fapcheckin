import 'package:flutter/material.dart';
import '../profile_colors.dart';

/// Header của màn hình Hồ sơ:
/// - Title: "Hồ sơ"
/// - Nút thông báo (bell) và Nút cài đặt (gear) bên phải
class ProfileHeader extends StatelessWidget {
  final VoidCallback? onSettings;
  final VoidCallback? onNotification;
  final VoidCallback? onEdit;

  const ProfileHeader({
    super.key,
    this.onSettings,
    this.onNotification,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
        // Nút icon răng cưa (Cài đặt & Trợ giúp)
        InkWell(
          onTap: onSettings,
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
              Icons.settings_outlined,
              size: 21,
              color: Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }
}
