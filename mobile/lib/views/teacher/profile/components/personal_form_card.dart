import 'package:flutter/material.dart';
import '../profile_colors.dart';

/// Thẻ biểu mẫu thông tin cá nhân:
/// - Họ và tên
/// - Email (khóa không chỉnh sửa, kèm icon ổ khóa & ghi chú)
/// - Số điện thoại
/// - Ngày sinh (kèm icon lịch)
class PersonalFormCard extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController birthDateController;
  final VoidCallback? onPickBirthDate;

  const PersonalFormCard({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.birthDateController,
    this.onPickBirthDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ProfileColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ProfileColors.borderSubtle),
        boxShadow: ProfileColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Họ và tên
          _buildField(
            label: 'Họ và tên',
            controller: nameController,
          ),
          const SizedBox(height: 16),

          // 2. Email (read-only)
          _buildField(
            label: 'Email',
            controller: emailController,
            readOnly: true,
            trailingIcon: Icons.lock_outline_rounded,
            helperText: 'Email do nhà trường cấp, không thể thay đổi.',
          ),
          const SizedBox(height: 16),

          // 3. Số điện thoại
          _buildField(
            label: 'Số điện thoại',
            controller: phoneController,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),

          // 4. Ngày sinh
          _buildField(
            label: 'Ngày sinh',
            controller: birthDateController,
            readOnly: true,
            onTap: onPickBirthDate,
            trailingIcon: Icons.calendar_today_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
    IconData? trailingIcon,
    String? helperText,
    TextInputType? keyboardType,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: ProfileColors.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: readOnly ? const Color(0xFFF8FAFC) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ProfileColors.borderSubtle),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    readOnly: readOnly,
                    onTap: onTap,
                    keyboardType: keyboardType,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ProfileColors.textDark,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    trailingIcon,
                    size: 18,
                    color: ProfileColors.textSubtle,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 5),
          Text(
            helperText,
            style: const TextStyle(
              fontSize: 11,
              color: ProfileColors.textSubtle,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

