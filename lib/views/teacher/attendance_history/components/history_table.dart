import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../viewmodels/attendance_history_viewmodel.dart';
import '../../../../data/models/history_student.dart';

class HistoryTable extends StatelessWidget {
  const HistoryTable({super.key});
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AttendanceHistoryViewModel>();
    final session = vm.detail?.selectedSession;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              session == null
                  ? 'Danh sách sinh viên của lớp'
                  : 'Điểm danh ngày ${historyDate(session.sessionDate)} · Ca ${session.slotCode}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
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
                DropdownButton<String>(
                  value: vm.statusFilter,
                  onChanged: (s) {
                    if (s != null) vm.setStatusFilter(s);
                  },
                  items: [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('Tất cả (${vm.students.length})'),
                    ),
                    ...['Present', 'Late', 'Absent', 'Unchecked'].map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(
                          '${attendanceStatusLabels[s]} (${vm.count(s)})',
                        ),
                      ),
                    ),
                  ],
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
                  icon: const Icon(Icons.save),
                  label: Text(
                    vm.saving ? 'Đang lưu...' : 'Lưu thay đổi thủ công',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (vm.filteredStudents.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Không có sinh viên phù hợp.'),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('STT')),
                    DataColumn(label: Text('MSSV')),
                    DataColumn(label: Text('Họ và tên')),
                    DataColumn(label: Text('Thời gian điểm danh')),
                    DataColumn(label: Text('Phương thức')),
                    DataColumn(label: Text('Trạng thái')),
                    DataColumn(label: Text('Vắng lũy kế')),
                    DataColumn(label: Text('Ghi chú')),
                    DataColumn(label: Text('Thao tác')),
                  ],
                  rows: vm.filteredStudents.asMap().entries.map((entry) {
                    final s = entry.value;
                    return DataRow(
                      cells: [
                        DataCell(Text('${entry.key + 1}')),
                        DataCell(Text(s.rollNumber)),
                        DataCell(
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.fullName.isEmpty ? s.rollNumber : s.fullName,
                              ),
                              Text(
                                s.email,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Text(historyDate(s.checkinTime, includeTime: true)),
                        ),
                        DataCell(
                          Text(
                            s.status == 'ManualByGV' || s.method == 'Manual'
                                ? 'Giảng viên cập nhật'
                                : s.checkinTime.isEmpty
                                ? '—'
                                : 'QR',
                          ),
                        ),
                        DataCell(
                          Text(attendanceStatusLabels[s.status] ?? s.status),
                        ),
                        DataCell(
                          Text(
                            '${s.absenceCount}/${s.totalSessions} (${(s.absenceRate * 100).toStringAsFixed(0)}%)',
                            style: TextStyle(
                              color: s.absenceRate > .2 ? Colors.red : null,
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
