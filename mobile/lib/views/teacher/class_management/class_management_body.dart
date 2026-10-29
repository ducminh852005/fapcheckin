import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin_core/responsive/breakpoints.dart';
import '../../../viewmodels/dashboard_viewmodel.dart';
import '../dashboard/components/weekly_timetable.dart';
import 'class_management_colors.dart';
import 'components/class_management_header.dart';
import 'components/class_search_bar.dart';
import 'components/class_summary_banner.dart';
import 'components/class_item_card.dart';

/// Màn hình Quản lý lớp học của Giảng viên:
/// 1. Header (Học kỳ Thu 2026, Tiêu đề "Quản lý lớp", Nút "Lịch sử điểm danh")
/// 2. Thanh tìm kiếm lớp / mã môn / sinh viên
/// 3. Thẻ Dark Navy thống kê: 06 Lớp phụ trách & 192 Sinh viên
/// 4. Nhóm "Tất cả lớp học" (HÔM NAY):
///    - Ca 1: PRN231 • SE1801 (Đang dạy - Có nút Mở điểm danh)
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
        : 6;
    final totalStudents = dashboardVm.totalStudents > 0
        ? dashboardVm.totalStudents
        : 192;

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
                                      color: ClassManagementColors.textMuted,
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
                            onOpenCheckin: () {
                              dashboardVm.navigate('diem-danh-qr');
                            },
                            onTap: () {
                              dashboardVm.navigate('lich-su-diem-danh');
                            },
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
                            onTap: () {
                              dashboardVm.navigate('lich-su-diem-danh');
                            },
                          ),
                        ],
                        const SizedBox(height: 20),
                      ],

                      // 7. Ghi chú chân trang (Footer note)
                      Center(
                        child: Text(
                          'Danh sách lớp được đồng bộ từ FAP.\nCập nhật gần nhất lúc 09:35, 08/10/2026.',
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
    // Dữ liệu mẫu chuẩn khớp 100% với mockup
    final List<_ClassCardData> defaultItems = [
      // Hôm nay
      const _ClassCardData(
        dayLabel: 'Hôm nay',
        startTime: '07:30',
        slotLabel: 'Slot 1',
        subjectCode: 'PRN231',
        classCode: 'SE1801',
        subjectName: 'Lập trình ứng dụng .NET',
        timeDetail: '07:30–09:50 • AL-204 • 32 SV',
        attendanceRate: '92,5%',
        status: ClassCardStatus.active,
        activeScannedInfo: '28/32 có mặt',
        isToday: true,
      ),
      const _ClassCardData(
        dayLabel: 'Hôm nay',
        startTime: '12:50',
        slotLabel: 'Slot 3',
        subjectCode: 'PRN231',
        classCode: 'SE1803',
        subjectName: 'Lập trình ứng dụng .NET',
        timeDetail: '12:50–15:10 • AL-204 • 32 SV',
        attendanceRate: '93,8%',
        status: ClassCardStatus.next,
        isToday: true,
      ),
      const _ClassCardData(
        dayLabel: 'Hôm nay',
        startTime: '15:20',
        slotLabel: 'Slot 4',
        subjectCode: 'SWT301',
        classCode: 'SE1805',
        subjectName: 'Kiểm thử phần mềm',
        timeDetail: '15:20–17:40 • AL-305 • 32 SV',
        attendanceRate: '93,8%',
        status: ClassCardStatus.normal,
        isToday: true,
      ),
      // Sắp tới
      const _ClassCardData(
        dayLabel: 'Thứ 6',
        startTime: '07:30',
        slotLabel: 'Slot 1',
        subjectCode: 'SWP391',
        classCode: 'SE1802',
        subjectName: 'Dự án phát triển phần mềm',
        timeDetail: '07:30–09:50 • BE-301 • 32 SV',
        attendanceRate: '96,3%',
        status: ClassCardStatus.normal,
        isToday: false,
      ),
      const _ClassCardData(
        dayLabel: 'Thứ 6',
        startTime: '12:50',
        slotLabel: 'Slot 3',
        subjectCode: 'SWP391',
        classCode: 'SE1804',
        subjectName: 'Dự án phát triển phần mềm',
        timeDetail: '12:50–15:10 • BE-302 • 32 SV',
        attendanceRate: '93,8%',
        status: ClassCardStatus.normal,
        isToday: false,
      ),
      const _ClassCardData(
        dayLabel: 'Thứ 2',
        startTime: '10:00',
        slotLabel: 'Slot 2',
        subjectCode: 'PRM392',
        classCode: 'SE1806',
        subjectName: 'Lập trình di động',
        timeDetail: '10:00–12:20 • AL-306 • 32 SV',
        attendanceRate: '93,8%',
        status: ClassCardStatus.normal,
        isToday: false,
      ),
    ];

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
          const names = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'CN'];
          dayLabel = names[info.weekdays.first - 1];
        }

        String startTime = c.startTime ?? '07:30';
        String slotLabel = c.slotCode.isNotEmpty ? 'Slot ${c.slotCode}' : 'Slot 1';
        slotLabel = slotLabel.replaceAll('Slot Ca ', 'Slot ');

        ClassCardStatus status = ClassCardStatus.normal;
        if (c.isActive) {
          status = ClassCardStatus.active;
        }

        final rateStr = c.averageAttendance > 0
            ? '${(c.averageAttendance * 100).toStringAsFixed(1)}%'
            : '93,8%';

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
            activeScannedInfo: '${vm.activeSessionScanned}/${c.studentCount} có mặt',
            isToday: isToday,
          ),
        );
      }
    } else {
      allItems.addAll(defaultItems);
    }

    // Lọc theo tìm kiếm
    if (_searchQuery.isNotEmpty) {
      allItems = allItems.where((item) {
        return item.classCode.toLowerCase().contains(_searchQuery) ||
            item.subjectCode.toLowerCase().contains(_searchQuery) ||
            item.subjectName.toLowerCase().contains(_searchQuery);
      }).toList();
    }

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
