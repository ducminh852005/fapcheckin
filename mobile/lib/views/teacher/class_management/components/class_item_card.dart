import 'package:flutter/material.dart';

import '../class_management_colors.dart';

/// Thẻ môn học; không hiển thị slot hay giờ học.
class ClassItemCard extends StatelessWidget {
  const ClassItemCard({
    super.key,
    required this.subjectCode,
    required this.classCode,
    required this.subjectName,
    required this.studentCount,
    required this.completedSessions,
    required this.totalSessions,
    required this.attendanceRate,
    this.onTap,
  });

  final String subjectCode, classCode, subjectName;
  final int studentCount, completedSessions, totalSessions;
  final double attendanceRate;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : ClassManagementColors.textDark;
    final muted = isDark
        ? const Color(0xFF94A3B8)
        : ClassManagementColors.textMuted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : ClassManagementColors.cardBorder,
              ),
              boxShadow: isDark ? null : ClassManagementColors.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isDark
                        ? ClassManagementColors.orangePrimary.withValues(
                            alpha: .16,
                          )
                        : ClassManagementColors.orangeLight,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: ClassManagementColors.orangePrimary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            subjectCode,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              classCode,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subjectName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: muted, fontSize: 12.5),
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          _Meta(
                            icon: Icons.people_alt_outlined,
                            text: '$studentCount sinh viên',
                            color: muted,
                          ),
                          _Meta(
                            icon: Icons.fact_check_outlined,
                            text: '$completedSessions/$totalSessions buổi',
                            color: muted,
                          ),
                          _Meta(
                            icon: Icons.insights_rounded,
                            text:
                                '${attendanceRate.toStringAsFixed(1)}% có mặt',
                            color: muted,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: ClassManagementColors.textSubtle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text, required this.color});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(color: color, fontSize: 10.5)),
    ],
  );
}
