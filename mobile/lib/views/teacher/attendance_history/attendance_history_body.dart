import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin_core/responsive/breakpoints.dart';
import '../../../viewmodels/dashboard_viewmodel.dart';
import 'attendance_history_colors.dart';
import 'components/attendance_history_header.dart';
import 'components/attendance_session_selector.dart';
import 'components/attendance_summary_card.dart';
import 'components/attendance_search_filter_bar.dart';
import 'components/attendance_student_card.dart';
import 'components/attendance_save_action_button.dart';

/// Màn hình Lịch sử điểm danh / Điểm danh sinh viên:
/// 1. Header: Back, Tiêu đề "Điểm danh sinh viên", "PRN231 • SE1801 • Ca 2 (Phòng AL-204)", nút Xuất & Tuỳ chọn
/// 2. Session Picker: Buổi 12 (Hôm nay), Buổi 11, Buổi 10, ...
/// 3. Thẻ tóm tắt Sĩ số (32 SV), Đang diễn ra, 87.5%, Thanh 2 màu, Có mặt 28, Vắng 4 (1 có phép)
/// 4. Thanh tìm kiếm & bộ lọc: Tất cả (32), Có mặt (28), Vắng (4), Chọn nhanh
/// 5. Danh sách thẻ sinh viên theo thiết kế mockup
/// 6. Nút "Lưu bảng điểm danh buổi 12" & Dòng đồng bộ FAP Portal
class AttendanceHistoryBody extends StatefulWidget {
  const AttendanceHistoryBody({super.key});

  @override
  State<AttendanceHistoryBody> createState() => _AttendanceHistoryBodyState();
}

class _AttendanceHistoryBodyState extends State<AttendanceHistoryBody> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedSession = 12;
  AttendanceFilterType _activeFilter = AttendanceFilterType.all;
  String _searchQuery = '';

  // Danh sách sinh viên mẫu theo thiết kế chuẩn mockup
  late List<StudentAttendanceModel> _students;

  @override
  void initState() {
    super.initState();
    _initSampleStudents();
  }

  void _initSampleStudents() {
    _students = [
      const StudentAttendanceModel(
        rollNumber: 'HE180101',
        fullName: 'Nguyễn Minh Anh',
        initials: 'NA',
        avatarBgColor: Color(0xFFE0F2FE),
        avatarTextColor: Color(0xFF0284C7),
        seatOrNote: 'Bàn 01',
        state: StudentAttendanceState.presentQr,
        checkinTime: '08:48',
      ),
      const StudentAttendanceModel(
        rollNumber: 'HE180105',
        fullName: 'Đỗ Hải Đăng',
        initials: 'HĐ',
        avatarBgColor: Color(0xFFF3E8FF),
        avatarTextColor: Color(0xFF9333EA),
        seatOrNote: 'Bàn 02',
        state: StudentAttendanceState.presentQr,
        checkinTime: '08:50',
      ),
      const StudentAttendanceModel(
        rollNumber: 'HE180112',
        fullName: 'Bùi Ngọc Linh',
        initials: 'NL',
        avatarBgColor: Color(0xFFFFE4E6),
        avatarTextColor: Color(0xFFE11D48),
        seatOrNote: 'Chưa quét',
        state: StudentAttendanceState.absentUnscanned,
        warningText: 'Cảnh báo 20%',
      ),
      const StudentAttendanceModel(
        rollNumber: 'HE180118',
        fullName: 'Trần Đức Huy',
        initials: 'TH',
        avatarBgColor: Color(0xFFF5F3FF),
        avatarTextColor: Color(0xFF7C3AED),
        seatOrNote: 'Xác nhận tay',
        state: StudentAttendanceState.presentManual,
        checkinTime: '08:55',
      ),
      const StudentAttendanceModel(
        rollNumber: 'HE180124',
        fullName: 'Lê Hoàng Nam',
        initials: 'LN',
        avatarBgColor: Color(0xFFFEF9C3),
        avatarTextColor: Color(0xFFD97706),
        seatOrNote: 'Đơn phép FAP',
        state: StudentAttendanceState.absentExcused,
      ),
      const StudentAttendanceModel(
        rollNumber: 'HE180130',
        fullName: 'Hoàng Văn Thái',
        initials: 'HT',
        avatarBgColor: Color(0xFFDCFCE7),
        avatarTextColor: Color(0xFF16A34A),
        seatOrNote: 'Bàn 04',
        state: StudentAttendanceState.presentQr,
        checkinTime: '08:46',
      ),
      const StudentAttendanceModel(
        rollNumber: 'HE180132',
        fullName: 'Vũ Quang Minh',
        initials: 'QM',
        avatarBgColor: Color(0xFFCCFBF1),
        avatarTextColor: Color(0xFF0D9488),
        seatOrNote: 'Bàn 05',
        state: StudentAttendanceState.presentQr,
        checkinTime: '08:52',
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardVm = context.watch<DashboardViewModel>();
    final horizontalPadding = context.isMobile ? 12.0 : context.pagePadding;

    // Lọc danh sách sinh viên theo tìm kiếm và tab filter
    final filteredList = _getFilteredStudents();

    // Thống kê số lượng
    final total = 32;
    final presentCount = _students.where((s) => s.isPresent).length + 24; // Mock 28
    final absentCount = total - presentCount; // 4
    final excusedCount = _students.where((s) => s.state == StudentAttendanceState.absentExcused).length;
    final rate = (presentCount / total) * 100;

    // Tiêu đề & Thông tin lớp
    final classSubtitle = _buildClassSubtitle(dashboardVm);

    return Scaffold(
      backgroundColor: AttendanceHistoryColors.pageBg,
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          context.isMobile ? 14.0 : 20.0,
          horizontalPadding,
          context.isMobile ? 32.0 : 40.0,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header (Nút quay lại, Tiêu đề, Thông tin lớp, Nút xuất & tuỳ chọn)
                AttendanceHistoryHeader(
                  title: 'Điểm danh sinh viên',
                  subtitle: classSubtitle,
                  onBack: () => dashboardVm.navigate('lop-hoc'),
                  onExport: () => _handleExport(context),
                  onOptions: () => _handleOptions(context),
                ),
                const SizedBox(height: 14),

                // 2. Thanh chọn buổi học (Session Selector)
                AttendanceSessionSelector(
                  selectedSession: _selectedSession,
                  onSelectSession: (session) {
                    setState(() => _selectedSession = session);
                  },
                ),
                const SizedBox(height: 14),

                // 3. Thẻ thống kê Sĩ số & Tiến độ điểm danh
                AttendanceSummaryCard(
                  totalStudents: total,
                  presentCount: presentCount,
                  absentCount: absentCount,
                  excusedAbsentCount: excusedCount,
                  attendanceRate: rate,
                  isOngoing: _selectedSession == 12,
                ),
                const SizedBox(height: 14),

                // 4. Thanh tìm kiếm và bộ lọc trạng thái
                AttendanceSearchFilterBar(
                  searchController: _searchController,
                  onSearchChanged: (val) {
                    setState(() => _searchQuery = val.trim().toLowerCase());
                  },
                  activeFilter: _activeFilter,
                  onFilterChanged: (filter) {
                    setState(() => _activeFilter = filter);
                  },
                  totalCount: total,
                  presentCount: presentCount,
                  absentCount: absentCount,
                  onQuickSelect: () => _handleQuickSelect(context),
                ),
                const SizedBox(height: 12),

                // 5. Danh sách sinh viên
                if (filteredList.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: const Text(
                      'Không tìm thấy sinh viên phù hợp.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AttendanceHistoryColors.textMuted,
                      ),
                    ),
                  )
                else
                  for (int i = 0; i < filteredList.length; i++)
                    AttendanceStudentCard(
                      student: filteredList[i],
                      onManualCheckin: () =>
                          _handleManualCheckin(filteredList[i]),
                      onChangeStatus: () =>
                          _handleChangeStatus(filteredList[i]),
                      onOptions: () => _handleStudentOptions(
                        context,
                        filteredList[i],
                      ),
                    ),

                const SizedBox(height: 20),

                // 6. Nút lưu bảng điểm danh & Dòng đồng bộ FAP Portal
                AttendanceSaveActionButton(
                  sessionNumber: _selectedSession,
                  onSave: () => _handleSaveAttendance(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildClassSubtitle(DashboardViewModel dashboardVm) {
    if (dashboardVm.classes.isNotEmpty) {
      final c = dashboardVm.classes.first;
      return '${c.subjectCode} • ${c.classCode} • Ca 2 (Phòng ${c.room.isNotEmpty ? c.room : "AL-204"})';
    }
    return 'PRN231 • SE1801 • Ca 2 (Phòng AL-204)';
  }

  List<StudentAttendanceModel> _getFilteredStudents() {
    return _students.where((s) {
      // Lọc theo filter tab
      if (_activeFilter == AttendanceFilterType.present && !s.isPresent) {
        return false;
      }
      if (_activeFilter == AttendanceFilterType.absent && !s.isAbsent) {
        return false;
      }
      // Lọc theo text search
      if (_searchQuery.isNotEmpty) {
        final matchName = s.fullName.toLowerCase().contains(_searchQuery);
        final matchRoll = s.rollNumber.toLowerCase().contains(_searchQuery);
        return matchName || matchRoll;
      }
      return true;
    }).toList();
  }

  void _handleManualCheckin(StudentAttendanceModel student) {
    setState(() {
      final index = _students.indexWhere((s) => s.rollNumber == student.rollNumber);
      if (index != -1) {
        _students[index] = StudentAttendanceModel(
          rollNumber: student.rollNumber,
          fullName: student.fullName,
          initials: student.initials,
          avatarBgColor: student.avatarBgColor,
          avatarTextColor: student.avatarTextColor,
          seatOrNote: 'Xác nhận tay',
          state: StudentAttendanceState.presentManual,
          checkinTime: '08:58',
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã điểm danh cho sinh viên ${student.fullName}'),
        duration: const Duration(seconds: 2),
        backgroundColor: AttendanceHistoryColors.statusGreen,
      ),
    );
  }

  void _handleChangeStatus(StudentAttendanceModel student) {
    setState(() {
      final index = _students.indexWhere((s) => s.rollNumber == student.rollNumber);
      if (index != -1) {
        final newState = student.state == StudentAttendanceState.absentExcused
            ? StudentAttendanceState.presentManual
            : StudentAttendanceState.absentExcused;

        _students[index] = StudentAttendanceModel(
          rollNumber: student.rollNumber,
          fullName: student.fullName,
          initials: student.initials,
          avatarBgColor: student.avatarBgColor,
          avatarTextColor: student.avatarTextColor,
          seatOrNote: newState == StudentAttendanceState.presentManual
              ? 'Xác nhận tay'
              : 'Đơn phép FAP',
          state: newState,
          checkinTime: newState == StudentAttendanceState.presentManual ? '08:59' : null,
        );
      }
    });
  }

  void _handleQuickSelect(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chế độ chọn nhanh: Có thể đánh dấu hàng loạt sinh viên.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleExport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đang xuất bảng điểm danh buổi $_selectedSession ra file Excel...',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.refresh_rounded, color: AttendanceHistoryColors.orangePrimary),
                title: const Text('Đồng bộ lại từ FAP Portal'),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: const Icon(Icons.print_outlined, color: AttendanceHistoryColors.textDark),
                title: const Text('In danh sách điểm danh'),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleStudentOptions(BuildContext context, StudentAttendanceModel student) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline_rounded),
                title: Text(student.fullName),
                subtitle: Text('MSSV: ${student.rollNumber}'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.edit_note_rounded, color: AttendanceHistoryColors.orangePrimary),
                title: const Text('Chỉnh sửa ghi chú'),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: const Icon(Icons.history_rounded, color: AttendanceHistoryColors.textDark),
                title: const Text('Xem lịch sử chuyên cần sinh viên'),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSaveAttendance(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Đã lưu và đồng bộ bảng điểm danh buổi $_selectedSession lên FAP Portal thành công!',
              ),
            ),
          ],
        ),
        backgroundColor: AttendanceHistoryColors.statusGreen,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
