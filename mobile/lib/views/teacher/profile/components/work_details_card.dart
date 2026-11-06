import 'package:flutter/material.dart';
import '../profile_colors.dart';

class WorkDetailEntry {
  final String label;
  final String value;

  const WorkDetailEntry({
    required this.label,
    required this.value,
  });
}

/// Thẻ bảng chi tiết thông tin công tác:
/// - Tiêu đề "Chi tiết"
/// - Các dòng: Mã giảng viên, Khoa, Bộ môn, Chức vụ, Ngày vào làm, Loại hợp đồng
class WorkDetailsCard extends StatelessWidget {
  final List<WorkDetailEntry> entries;

  const WorkDetailsCard({
    super.key,
    this.entries = const [
      WorkDetailEntry(label: 'Mã giảng viên', value: 'GV01234'),
      WorkDetailEntry(label: 'Khoa', value: 'Công nghệ thông tin'),
      WorkDetailEntry(label: 'Bộ môn', value: 'Phát triển phần mềm'),
      WorkDetailEntry(label: 'Chức vụ', value: 'Giảng viên'),
      WorkDetailEntry(label: 'Ngày vào làm', value: '01/09/2020'),
      WorkDetailEntry(label: 'Loại hợp đồng', value: 'Chính thức'),
    ],
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: isDark ? null : ProfileColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chi tiết',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            _buildRow(entries[i], textColor, mutedColor),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(WorkDetailEntry entry, Color textColor, Color mutedColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          entry.label,
          style: TextStyle(
            fontSize: 13,
            color: mutedColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: FittedBox(
            alignment: Alignment.centerRight,
            fit: BoxFit.scaleDown,
            child: Text(
              entry.value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

