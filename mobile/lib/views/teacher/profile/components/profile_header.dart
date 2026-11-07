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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFF8FAFC) : ProfileColors.textDark;
    final iconColor = isDark
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF334155);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              'Hồ sơ',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: textColor,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Nút icon răng cưa (Cài đặt & Trợ giúp)
        Tooltip(
          message: 'Cài đặt & Trợ giúp',
          child: IconButton(
            onPressed: onSettings,
            icon: Icon(
              Icons.settings_outlined,
              size: 25,
              color: iconColor,
            ),
          ),
        ),
      ],
    );
  }
}
