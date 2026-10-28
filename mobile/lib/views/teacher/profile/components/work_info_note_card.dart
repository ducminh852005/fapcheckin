import 'package:flutter/material.dart';
import '../profile_colors.dart';

/// Thẻ ghi chú thông tin công tác:
/// - Icon thông tin (i)
/// - Mô tả: "Thông tin công tác do quản trị viên quản lý. Liên hệ phòng Tổ chức nếu cần cập nhật."
class WorkInfoNoteCard extends StatelessWidget {
  const WorkInfoNoteCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ProfileColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: ProfileColors.textMuted,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Thông tin công tác do quản trị viên quản lý. Liên hệ phòng Tổ chức nếu cần cập nhật.',
              style: TextStyle(
                fontSize: 11.5,
                color: ProfileColors.textMuted,
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

