import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
<<<<<<< HEAD
import '../../../core/constants/app_spacing.dart';
import '../../../viewmodels/attendance_history_viewmodel.dart';
import '../../../viewmodels/dashboard_viewmodel.dart';
import 'components/class_selector.dart';
import 'components/kpi_dashboard.dart';
import 'components/history_table.dart';

=======

import '../../../core/constants/app_spacing.dart';
import '../../../viewmodels/attendance_history_viewmodel.dart';
import 'components/header_bar.dart';
import 'components/class_selector.dart';
import 'components/kpi_dashboard.dart';
import 'components/history_table.dart';

>>>>>>> origin/dev
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
  State<AttendanceHistoryBody> createState() => _AttendanceHistoryBodyState();
}

class _AttendanceHistoryBodyState extends State<AttendanceHistoryBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dashVm = context.read<DashboardViewModel>();
      final historyVm = context.read<AttendanceHistoryViewModel>();
      if (dashVm.classes.isNotEmpty) {
        historyVm.setTeacherClasses(dashVm.classes);
      } else if (historyVm.selectedClassCode != null) {
        historyVm.loadHistoryForClass(historyVm.selectedClassCode!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    final historyVm = context.watch<AttendanceHistoryViewModel>();

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClassSelector(),
              SizedBox(height: AppSpacing.md),
              KpiDashboard(),
              SizedBox(height: AppSpacing.md),
              HistoryTable(),
            ],
          ),
        ),
        if (historyVm.isLoading)
          Container(
            color: Colors.black12,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
=======
    final vm = context.watch<AttendanceHistoryViewModel>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HeaderBar(),
          const SizedBox(height: AppSpacing.md),
          if (vm.hasChanges)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Có thay đổi chưa lưu. Hãy lưu hoặc hủy trước khi đổi lớp/buổi học.',
                    ),
                    TextButton(
                      onPressed: vm.busy ? null : vm.discardChanges,
                      child: const Text('Hủy thay đổi'),
                    ),
                  ],
                ),
              ),
            ),
          if (vm.errorMessage != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SelectableText(
                      vm.errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    TextButton(
                      onPressed: vm.busy || vm.hasChanges
                          ? null
                          : vm.loadClasses,
                      child: const Text('Tải lại'),
                    ),
                  ],
                ),
              ),
            ),
          if (vm.busy) const LinearProgressIndicator(),
          if (!vm.loadingClasses &&
              vm.classes.isEmpty &&
              vm.errorMessage == null)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Chưa có lớp được phân công cho tài khoản này.'),
            ),
          if (vm.classes.isNotEmpty) const ClassSelector(),
          if (vm.detail != null) ...[
            const SizedBox(height: AppSpacing.md),
            const KpiDashboard(),
            const SizedBox(height: AppSpacing.md),
            const HistoryTable(),
          ],
        ],
      ),
>>>>>>> origin/dev
    );
  }
}
