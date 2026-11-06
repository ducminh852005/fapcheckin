import 'package:flutter/material.dart';
import '../class_management_colors.dart';

/// Phần Header của trang Quản lý lớp:
/// - Tiêu đề lớn "Quản lý lớp"
class ClassManagementHeader extends StatelessWidget {
  const ClassManagementHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Text(
          'Quản lý lớp',
          style: TextStyle(
            color: isDark
                ? const Color(0xFFF8FAFC)
                : ClassManagementColors.textDark,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
