import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin_core/models/report_model.dart';
import 'package:fapcheckin_core/utils/history_excel.dart';

import '../../../core/services/history_download.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../viewmodels/report_viewmodel.dart';
import 'components/report_daily_chart.dart';
import 'components/report_mini_kpi_bar.dart';
import 'components/report_scope_bottom_sheet.dart';
import 'components/report_subject_summary.dart';
import 'components/report_week_selector.dart';
import 'report_colors.dart';

/// Báo cáo chuyên cần dạng khối nhúng (không Scaffold) — nằm trong màn Tổng quan.
/// Tự gọi [ReportViewModel.load] khi xuất hiện; kéo-để-làm-mới của Tổng quan gọi
/// thêm `load(force: true)` để cập nhật.
class ReportSection extends StatefulWidget {
  const ReportSection({super.key});

  @override
  State<ReportSection> createState() => _ReportSectionState();
}

class _ReportSectionState extends State<ReportSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ReportViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportVm = context.watch<ReportViewModel>();
    final report = reportVm.report;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      key: const Key('report-section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                'Báo cáo chuyên cần',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: isDark
                      ? const Color(0xFFF8FAFC)
                      : ReportColors.textDark,
                ),
              ),
            ),
            Tooltip(
              message: 'Xuất báo cáo Excel',
              child: IconButton(
                key: const Key('report-export'),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: report == null ? null : () => _exportExcel(context),
                icon: Icon(
                  Icons.file_download_outlined,
                  size: 24,
                  color: isDark
                      ? const Color(0xFFF8FAFC)
                      : const Color(0xFF334155),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ReportWeekSelector(
          weekLabel: _formatWeekLabel(reportVm.from, reportVm.to),
          subtitle:
              'Tất cả ${report?.classCount ?? 0} lớp • ${report?.closedSessionCount ?? 0} buổi đã kết thúc',
          onTap: () async {
            final range = await showReportScopeBottomSheet(
              context: context,
              currentFrom: reportVm.from,
              currentTo: reportVm.to,
              totalClosedSessions: report?.closedSessionCount ?? 0,
            );
            if (!context.mounted || range == null) return;
            await reportVm.setRange(range['start'], range['end']);
          },
        ),
        const SizedBox(height: 10),
        ReportMiniKpiBar(
          attendanceRate: (report?.kpis.attendanceRate ?? 0) * 100,
          attendanceRateText:
              '${((report?.kpis.attendanceRate ?? 0) * 100).toStringAsFixed(1)}%',
          presentCount: report?.kpis.totalCheckins ?? 0,
          absentCount: report?.kpis.absentCount ?? 0,
        ),
        const SizedBox(height: 12),
        if (reportVm.loading) const _LoadingBanner(),
        if (reportVm.errorMessage != null)
          _ErrorBanner(
            message: reportVm.errorMessage!,
            onRetry: () => reportVm.load(force: true),
          ),
        ReportDailyChart(
          items: [
            for (final w in report?.weekly ?? <ReportWeek>[])
              DailyAttendanceItem(
                dayLabel: w.label,
                rate: w.presentRate * 100,
                rateText: (w.presentRate * 100).toStringAsFixed(1),
              ),
          ],
          note: 'Tuần tính từ buổi học đầu tiên. Chỉ tính lượt đã ghi nhận.',
        ),
        const SizedBox(height: 16),
        ReportSubjectSummary(subjects: _subjects(report)),
        const SizedBox(height: 12),
        Center(
          child: Text(
            report == null
                ? 'Chưa có báo cáo.'
                : 'Cập nhật: ${_formatGeneratedAt(report.generatedAt)}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: ReportColors.textSubtle,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }

  List<SubjectAttendanceSummary> _subjects(ReportData? report) => [
    for (final s in report?.subjects ?? <ReportSubject>[])
      SubjectAttendanceSummary(
        code: '${s.classCode} · ${s.subjectName}',
        checkinCountText: '${s.presentCount}/${s.expectedCount} lượt',
        rateText: '${(s.attendanceRate * 100).toStringAsFixed(1)}%',
        rate: s.attendanceRate,
      ),
  ];

  String _formatGeneratedAt(String raw) {
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return raw;
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    return '$hh:$mm · $dd/$mo/${dt.year}';
  }

  String _formatWeekLabel(DateTime? from, DateTime? to) {
    if (from == null || to == null) return 'Toàn bộ lịch sử điểm danh';
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    final fromStr = fmt(from);
    final toStr = fmt(to);
    if (fromStr == toStr) return 'Hôm nay - $fromStr';
    return '$fromStr → $toStr';
  }

  Future<void> _exportExcel(BuildContext context) async {
    final report = context.read<ReportViewModel>().report;
    if (report == null) return;
    try {
      final file = buildHistoryWorkbook([
        ['Lớp', 'Môn', 'Sĩ số', 'Có mặt', 'Tổng lượt', 'Tỷ lệ có mặt'],
        for (final s in report.subjects)
          [
            s.classCode,
            s.subjectName,
            s.studentCount,
            s.presentCount,
            s.expectedCount,
            s.attendanceRate,
          ],
      ], 'report');
      final message = await downloadHistory(
        file.filename,
        file.base64,
        file.mimeType,
      );
      if (context.mounted) {
        showAppToast(context, message: message, type: AppToastType.success);
      }
    } catch (e) {
      if (context.mounted) {
        showAppToast(
          context,
          message: 'Không thể xuất báo cáo: $e',
          type: AppToastType.error,
        );
      }
    }
  }
}

class _LoadingBanner extends StatelessWidget {
  const _LoadingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ReportColors.orangePrimary,
            ),
          ),
          SizedBox(width: 10),
          Text(
            'Đang cập nhật dữ liệu báo cáo...',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: ReportColors.orangePrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFFB91C1C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Thử lại'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(48, 48),
            ),
          ),
        ],
      ),
    );
  }
}
