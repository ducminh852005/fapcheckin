import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fapcheckin_core/constants/app_colors.dart';
import 'package:fapcheckin_core/constants/app_spacing.dart';
import '../../../../viewmodels/attendance_history_viewmodel.dart';
import './kpi_dashboard.dart';
import './history_table.dart';
import './sessions_tab.dart';

class ClassDetailsView extends StatefulWidget {
  const ClassDetailsView({super.key});

  @override
  State<ClassDetailsView> createState() => _ClassDetailsViewState();
}

class _ClassDetailsViewState extends State<ClassDetailsView>
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
    final vm = context.read<AttendanceHistoryViewModel>();
    final loadingSummary = context.select<AttendanceHistoryViewModel, bool>(
      (value) => value.loadingSummary,
    );
    final hasSummary = context.select<AttendanceHistoryViewModel, bool>(
      (value) => value.summary != null,
    );
    final errorMessage = context.select<AttendanceHistoryViewModel, String?>(
      (value) => value.errorMessage,
    );

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => vm.clearSelectedClass(),
              ),
              SizedBox(width: 8),
              Text(
                'Chi tiết lớp học',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),

          if (loadingSummary)
            Expanded(child: Center(child: CircularProgressIndicator()))
          else if (errorMessage != null && !hasSummary)
            Expanded(
              child: Center(
                child: Text(
                  errorMessage,
                  style: TextStyle(color: AppColors.statusAbsent),
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
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      dividerColor: Colors.transparent,
                      tabs: [
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
                  SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
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
            Expanded(child: Center(child: Text('Không có dữ liệu.'))),
        ],
      ),
    );
  }
}
