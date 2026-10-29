import 'package:flutter/material.dart';
import '../class_management_colors.dart';

/// Phần Header của trang Quản lý lớp:
/// - Tiêu đề lớn "Quản lý lớp"
class ClassManagementHeader extends StatelessWidget {
  const ClassManagementHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Text(
          'Quản lý lớp',
          style: TextStyle(
            color: ClassManagementColors.textDark,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
