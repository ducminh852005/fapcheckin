import 'package:flutter/material.dart';
import '../profile_colors.dart';

/// Thẻ ghi chú thông tin công tác:
/// - Icon thông tin (i)
/// - Mô tả: "Thông tin công tác do quản trị viên quản lý. Liên hệ phòng Tổ chức nếu cần cập nhật."
class WorkInfoNoteCard extends StatelessWidget {
  const WorkInfoNoteCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? Theme.of(context).colorScheme.surface
        : const Color(0xFFF8FAFC);
    final borderColor = isDark
        ? const Color(0xFF334155)
        : ProfileColors.borderSubtle;
    final mutedColor = isDark
        ? const Color(0xFF94A3B8)
        : ProfileColors.textMuted;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: mutedColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Thông tin công tác do quản trị viên quản lý. Liên hệ phòng Tổ chức nếu cần cập nhật.',
              style: TextStyle(
                fontSize: 11.5,
                color: mutedColor,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

