import 'package:flutter/material.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/views/teacher/attendance_history/components/class_selector.dart';
import 'package:fapcheckin/views/teacher/attendance_history/components/kpi_dashboard.dart';
import 'package:fapcheckin/views/teacher/attendance_history/components/history_table.dart';

class AttendanceHistoryBody extends StatelessWidget {
  const AttendanceHistoryBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
    );
  }
}
