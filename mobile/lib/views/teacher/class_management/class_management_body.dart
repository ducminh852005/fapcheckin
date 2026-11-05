import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin_core/responsive/breakpoints.dart';

import '../../../viewmodels/dashboard_viewmodel.dart';
import '../dashboard/components/weekly_timetable.dart';
import 'class_management_colors.dart';
import '../../../viewmodels/attendance_history_viewmodel.dart';
import '../../../core/services/auto_session_manager.dart';
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
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Hiệu ứng ánh sáng ấm áp góc trên đồng bộ với Trang chủ & Lịch dạy
          if (!isDark)
            Container(
              height: 320,
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
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PHẦN CỐ ĐỊNH (HEADER + TÌM KIẾM + THẺ THỐNG KÊ + TIÊU ĐỀ MỤC)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        14,
                        horizontalPadding,
                        10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (dashboardVm.isLoading)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: LinearProgressIndicator(),
                            ),
                          if (dashboardVm.errorMessage != null)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFECACA),
                                ),
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
                                      dashboardVm.errorMessage!,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: Color(0xFFB91C1C),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: dashboardVm.loadClasses,
                                    icon: const Icon(
                                      Icons.refresh_rounded,
                                      size: 16,
                                    ),
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
                          // 1. Header
                          const ClassManagementHeader(),
                          const SizedBox(height: 16),

                          // 2. Thẻ thống kê màu tối (Dark Navy Banner) - tự ẩn khi mở bàn phím ảo
                          if (!isKeyboardOpen) ...[
                            ClassSummaryBanner(
                              classCount: totalClasses,
                              studentCount: totalStudents,
                            ),
                            const SizedBox(height: 14),
                          ],

                          // 3. Ô tìm kiếm
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

                          // 4. Tiêu đề mục: "Tất cả lớp học" & "Theo giờ dạy ↑" (Cố định)
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
                              Tooltip(
                                message: 'Đổi thứ tự sắp xếp theo giờ dạy',
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _sortAscending = !_sortAscending;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
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
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // PHẦN CUỘN (CHỈ DANH SÁCH LỚP HỌC PHÍA DƯỚI)
                    Expanded(
                      child: RefreshIndicator(
                        color: ClassManagementColors.orangePrimary,
                        onRefresh: () async {
                          await dashboardVm.loadClasses();
                        },
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            4,
                            horizontalPadding,
                            context.isMobile ? 108 : 36,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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

                              // 6.5. Empty State khi chưa có lớp hoặc không khớp tìm kiếm
                              if (classGroups.todayClasses.isEmpty &&
                                  classGroups.upcomingClasses.isEmpty) ...[
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(top: 6, bottom: 20),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 28,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: ClassManagementColors.cardBorder,
                                    ),
                                    boxShadow: ClassManagementColors.cardShadow,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: ClassManagementColors.orangeLight,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Icon(
                                          _searchQuery.isNotEmpty
                                              ? Icons.search_off_rounded
                                              : Icons.class_outlined,
                                          color:
                                              ClassManagementColors.orangePrimary,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        _searchQuery.isNotEmpty
                                            ? 'Không tìm thấy lớp học phù hợp'
                                            : 'Chưa có lớp được phân công.',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: ClassManagementColors.textDark,
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _searchQuery.isNotEmpty
                                            ? 'Thử tìm bằng mã môn, mã lớp khác hoặc xóa từ khóa hiện tại.'
                                            : 'Bạn có thể quét ảnh thời khóa biểu FAP trong mục Lịch dạy để đồng bộ lớp.',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: ClassManagementColors.textMuted,
                                          fontSize: 12,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      SizedBox(
                                        height: 38,
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            if (_searchQuery.isNotEmpty) {
                                              _searchController.clear();
                                              setState(() {
                                                _searchQuery = '';
                                              });
                                            } else {
                                              dashboardVm.navigate('lich-hoc');
                                            }
                                          },
                                          icon: Icon(
                                            _searchQuery.isNotEmpty
                                              ? Icons.clear_rounded
                                              : Icons.calendar_today_rounded,
                                          size: 15,
                                          color:
                                              ClassManagementColors.orangePrimary,
                                        ),
                                        label: Text(
                                          _searchQuery.isNotEmpty
                                              ? 'Xóa bộ lọc tìm kiếm'
                                              : 'Tới Lịch dạy & Quét TKB',
                                          style: const TextStyle(
                                            color: ClassManagementColors
                                                .orangePrimary,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: Color(0xFFFED7AA),
                                            width: 1.2,
                                          ),
                                          backgroundColor:
                                              const Color(0xFFFFF7ED),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                          ],
                        ),
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
        } else if (isToday) {
          final (startDt, endDt) = TimeSlotHelper.resolveSlotRange(now, c);
          if (startDt != null && endDt != null) {
            if ((now.isAfter(startDt) || now.isAtSameMomentAs(startDt)) &&
                now.isBefore(endDt)) {
              status = ClassCardStatus.active;
            }
          }
        }

        final rateStr = '${c.averageAttendance.toStringAsFixed(1)}%';

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

    allItems.sort((a, b) {
      // Ca đang diễn ra luôn phải nằm đầu danh sách để giảng viên có thể
      // truy cập ngay, bất kể đang chọn sắp xếp giờ tăng hay giảm.
      final activeCompare = _statusPriority(
        a.status,
      ).compareTo(_statusPriority(b.status));
      if (activeCompare != 0) return activeCompare;

      return _sortAscending
          ? a.startTime.compareTo(b.startTime)
          : b.startTime.compareTo(a.startTime);
    });
    final today = allItems.where((c) => c.isToday).toList();
    final upcoming = allItems.where((c) => !c.isToday).toList();

    return _ClassGroups(todayClasses: today, upcomingClasses: upcoming);
  }

  int _statusPriority(ClassCardStatus status) {
    return status == ClassCardStatus.active ? 0 : 1;
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
