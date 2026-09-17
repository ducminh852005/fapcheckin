import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/viewmodels/attendance_history_viewmodel.dart';
import 'package:fapcheckin/data/models/history_class.dart';

class ClassSelector extends StatelessWidget {
  const ClassSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AttendanceHistoryViewModel>();
    final classes = vm.classes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.view_carousel, color: AppColors.primaryContainer, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Lớp học phụ trách',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '${classes.length} Lớp',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {},
                child: const Row(
                  children: [
                    Text('Xem tất cả danh sách', style: TextStyle(fontSize: 12, color: AppColors.primaryContainer)),
                    Icon(Icons.arrow_forward, size: 16, color: AppColors.primaryContainer),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: classes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final hc = classes[index];
              final isSelected = hc.courseCode == vm.selectedClassCode;
              return _ClassCard(
                historyClass: hc,
                isSelected: isSelected,
                onTap: () => vm.selectClass(hc.courseCode),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ClassCard extends StatelessWidget {
  final HistoryClass historyClass;
  final bool isSelected;
  final VoidCallback onTap;

  const _ClassCard({
    required this.historyClass,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progressPct = historyClass.completedSessions / historyClass.totalSessions;
    final pctString = (historyClass.attendanceRate * 100).toStringAsFixed(1);
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 240,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight.withValues(alpha: 0.4) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: AppColors.primaryContainer, width: 2) : Border.all(color: Colors.transparent, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryContainer : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    historyClass.className,
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.onPrimary : AppColors.textPrimary,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: historyClass.isWarning ? AppColors.statusLate : AppColors.statusPresent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$pctString%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: historyClass.isWarning ? AppColors.statusLate : AppColors.statusPresent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              historyClass.courseCode,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              historyClass.courseName,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tiến độ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      Text(
                        '${historyClass.completedSessions}/${historyClass.totalSessions} buổi',
                        style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: progressPct,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    color: AppColors.primaryContainer,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Gần nhất: ${historyClass.latestSessionDate}', style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                      Row(
                        children: [
                          Text(
                            historyClass.latestSessionName,
                            style: TextStyle(
                              fontSize: 12, 
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? AppColors.primaryContainer : AppColors.textSecondary
                            ),
                          ),
                          if (historyClass.isActive)
                            const Icon(Icons.check, size: 14, color: AppColors.primaryContainer),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
