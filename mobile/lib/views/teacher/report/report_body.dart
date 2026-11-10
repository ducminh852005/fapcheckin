import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin_core/responsive/breakpoints.dart';
import 'package:fapcheckin_core/models/report_model.dart';

import '../../../viewmodels/report_viewmodel.dart';
import 'report_colors.dart';

import 'package:fapcheckin_core/utils/history_excel.dart';

import '../../../core/services/history_download.dart';
import 'components/report_custom_header.dart';
import 'components/report_week_selector.dart';
import 'components/report_scope_bottom_sheet.dart';
import 'components/report_mini_kpi_bar.dart';
import 'components/report_daily_chart.dart';
import 'components/report_subject_summary.dart';

/// Màn hình Báo cáo chuyên cần:
/// 1. Header (Báo cáo chuyên cần, icon Download xuất Excel ở góc phải)
/// 2. Thẻ chọn tuần: "Tuần này - 05-11/10/2026"
/// 3. Thẻ Hero Dark Navy: Circular progress gauge (94,1% CÓ MẶT) + Nhịp học tập đang rất tốt
/// 4. 2 thẻ thống kê: Lượt có mặt (542) & Lượt vắng mặt (34)
/// 5. Thẻ biểu đồ cột: Chuyên cần theo ngày (T2 - 05 đến T5 - 08 cam)
/// 6. Thẻ danh sách: Tổng hợp theo môn (PRN231, SWP391, SWT301, PRM392)
/// 7. Ghi chú chân trang cập nhật thời gian
class ReportBody extends StatefulWidget {
  const ReportBody({super.key, this.embedded = false});

  /// Khi nhúng vào Tổng quan, chỉ dựng nội dung báo cáo, không tạo Scaffold
  /// hoặc vùng cuộn riêng.
  final bool embedded;

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
    final reportVm = context.watch<ReportViewModel>();
    final report = reportVm.report;
    final horizontalPadding = context.isMobile ? 18.0 : context.pagePadding;

    // Chuẩn bị dữ liệu hiển thị (kết hợp dữ liệu API và dữ liệu mẫu chuẩn mockup)
    final attendanceRate = _getAttendanceRate(report);
    final attendanceRateText = _getAttendanceRateText(attendanceRate);
    final presentCount = _getPresentCount(report);
    final absentCount = _getAbsentCount(report, presentCount);
    final subjects = _getSubjects(report);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isShortScreen = MediaQuery.sizeOf(context).height < 500;

    if (widget.embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildEmbeddedHeader(
            context: context,
            reportVm: reportVm,
            report: report,
            attendanceRate: attendanceRate,
            attendanceRateText: attendanceRateText,
            presentCount: presentCount,
            absentCount: absentCount,
          ),
          const SizedBox(height: 12),
          ..._buildScrollableItems(
            context: context,
            reportVm: reportVm,
            report: report,
            subjects: subjects,
          ),
        ],
      );
    }

    if (isShortScreen) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            if (!isDark)
              Container(
                height: 220,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFEDE3),
                      Color(0xFFFFF8F5),
                      Color(0xFFF8FAFC),
                    ],
                  ),
                ),
              ),
            SafeArea(
              bottom: false,
              child: RefreshIndicator(
                color: ReportColors.orangePrimary,
                onRefresh: () => reportVm.load(force: true),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    16,
                    horizontalPadding,
                    context.isMobile ? 108.0 : 40.0,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTopControls(
                            context: context,
                            reportVm: reportVm,
                            report: report,
                            attendanceRate: attendanceRate,
                            attendanceRateText: attendanceRateText,
                            presentCount: presentCount,
                            absentCount: absentCount,
                          ),
                          const SizedBox(height: 12),
                          ..._buildScrollableItems(
                            context: context,
                            reportVm: reportVm,
                            report: report,
                            subjects: subjects,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          if (!isDark)
            Container(
              height: 220,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFEDE3),
                    Color(0xFFFFF8F5),
                    Color(0xFFF8FAFC),
                  ],
                ),
              ),
            ),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 1. Khung cố định: Header + Chọn tuần + Mini KPI Bar ──
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    16,
                    horizontalPadding,
                    8,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: _buildTopControls(
                        context: context,
                        reportVm: reportVm,
                        report: report,
                        attendanceRate: attendanceRate,
                        attendanceRateText: attendanceRateText,
                        presentCount: presentCount,
                        absentCount: absentCount,
                      ),
                    ),
                  ),
                ),

                // ── 2. Vùng cuộn chi tiết: Biểu đồ cột, Tổng hợp theo môn ──
                Expanded(
                  child: RefreshIndicator(
                    color: ReportColors.orangePrimary,
                    onRefresh: () => reportVm.load(force: true),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        6,
                        horizontalPadding,
                        context.isMobile ? 108.0 : 40.0,
                      ),
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 680),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: _buildScrollableItems(
                                context: context,
                                reportVm: reportVm,
                                report: report,
                                subjects: subjects,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmbeddedHeader({
    required BuildContext context,
    required ReportViewModel reportVm,
    required ReportData? report,
    required double attendanceRate,
    required String attendanceRateText,
    required int presentCount,
    required int absentCount,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? ReportColors.orangePrimary.withValues(alpha: .16)
                    : const Color(0xFFFFEDE3),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.insights_rounded,
                color: ReportColors.orangePrimary,
                size: 21,
              ),
            ),
            const SizedBox(width: 11),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phân tích chuyên cần',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: ReportColors.textDark,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Theo dõi xu hướng và hiệu quả điểm danh',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: ReportColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Xuất báo cáo Excel',
              onPressed: report == null
                  ? null
                  : () => _handleExportExcel(context),
              icon: const Icon(Icons.download_rounded, size: 20),
              style: IconButton.styleFrom(
                foregroundColor: ReportColors.orangePrimary,
                backgroundColor: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFFFF1EA),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ReportWeekSelector(
          weekLabel: _formatWeekLabel(reportVm.from, reportVm.to),
          subtitle:
              '${report?.classCount ?? 0} lớp • ${report?.closedSessionCount ?? 0} buổi đã kết thúc',
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
          attendanceRate: attendanceRate,
          attendanceRateText: attendanceRateText,
          presentCount: presentCount,
          absentCount: absentCount,
        ),
      ],
    );
  }

  Widget _buildTopControls({
    required BuildContext context,
    required ReportViewModel reportVm,
    required ReportData? report,
    required double attendanceRate,
    required String attendanceRateText,
    required int presentCount,
    required int absentCount,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Header có nút xuất Excel ở góc phải
        ReportCustomHeader(onDownload: () => _handleExportExcel(context)),
        const SizedBox(height: 12),

        // 2. Chọn tuần / Phạm vi báo cáo
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

        // 3. Mini KPI Bar (Tỉ lệ % & Lượt có mặt/vắng)
        ReportMiniKpiBar(
          attendanceRate: attendanceRate,
          attendanceRateText: attendanceRateText,
          presentCount: presentCount,
          absentCount: absentCount,
        ),
      ],
    );
  }

  List<Widget> _buildScrollableItems({
    required BuildContext context,
    required ReportViewModel reportVm,
    required ReportData? report,
    required List<SubjectAttendanceSummary> subjects,
  }) {
    return [
      if (reportVm.loading)
        Container(
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
        ),
      if (reportVm.errorMessage != null)
        Container(
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
                  reportVm.errorMessage!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFFB91C1C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => reportVm.load(force: true),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Thử lại'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              ),
            ],
          ),
        ),

      // 4. Thẻ chuyên cần theo ngày (Biểu đồ cột)
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

      // 5. Tổng hợp theo môn
      ReportSubjectSummary(subjects: subjects),
      const SizedBox(height: 18),

      const SizedBox(height: 8),
    ];
  }

  String _formatWeekLabel(DateTime? from, DateTime? to) {
    if (from == null || to == null) return 'Toàn bộ lịch sử điểm danh';
    final fromStr =
        '${from.day.toString().padLeft(2, '0')}/${from.month.toString().padLeft(2, '0')}/${from.year}';
    final toStr =
        '${to.day.toString().padLeft(2, '0')}/${to.month.toString().padLeft(2, '0')}/${to.year}';
    if (fromStr == toStr) {
      return 'Hôm nay - $fromStr';
    }
    return '$fromStr → $toStr';
  }

  double _getAttendanceRate(ReportData? report) =>
      (report?.kpis.attendanceRate ?? 0) * 100;
  String _getAttendanceRateText(double rate) => '${rate.toStringAsFixed(1)}%';
  int _getPresentCount(ReportData? report) => report?.kpis.totalCheckins ?? 0;
  int _getAbsentCount(ReportData? report, int presentCount) =>
      report?.kpis.absentCount ?? 0;
  List<SubjectAttendanceSummary> _getSubjects(ReportData? report) => [
    for (final s in report?.subjects ?? <ReportSubject>[])
      SubjectAttendanceSummary(
        code: '${s.classCode} · ${s.subjectName}',
        checkinCountText: '${s.presentCount}/${s.expectedCount} lượt',
        rateText: '${(s.attendanceRate * 100).toStringAsFixed(1)}%',
        rate: s.attendanceRate,
      ),
  ];
  Future<void> _handleExportExcel(BuildContext context) async {
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể xuất báo cáo: $e')));
      }
    }
  }
}
