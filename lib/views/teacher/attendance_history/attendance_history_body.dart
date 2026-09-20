import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../viewmodels/attendance_history_viewmodel.dart';
import '../../../viewmodels/dashboard_viewmodel.dart';
import 'components/class_selector.dart';
import 'components/kpi_dashboard.dart';
import 'components/history_table.dart';

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
    );
  }
}
