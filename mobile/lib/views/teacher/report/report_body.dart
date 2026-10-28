import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin_core/responsive/breakpoints.dart';
import 'package:fapcheckin_core/models/report_model.dart';
import '../../../viewmodels/report_viewmodel.dart';
import 'report_colors.dart';
import 'components/report_custom_header.dart';
import 'components/report_week_selector.dart';
import 'components/report_hero_gauge_card.dart';
import 'components/report_stat_cards.dart';
import 'components/report_daily_chart.dart';
import 'components/report_subject_summary.dart';
import 'components/report_export_button.dart';

/// Màn hình Báo cáo chuyên cần:
/// 1. Header (DỮ LIỆU ĐỂ THẤU HIỂU LỚP HỌC, Báo cáo chuyên cần, icon Download)
/// 2. Thẻ chọn tuần: "Tuần này - 05-11/10/2026"
/// 3. Thẻ Hero Dark Navy: Circular progress gauge (94,1% CÓ MẶT) + Nhịp học tập đang rất tốt
/// 4. 2 thẻ thống kê: Lượt có mặt (542) & Lượt vắng mặt (34)
/// 5. Thẻ biểu đồ cột: Chuyên cần theo ngày (T2 - 05 đến T5 - 08 cam)
/// 6. Thẻ danh sách: Tổng hợp theo môn (PRN231, SWP391, SWT301, PRM392)
/// 7. Nút: Xuất báo cáo Excel
/// 8. Ghi chú chân trang cập nhật thời gian
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
        context.read<ReportViewModel>().load();
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
                  // 1. Header
                  ReportCustomHeader(
                    onDownload: () => _handleExportExcel(context),
                  ),
                  const SizedBox(height: 16),

                  // 2. Chọn tuần
                  ReportWeekSelector(
                    weekLabel: 'Tuần này - 05-11/10/2026',
                    subtitle: 'Tất cả ${report?.classCount ?? 6} lớp • Chỉ tính ${report?.closedSessionCount ?? 18} buổi đã kết thúc',
                    onTap: () {
                      // Có thể mở popup chọn tuần khi cần
                    },
                  ),
                  const SizedBox(height: 16),

                  // 3. Hero Gauge Card (Dark Navy)
                  ReportHeroGaugeCard(
                    attendanceRate: attendanceRate,
                    attendanceRateText: attendanceRateText,
                    statusHeadline: 'Nhịp học tập\nđang rất tốt',
                    detailText: '$presentCount/${presentCount + absentCount} lượt có mặt\ntrong ${report?.closedSessionCount ?? 18} buổi học',
                    trendText: '↗ +2,3 điểm % so với tuần trước',
                  ),
                  const SizedBox(height: 14),

                  // 4. Hai thẻ thống kê nhanh: Lượt có mặt & Lượt vắng mặt
                  ReportStatCards(
                    presentCount: presentCount,
                    absentCount: absentCount,
                  ),
                  const SizedBox(height: 16),

                  // 5. Thẻ chuyên cần theo ngày (Biểu đồ cột)
                  const ReportDailyChart(
                    items: [
                      DailyAttendanceItem(
                        dayLabel: 'T2 - 05',
                        rate: 93.8,
                        rateText: '93,8',
                      ),
                      DailyAttendanceItem(
                        dayLabel: 'T3 - 06',
                        rate: 95.1,
                        rateText: '95,1',
                      ),
                      DailyAttendanceItem(
                        dayLabel: 'T4 - 07',
                        rate: 92.7,
                        rateText: '92,7',
                      ),
                      DailyAttendanceItem(
                        dayLabel: 'T5 - 08',
                        rate: 93.8,
                        rateText: '93,8',
                        isHighlighted: true,
                      ),
                    ],
                    note: 'T6–CN: chưa có buổi học kết thúc.',
                  ),
                  const SizedBox(height: 16),

                  // 6. Tổng hợp theo môn
                  ReportSubjectSummary(subjects: subjects),
                  const SizedBox(height: 18),

                  // 7. Nút xuất file Excel
                  ReportExportButton(
                    onPressed: () => _handleExportExcel(context),
                  ),
                  const SizedBox(height: 16),

                  // 8. Chân trang thông tin cập nhật
                  Center(
                    child: Text(
                      'Cập nhật lúc 09:41, 08/10/2026.\nPhiên PRN231 - SE1801 đang mở chưa được tính.',
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
      ),
    );
  }

  double _getAttendanceRate(ReportData? report) {
    if (report == null) return 94.1;
    final rate = report.kpis.attendanceRate;
    if (rate <= 0) return 94.1;
    return rate > 1.0 ? rate : rate * 100.0;
  }

  String _getAttendanceRateText(double rate) {
    return '${rate.toStringAsFixed(1).replaceAll('.', ',')}%';
  }

  int _getPresentCount(ReportData? report) {
    if (report != null && report.kpis.totalCheckins > 0) {
      return report.kpis.totalCheckins;
    }
    return 542;
  }

  int _getAbsentCount(ReportData? report, int presentCount) {
    if (report != null && report.warnings.isNotEmpty) {
      final totalAbs = report.warnings.fold<int>(0, (acc, w) => acc + w.absent);
      if (totalAbs > 0) return totalAbs;
    }
    return 34;
  }

  List<SubjectAttendanceSummary> _getSubjects(ReportData? report) {
    if (report != null && report.subjects.isNotEmpty) {
      return report.subjects.map((s) {
        final rate = s.attendanceRate > 1.0 ? s.attendanceRate / 100.0 : s.attendanceRate;
        final count = (s.studentCount * rate * 8).round();
        final total = s.studentCount * 8;
        return SubjectAttendanceSummary(
          code: s.classCode.isNotEmpty ? s.classCode : s.subjectName,
          checkinCountText: '$count/$total lượt',
          rateText: '${(rate * 100).toStringAsFixed(1).replaceAll('.', ',')}%',
          rate: rate,
        );
      }).toList();
    }

    return const [
      SubjectAttendanceSummary(
        code: 'PRN231',
        checkinCountText: '238/256 lượt',
        rateText: '93,0%',
        rate: 0.930,
      ),
      SubjectAttendanceSummary(
        code: 'SWP391',
        checkinCountText: '244/256 lượt',
        rateText: '95,3%',
        rate: 0.953,
      ),
      SubjectAttendanceSummary(
        code: 'SWT301',
        checkinCountText: '30/32 lượt',
        rateText: '93,8%',
        rate: 0.938,
      ),
      SubjectAttendanceSummary(
        code: 'PRM392',
        checkinCountText: '30/32 lượt',
        rateText: '93,8%',
        rate: 0.938,
      ),
    ];
  }

  void _handleExportExcel(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đang xuất báo cáo chuyên cần ra file Excel...'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
