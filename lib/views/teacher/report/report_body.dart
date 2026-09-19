import 'package:flutter/material.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/views/teacher/report/components/report_header.dart';
import 'package:fapcheckin/views/teacher/report/components/report_kpis.dart';
import 'package:fapcheckin/views/teacher/report/components/report_charts.dart';
import 'package:fapcheckin/views/teacher/report/components/subject_comparison.dart';
import 'package:fapcheckin/views/teacher/report/components/checkin_modality.dart';
import 'package:fapcheckin/views/teacher/report/components/warning_table.dart';
import 'package:fapcheckin/views/teacher/report/components/regulatory_notice.dart';

class ReportBody extends StatelessWidget {
  const ReportBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReportHeader(),
          SizedBox(height: AppSpacing.lg),
          ReportKpis(),
          SizedBox(height: AppSpacing.lg),
          
          // Main Content Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT COLUMN: Trend and Comparative Visualizations
              Expanded(
                flex: 7,
                child: Column(
                  children: [
                    ReportCharts(),
                    SizedBox(height: AppSpacing.lg),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: SubjectComparison()),
                        SizedBox(width: AppSpacing.lg),
                        Expanded(child: CheckinModality()),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.lg),
              // RIGHT COLUMN: Warning Table & Action Hub
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    WarningTable(),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: AppSpacing.lg),
          RegulatoryNotice(),
        ],
      ),
    );
  }
}
