import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../viewmodels/attendance_history_viewmodel.dart';
import '../../../../data/models/history_student.dart';

class ClassSelector extends StatelessWidget {
  const ClassSelector({super.key});
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AttendanceHistoryViewModel>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Lớp học phụ trách (${vm.classes.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        SizedBox(
          width: 360,
          child: TextField(
            onChanged: vm.setClassSearch,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Tìm mã lớp hoặc môn học',
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (vm.visibleClasses.isEmpty)
          const Text('Không tìm thấy lớp phù hợp.'),
        SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: vm.visibleClasses.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final c = vm.visibleClasses[index];
              final selected = vm.selectedClassCode == c.classCode;
              return SizedBox(
                width: 280,
                child: Card(
                  color: selected ? AppColors.primaryLight : AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: selected ? AppColors.primary : Colors.transparent,
                    ),
                  ),
                  child: InkWell(
                    onTap: vm.busy || vm.hasChanges
                        ? null
                        : () => vm.selectClass(c.classCode),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.classCode,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            c.subjectName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Text(
                            '${c.studentCount} sinh viên · ${c.completedSessions}/${c.totalSessions} buổi đã kết thúc',
                          ),
                          Text(
                            c.completedSessions == 0
                                ? 'Chưa có tỷ lệ chuyên cần'
                                : 'Có mặt: ${(c.attendanceRate * 100).toStringAsFixed(1)}%',
                          ),
                          const SizedBox(height: 6),
                          Text(
                            c.latestSession == null
                                ? 'Chưa có buổi điểm danh'
                                : 'Gần nhất: ${historyDate(c.latestSession!.sessionDate)}',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
