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
import 'components/report_hero_gauge_card.dart';
import 'components/report_stat_cards.dart';
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
    final reportVm = context.watch<ReportViewModel>();
    final report = reportVm.report;
    final horizontalPadding = context.isMobile ? 18.0 : context.pagePadding;

    // Chuẩn bị dữ liệu hiển thị (kết hợp dữ liệu API và dữ liệu mẫu chuẩn mockup)
    final attendanceRate = _getAttendanceRate(report);
    final attendanceRateText = _getAttendanceRateText(attendanceRate);
    final presentCount = _getPresentCount(report);
    final absentCount = _getAbsentCount(report, presentCount);
    final subjects = _getSubjects(report);

    return Scaffold(
      backgroundColor: ReportColors.pageBg,
      body: RefreshIndicator(
        color: ReportColors.orangePrimary,
        onRefresh: () => reportVm.load(force: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Stack(
            children: [
              // Hiệu ứng ánh sáng ấm áp góc trên đồng bộ với Trang chủ & Lịch dạy
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
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  context.isMobile ? 16.0 : 24.0,
                  horizontalPadding,
                  context.isMobile ? 32.0 : 40.0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (reportVm.loading) const LinearProgressIndicator(),
                        if (reportVm.errorMessage != null)
                          Text(reportVm.errorMessage!),
                        // 1. Header có nút xuất Excel ở góc phải
                        ReportCustomHeader(
                          onDownload: () => _handleExportExcel(context),
                        ),
                        const SizedBox(height: 16),

                        // 2. Chọn tuần / Phạm vi báo cáo
                        ReportWeekSelector(
                          weekLabel: _formatWeekLabel(reportVm.from, reportVm.to),
                          subtitle:
                              'Tất cả ${report?.classCount ?? 0} lớp • Đã kết thúc: ${report?.closedSessionCount ?? 0} buổi đã kết thúc',
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
                        const SizedBox(height: 16),

                        // 3. Hero Gauge Card (Dark Navy)
                        ReportHeroGaugeCard(
                          attendanceRate: attendanceRate,
                          attendanceRateText: attendanceRateText,
                          statusHeadline: report == null
                              ? 'Chưa có dữ liệu'
                              : 'Chuyên cần\ncác lớp phụ trách',
                          detailText:
                              '$presentCount/${presentCount + absentCount} lượt có mặt\ntrong ${report?.closedSessionCount ?? 0} buổi học',
                          trendText: 'Tính trên các lượt đã ghi nhận',
                        ),
                        const SizedBox(height: 14),

                        // 4. Hai thẻ thống kê nhanh: Lượt có mặt & Lượt vắng mặt
                        ReportStatCards(
                          presentCount: presentCount,
                          absentCount: absentCount,
                        ),
                        const SizedBox(height: 16),

                        // 5. Thẻ chuyên cần theo ngày (Biểu đồ cột)
                        ReportDailyChart(
                          items: [
                            for (final w in report?.weekly ?? <ReportWeek>[])
                              DailyAttendanceItem(
                                dayLabel: w.label,
                                rate: w.presentRate * 100,
                                rateText: (w.presentRate * 100).toStringAsFixed(
                                   1,
                                ),
                              ),
                          ],
                          note: 'Tuần tính từ buổi học đầu tiên. Chỉ tính lượt đã ghi nhận.',
                        ),
                        const SizedBox(height: 16),

                        // 6. Tổng hợp theo môn
                        ReportSubjectSummary(subjects: subjects),
                        const SizedBox(height: 18),

                        // 7. Chân trang thông tin cập nhật
                        Center(
                          child: Text(
                            report == null
                                ? 'Chưa có báo cáo.'
                                : 'Cập nhật: ${DateTime.tryParse(report.generatedAt)?.toLocal() ?? report.generatedAt}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              color: ReportColors.textSubtle,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
