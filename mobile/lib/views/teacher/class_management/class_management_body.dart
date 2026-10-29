import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin_core/responsive/breakpoints.dart';

import '../../../viewmodels/dashboard_viewmodel.dart';
import '../dashboard/components/weekly_timetable.dart';
import 'class_management_colors.dart';
import '../../../viewmodels/attendance_history_viewmodel.dart';
import '../live_session/dialogs/start_session_dialog.dart';
import 'components/class_management_header.dart';
import 'components/class_search_bar.dart';
import 'components/class_summary_banner.dart';
import 'components/class_item_card.dart';

/// Màn hình Quản lý lớp học của Giảng viên:
/// 1. Header (Tiêu đề "Quản lý lớp")
/// 2. Thanh tìm kiếm lớp / mã môn / sinh viên
/// 3. Thẻ Dark Navy thống kê: 06 Lớp phụ trách & 192 Sinh viên
/// 4. Nhóm "Tất cả lớp học" (HÔM NAY):
///    - Ca 1: PRN231 • SE1801 (Đang dạy - Viền cam nổi bật)
///    - Ca 2: PRN231 • SE1803 (Tiếp theo)
///    - Ca 3: SWT301 • SE1805
/// 5. Nhóm "SẮP TỚI":
///    - SWP391 • SE1802 (Thứ 6)
///    - SWP391 • SE1804 (Thứ 6)
///    - PRM392 • SE1806 (Thứ 2)
/// 6. Ghi chú chân trang: "Danh sách lớp được đồng bộ từ FAP"
class ClassManagementBody extends StatefulWidget {
  const ClassManagementBody({super.key});

  @override
  State<ClassManagementBody> createState() => _ClassManagementBodyState();
}

class _ClassManagementBodyState extends State<ClassManagementBody> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _sortAscending = true;

  Future<void> _openHistory(String classCode) async {
    final history = context.read<AttendanceHistoryViewModel>();
    final dashboard = context.read<DashboardViewModel>();
    await history.loadClasses();
    if (!mounted) return;
    await history.selectClass(classCode);
    if (mounted) dashboard.navigate('lich-su-diem-danh');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardVm = context.watch<DashboardViewModel>();
    final horizontalPadding = context.isMobile ? 18.0 : context.pagePadding;

    // Tổng số lớp và tổng số sinh viên
    final totalClasses = dashboardVm.classes.isNotEmpty
        ? dashboardVm.classes.length
        : 0;
    final totalStudents = dashboardVm.totalStudents > 0
        ? dashboardVm.totalStudents
        : 0;

    // Dữ liệu lớp học
    final classGroups = _buildClassGroups(dashboardVm);

    return Scaffold(
      backgroundColor: ClassManagementColors.pageBg,
      body: RefreshIndicator(
        color: ClassManagementColors.orangePrimary,
        onRefresh: () async {
          await dashboardVm.loadClasses();
        },
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
                          if (dashboardVm.isLoading)
                            const LinearProgressIndicator(),
                          if (dashboardVm.errorMessage != null)
                            Text(dashboardVm.errorMessage!),
                          if (!dashboardVm.isLoading &&
                              dashboardVm.classes.isEmpty)
                            const Text('Chưa có lớp được phân công.'),
                          // 1. Header
                          const ClassManagementHeader(),
                          const SizedBox(height: 16),

                          // 2. Ô tìm kiếm
                          ClassSearchBar(
                            controller: _searchController,
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val.trim().toLowerCase();
                              });
                            },
                            onClear: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // 3. Thẻ thống kê màu tối (Dark Navy Banner)
                          ClassSummaryBanner(
                            classCount: totalClasses,
                            studentCount: totalStudents,
                          ),
                          const SizedBox(height: 22),

                          // 4. Tiêu đề mục: "Tất cả lớp học" & "Theo giờ dạy ↑"
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Flexible(
                                child: Text(
                                  'Tất cả lớp học',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: ClassManagementColors.textDark,
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _sortAscending = !_sortAscending;
                                  });
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Theo giờ dạy ${_sortAscending ? "↑" : "↓"}',
                                        style: const TextStyle(
                                          color:
                                              ClassManagementColors.textMuted,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // 5. Khối HÔM NAY
                          if (classGroups.todayClasses.isNotEmpty) ...[
                            Text(
                              'HÔM NAY • ${_getTodaySubtitle()}',
                              style: const TextStyle(
                                color: ClassManagementColors.textMuted,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            for (final item in classGroups.todayClasses) ...[
                              ClassItemCard(
                                dayLabel: item.dayLabel,
                                startTime: item.startTime,
                                slotLabel: item.slotLabel,
                                subjectCode: item.subjectCode,
                                classCode: item.classCode,
                                subjectName: item.subjectName,
                                timeDetail: item.timeDetail,
                                attendanceRate: item.attendanceRate,
                                status: item.status,
                                activeScannedInfo: item.activeScannedInfo,
                                onOpenCheckin: () async {
                                  final cls = dashboardVm.classes
                                      .where(
                                        (c) => c.classCode == item.classCode,
                                      )
                                      .first;
                                  final ok = await startSessionWithOptions(
                                    context,
                                    classSection: cls,
                                    slotCode: cls.slotCode,
                                  );
                                  if (mounted && ok) {
                                    dashboardVm.navigate('diem-danh-qr');
                                  }
                                },
                                onTap: () => _openHistory(item.classCode),
                              ),
                            ],
                            const SizedBox(height: 12),
                          ],

                          // 6. Khối SẮP TỚI
                          if (classGroups.upcomingClasses.isNotEmpty) ...[
                            const Text(
                              'SẮP TỚI',
                              style: TextStyle(
                                color: ClassManagementColors.textMuted,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            for (final item in classGroups.upcomingClasses) ...[
                              ClassItemCard(
                                dayLabel: item.dayLabel,
                                startTime: item.startTime,
                                slotLabel: item.slotLabel,
                                subjectCode: item.subjectCode,
                                classCode: item.classCode,
                                subjectName: item.subjectName,
                                timeDetail: item.timeDetail,
                                attendanceRate: item.attendanceRate,
                                status: item.status,
                                onTap: () => _openHistory(item.classCode),
                              ),
                            ],
                            const SizedBox(height: 20),
                          ],

                          // 7. Ghi chú chân trang (Footer note)
                          Center(
                            child: Text(
                              'Danh sách lớp được tải từ Firebase.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: ClassManagementColors.textSubtle,
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),
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

  String _getTodaySubtitle() {
    final now = DateTime.now();
    const dayNames = [
      'THỨ 2',
      'THỨ 3',
      'THỨ 4',
      'THỨ 5',
      'THỨ 6',
      'THỨ 7',
      'CHỦ NHẬT',
    ];
    final dayStr = dayNames[now.weekday - 1];
    return '$dayStr, ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}';
  }

  _ClassGroups _buildClassGroups(DashboardViewModel vm) {
    List<_ClassCardData> allItems = [];

    if (vm.classes.isNotEmpty) {
      final now = DateTime.now();
      for (final c in vm.classes) {
        final info = SlotCodeParser.parse(c.slotCode);
        final isToday = info != null
            ? info.weekdays.contains(now.weekday)
            : c.isActive;

        String dayLabel = isToday ? 'Hôm nay' : 'Sắp tới';
        if (info != null && !isToday && info.weekdays.isNotEmpty) {
          const names = [
            'Thứ 2',
            'Thứ 3',
            'Thứ 4',
            'Thứ 5',
            'Thứ 6',
            'Thứ 7',
            'CN',
          ];
          dayLabel = names[info.weekdays.first - 1];
        }

        String startTime = c.startTime ?? '—';
        String slotLabel = c.slotCode.isNotEmpty
            ? 'Slot ${c.slotCode}'
            : 'Chưa có ca';
        slotLabel = slotLabel.replaceAll('Slot Ca ', 'Slot ');

        ClassCardStatus status = ClassCardStatus.normal;
        if (c.isActive) {
          status = ClassCardStatus.active;
        }

        final rateStr = c.averageAttendance > 0
            ? '${(c.averageAttendance).toStringAsFixed(1)}%'
            : '—';

        allItems.add(
          _ClassCardData(
            dayLabel: dayLabel,
            startTime: startTime,
            slotLabel: slotLabel,
            subjectCode: c.subjectCode,
            classCode: c.classCode,
            subjectName: c.subjectName,
            timeDetail: '${c.timeLabel} • ${c.room} • ${c.studentCount} SV',
            attendanceRate: rateStr,
            status: status,
            activeScannedInfo:
                '${vm.activeSessionScanned}/${c.studentCount} có mặt',
            isToday: isToday,
          ),
        );
      }
    }

    // Lọc theo tìm kiếm
    if (_searchQuery.isNotEmpty) {
      allItems = allItems.where((item) {
        return item.classCode.toLowerCase().contains(_searchQuery) ||
            item.subjectCode.toLowerCase().contains(_searchQuery) ||
            item.subjectName.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    allItems.sort(
      (a, b) => _sortAscending
          ? a.startTime.compareTo(b.startTime)
          : b.startTime.compareTo(a.startTime),
    );
    final today = allItems.where((c) => c.isToday).toList();
    final upcoming = allItems.where((c) => !c.isToday).toList();

    return _ClassGroups(todayClasses: today, upcomingClasses: upcoming);
  }
}

class _ClassCardData {
  final String dayLabel;
  final String startTime;
  final String slotLabel;
  final String subjectCode;
  final String classCode;
  final String subjectName;
  final String timeDetail;
  final String attendanceRate;
  final ClassCardStatus status;
  final String? activeScannedInfo;
  final bool isToday;

  const _ClassCardData({
    required this.dayLabel,
    required this.startTime,
    required this.slotLabel,
    required this.subjectCode,
    required this.classCode,
    required this.subjectName,
    required this.timeDetail,
    required this.attendanceRate,
    required this.status,
    this.activeScannedInfo,
    required this.isToday,
  });
}

class _ClassGroups {
  final List<_ClassCardData> todayClasses;
  final List<_ClassCardData> upcomingClasses;

  const _ClassGroups({
    required this.todayClasses,
    required this.upcomingClasses,
  });
}
