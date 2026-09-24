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
import 'package:fapcheckin/views/teacher/report/components/regulatory_notice.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      child: Container(
        color: ReportColors.background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ReportHeader(generatedAt: report.generatedAt),
            SizedBox(height: 14),
            ReportKpis(data: report),
            SizedBox(height: 14),
            _ReportMainContent(data: report),
            SizedBox(height: 14),
            RegulatoryNotice(),
            SizedBox(height: 10),
            Center(
              child: Text(
                'Dữ liệu lấy từ các phiên điểm danh đã kết thúc · Responsive dashboard',
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
              SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: SubjectComparison(data: data)),
                  SizedBox(width: 14),
                  Expanded(child: CheckinModality(data: data)),
                ],
              ),
              SizedBox(height: 14),
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
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: SubjectComparison(data: data)),
                      const SizedBox(width: 14),
                      Expanded(child: CheckinModality(data: data)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(flex: 8, child: WarningTable(data: data)),
          ],
        );
      },
    );
  }
}
