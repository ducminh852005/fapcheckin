import 'package:flutter/material.dart';
import '../profile_colors.dart';

/// Nút "Đăng xuất" chữ đỏ
class ProfileLogoutButton extends StatelessWidget {
  final VoidCallback? onLogout;

  const ProfileLogoutButton({
    super.key,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onLogout,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: ProfileColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ProfileColors.borderSubtle),
          boxShadow: ProfileColors.cardShadow,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.logout_rounded,
                size: 19,
                color: ProfileColors.logoutRed,
              ),
              SizedBox(width: 8),
              Text(
                'Đăng xuất',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: ProfileColors.logoutRed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

