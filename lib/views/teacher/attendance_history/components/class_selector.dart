import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/history_class.dart';
import '../../../../viewmodels/attendance_history_viewmodel.dart';
import '../../../../data/models/history_student.dart';

class ClassSelector extends StatelessWidget {
  const ClassSelector({super.key});
  @override
  Widget build(BuildContext context) {
    final vm = context.read<AttendanceHistoryViewModel>();
    final visibleClasses = context
        .select<AttendanceHistoryViewModel, List<HistoryClass>>(
          (value) => value.visibleClasses,
        );
    final classCount = context.select<AttendanceHistoryViewModel, int>(
      (value) => value.classes.length,
    );
    final selectedClassCode = context
        .select<AttendanceHistoryViewModel, String?>(
          (value) => value.selectedClassCode,
        );
    final busy = context.select<AttendanceHistoryViewModel, bool>(
      (value) => value.busy,
    );
    final hasChanges = context.select<AttendanceHistoryViewModel, bool>(
      (value) => value.hasChanges,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Lớp học phụ trách',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$classCount',
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 380,
          child: TextField(
            onChanged: vm.setClassSearch,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Tìm mã lớp hoặc môn học',
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (visibleClasses.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'Không tìm thấy lớp phù hợp.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          SizedBox(
            height: 218,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: visibleClasses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final c = visibleClasses[index];
                final selected = selectedClassCode == c.classCode;
                return _ClassCard(
                  classInfo: c,
                  selected: selected,
                  enabled: !busy && !hasChanges,
                  onTap: () => vm.selectClass(c.classCode),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.classInfo,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final HistoryClass classInfo;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 292,
      child: Material(
        color: selected ? AppColors.primaryLight : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        classInfo.classCode,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (selected)
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.primary,
                        size: 18,
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  classInfo.subjectName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const Spacer(),
                Text(
                  '${classInfo.studentCount} sinh viên · ${classInfo.completedSessions}/${classInfo.totalSessions} buổi',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _ClassMetric(
                      icon: Icons.people_alt_outlined,
                      label: classInfo.completedSessions == 0
                          ? 'Chưa có tỷ lệ'
                          : '${(classInfo.attendanceRate * 100).toStringAsFixed(1)}% có mặt',
                      color: classInfo.attendanceRate < .8
                          ? AppColors.statusAbsent
                          : AppColors.statusPresent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        classInfo.latestSession == null
                            ? 'Chưa có buổi'
                            : 'Gần nhất ${historyDate(classInfo.latestSession!.sessionDate)}',
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassMetric extends StatelessWidget {
  const _ClassMetric({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
