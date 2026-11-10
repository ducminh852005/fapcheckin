import 'package:flutter/material.dart';

import '../class_management_colors.dart';

/// Thanh tìm kiếm môn học theo mã môn, tên môn hoặc mã lớp.
class ClassSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const ClassSearchBar({
    super.key,
    required this.controller,
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Theme.of(context).colorScheme.outline
              : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: isDark ? null : ClassManagementColors.cardShadow,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
          color: isDark ? Colors.white : ClassManagementColors.textDark,
          fontSize: 13.5,
        ),
        decoration: InputDecoration(
          hintText: 'Tìm mã môn, tên môn hoặc mã lớp...',
          hintStyle: const TextStyle(
            color: ClassManagementColors.textSubtle,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: ClassManagementColors.textMuted,
            size: 20,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: ClassManagementColors.textMuted,
                    size: 18,
                  ),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
