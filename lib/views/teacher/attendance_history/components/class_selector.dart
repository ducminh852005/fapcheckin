import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/history_class.dart';
import '../../../../viewmodels/attendance_history_viewmodel.dart';
import '../../../../data/models/history_student.dart';

class ClassSelector extends StatefulWidget {
  const ClassSelector({super.key});

  @override
  State<ClassSelector> createState() => _ClassSelectorState();
}

class _ClassSelectorState extends State<ClassSelector> {
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final vm = context.read<AttendanceHistoryViewModel>();
    final allVisibleClasses = context
        .select<AttendanceHistoryViewModel, List<HistoryClass>>(
          (value) => value.visibleClasses,
        );

    // Apply local status filter
    final visibleClasses = allVisibleClasses.where((c) {
      if (_statusFilter == 'active') {
        return c.completedSessions < c.totalSessions;
      }
      if (_statusFilter == 'completed') {
        return c.completedSessions >= c.totalSessions;
      }
      return true;
    }).toList();

    final classCount = context.select<AttendanceHistoryViewModel, int>(
      (value) => value.classes.length,
    );
    final busy = context.select<AttendanceHistoryViewModel, bool>(
      (value) => value.busy,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Tiết học phụ trách',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$classCount',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final searchField = TextField(
              onChanged: vm.setClassSearch,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Tìm mã lớp hoặc môn học',
              ),
            );
            final filterDropdown = Container(
              width: isMobile ? double.infinity : null,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: isMobile,
                  value: _statusFilter,
                  items: [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('Tất cả trạng thái'),
                    ),
                    DropdownMenuItem(value: 'active', child: Text('Đang học')),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text('Đã xong'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _statusFilter = val);
                  },
                ),
              ),
            );

            if (isMobile) {
              return Column(
                children: [searchField, SizedBox(height: 12), filterDropdown],
              );
            }
            return Row(
              children: [
                Expanded(flex: 3, child: searchField),
                SizedBox(width: 12),
                filterDropdown,
              ],
            );
          },
        ),
        SizedBox(height: 16),
        if (visibleClasses.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Không tìm thấy lớp phù hợp.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              double cardWidth;
              if (constraints.maxWidth >= 900) {
                cardWidth = 292; // Fixed on large screens
              } else if (constraints.maxWidth >= 600) {
                cardWidth = (constraints.maxWidth - 16) / 2; // 2 items per row
              } else {
                cardWidth = constraints.maxWidth; // 1 item per row full width
              }

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: visibleClasses.map((c) {
                  return _ClassCard(
                    classInfo: c,
                    width: cardWidth,
                    enabled: !busy,
                    onTap: () {
                      vm.selectClass(c.classCode);
                    },
                  );
                }).toList(),
              );
            },
          ),
      ],
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.classInfo,
    required this.enabled,
    required this.onTap,
    required this.width,
  });

  final HistoryClass classInfo;
  final bool enabled;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 180,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        classInfo.classCode,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  classInfo.subjectName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                Spacer(),
                Text(
                  '${classInfo.studentCount} sinh viên · ${classInfo.completedSessions}/${classInfo.totalSessions} buổi',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 8),
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
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        classInfo.latestSession == null
                            ? 'Chưa có buổi'
                            : 'Gần nhất ${historyDate(classInfo.latestSession!.sessionDate)}',
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
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
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
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
