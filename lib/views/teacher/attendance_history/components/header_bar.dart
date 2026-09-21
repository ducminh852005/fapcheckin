import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../viewmodels/attendance_history_viewmodel.dart';
import '../history_actions.dart';

class HeaderBar extends StatelessWidget {
  const HeaderBar({super.key});
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AttendanceHistoryViewModel>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 20,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Lịch sử điểm danh',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            OutlinedButton.icon(
              onPressed: vm.busy || vm.hasChanges ? null : vm.loadClasses,
              icon: const Icon(Icons.refresh),
              label: const Text('Làm mới'),
            ),
            FilledButton.icon(
              onPressed: vm.busy || vm.hasChanges || vm.detail == null
                  ? null
                  : () => exportHistory(context),
              icon: const Icon(Icons.download),
              label: const Text('Xuất Excel (.xlsx)'),
            ),
          ],
        ),
      ),
    );
  }
}
