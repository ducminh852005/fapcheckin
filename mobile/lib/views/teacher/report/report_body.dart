import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './report_colors.dart';
import 'package:fapcheckin_core/models/report_model.dart';
import '../../../viewmodels/report_viewmodel.dart';
import './components/report_header.dart';
import './components/report_kpis.dart';
import './components/report_charts.dart';
import './components/subject_comparison.dart';
import './components/checkin_modality.dart';
import './components/warning_table.dart';
import 'package:fapcheckin_core/responsive/breakpoints.dart';

class ReportBody extends StatefulWidget {
  const ReportBody({super.key});

  @override
  State<ReportBody> createState() => _ReportBodyState();
}

class _ReportBodyState extends State<ReportBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ReportViewModel>().load(force: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportViewModel>();
    if (vm.loading && vm.report == null) {
      return Center(child: CircularProgressIndicator());
    }
    if (vm.errorMessage != null && vm.report == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(vm.errorMessage!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => vm.load(force: true),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }
    final report = vm.report;
    if (report == null) return SizedBox.shrink();
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        context.pagePadding,
        context.isMobile ? 12 : 20,
        context.pagePadding,
        28,
      ),
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
            SizedBox(height: 18),
            ReportKpis(data: report),
            SizedBox(height: 18),
            _ReportMainContent(data: report),
            SizedBox(height: 18),
            Center(
              child: Text(
                'Dữ liệu từ các phiên điểm danh đang mở và đã hoàn thành',
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
              SizedBox(height: 18),
              if (constraints.maxWidth < 700) ...[
                SubjectComparison(data: data),
                SizedBox(height: 18),
                CheckinModality(data: data),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: SubjectComparison(data: data)),
                    SizedBox(width: 18),
                    Expanded(child: CheckinModality(data: data)),
                  ],
                ),
              SizedBox(height: 18),
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
                  SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: SubjectComparison(data: data)),
                      SizedBox(width: 18),
                      Expanded(child: CheckinModality(data: data)),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 18),
            Expanded(flex: 8, child: WarningTable(data: data)),
          ],
        );
      },
    );
  }
}
