import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../viewmodels/attendance_history_viewmodel.dart';
import 'kpi_dashboard.dart';
import 'history_table.dart';
import 'sessions_tab.dart';

class ClassDetailsDialog extends StatefulWidget {
  const ClassDetailsDialog({super.key});

  @override
  State<ClassDetailsDialog> createState() => _ClassDetailsDialogState();
}

class _ClassDetailsDialogState extends State<ClassDetailsDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loadingSummary = context.select<AttendanceHistoryViewModel, bool>(
      (value) => value.loadingSummary,
    );
    final hasSummary = context.select<AttendanceHistoryViewModel, bool>(
      (value) => value.summary != null,
    );
    final errorMessage = context.select<AttendanceHistoryViewModel, String?>(
      (value) => value.errorMessage,
    );

    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 1000,
        height: 700,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chi tiết lớp học',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            
            if (loadingSummary)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (errorMessage != null && !hasSummary)
              Expanded(
                child: Center(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: AppColors.statusAbsent),
                  ),
                ),
              )
            else if (hasSummary)
              Expanded(
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: AppColors.primaryContainer,
                        unselectedLabelColor: AppColors.textSecondary,
                        indicatorColor: AppColors.primaryContainer,
                        indicatorSize: TabBarIndicatorSize.label,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(
                            icon: Icon(Icons.bar_chart_outlined, size: 18),
                            text: 'Tổng quan',
                          ),
                          Tab(
                            icon: Icon(Icons.list_alt_outlined, size: 18),
                            text: 'Buổi học',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: const [
                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                KpiDashboard(),
                                SizedBox(height: AppSpacing.md),
                                HistoryTable(),
                              ],
                            ),
                          ),
                          SessionsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              const Expanded(
                child: Center(
                  child: Text('Không có dữ liệu.'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
