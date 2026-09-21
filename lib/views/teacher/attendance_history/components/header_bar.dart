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
    final hasChanges = context.select<AttendanceHistoryViewModel, bool>(
      (value) => value.hasChanges,
    );
    final hasDetail = context.select<AttendanceHistoryViewModel, bool>(
      (value) => value.detail != null,
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
                  'Lịch sử điểm danh',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Theo dõi tình trạng điểm danh theo lớp và từng buổi học.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: busy || hasChanges
                ? null
                : () => vm.loadClasses(force: true),
            icon: const Icon(Icons.refresh_outlined),
            label: const Text('Làm mới'),
          ),
          FilledButton.icon(
            onPressed: busy || hasChanges || !hasDetail
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
