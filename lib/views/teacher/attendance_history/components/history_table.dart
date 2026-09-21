import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../viewmodels/attendance_history_viewmodel.dart';
import '../../../../data/models/history_student.dart';
import '../../../../core/constants/app_colors.dart';

class HistoryTable extends StatelessWidget {
  const HistoryTable({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AttendanceHistoryViewModel>();
    final session = vm.detail?.selectedSession;
    final filteredStudents = vm.filteredStudents;
    final studentsCount = vm.students.length;
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
                _StudentCount(count: filteredStudents.length),
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
                    onChanged: vm.setSearch,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Tìm MSSV, họ tên, email',
                    ),
                  ),
                ),
                _StatusFilter(
                  value: vm.statusFilter,
                  studentsCount: studentsCount,
                  count: vm.count,
                  onChanged: vm.setStatusFilter,
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
                  icon: const Icon(Icons.save_outlined),
                  label: Text(vm.saving ? 'Đang lưu...' : 'Lưu thay đổi'),
                ),
              ],
            ),
          ),
          if (filteredStudents.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Text(
                'Không có sinh viên phù hợp.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStatePropertyAll(
                  AppColors.surfaceContainerLow,
                ),
                dataRowMinHeight: 64,
                dataRowMaxHeight: 76,
                headingRowHeight: 44,
                horizontalMargin: 20,
                columnSpacing: 24,
                dividerThickness: 0.6,
                columns: const [
                  DataColumn(label: _TableHeader('STT')),
                  DataColumn(label: _TableHeader('MSSV')),
                  DataColumn(label: _TableHeader('HỌ VÀ TÊN')),
                  DataColumn(label: _TableHeader('GIỜ ĐIỂM DANH')),
                  DataColumn(label: _TableHeader('PHƯƠNG THỨC')),
                  DataColumn(label: _TableHeader('TRẠNG THÁI')),
                  DataColumn(label: _TableHeader('VẮNG LŨY KẾ')),
                  DataColumn(label: _TableHeader('GHI CHÚ')),
                  DataColumn(label: _TableHeader('THAO TÁC')),
                ],
                rows: filteredStudents.asMap().entries.map((entry) {
                  final s = entry.value;
                  return DataRow(
                    color: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.hovered)
                          ? AppColors.primaryLight.withValues(alpha: 0.45)
                          : null,
                    ),
                    cells: [
                      DataCell(
                        Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          s.rollNumber,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 190,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.fullName.isEmpty ? s.rollNumber : s.fullName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                s.email,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          s.checkinTime.isEmpty
                              ? '--:--'
                              : historyDate(s.checkinTime, includeTime: true),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      DataCell(Text(_methodLabel(s))),
                      DataCell(_StatusBadge(status: s.status)),
                      DataCell(
                        Text(
                          '${s.absenceCount}/${s.totalSessions} (${(s.absenceRate * 100).toStringAsFixed(0)}%)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: s.absenceRate > .2
                                ? AppColors.statusAbsent
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 180,
                          child: Tooltip(
                            message: s.note,
                            child: Text(
                              s.note.isEmpty ? '—' : s.note,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Chỉnh sửa trạng thái',
                              onPressed: vm.busy || session == null
                                  ? null
                                  : () => _edit(context, s),
                              icon: const Icon(Icons.edit_note),
                            ),
                            IconButton(
                              tooltip: 'Ghi chú sinh viên',
                              onPressed: vm.busy || session == null
                                  ? null
                                  : () => _edit(context, s),
                              icon: const Icon(Icons.comment_outlined),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, HistoryStudent student) async {
    final vm = context.read<AttendanceHistoryViewModel>();
    final note = TextEditingController(text: student.note);
    var status = student.status;
    if (!attendanceStatusLabels.containsKey(status)) status = 'Unchecked';
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('${student.rollNumber} · ${student.fullName}'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: status,
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
                const SizedBox(height: 12),
                TextField(
                  controller: note,
                  maxLines: 4,
                  maxLength: 2000,
                  decoration: const InputDecoration(labelText: 'Ghi chú'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Áp dụng'),
            ),
          ],
        ),
      ),
    );
    if (saved == true && context.mounted) vm.edit(student, status, note.text);
    // Dialog route may still animate out; dispose after its transition.
    Future<void>.delayed(const Duration(milliseconds: 400), note.dispose);
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    );
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
