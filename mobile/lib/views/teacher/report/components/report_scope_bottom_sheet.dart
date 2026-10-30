import 'package:flutter/material.dart';

/// Các chế độ phạm vi thời gian báo cáo
enum ReportScopeType {
  all,
  week,
  today,
  custom,
}

/// Hiển thị Popup "Phạm vi báo cáo" dạng Bottom Sheet trượt từ dưới lên
Future<Map<String, DateTime?>?> showReportScopeBottomSheet({
  required BuildContext context,
  DateTime? currentFrom,
  DateTime? currentTo,
  int totalClosedSessions = 0,
}) {
  return showModalBottomSheet<Map<String, DateTime?>?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xFF0F172A).withValues(alpha: 0.55),
    builder: (ctx) => ReportScopeBottomSheet(
      currentFrom: currentFrom,
      currentTo: currentTo,
      totalClosedSessions: totalClosedSessions,
    ),
  );
}

class ReportScopeBottomSheet extends StatefulWidget {
  const ReportScopeBottomSheet({
    super.key,
    this.currentFrom,
    this.currentTo,
    this.totalClosedSessions = 0,
  });

  final DateTime? currentFrom;
  final DateTime? currentTo;
  final int totalClosedSessions;

  @override
  State<ReportScopeBottomSheet> createState() => _ReportScopeBottomSheetState();
}

class _ReportScopeBottomSheetState extends State<ReportScopeBottomSheet> {
  late ReportScopeType _selectedType;
  late DateTime _customStart;
  late DateTime _customEnd;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _customEnd = widget.currentTo ?? now;
    _customStart = widget.currentFrom ??
        DateTime(now.year, now.month, 1);

    if (widget.currentFrom == null && widget.currentTo == null) {
      _selectedType = ReportScopeType.all;
    } else {
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

      if (widget.currentFrom != null &&
          widget.currentTo != null &&
          _isSameDay(widget.currentFrom!, todayStart) &&
          _isSameDay(widget.currentTo!, todayEnd)) {
        _selectedType = ReportScopeType.today;
      } else if (widget.currentFrom != null &&
          widget.currentTo != null &&
          _isSameDay(widget.currentFrom!, weekStart) &&
          _isSameDay(widget.currentTo!, weekEnd)) {
        _selectedType = ReportScopeType.week;
      } else {
        _selectedType = ReportScopeType.custom;
      }
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
  }

  String _weekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Thứ Hai';
      case DateTime.tuesday:
        return 'Thứ Ba';
      case DateTime.wednesday:
        return 'Thứ Tư';
      case DateTime.thursday:
        return 'Thứ Năm';
      case DateTime.friday:
        return 'Thứ Sáu';
      case DateTime.saturday:
        return 'Thứ Bảy';
      case DateTime.sunday:
      default:
        return 'Chủ Nhật';
    }
  }

  int _weekNumber(DateTime date) {
    // Ước lượng tuần học trong học kỳ hiện tại (tính từ tháng 9 hoặc tháng 1)
    final semesterStart = date.month >= 9
        ? DateTime(date.year, 9, 1)
        : (date.month >= 5 ? DateTime(date.year, 5, 1) : DateTime(date.year, 1, 1));
    final diffDays = date.difference(semesterStart).inDays;
    final week = (diffDays / 7).floor() + 1;
    return week.clamp(1, 20);
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _customStart,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _customStart = DateTime(picked.year, picked.month, picked.day);
        if (_customEnd.isBefore(_customStart)) {
          _customEnd = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        }
        _selectedType = ReportScopeType.custom;
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _customEnd,
      firstDate: _customStart,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _customEnd = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        _selectedType = ReportScopeType.custom;
      });
    }
  }

  void _applyFilter() {
    final now = DateTime.now();
    DateTime? from;
    DateTime? to;

    switch (_selectedType) {
      case ReportScopeType.all:
        from = null;
        to = null;
        break;
      case ReportScopeType.week:
        final startOfWeek = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        from = startOfWeek;
        to = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        break;
      case ReportScopeType.today:
        from = DateTime(now.year, now.month, now.day);
        to = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case ReportScopeType.custom:
        from = DateTime(_customStart.year, _customStart.month, _customStart.day);
        to = DateTime(_customEnd.year, _customEnd.month, _customEnd.day, 23, 59, 59);
        break;
    }

    Navigator.of(context).pop({'start': from, 'end': to});
  }

  void _resetFilter() {
    final now = DateTime.now();
    setState(() {
      _selectedType = ReportScopeType.all;
      _customStart = DateTime(now.year, now.month, 1);
      _customEnd = now;
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final weekNum = _weekNumber(now).toString().padLeft(2, '0');

    // Xác định học kỳ hiện tại (Spring, Summer, Fall)
    final semesterName = now.month >= 9
        ? 'Fall ${now.year}'
        : (now.month >= 5 ? 'Summer ${now.year}' : 'Spring ${now.year}');

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thanh kéo nhỏ trên đầu bottom sheet
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header: Icon Phễu cam + Tiêu đề + Nút đóng X
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.filter_alt_outlined,
                    color: Color(0xFFEA580C),
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phạm vi báo cáo',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Chọn khoảng thời gian thống kê điểm danh chuyên cần',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ── 1. Thẻ "Toàn bộ lịch sử" ──────────────────────────────
              _buildScopeCard(
                type: ReportScopeType.all,
                icon: Icons.history_rounded,
                title: 'Toàn bộ lịch sử',
                badge: 'Hiện tại',
                subtitle:
                    'Từ đầu học kỳ $semesterName đến nay (${widget.totalClosedSessions} buổi)',
              ),
              const SizedBox(height: 10),

              // ── 2. Thẻ "Tuần này" ─────────────────────────────────────
              _buildScopeCard(
                type: ReportScopeType.week,
                icon: Icons.calendar_view_week_rounded,
                title: 'Tuần này',
                subtitle:
                    '${_formatDate(weekStart).substring(0, 5)} - ${_formatDate(weekEnd)} (Tuần học $weekNum)',
              ),
              const SizedBox(height: 10),

              // ── 3. Thẻ "Hôm nay" ──────────────────────────────────────
              _buildScopeCard(
                type: ReportScopeType.today,
                icon: Icons.today_rounded,
                title: 'Hôm nay',
                subtitle:
                    '${_weekdayName(now.weekday)}, ${_formatDate(now)} • Các ca trong ngày',
              ),
              const SizedBox(height: 10),

              // ── 4. Thẻ "Tùy chọn khoảng ngày" ────────────────────────
              _buildScopeCard(
                type: ReportScopeType.custom,
                icon: Icons.date_range_rounded,
                title: 'Tùy chọn khoảng ngày',
                subtitle: 'Linh hoạt chọn ngày bắt đầu & kết thúc',
                customChild: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      // Hộp Từ ngày
                      Expanded(
                        child: InkWell(
                          onTap: _pickStartDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'TỪ NGÀY',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF94A3B8),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDate(_customStart),
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.calendar_month_outlined,
                                      size: 15,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Hộp Đến ngày
                      Expanded(
                        child: InkWell(
                          onTap: _pickEndDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ĐẾN NGÀY',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF94A3B8),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDate(_customEnd),
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.calendar_month_outlined,
                                      size: 15,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ],
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
              const SizedBox(height: 20),

              // ── Hàng nút hành động dưới cùng: Thiết lập lại & Áp dụng ──
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _resetFilter,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF334155),
                          side: const BorderSide(
                            color: Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Thiết lập lại',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _applyFilter,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEA580C),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Áp dụng bộ lọc',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
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
      ),
    );
  }

  Widget _buildScopeCard({
    required ReportScopeType type,
    required IconData icon,
    required String title,
    String? badge,
    required String subtitle,
    Widget? customChild,
  }) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFEA580C)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 1.6 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Khối icon bên trái
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFFEDD5)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected
                        ? const Color(0xFFEA580C)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 12),

                // Tiêu đề & phụ đề
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEDD5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                badge,
                                style: const TextStyle(
                                  color: Color(0xFFEA580C),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Nút Radio bo tròn tuỳ chỉnh
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFEA580C)
                          : const Color(0xFFCBD5E1),
                      width: isSelected ? 2 : 1.5,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFEA580C),
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
            ?customChild,
          ],
        ),
      ),
    );
  }
}
