import 'package:flutter/material.dart';
import '../profile_colors.dart';
import 'profile_menu_item.dart';

/// Nhóm thiết lập "Tài khoản":
/// - Thông tin cá nhân
/// - Thông tin công tác
/// - Tài khoản & Bảo mật
class ProfileAccountCard extends StatelessWidget {
  final VoidCallback? onPersonalInfoTap;
  final VoidCallback? onWorkInfoTap;
  final VoidCallback? onSecurityTap;

  const ProfileAccountCard({
    super.key,
    this.onPersonalInfoTap,
    this.onWorkInfoTap,
    this.onSecurityTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: ProfileColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ProfileColors.borderSubtle),
        boxShadow: ProfileColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Tài khoản',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: ProfileColors.textDark,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ProfileMenuItem(
            icon: Icons.person_outline_rounded,
            title: 'Thông tin cá nhân',
            subtitle: 'Họ tên, email, số điện thoại',
            onTap: onPersonalInfoTap,
          ),
          const SizedBox(height: 4),
          ProfileMenuItem(
            icon: Icons.work_outline_rounded,
            title: 'Thông tin công tác',
            subtitle: 'Khoa, bộ môn, chức vụ',
            onTap: onWorkInfoTap,
          ),
          const SizedBox(height: 4),
          ProfileMenuItem(
            icon: Icons.shield_outlined,
            title: 'Tài khoản & Bảo mật',
            subtitle: 'Mật khẩu, xác thực hai lớp',
            onTap: onSecurityTap,
          ),
        ],
      ),
    );
  }
}

