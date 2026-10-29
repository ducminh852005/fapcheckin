import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../viewmodels/attendance_history_viewmodel.dart';
import 'components/class_selector.dart';
import 'components/class_details_view.dart';
import 'history_actions.dart';

class AttendanceHistoryBody extends StatefulWidget {
  const AttendanceHistoryBody({super.key});
  @override
  State<AttendanceHistoryBody> createState() => _AttendanceHistoryBodyState();
}

class _AttendanceHistoryBodyState extends State<AttendanceHistoryBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AttendanceHistoryViewModel>().loadClasses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AttendanceHistoryViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử điểm danh'),
        actions: [
          IconButton(
            tooltip: 'Đồng bộ FAP',
            onPressed: vm.busy ? null : () => syncClassToFap(context),
            icon: const Icon(Icons.sync),
          ),
          IconButton(
            onPressed: vm.busy ? null : () => vm.loadClasses(force: true),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: vm.busy || vm.summary == null
                ? null
                : () => exportHistory(context),
            icon: const Icon(Icons.download),
          ),
        ],
      ),
      body: Column(
        children: [
          if (vm.errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                vm.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          if (vm.loadingClasses) const LinearProgressIndicator(),
          Expanded(
            child: vm.selectedClassCode == null
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: vm.classes.isEmpty
                        ? const Text('Chưa có lớp học.')
                        : const ClassSelector(),
                  )
                : const ClassDetailsView(),
          ),
        ],
      ),
    );
  }
}
