import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../viewmodels/attendance_history_viewmodel.dart';
import '../../../../viewmodels/dashboard_viewmodel.dart';
import '../../../../data/models/history_student.dart';
import '../../../../core/constants/app_colors.dart';

class HistoryTable extends StatefulWidget {
  const HistoryTable({super.key});

  @override
  State<HistoryTable> createState() => _HistoryTableState();
}

class _HistoryTableState extends State<HistoryTable> {
  int _currentPage = 0;
  static const int _itemsPerPage = 10;
  String _prevClassCode = '';
  String _prevSessionId = '';

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AttendanceHistoryViewModel>();
    final session = vm.detail?.selectedSession;
    final filteredStudents = vm.filteredStudents;
    final totalStudents = filteredStudents.length;
    final studentsCount = vm.students.length;

    // Reset pagination when switching class or session
    final currentClass = vm.selectedClassCode ?? '';
    final currentSession = session?.sessionId ?? '';
    if (currentClass != _prevClassCode || currentSession != _prevSessionId) {
      _currentPage = 0;
      _prevClassCode = currentClass;
      _prevSessionId = currentSession;
    }

    final totalPages = (totalStudents / _itemsPerPage).ceil();
    if (_currentPage >= totalPages && totalPages > 0) {
      _currentPage = totalPages - 1;
    }

    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage > totalStudents)
        ? totalStudents
        : startIndex + _itemsPerPage;

    final paginatedStudents = totalStudents > 0
        ? filteredStudents.sublist(startIndex, endIndex)
        : <HistoryStudent>[];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  session == null
                      ? 'Danh sách sinh viên của lớp'
                      : 'Điểm danh ngày ${historyDate(session.sessionDate)} · Ca ${session.slotCode}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                _StudentCount(count: totalStudents),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 280,
                  child: TextFormField(
                    key: ValueKey(vm.selectedClassCode),
                    initialValue: vm.searchQuery,
                    onChanged: (val) {
                      setState(() => _currentPage = 0);
                      vm.setSearch(val);
                    },
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search, size: 20),
                      hintText: 'Tìm MSSV, họ tên, email',
                      isDense: true,
                    ),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: _StatusFilter(
                    value: vm.statusFilter,
                    studentsCount: studentsCount,
                    count: vm.count,
                    onChanged: (val) {
                      setState(() => _currentPage = 0);
                      vm.setStatusFilter(val);
                    },
                  ),
                ),
                FilledButton.icon(

                  onPressed: vm.busy || !vm.hasChanges || session == null
                      ? null
                      : () async {
                          final saved = await vm.saveChanges();
                          if (context.mounted && saved) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã lưu điểm danh và ghi chú.'),
                              ),
                            );
                          }
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: Text(vm.saving ? 'Đang lưu...' : 'Lưu thay đổi'),
                ),
              ],
            ),
          ),
          if (filteredStudents.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 36),
              child: Center(
                child: Text(
                  'Không có sinh viên phù hợp.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final tableWidth = constraints.maxWidth < 980 ? 980.0 : constraints.maxWidth;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Table(
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                      columnWidths: const {
                        0: FixedColumnWidth(60),   // STT
                        1: FixedColumnWidth(110),  // MSSV
                        2: FlexColumnWidth(2.8),   // HỌ VÀ TÊN
                        3: FixedColumnWidth(120),  // GIỜ ĐIỂM DANH
                        4: FixedColumnWidth(130),  // PHƯƠNG THỨC
                        5: FixedColumnWidth(140),  // TRẠNG THÁI
                        6: FixedColumnWidth(110),  // VẮNG LŨY KẾ
                        7: FlexColumnWidth(2.0),   // GHI CHÚ
                        8: FixedColumnWidth(90),   // THAO TÁC
                      },
                      children: [
                        TableRow(
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                          ),
                          children: [
                            _headerCell('STT', center: true),
                            _headerCell('MSSV'),
                            _headerCell('HỌ VÀ TÊN'),
                            _headerCell('GIỜ ĐIỂM DANH', center: true),
                            _headerCell('PHƯƠNG THỨC', center: true),
                            _headerCell('TRẠNG THÁI', center: true),
                            _headerCell('VẮNG LŨY KẾ', center: true),
                            _headerCell('GHI CHÚ'),
                            _headerCell('THAO TÁC', center: true),
                          ],
                        ),
                        ...paginatedStudents.asMap().entries.map((entry) {
                          final s = entry.value;
                          final idx = startIndex + entry.key + 1;
                          final isEven = entry.key.isEven;
                          return TableRow(
                            decoration: BoxDecoration(
                              color: isEven
                                  ? Colors.transparent
                                  : AppColors.surfaceContainerLowest.withValues(alpha: 0.5),
                              border: Border(
                                bottom: BorderSide(
                                  color: AppColors.border.withValues(alpha: 0.6),
                                  width: 0.6,
                                ),
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                                child: Text(
                                  '$idx'.padLeft(2, '0'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                                child: Text(
                                  s.rollNumber,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primaryLight,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        _getInitials(s.fullName.isEmpty ? s.rollNumber : s.fullName),
                                        style: const TextStyle(
                                          color: AppColors.primaryDark,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            s.fullName.isEmpty ? s.rollNumber : s.fullName,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            s.email,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                                child: Text(
                                  s.checkinTime.isEmpty
                                      ? '--:--'
                                      : historyDate(s.checkinTime, includeTime: true),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                                child: Text(
                                  _methodLabel(s),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                child: Center(
                                  child: _StatusBadge(status: s.status),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                                child: Text(
                                  '${s.absenceCount}/${s.totalSessions} (${(s.absenceRate * 100).toStringAsFixed(0)}%)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: s.absenceRate > .2
                                        ? AppColors.statusAbsent
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                                child: Tooltip(
                                  message: s.note,
                                  child: Text(
                                    s.note.isEmpty ? '—' : s.note,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Chỉnh sửa trạng thái',
                                      iconSize: 18,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      onPressed: vm.busy || session == null
                                          ? null
                                          : () => _edit(context, s),
                                      icon: const Icon(Icons.edit_note, color: AppColors.textSecondary),
                                    ),
                                    IconButton(
                                      tooltip: 'Ghi chú sinh viên',
                                      iconSize: 18,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      onPressed: vm.busy || session == null
                                          ? null
                                          : () => _edit(context, s),
                                      icon: const Icon(Icons.comment_outlined, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
          if (totalPages > 1) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _currentPage > 0
                        ? () => setState(() => _currentPage--)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                    tooltip: 'Trang trước',
                    color: AppColors.primaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Trang ${_currentPage + 1} / $totalPages',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _currentPage < totalPages - 1
                        ? () => setState(() => _currentPage++)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                    tooltip: 'Trang tiếp',
                    color: AppColors.primaryContainer,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _headerCell(String label, {bool center = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      child: Text(
        label,
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  static String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length.clamp(0, 2)).toUpperCase();
    }
    return (parts[parts.length - 2][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  static String _getSlotTimeLabel(String slotCode) {
    final clean = slotCode.replaceAll(RegExp(r'[^0-9]'), '');
    final num = int.tryParse(clean);
    switch (num) {
      case 1:
        return '07:30 - 09:50';
      case 2:
        return '10:00 - 12:20';
      case 3:
        return '12:50 - 15:10';
      case 4:
        return '15:20 - 17:40';
      case 5:
        return '17:50 - 20:10';
      case 6:
        return '20:20 - 22:40';
      default:
        return '';
    }
  }

  Future<void> _edit(BuildContext context, HistoryStudent student) async {
    final vm = context.read<AttendanceHistoryViewModel>();
    final dashVm = context.read<DashboardViewModel>();
    final detail = vm.detail;
    final session = detail?.selectedSession;
    final note = TextEditingController(text: student.note);
    var status = student.status;
    if (!attendanceStatusLabels.containsKey(status)) status = 'Unchecked';

    final subjectCode = detail?.classInfo.subjectCode.isNotEmpty == true
        ? detail!.classInfo.subjectCode
        : (vm.selectedClassCode ?? '');
    final slotCodeStr = session?.slotCode ?? '1';
    final timeRange = _getSlotTimeLabel(slotCodeStr);
    final slotLabel = timeRange.isNotEmpty
        ? 'Ca $slotCodeStr ($timeRange)'
        : 'Ca $slotCodeStr';
    final teacherName = detail?.teacherName.isNotEmpty == true
        ? detail!.teacherName
        : (dashVm.teacherName.isNotEmpty ? dashVm.teacherName : 'GV. ThS Lê Trần Anh Khoa');
    final dateStr = session != null && session.sessionDate.isNotEmpty
        ? historyDate(session.sessionDate)
        : historyDate(DateTime.now().toIso8601String());

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          width: 520,
          padding: const EdgeInsets.all(28),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Close button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '${student.rollNumber} · ${student.fullName}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            height: 1.25,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Subtitle chips row: @ email • subjectCode • slotLabel
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '@',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              student.email,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (subjectCode.isNotEmpty) ...[
                        const Text(
                          '•',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                        ),
                        Text(
                          subjectCode,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                      const Text(
                        '•',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                      Text(
                        slotLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Section: TRẠNG THÁI ĐIỂM DANH *
                  Row(
                    children: const [
                      Text(
                        'TRẠNG THÁI ĐIỂM DANH',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        ' *',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    initialValue: status,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFC2410C), width: 1.5),
                      ),
                    ),
                    items: attendanceStatusLabels.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => status = value);
                    },
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: const [
                      Icon(Icons.info_outline, size: 15, color: Color(0xFF94A3B8)),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Trạng thái này sẽ ghi đè kết quả điểm danh tự động của ca học hiện tại.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Section: GHI CHÚ ... Tùy chọn
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'GHI CHÚ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Tùy chọn',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: note,
                    maxLines: 4,
                    maxLength: 2000,
                    buildCounter: (
                      context, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) => null,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Ghi chú',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                      contentPadding: const EdgeInsets.all(16),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFC2410C), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${note.text.length}/2000',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Info Box: Performed by
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                children: [
                                  const TextSpan(text: 'Người thực hiện: '),
                                  TextSpan(
                                    text: teacherName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Actions: Hủy & Áp dụng
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFC2410C),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Hủy'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFC2410C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Áp dụng'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    if (saved == true && context.mounted) vm.edit(student, status, note.text);
    Future<void>.delayed(const Duration(milliseconds: 400), note.dispose);
  }
}

class _StudentCount extends StatelessWidget {
  const _StudentCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count sinh viên',
        style: const TextStyle(
          color: AppColors.primaryDark,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusFilter extends StatelessWidget {
  const _StatusFilter({
    required this.value,
    required this.studentsCount,
    required this.count,
    required this.onChanged,
  });

  final String value;
  final int studentsCount;
  final int Function(String status) count;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: (status) {
        if (status != null) onChanged(status);
      },
      decoration: const InputDecoration(
        labelText: 'Lọc trạng thái',
        prefixIcon: Icon(Icons.filter_list),
        isDense: true,
      ),
      items: [
        DropdownMenuItem(value: 'all', child: Text('Tất cả ($studentsCount)')),
        ...['Present', 'Late', 'Absent', 'Unchecked'].map(
          (status) => DropdownMenuItem(
            value: status,
            child: Text('${attendanceStatusLabels[status]} (${count(status)})'),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = switch (status) {
      'Present' || 'ManualByGV' => (
        foreground: AppColors.statusPresent,
        background: AppColors.statusPresentBg,
      ),
      'Late' => (
        foreground: AppColors.statusLate,
        background: AppColors.statusLateBg,
      ),
      'Absent' => (
        foreground: AppColors.statusAbsent,
        background: AppColors.statusAbsentBg,
      ),
      _ => (
        foreground: AppColors.statusUnchecked,
        background: AppColors.statusUncheckedBg,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        attendanceStatusLabels[status] ?? status,
        style: TextStyle(
          color: colors.foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _methodLabel(HistoryStudent student) {
  if (student.status == 'ManualByGV' || student.method == 'Manual') {
    return 'Giảng viên cập nhật';
  }
  return student.checkinTime.isEmpty ? '—' : 'QR';
}
