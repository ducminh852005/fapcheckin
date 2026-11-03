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
          const Text(
            'Chi tiết',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: ProfileColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            _buildRow(entries[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(WorkDetailEntry entry) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          entry.label,
          style: const TextStyle(
            fontSize: 13,
            color: ProfileColors.textMuted,
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
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: ProfileColors.textDark,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

