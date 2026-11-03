import 'package:flutter/material.dart';
import '../profile_colors.dart';
import 'profile_menu_item.dart';

/// Nhóm thiết lập "Cài đặt":
/// - Giao diện: Chế độ sáng/tối, ngôn ngữ ("Sáng")
/// - Thông báo: Nhắc lịch dạy, kết quả điểm danh ("Bật")
class ProfileSettingsCard extends StatelessWidget {
  final VoidCallback? onThemeTap;
  final VoidCallback? onNotificationsTap;

  const ProfileSettingsCard({
    super.key,
    this.onThemeTap,
    this.onNotificationsTap,
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
              'Cài đặt',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: ProfileColors.textDark,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ProfileMenuItem(
            icon: Icons.wb_sunny_outlined,
            title: 'Giao diện',
            subtitle: 'Chế độ sáng/tối, ngôn ngữ',
            valueText: 'Sáng',
            onTap: onThemeTap,
          ),
          const SizedBox(height: 4),
          ProfileMenuItem(
            icon: Icons.notifications_none_rounded,
            title: 'Thông báo',
            subtitle: 'Nhắc lịch dạy, kết quả điểm danh',
            valueText: 'Bật',
            onTap: onNotificationsTap,
          ),
        ],
      ),
    );
  }
}

