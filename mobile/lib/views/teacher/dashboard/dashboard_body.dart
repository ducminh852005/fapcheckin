import 'package:fapcheckin_core/models/class_section_model.dart';
import 'package:fapcheckin_core/models/report_model.dart';
import 'package:fapcheckin_core/responsive/breakpoints.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../viewmodels/dashboard_viewmodel.dart';
import '../../../viewmodels/live_session_viewmodel.dart';
import '../../../viewmodels/report_viewmodel.dart';
import '../../../core/services/auto_session_manager.dart';
import '../live_session/dialogs/start_session_dialog.dart';
import 'components/dashboard_header.dart';
import 'components/weekly_timetable.dart';
import 'dashboard_colors.dart';

/// Dashboard mobile compact: hành động hiện tại ở trên, phân tích ở dưới.
/// Mọi số liệu đều đến từ DashboardViewModel và ReportViewModel (Firebase).
class DashboardBody extends StatefulWidget {
  const DashboardBody({super.key});

  @override
  State<DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<DashboardBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ReportViewModel>().load(force: true);
    });
  }

  Future<void> _refreshAll() => Future.wait([
    context.read<DashboardViewModel>().loadClasses(),
    context.read<ReportViewModel>().load(force: true),
  ]);

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardViewModel>();
    final reportVm = context.watch<ReportViewModel>();
    final report = reportVm.report;
    final live = context.watch<LiveSessionViewModel>();
    final padding = context.isMobile ? 16.0 : context.pagePadding;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final todayClasses = _todayClasses(dashboard.classes);
    final focusClass = _currentClass(todayClasses);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          if (!isDark)
            Container(
              height: 240,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: DashboardColors.headerGradient,
              ),
            ),
          SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: RefreshIndicator(
                  color: DashboardColors.orangePrimary,
                  onRefresh: _refreshAll,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      padding,
                      12,
                      padding,
                      context.isMobile ? 108 : 32,
                    ),
                    children: [
                      const DashboardHeader(),
                      const SizedBox(height: 14),
                      if (dashboard.isLoading || reportVm.loading)
                        const LinearProgressIndicator(minHeight: 2),
                      if (dashboard.errorMessage != null) ...[
                        const SizedBox(height: 10),
                        _ErrorCard(
                          message: dashboard.errorMessage!,
                          onRetry: _refreshAll,
                        ),
                      ],
                      const SizedBox(height: 10),
                      _AttendanceAnalysisCard(report: report),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _CountCard(
                              icon: Icons.groups_rounded,
                              title: 'LỚP ĐANG DẠY',
                              value: '${dashboard.classes.length}',
                              unit: 'lớp',
                              note:
                                  '${dashboard.totalStudents} sinh viên quản lý',
                              color: const Color(0xFFFF5A1F),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _CountCard(
                              icon: Icons.calendar_today_rounded,
                              title: 'CA HÔM NAY',
                              value: '${todayClasses.length}',
                              unit: 'ca dạy',
                              note: dashboard.classes.any((c) => c.isActive)
                                  ? '1 ca đang tiến hành'
                                  : 'Chưa có ca đang mở',
                              color: const Color(0xFF356DF3),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (focusClass != null)
                        _CurrentClassCard(
                          classInfo: focusClass,
                          dashboard: dashboard,
                          live: live,
                        ),
                      const SizedBox(height: 12),
                      _WeeklyAttendanceCard(report: report),
                      const SizedBox(height: 12),
                      _SubjectAnalysisCard(report: report),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<ClassSectionModel> _todayClasses(List<ClassSectionModel> classes) {
    final today = DateTime.now().weekday;
    return classes.where((c) {
      if (c.isActive || c.isMakeup) return true;
      return SlotCodeParser.parse(c.slotCode)?.weekdays.contains(today) ??
          false;
    }).toList();
  }

  ClassSectionModel? _currentClass(List<ClassSectionModel> todayClasses) {
    // Session đang mở trên Firebase luôn được ưu tiên để giảng viên có thể
    // quay lại QR/đóng phiên, kể cả khi thiết bị vừa khôi phục ứng dụng.
    final openSession = todayClasses.where((c) => c.isActive).firstOrNull;
    if (openSession != null) return openSession;

    // Khi chưa mở session, chỉ cho phép hiện hành động QR trong đúng khung giờ
    // của ca. Không lấy lớp đầu tiên trong ngày làm ca hiện tại.
    final now = DateTime.now();
    for (final classInfo in todayClasses) {
      final (start, end) = TimeSlotHelper.resolveSlotRange(now, classInfo);
      if (start == null || end == null) continue;
      final hasStarted = now.isAtSameMomentAs(start) || now.isAfter(start);
      if (hasStarted && now.isBefore(end)) return classInfo;
    }
    return null;
  }
}

class _AttendanceAnalysisCard extends StatelessWidget {
  const _AttendanceAnalysisCard({required this.report});
  final ReportData? report;

  @override
  Widget build(BuildContext context) {
    final rate = (report?.kpis.attendanceRate ?? 0).clamp(0.0, 1.0);
    final present = report?.kpis.totalCheckins ?? 0;
    final absent = report?.kpis.absentCount ?? 0;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _SectionTitle(
                  icon: Icons.circle,
                  title: 'PHÂN TÍCH CHUYÊN CẦN',
                ),
              ),
              const SizedBox(width: 6),
              _SoftChip(text: report?.semester ?? 'Học kỳ hiện tại'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 92,
                height: 92,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: rate,
                        strokeWidth: 10,
                        strokeCap: StrokeCap.round,
                        color: DashboardColors.orangePrimary,
                        backgroundColor: const Color(0xFFF1F5F9),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(rate * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const Text(
                          'CÓ MẶT',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tỷ lệ chuyên cần rất tốt',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Ghi nhận tất cả giờ học đã hoàn tất.',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _AttendanceCount(
                            label: 'CÓ MẶT',
                            value: '$present sv',
                            color: const Color(0xFF059669),
                            background: const Color(0xFFECFDF5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _AttendanceCount(
                            label: 'VẮNG',
                            value: '$absent sv',
                            color: const Color(0xFFE11D48),
                            background: const Color(0xFFFFF1F2),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.unit,
    required this.note,
    required this.color,
  });
  final IconData icon;
  final String title, value, unit, note;
  final Color color;

  @override
  Widget build(BuildContext context) => _Panel(
    padding: const EdgeInsets.all(13),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            Icon(icon, size: 17, color: color),
          ],
        ),
        const SizedBox(height: 13),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          note,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 9.5, color: color),
        ),
      ],
    ),
  );
}

class _CurrentClassCard extends StatelessWidget {
  const _CurrentClassCard({
    required this.classInfo,
    required this.dashboard,
    required this.live,
  });
  final ClassSectionModel classInfo;
  final DashboardViewModel dashboard;
  final LiveSessionViewModel live;

  @override
  Widget build(BuildContext context) {
    final parsed = SlotCodeParser.parse(classInfo.slotCode);
    final slot = parsed?.slot.toString() ?? classInfo.slotCode;
    final active = classInfo.isActive;
    final scanned = live.classInfo?.classCode == classInfo.classCode
        ? live.roster.where((r) => r.isPresent).length
        : dashboard.activeSessionScanned;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DashboardColors.orangePrimary, width: 1.4),
        boxShadow: DashboardColors.activeCardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'CA TRỰC TIẾP • SLOT HIỆN TẠI',
                style: TextStyle(
                  color: DashboardColors.orangePrimary,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              _SoftChip(text: active ? 'Đang diễn ra' : 'Ca kế tiếp'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 42,
                height: 48,
                decoration: BoxDecoration(
                  color: DashboardColors.orangePrimary,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'CA',
                      style: TextStyle(color: Colors.white, fontSize: 9),
                    ),
                    Text(
                      slot,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          classInfo.subjectCode,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            classInfo.classCode,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${classInfo.timeLabel}  •  ${classInfo.room}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  '$scanned/${classInfo.studentCount}\ncó mặt',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF059669),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: FilledButton.icon(
              onPressed: () async {
                if (active) {
                  dashboard.navigate('diem-danh-qr');
                  return;
                }
                final ok = await startSessionWithOptions(
                  context,
                  classSection: classInfo,
                  slotCode: classInfo.slotCode,
                );
                if (context.mounted && ok) dashboard.navigate('diem-danh-qr');
              },
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
              label: Text(
                active ? 'Mở mã QR đang hoạt động' : 'Mở mã QR điểm danh ngay',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: DashboardColors.orangePrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyAttendanceCard extends StatelessWidget {
  const _WeeklyAttendanceCard({required this.report});
  final ReportData? report;

  @override
  Widget build(BuildContext context) {
    final weeks = (report?.weekly ?? const <ReportWeek>[]).take(5).toList();
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _SectionTitle(
                  icon: Icons.bar_chart_rounded,
                  title: 'CHUYÊN CẦN THEO TUẦN',
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Chi tiết ›',
                style: TextStyle(
                  color: DashboardColors.orangePrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 118,
            child: weeks.isEmpty
                ? const Center(
                    child: Text(
                      'Chưa có dữ liệu chuyên cần theo tuần',
                      style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (int i = 0; i < weeks.length; i++)
                        Expanded(
                          child: _WeekBar(
                            week: weeks[i],
                            active: i == weeks.length - 1,
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Dữ liệu tổng hợp trực tiếp từ các buổi học đã hoàn thành.',
            style: TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}

class _WeekBar extends StatelessWidget {
  const _WeekBar({required this.week, required this.active});
  final ReportWeek week;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final percent = (week.presentRate * 100).clamp(0, 100);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          percent.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: active
                ? DashboardColors.orangePrimary
                : const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 28,
          height: 22 + 58 * week.presentRate.clamp(0.0, 1.0),
          decoration: BoxDecoration(
            color: active
                ? DashboardColors.orangePrimary
                : const Color(0xFFE2E8F0),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          week.label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            color: active
                ? DashboardColors.orangePrimary
                : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

class _SubjectAnalysisCard extends StatelessWidget {
  const _SubjectAnalysisCard({required this.report});
  final ReportData? report;

  @override
  Widget build(BuildContext context) {
    final subjects = (report?.subjects ?? const <ReportSubject>[])
        .take(4)
        .toList();
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _SectionTitle(
                  icon: Icons.analytics_outlined,
                  title: 'PHÂN TÍCH THEO MÔN',
                ),
              ),
              const SizedBox(width: 6),
              _SoftChip(text: '${subjects.length} môn chính'),
            ],
          ),
          const SizedBox(height: 13),
          if (subjects.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Chưa có dữ liệu môn học',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ),
            )
          else
            for (int i = 0; i < subjects.length; i++) ...[
              _SubjectRow(subject: subjects[i]),
              if (i < subjects.length - 1) const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  const _SubjectRow({required this.subject});
  final ReportSubject subject;

  @override
  Widget build(BuildContext context) {
    final rate = subject.attendanceRate.clamp(0.0, 1.0);
    final color = rate >= .9
        ? const Color(0xFF10B981)
        : rate >= .8
        ? DashboardColors.orangePrimary
        : const Color(0xFFE11D48);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject.classCode,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subject.subjectName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(rate * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${subject.presentCount}/${subject.expectedCount} SV',
                  style: const TextStyle(
                    fontSize: 8.5,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: rate,
            minHeight: 5,
            color: color,
            backgroundColor: const Color(0xFFE2E8F0),
          ),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = const EdgeInsets.all(15)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0F0F172A),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 10, color: DashboardColors.orangePrimary),
      const SizedBox(width: 5),
      Flexible(
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF64748B),
            letterSpacing: .25,
          ),
        ),
      ),
    ],
  );
}

class _SoftChip extends StatelessWidget {
  const _SoftChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xFF64748B),
        fontSize: 8.5,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _AttendanceCount extends StatelessWidget {
  const _AttendanceCount({
    required this.label,
    required this.value,
    required this.color,
    required this.background,
  });
  final String label, value;
  final Color color, background;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFEF2F2),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFFECACA)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(fontSize: 11, color: Color(0xFF991B1B)),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Thử lại')),
      ],
    ),
  );
}
