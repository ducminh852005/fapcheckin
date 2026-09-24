import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin/views/teacher/report/report_colors.dart';
import 'package:fapcheckin/data/models/report_model.dart';
import 'package:fapcheckin/viewmodels/report_viewmodel.dart';
import 'package:fapcheckin/views/teacher/report/components/report_header.dart';
import 'package:fapcheckin/views/teacher/report/components/report_kpis.dart';
import 'package:fapcheckin/views/teacher/report/components/report_charts.dart';
import 'package:fapcheckin/views/teacher/report/components/subject_comparison.dart';
import 'package:fapcheckin/views/teacher/report/components/checkin_modality.dart';
import 'package:fapcheckin/views/teacher/report/components/warning_table.dart';

class ReportBody extends StatelessWidget {
  const ReportBody({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportViewModel>();
    if (!vm.loading && vm.report == null && vm.errorMessage == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => vm.load());
    }
    if (vm.loading && vm.report == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.errorMessage != null && vm.report == null) {
      return Center(child: Text(vm.errorMessage!));
    }
    final report = vm.report;
    if (report == null) return const SizedBox.shrink();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: Container(
        color: ReportColors.background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ReportHeader(
              generatedAt: report.generatedAt,
              semester: report.semester,
              classCount: report.classCount,
            ),
            const SizedBox(height: 18),
            ReportKpis(data: report),
            const SizedBox(height: 18),
            _ReportMainContent(data: report),
            const SizedBox(height: 18),
            Center(
              child: Text(
                'Dữ liệu từ các phiên điểm danh đã kết thúc',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: ReportColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportMainContent extends StatelessWidget {
  final ReportData data;
  const _ReportMainContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1050) {
          return Column(
            children: [
              ReportCharts(data: data),
              const SizedBox(height: 18),
              if (constraints.maxWidth < 700) ...[
                SubjectComparison(data: data),
                const SizedBox(height: 18),
                CheckinModality(data: data),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: SubjectComparison(data: data)),
                    const SizedBox(width: 18),
                    Expanded(child: CheckinModality(data: data)),
                  ],
                ),
              const SizedBox(height: 18),
              WarningTable(data: data),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 17,
              child: Column(
                children: [
                  ReportCharts(data: data),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: SubjectComparison(data: data)),
                      const SizedBox(width: 18),
                      Expanded(child: CheckinModality(data: data)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(flex: 8, child: WarningTable(data: data)),
          ],
        );
      },
    );
  }
}
