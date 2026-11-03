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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ProfileColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ProfileColors.borderSubtle),
        boxShadow: ProfileColors.cardShadow,
      ),
      child: Row(
        children: [
          // Icon cặp công tác
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: ProfileColors.orangeLight,
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: ProfileColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  roleTitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: ProfileColors.textMuted,
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
              color: ProfileColors.statusGreenLight,
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
