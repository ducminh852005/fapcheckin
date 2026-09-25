import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../viewmodels/attendance_history_viewmodel.dart';
import '../history_actions.dart';

class HeaderBar extends StatelessWidget {
  const HeaderBar({super.key});
  @override
  Widget build(BuildContext context) {
    final vm = context.read<AttendanceHistoryViewModel>();
    final busy = context.select<AttendanceHistoryViewModel, bool>(
      (value) => value.busy,
    );
    final hasSummary = context.select<AttendanceHistoryViewModel, bool>(
      (value) => value.summary != null,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 14,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const SizedBox(
            width: 280,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Khóa học',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tổng hợp lịch sử điểm danh theo từng lớp, từ buổi đầu đến nay.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: busy ? null : () => vm.loadClasses(force: true),
            icon: const Icon(Icons.refresh_outlined),
            label: const Text('Làm mới'),
          ),
          FilledButton.icon(
            onPressed: busy || !hasSummary
                ? null
                : () => exportHistory(context),
            icon: const Icon(Icons.file_download_outlined),
            label: const Text('Xuất Excel'),
          ),
        ],
      ),
    );
  }
}
