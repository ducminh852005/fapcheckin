import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/api_service.dart';
import '../../../../data/models/attendance_history_model.dart';
import '../../../../data/models/class_section_model.dart';
import '../../../../data/models/session_model.dart';
import '../../../../data/repositories/teacher_repository.dart';
import '../../../../viewmodels/dashboard_viewmodel.dart';
import '../../../../viewmodels/live_session_viewmodel.dart';

class ClassDetailDialog extends StatefulWidget {
  final ClassSectionModel classData;

  const ClassDetailDialog({super.key, required this.classData});

  static Future<void> show(BuildContext context, ClassSectionModel classData) {
    return showDialog(
      context: context,
      builder: (context) => ClassDetailDialog(classData: classData),
    );
  }

  @override
  State<ClassDetailDialog> createState() => _ClassDetailDialogState();
}

class _ClassDetailDialogState extends State<ClassDetailDialog> {
  int _activeTab = 0; // 0: Lịch trình, 1: Danh sách SV
  String _sessionFilter = 'all'; // all, completed, upcoming
  final TextEditingController _studentSearch = TextEditingController();

  bool _isLoading = true;
  String? _fetchError;
  List<SessionModel> _realSessions = [];
  List<AttendanceStudentRecord> _realStudents = [];

  @override
  void initState() {
    super.initState();
    _fetchRealData();
  }

  Future<void> _fetchRealData() async {
    setState(() {
      _isLoading = true;
      _fetchError = null;
    });

    try {
      final apiService = context.read<ApiService>();
      final repo = TeacherRepository(apiService);
      final classCode = widget.classData.classCode;

      final results = await Future.wait([
        repo.getSessions(classCode: classCode),
        repo.getAttendanceHistory(classCode: classCode),
      ]);

      final sessionsRes = results[0] as ApiResult<List<SessionModel>>;
      final historyRes = results[1] as ApiResult<AttendanceHistoryResult>;

      List<SessionModel> fetchedSessions = [];
      List<AttendanceStudentRecord> fetchedStudents = [];

      if (sessionsRes is ApiSuccess<List<SessionModel>>) {
        fetchedSessions = sessionsRes.data;
      }

      if (historyRes is ApiSuccess<AttendanceHistoryResult>) {
        fetchedStudents = historyRes.data.students;
      }

      if (mounted) {
        setState(() {
          // Sort theo ngày tăng dần (cũ → mới)
          _realSessions = fetchedSessions
            ..sort((a, b) {
              final da = DateTime.tryParse(a.sessionDate) ?? DateTime(0);
              final db = DateTime.tryParse(b.sessionDate) ?? DateTime(0);
              if (da != db) return da.compareTo(db);
              return a.slotCode.compareTo(b.slotCode);
            });
          _realStudents = fetchedStudents;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fetchError = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _studentSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cls = widget.classData;

    return Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040, maxHeight: 860),
        child: Column(
          children: [
            // ── Top Header Banner (White & Orange Theme) ─────────────────────
            _buildHeaderBanner(cls),

            // ── Scrollable Body ─────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Top 3 Stat Cards Row
                    _buildSummaryGrid(cls),
                    const SizedBox(height: 24),

                    // 2. Tab Bar Selection
                    _buildTabBar(cls),
                    const SizedBox(height: 20),

                    // 3. Tab Content
                    if (_activeTab == 0)
                      _buildScheduleTab(cls)
                    else
                      _buildStudentsTab(cls),
                  ],
                ),
              ),
            ),

            // ── Footer Bar ──────────────────────────────────────────────────
            const Divider(height: 1, color: AppColors.surfaceContainerHigh),
            _buildFooter(cls),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Header Banner
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHeaderBanner(ClassSectionModel cls) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        cls.classCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: cls.isActive
                            ? AppColors.statusPresent
                            : Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            cls.isActive ? 'Đang mở phiên' : 'Đang học',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Kỹ thuật phần mềm • ${cls.classCode}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${cls.subjectCode} — ${cls.subjectName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Phòng Kỹ thuật Phần mềm • Học kỳ Fall 2026 • Khóa K19',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white, size: 22),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3 Summary Stat Cards
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSummaryGrid(ClassSectionModel cls) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 750;
        final cardWidth = isSmall ? constraints.maxWidth : (constraints.maxWidth - 32) / 3;
        final actualStudentCount = _realStudents.isNotEmpty ? _realStudents.length : cls.studentCount;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            // Card 1: Lịch học định kỳ
            _buildStatCardContainer(
              width: cardWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatCardHeader('LỊCH HỌC ĐỊNH KỲ', Icons.calendar_today_outlined),
                  const SizedBox(height: 8),
                  Text(
                    cls.timeLabel.isNotEmpty ? cls.timeLabel : 'Thứ 2 • Thứ 4',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Ca 1 (07:30 - 09:50)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryContainer,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: AppColors.textTertiary),
                      SizedBox(width: 4),
                      Text(
                        'Mở điểm danh: 15 phút đầu giờ',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Card 2: Phòng học & hạ tầng
            _buildStatCardContainer(
              width: cardWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatCardHeader('PHÒNG HỌC & HẠ TẦNG', Icons.domain_outlined),
                  const SizedBox(height: 8),
                  Text(
                    cls.room.isEmpty ? 'Phòng P.111' : 'Phòng ${cls.room}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Tòa Alpha • Lab Tier A',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(Icons.wifi_lock, size: 14, color: AppColors.statusPresent),
                      SizedBox(width: 4),
                      Text(
                        'Khóa IP Subnet & Wi-Fi FPT',
                        style: TextStyle(fontSize: 11, color: AppColors.statusPresent, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Card 3: Sĩ số sinh viên
            _buildStatCardContainer(
              width: cardWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'SĨ SỐ SINH VIÊN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textTertiary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _activeTab = 1),
                        child: const Text(
                          'Xem danh sách',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$actualStudentCount',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Sinh viên',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.statusPresentBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${actualStudentCount > 0 ? (actualStudentCount * 0.94).round() : 0} Chính quy',
                          style: const TextStyle(fontSize: 10, color: AppColors.statusPresent, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.statusLateBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${actualStudentCount > 0 ? actualStudentCount - (actualStudentCount * 0.94).round() : 0} Học ghép',
                          style: const TextStyle(fontSize: 10, color: AppColors.statusLate, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCardContainer({required double width, required Widget child}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainerHigh),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05142433),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildStatCardHeader(String title, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textTertiary,
            letterSpacing: 0.5,
          ),
        ),
        Icon(icon, size: 16, color: AppColors.primaryContainer),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Tab Bar
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTabBar(ClassSectionModel cls) {
    final studentBadge = _realStudents.isNotEmpty ? '${_realStudents.length} SV' : '${cls.studentCount} SV';
    final totalSessions = cls.totalSessions > 0 ? cls.totalSessions : 30;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTabButton(
            index: 0,
            icon: Icons.calendar_month_outlined,
            label: 'Lịch trình & Nhật ký ca học',
            badge: '$totalSessions',
          ),
          const SizedBox(width: 4),
          _buildTabButton(
            index: 1,
            icon: Icons.people_outline,
            label: 'Danh sách sinh viên',
            badge: studentBadge,
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.statusPresent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Lớp: ${cls.classCode}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required IconData icon,
    required String label,
    required String badge,
  }) {
    final isActive = _activeTab == index;
    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? const [
                  BoxShadow(
                    color: Color(0x10142433),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? AppColors.primaryDark : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primaryLight : AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isActive ? AppColors.primaryDark : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Tab 1: Schedule Table
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildScheduleTab(ClassSectionModel cls) {
    final completedCount = _realSessions.isNotEmpty
        ? _realSessions.where((s) => s.sessionStatus == 'closed').length
        : cls.completedSessions;
    final totalCount = cls.totalSessions > 0 ? cls.totalSessions : 30;
    final upcomingCount = totalCount - completedCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sub-header with title & filters
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Lịch trình & Nhật ký ca học',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Học kỳ $totalCount buổi',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            Row(
              children: [
                _buildFilterChip('Tất cả các ca ($totalCount)', 'all'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Session Table Container
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceContainerHigh),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Table Header
              Container(
                color: AppColors.surfaceContainerLow,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: const Row(
                  children: [
                    SizedBox(width: 48, child: Text('CA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textTertiary))),
                    Expanded(flex: 3, child: Text('NGÀY & GIỜ HỌC', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textTertiary))),
                    Expanded(flex: 5, child: Text('NỘI DUNG BÀI GIẢNG & THỰC HÀNH LAB', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textTertiary))),
                    Expanded(flex: 3, child: Text('PHÒNG & HÌNH THỨC', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textTertiary))),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.surfaceContainerHigh),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primaryContainer),
                  ),
                )
              else
                ..._buildScheduleRowsList(cls),
            ],
          ),
        ),
      ],
    );
  }

  String _formatSessionDate(String rawDate) {
    if (rawDate.isEmpty) return 'Chưa xếp ngày';
    final dt = DateTime.tryParse(rawDate);
    if (dt != null) {
      String pad(int n) => n.toString().padLeft(2, '0');
      return '${pad(dt.day)}/${pad(dt.month)}/${dt.year}';
    }
    if (rawDate.contains('T')) {
      final date = rawDate.split('T')[0];
      final parts = date.split('-');
      if (parts.length == 3) return '${parts[2]}/${parts[1]}/${parts[0]}';
      return date;
    }
    // Nếu format yyyy-MM-dd thì đổi thành dd/MM/yyyy
    final parts = rawDate.split('-');
    if (parts.length == 3 && parts[0].length == 4) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return rawDate;
  }

  List<Widget> _buildScheduleRowsList(ClassSectionModel cls) {
    final List<Widget> widgets = [];

    if (_realSessions.isNotEmpty) {
      for (int i = 0; i < _realSessions.length; i++) {
        final sess = _realSessions[i];
        final isClosed = sess.sessionStatus == 'closed';
        final isOpen = sess.sessionStatus == 'open';

        if (_sessionFilter == 'completed' && !isClosed) continue;
        if (_sessionFilter == 'upcoming' && isClosed) continue;

        widgets.add(
          _buildSessionRow(
            ca: '#${i + 1}',
            dayDate: _formatSessionDate(sess.sessionDate),
            timeSlot: sess.slotCode.isNotEmpty
                ? 'Slot ${sess.slotCode}'
                : (cls.timeLabel.isNotEmpty ? cls.timeLabel : 'Slot ${cls.slotCode}'),
            title: '${cls.subjectCode} — Ca học thực hành',
            subtitle: 'Điểm danh phiên lớp ${cls.classCode}',
            room: cls.room.isNotEmpty ? 'Phòng ${cls.room}' : 'P.111',
            format: 'Physical (Trực tiếp)',
            statusType: isClosed
                ? 'synced'
                : (isOpen ? 'ready' : 'planned'),
            statusText: isClosed
                ? 'Đã hoàn thành'
                : (isOpen
                    ? 'Sẵn sàng mở phiên'
                    : (sess.sessionStatus == 'planned'
                        ? 'Lịch kế hoạch'
                        : 'Theo kế hoạch')),
            tagText: null,
            isHighlighted: false,
          ),
        );
        widgets.add(const Divider(height: 1, color: AppColors.surfaceContainerHigh));
      }
    } else {
      final total = cls.totalSessions > 0 ? cls.totalSessions : 30;
      final completed = cls.completedSessions;

      for (int i = 1; i <= 4; i++) {
        final isDone = i <= completed;
        final isNext = i == completed + 1;

        if (_sessionFilter == 'completed' && !isDone) continue;
        if (_sessionFilter == 'upcoming' && isDone) continue;

        widgets.add(
          _buildSessionRow(
            ca: '#$i',
            dayDate: 'Buổi $i / $total',
            timeSlot: cls.timeLabel.isNotEmpty ? cls.timeLabel : 'Slot 1 (07:30 - 09:50)',
            title: '${cls.subjectCode} — Bài học ca $i',
            subtitle: 'Thực hành Lab & Lý thuyết',
            room: cls.room.isNotEmpty ? 'Phòng ${cls.room}' : 'Phòng P.111',
            format: 'Physical (Trực tiếp)',
            statusType: isDone ? 'synced' : (isNext ? 'ready' : 'planned'),
            statusText: isDone ? 'Đã hoàn thành' : (isNext ? 'Sẵn sàng mở phiên' : 'Theo kế hoạch'),
            tagText: null,
            isHighlighted: false,
          ),
        );
        widgets.add(const Divider(height: 1, color: AppColors.surfaceContainerHigh));
      }
    }

    if (widgets.isEmpty) {
      widgets.add(
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('Không có ca học nào thuộc bộ lọc này', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _sessionFilter == value;
    return InkWell(
      onTap: () => setState(() => _sessionFilter = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryContainer : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSessionRow({
    required String ca,
    required String dayDate,
    required String timeSlot,
    required String title,
    required String subtitle,
    required String room,
    required String format,
    required String statusType,
    required String statusText,
    String? tagText,
    bool isHighlighted = false,
  }) {
    return Container(
      color: isHighlighted ? AppColors.primaryLight.withOpacity(0.2) : AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // CA #
          SizedBox(
            width: 48,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isHighlighted ? AppColors.primaryContainer : AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                ca,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isHighlighted ? Colors.white : AppColors.textSecondary,
                  fontFamily: 'JetBrains Mono',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // NGÀY & GIỜ HỌC
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      dayDate,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    if (tagText != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tagText == 'TIẾP THEO' ? AppColors.primaryContainer : Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tagText,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: tagText == 'TIẾP THEO' ? Colors.white : Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  timeSlot,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          // NỘI DUNG BÀI GIẢNG
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          // PHÒNG & HÌNH THỨC
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.meeting_room, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      room,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  format,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String type, String text) {
    Color bg;
    Color fg;
    IconData icon;

    switch (type) {
      case 'synced':
        bg = AppColors.statusPresentBg;
        fg = AppColors.statusPresent;
        icon = Icons.check_circle_outline;
        break;
      case 'ready':
        bg = AppColors.statusLateBg;
        fg = AppColors.statusLate;
        icon = Icons.bolt;
        break;
      case 'approved':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
        icon = Icons.verified_outlined;
        break;
      case 'planned':
      default:
        bg = AppColors.surfaceContainer;
        fg = AppColors.textSecondary;
        icon = Icons.hourglass_empty;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Tab 2: Students List Table
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildStudentsTab(ClassSectionModel cls) {
    final query = _studentSearch.text.trim().toLowerCase();
    final displayStudents = _realStudents.where((s) {
      if (query.isEmpty) return true;
      return s.rollNumber.toLowerCase().contains(query) ||
          s.fullName.toLowerCase().contains(query) ||
          s.email.toLowerCase().contains(query);
    }).toList();

    final count = _realStudents.isNotEmpty ? _realStudents.length : cls.studentCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header & Search
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Danh sách sinh viên lớp ${cls.classCode} ($count SV)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            SizedBox(
              width: 260,
              height: 36,
              child: TextField(
                controller: _studentSearch,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm MSSV, Họ tên...',
                  hintStyle: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                  prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.textSecondary),
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Students Table
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceContainerHigh),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                color: AppColors.surfaceContainerLow,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: const Row(
                  children: [
                    SizedBox(width: 40, child: Text('STT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textTertiary))),
                    SizedBox(width: 100, child: Text('MSSV', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textTertiary))),
                    Expanded(flex: 4, child: Text('HỌ VÀ TÊN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textTertiary))),
                    Expanded(flex: 4, child: Text('EMAIL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textTertiary))),
                    SizedBox(width: 110, child: Text('CHUYÊN CẦN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textTertiary))),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.surfaceContainerHigh),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primaryContainer),
                  ),
                )
              else if (displayStudents.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      _realStudents.isEmpty
                          ? 'Chưa có dữ liệu danh sách sinh viên từ hệ thống'
                          : 'Không tìm thấy sinh viên phù hợp',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                )
              else
                for (int i = 0; i < displayStudents.length; i++) ...[
                  _buildStudentRow(i + 1, displayStudents[i]),
                  if (i < displayStudents.length - 1)
                    const Divider(height: 1, color: AppColors.surfaceContainerHigh),
                ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentRow(int index, AttendanceStudentRecord student) {
    final total = student.totalSessions > 0 ? student.totalSessions : 30;
    final attended = total - student.absenceCount;
    final rate = total > 0 ? (attended / total * 100) : 100.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text('$index', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
          SizedBox(
            width: 100,
            child: Text(
              student.rollNumber,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'JetBrains Mono', color: AppColors.primaryDark),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              student.fullName.isNotEmpty ? student.fullName : student.rollNumber,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              student.email.isNotEmpty ? student.email : '${student.rollNumber.toLowerCase()}@fpt.edu.vn',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          SizedBox(
            width: 110,
            child: Row(
              children: [
                Icon(
                  rate >= 80 ? Icons.check_circle : Icons.warning_amber_rounded,
                  size: 14,
                  color: rate >= 80 ? AppColors.statusPresent : AppColors.statusLate,
                ),
                const SizedBox(width: 4),
                Text(
                  '${rate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: rate >= 80 ? AppColors.statusPresent : AppColors.statusLate,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Footer Bar
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildFooter(ClassSectionModel cls) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Icon(Icons.sync_outlined, size: 16, color: AppColors.textTertiary),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              'Đồng bộ gần nhất: Hôm nay qua Hệ thống FAP Engine',
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
            ),
          ),
        ],
      ),
    );
  }
}
