import 'package:flutter/material.dart';
import '../account_dialogs.dart';
import '../profile_colors.dart';

/// Thẻ hiển thị và thay đổi ảnh đại diện (Avatar):
/// - Vòng tròn viền cam, chữ viết tắt tên màu cam hoặc ảnh đại diện từ Storage
/// - Icon camera nhỏ ở góc phải avatar
/// - Nút "Đổi ảnh đại diện" & Ghi chú "JPG hoặc PNG, tối đa 5 MB"
class PersonalAvatarCard extends StatelessWidget {
  final String initials;
  final String avatarPath;
  final VoidCallback? onChangeAvatar;

  const PersonalAvatarCard({
    super.key,
    this.initials = 'NM',
    this.avatarPath = '',
    this.onChangeAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? Theme.of(context).colorScheme.surface
        : ProfileColors.cardBg;
    final borderColor = isDark
        ? const Color(0xFF334155)
        : ProfileColors.borderSubtle;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: isDark ? null : ProfileColors.cardShadow,
      ),
      child: Column(
        children: [
          // Khung Avatar kèm nút camera
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: cardBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ProfileColors.orangePrimary,
                    width: 2.0,
                  ),
                ),
                alignment: Alignment.center,
                child: avatarPath.isNotEmpty
                    ? AccountAvatar(
                        path: avatarPath,
                        initials: initials,
                        radius: 41,
                        backgroundColor: cardBg,
                        textStyle: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: ProfileColors.orangePrimary,
                        ),
                      )
                    : Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: ProfileColors.orangePrimary,
                        ),
                      ),
              ),
              InkWell(
                onTap: onChangeAvatar,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: ProfileColors.textDark,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Nút Đổi ảnh đại diện
          InkWell(
            onTap: onChangeAvatar,
            child: const Text(
              'Đổi ảnh đại diện',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: ProfileColors.orangePrimary,
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Ghi chú định dạng
          const Text(
            'JPG hoặc PNG, tối đa 5 MB',
            style: TextStyle(
              fontSize: 11,
              color: ProfileColors.textSubtle,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
