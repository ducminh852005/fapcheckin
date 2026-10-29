import 'package:flutter/material.dart';
import '../attendance_history_colors.dart';

enum AttendanceFilterType { all, present, absent }

/// Thanh tìm kiếm và bộ lọc trạng thái sinh viên:
/// - Ô nhập: "Tìm tên hoặc MSSV..."
/// - Filter chips: Tất cả (32) • Có mặt (28) • Vắng (4)
/// - Nút hành động: "⚡ Chọn nhanh"
class AttendanceSearchFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final AttendanceFilterType activeFilter;
  final ValueChanged<AttendanceFilterType> onFilterChanged;
  final int totalCount;
  final int presentCount;
  final int absentCount;
  final VoidCallback? onQuickSelect;

  const AttendanceSearchFilterBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.activeFilter,
    required this.onFilterChanged,
    this.totalCount = 32,
    this.presentCount = 28,
    this.absentCount = 4,
    this.onQuickSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Ô tìm kiếm ────────────────────────────────────────────────────────
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AttendanceHistoryColors.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            style: const TextStyle(
              fontSize: 13.5,
              color: AttendanceHistoryColors.textDark,
            ),
            decoration: InputDecoration(
              hintText: 'Tìm tên hoặc MSSV...',
              hintStyle: const TextStyle(
                fontSize: 13,
                color: AttendanceHistoryColors.textSubtle,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 20,
                color: AttendanceHistoryColors.textSubtle,
              ),
              suffixIcon: searchController.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AttendanceHistoryColors.textSubtle,
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── Hàng Filter chips & Nút Chọn nhanh ────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _FilterChipItem(
                label: 'Tất cả ($totalCount)',
                isSelected: activeFilter == AttendanceFilterType.all,
                onTap: () => onFilterChanged(AttendanceFilterType.all),
              ),
              const SizedBox(width: 8),
              _FilterChipItem(
                label: 'Có mặt ($presentCount)',
                isSelected: activeFilter == AttendanceFilterType.present,
                onTap: () => onFilterChanged(AttendanceFilterType.present),
              ),
              const SizedBox(width: 8),
              _FilterChipItem(
                label: 'Vắng ($absentCount)',
                isSelected: activeFilter == AttendanceFilterType.absent,
                onTap: () => onFilterChanged(AttendanceFilterType.absent),
              ),
              const SizedBox(width: 12),
              // Nút Chọn nhanh
              InkWell(
                onTap: onQuickSelect,
                borderRadius: BorderRadius.circular(16),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        size: 16,
                        color: AttendanceHistoryColors.orangePrimary,
                      ),
                      SizedBox(width: 2),
                      Text(
                        'Chọn nhanh',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AttendanceHistoryColors.orangePrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChipItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AttendanceHistoryColors.textDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AttendanceHistoryColors.textDark
                : AttendanceHistoryColors.borderSubtle,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : AttendanceHistoryColors.textDark,
          ),
        ),
      ),
    );
  }
}
