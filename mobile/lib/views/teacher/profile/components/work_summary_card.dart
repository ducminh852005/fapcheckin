import 'package:flutter/material.dart';

import '../profile_colors.dart';

/// Thẻ tóm tắt thông tin công tác:
/// - Icon cặp tài liệu màu cam trên nền cam nhạt
/// - Tên giảng viên & Chức danh
/// - Badge xanh lá: "Đang công tác"
class WorkSummaryCard extends StatelessWidget {
  final String fullName;
  final String roleTitle;
  final String statusBadge;

  const WorkSummaryCard({
    super.key,
    this.fullName = '',
    this.roleTitle = 'Giảng viên',
    this.statusBadge = 'Đang công tác',
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
    final textColor = isDark ? const Color(0xFFF8FAFC) : ProfileColors.textDark;
    final mutedColor = isDark
        ? const Color(0xFF94A3B8)
        : ProfileColors.textMuted;
    final iconBg = isDark
        ? ProfileColors.orangePrimary.withValues(alpha: 0.16)
        : ProfileColors.orangeLight;
    final badgeBg = isDark
        ? const Color(0xFF14532D).withValues(alpha: 0.4)
        : ProfileColors.statusGreenLight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: isDark ? null : ProfileColors.cardShadow,
      ),
      child: Row(
        children: [
          // Icon cặp công tác
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.business_center_outlined,
              size: 24,
              color: ProfileColors.orangePrimary,
            ),
          ),
          const SizedBox(width: 14),

          // Tên giảng viên & Chức danh
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    fullName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  roleTitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: mutedColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Badge trạng thái "Đang công tác"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusBadge,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: ProfileColors.statusGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
