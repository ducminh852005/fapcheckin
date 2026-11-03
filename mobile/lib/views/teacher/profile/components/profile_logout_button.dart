import 'package:flutter/material.dart';
import '../profile_colors.dart';

/// Nút "Đăng xuất"
class ProfileLogoutButton extends StatelessWidget {
  final VoidCallback? onLogout;

  const ProfileLogoutButton({
    super.key,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onLogout,
        icon: const Icon(
          Icons.logout_rounded,
          size: 19,
          color: ProfileColors.logoutRed,
        ),
        label: const Text(
          'Đăng xuất',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: ProfileColors.logoutRed,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: ProfileColors.logoutRed,
          side: const BorderSide(color: Color(0xFFFECACA), width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
