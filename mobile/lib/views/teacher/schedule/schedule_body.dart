import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin_core/constants/app_colors.dart';
import 'package:fapcheckin_core/constants/app_palette.dart';
import 'package:fapcheckin_core/responsive/breakpoints.dart';

import '../../../viewmodels/dashboard_viewmodel.dart';
import '../../../viewmodels/attendance_history_viewmodel.dart';
import '../../../viewmodels/live_session_viewmodel.dart';
import '../../../core/services/auto_session_manager.dart';
import 'components/import_timetable_bottom_sheet.dart';
import '../dashboard/components/weekly_timetable.dart';
import 'schedule_colors.dart';

import 'package:fapcheckin_core/repositories/schedule_repository.dart';
import 'package:fapcheckin_core/result/api_result.dart';

import '../live_session/dialogs/start_session_dialog.dart';
import 'components/create_schedule_bottom_sheet.dart';
import 'components/schedule_header.dart';
import 'components/schedule_week_picker.dart';
import 'components/schedule_day_summary.dart';
import 'components/schedule_timeline_item.dart';

/// Màn hình Lịch dạy của tôi (Teaching Schedule):
/// 1. Header chào hỏi + Tiêu đề lớn + Sub-nav 5 phím tắt
/// 2. Thẻ chọn tuần và ngày trong tuần (Tháng 10, 2026; T2..CN)
/// 3. Dòng tóm tắt ngày đang chọn và tổng số ca dạy
/// 4. Trục Timeline nối các ca dạy trong ngày (Đã xong, Đang dạy, Chưa bắt đầu)
class ScheduleBody extends StatefulWidget {
  const ScheduleBody({super.key});

  @override
  State<ScheduleBody> createState() => _ScheduleBodyState();
}

class _ScheduleBodyState extends State<ScheduleBody> {
  List<Map<String, dynamic>> _plans = [];
  String? _error;
  Future<void> _loadPlans() async {
    final result = await context.read<ScheduleRepository>().list();
    if (!mounted) return;
    setState(() {
      if (result is ApiSuccess<List<Map<String, dynamic>>>) {
        _plans = result.data;
        _error = null;
      }
      if (result is ApiFailure<List<Map<String, dynamic>>>) {
        _error = result.error.message;
      }
    });
  }

  Future<void> _open(_TimelineSessionData item) async {
    if (!DateUtils.isSameDay(_selectedDate, DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chỉ mở điểm danh cho ngày hôm nay.')),
      );
      return;
    }
    final vm = context.read<DashboardViewModel>();
    final cls = vm.classes
        .where((c) => c.classCode == item.classCode)
        .firstOrNull;
    if (cls == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không tìm thấy thông tin lớp ${item.classCode}.'),
        ),
      );
      return;
    }
    final ok = await startSessionWithOptions(
      context,
      classSection: cls,
      slotCode: item.slotCode,
    );
    if (mounted && ok) vm.navigate('diem-danh-qr');
  }

  Future<void> _openAttendancePage(String classCode) async {
    final history = context.read<AttendanceHistoryViewModel>();
    final dashboard = context.read<DashboardViewModel>();
    await history.loadClasses();
    if (!mounted) return;
    await history.selectClass(classCode);
    if (mounted) dashboard.navigate('lich-su-diem-danh');
  }

  late DateTime _selectedDate;
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadPlans();
    });
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _weekStart = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );
  }

  void _prevWeek() {
    setState(() {
      _weekStart = _weekStart.subtract(const Duration(days: 7));
      _selectedDate = _weekStart.add(Duration(days: _selectedDate.weekday - 1));
    });
  }

  void _nextWeek() {
    setState(() {
      _weekStart = _weekStart.add(const Duration(days: 7));
      _selectedDate = _weekStart.add(Duration(days: _selectedDate.weekday - 1));
    });
  }

  void _onDaySelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  Future<void> _scanTimetable(BuildContext context) async {
    final result = await showImportTimetableBottomSheet(context);
    if (!context.mounted || result == null) return;

    await context.read<DashboardViewModel>().loadClasses();
    if (!context.mounted) return;

    context.read<LiveSessionViewModel>().triggerToast(
      type: ToastType.custom,
      title: 'Đã cập nhật thời khóa biểu',
      message: 'Đã thêm giáo viên vào ${result.assignedCount} lớp.',
      icon: Icons.check_circle_outline,
      accentColor: AppColors.statusPresent,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardVm = context.watch<DashboardViewModel>();
    final horizontalPadding = context.isMobile ? 18.0 : context.pagePadding;

    // Lấy các ca học cho ngày đang chọn
    final sessions = _getSessionsForDate(_selectedDate, dashboardVm);

    // Xác định các ngày trong tuần có ca dạy (để hiển thị dấu chấm cam)
    final daysWithClasses = _getDaysWithClasses(dashboardVm);

    return Scaffold(
      backgroundColor: ScheduleColors.pageBg,
      body: RefreshIndicator(
        color: ScheduleColors.orangePrimary,
        onRefresh: () async {
          await dashboardVm.loadClasses();
          if (mounted) await _loadPlans();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Stack(
            children: [
              // Hiệu ứng ánh sáng ấm áp góc trên đồng bộ với Trang chủ, Báo cáo & Quản lý lớp
              Container(
                height: 240,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: AppPalette.headerGradient,
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 14,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Header (Lời chào, Tiêu đề, Chuông, Sub-nav 5 mục)
                          ScheduleHeader(
                            onScanTimetable: () => _scanTimetable(context),
                          ),
                          const SizedBox(height: 18),

                          if (dashboardVm.isLoading)
                            const LinearProgressIndicator(),
                          if (dashboardVm.errorMessage != null)
                            Text(dashboardVm.errorMessage!),
                          if (_error != null) Text(_error!),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              icon: const Icon(
                                Icons.add_circle_outline_rounded,
                                size: 18,
                                color: ScheduleColors.orangePrimary,
                              ),
                              label: const Text(
                                'Thêm lịch học bù / workshop',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: ScheduleColors.orangePrimary,
                                  fontSize: 13,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFFFED7AA),
                                  width: 1.2,
                                ),
                                backgroundColor: const Color(0xFFFFF7ED),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                              ),
                              onPressed: () async {
                                final created =
                                    await showCreateScheduleBottomSheet(
                                      context,
                                    );
                                if (created != null && mounted) {
                                  await _loadPlans();
                                  if (!context.mounted) return;
                                  context.read<LiveSessionViewModel>().triggerToast(
                                    type: ToastType.custom,
                                    title: 'Đã tạo lịch học bổ sung',
                                    message:
                                        'Lớp ${created['classCode']} ngày ${created['scheduleDate']} đã được tạo thành công.',
                                    icon: Icons.check_circle_outline,
                                    accentColor: AppColors.statusPresent,
                                    duration: const Duration(seconds: 4),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          // 2. Thẻ chọn tuần và ngày
                          ScheduleWeekPicker(
                            selectedDate: _selectedDate,
                            weekStart: _weekStart,
                            onDaySelected: _onDaySelected,
                            onPrevWeek: _prevWeek,
                            onNextWeek: _nextWeek,
                            daysWithClasses: daysWithClasses,
                          ),
                          const SizedBox(height: 18),

                          // 3. Dòng tóm tắt ngày
                          ScheduleDaySummary(
                            date: _selectedDate,
                            sessionCount: sessions.length,
                            semester: dashboardVm.semester.isNotEmpty
                                ? 'Học kỳ ${dashboardVm.semester}'
                                : '',
                          ),
                          const SizedBox(height: 16),

                          // 4. Trục Timeline các ca dạy hoặc Empty State
                          if (sessions.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 28,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF7ED),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.event_busy_rounded,
                                      color: ScheduleColors.orangePrimary,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Không có lịch dạy trong ngày đã chọn.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Hãy chọn một ngày khác trên thanh lịch tuần hoặc quét ảnh thời khóa biểu FAP.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Column(
                              children: [
                                for (int i = 0; i < sessions.length; i++) ...[
                                  ScheduleTimelineItem(
                                    slot: sessions[i].slot,
                                    timeRange: sessions[i].timeRange,
                                    subjectCode: sessions[i].subjectCode,
                                    classCode: sessions[i].classCode,
                                    subjectName: sessions[i].subjectName,
                                    room: sessions[i].room,
                                    subtext: sessions[i].subtext,
                                    status: sessions[i].status,
                                    isFirst: i == 0,
                                    isLast: i == sessions.length - 1,
                                    onOpenAttendance: () => _open(sessions[i]),
                                    onTap: () => _openAttendancePage(
                                      sessions[i].classCode,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          SizedBox(height: context.isMobile ? 108 : 36),
                        ],
                      ),
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

  Set<int> _getDaysWithClasses(DashboardViewModel vm) {
    final days = <int>{};
    for (final c in vm.classes) {
      final info = SlotCodeParser.parse(c.slotCode);
      if (info != null) {
        days.addAll(info.weekdays);
      }
    }
    for (final p in _plans) {
      final date = DateTime.tryParse(p['scheduleDate']?.toString() ?? '');
      if (date != null &&
          p['status'] != 'cancelled' &&
          !date.isBefore(_weekStart) &&
          date.isBefore(_weekStart.add(const Duration(days: 7)))) {
        days.add(date.weekday);
      }
    }
    return days;
  }

  List<_TimelineSessionData> _getSessionsForDate(
    DateTime date,
    DashboardViewModel vm,
  ) {
    final List<_TimelineSessionData> result = [];

    for (final c in vm.classes) {
      final info = SlotCodeParser.parse(c.slotCode);
      final isToday = info != null
          ? info.weekdays.contains(date.weekday)
          : false;

      if (isToday) {
        final slotNum = info.slot;
        final (startDt, endDt) = TimeSlotHelper.resolveSlotRange(date, c);

        final now = DateTime.now();
        final targetDay = DateTime(date.year, date.month, date.day);
        final today = DateTime(now.year, now.month, now.day);

        ScheduleSessionStatus status = ScheduleSessionStatus.upcoming;
        String subtext = '${c.studentCount} sinh viên • Điểm danh QR';

        if (targetDay.isBefore(today)) {
          status = ScheduleSessionStatus.completed;
          subtext = 'Đã hoàn thành • ${c.studentCount} sinh viên';
        } else if (targetDay.isAfter(today)) {
          status = ScheduleSessionStatus.upcoming;
          subtext = '${c.studentCount} sinh viên • Điểm danh QR';
        } else {
          // Ngày hôm nay: so sánh theo thời gian thực (real-time)
          if (startDt != null && endDt != null) {
            if (now.isAfter(endDt) || now.isAtSameMomentAs(endDt)) {
              status = ScheduleSessionStatus.completed;
              subtext = 'Ca học đã kết thúc (${c.endTime ?? 'hết giờ'})';
            } else if (c.isActive ||
                now.isAfter(startDt) ||
                now.isAtSameMomentAs(startDt)) {
              status = ScheduleSessionStatus.active;
              subtext = c.isActive
                  ? '${vm.activeSessionScanned}/${c.studentCount} sinh viên đã điểm danh'
                  : 'Đang trong giờ dạy • Vào điểm danh ngay';
            } else {
              status = ScheduleSessionStatus.upcoming;
              subtext =
                  '${c.studentCount} sinh viên • Bắt đầu lúc ${c.startTime ?? ''}';
            }
          }
        }

        result.add(
          _TimelineSessionData(
            slot: slotNum,
            slotCode: c.slotCode,
            timeRange: (c.startTime != null && c.endTime != null)
                ? '${c.startTime}–${c.endTime}'
                : c.timeLabel,
            subjectCode: c.subjectCode,
            classCode: c.classCode,
            subjectName: c.subjectName,
            room: c.room,
            subtext: subtext,
            status: status,
          ),
        );
      }
    }

    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    for (final p in _plans.where(
      (p) => p['scheduleDate'] == dateKey && p['status'] != 'cancelled',
    )) {
      final cls = vm.classes
          .where((c) => c.classCode == p['classCode'])
          .firstOrNull;
      if (cls == null) continue;
      final code = p['slotCode']?.toString() ?? '';

      final now = DateTime.now();
      final targetDay = DateTime(date.year, date.month, date.day);
      final today = DateTime(now.year, now.month, now.day);
      ScheduleSessionStatus planStatus = ScheduleSessionStatus.upcoming;
      if (targetDay.isBefore(today)) {
        planStatus = ScheduleSessionStatus.completed;
      } else if (targetDay.isAtSameMomentAs(today)) {
        final (pStart, pEnd) = TimeSlotHelper.resolveSlotRange(date, cls);
        if (pEnd != null && (now.isAfter(pEnd) || now.isAtSameMomentAs(pEnd))) {
          planStatus = ScheduleSessionStatus.completed;
        } else if (pStart != null &&
            (now.isAfter(pStart) || now.isAtSameMomentAs(pStart))) {
          planStatus = ScheduleSessionStatus.active;
        }
      }

      result.add(
        _TimelineSessionData(
          slot: SlotCodeParser.parse(code)?.slot ?? 0,
          slotCode: code,
          timeRange: code,
          subjectCode: cls.subjectCode,
          classCode: cls.classCode,
          subjectName: cls.subjectName,
          room: p['room']?.toString() ?? cls.room,
          subtext: 'Lịch bổ sung · ${p['note'] ?? ''}',
          status: planStatus,
        ),
      );
    }
    // Sắp xếp các ca theo thứ tự số ca tăng dần (1 -> 6)
    result.sort((a, b) => a.slot.compareTo(b.slot));
    return result;
  }
}

class _TimelineSessionData {
  final int slot;
  final String slotCode;
  final String timeRange;
  final String subjectCode;
  final String classCode;
  final String subjectName;
  final String room;
  final String subtext;
  final ScheduleSessionStatus status;

  const _TimelineSessionData({
    required this.slot,
    required this.slotCode,
    required this.timeRange,
    required this.subjectCode,
    required this.classCode,
    required this.subjectName,
    required this.room,
    required this.subtext,
    required this.status,
  });
}
