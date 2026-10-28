import 'package:flutter/material.dart';
import '../class_management_colors.dart';

/// Thẻ tóm tắt tổng số lớp và số sinh viên phụ trách (Thẻ màu xanh đen - Dark Navy)
class ClassSummaryBanner extends StatelessWidget {
  final int classCount;
  final int studentCount;

  const ClassSummaryBanner({
    super.key,
    required this.classCount,
    required this.studentCount,
  });

  @override
  Widget build(BuildContext context) {
    final classCountStr =
        classCount < 10 ? '0$classCount' : classCount.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: ClassManagementColors.bannerBg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cột 1: Lớp phụ trách
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    classCountStr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Lớp phụ trách',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Vạch ngăn cách dọc
          Container(
            width: 1,
            height: 44,
            color: const Color(0xFF334155),
          ),
          const SizedBox(width: 24),

          // Cột 2: Sinh viên (Số màu cam)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    studentCount.toString(),
                    style: const TextStyle(
                      color: ClassManagementColors.orangePrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sinh viên',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

