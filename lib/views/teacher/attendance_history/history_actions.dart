import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../viewmodels/attendance_history_viewmodel.dart';
import '../../../viewmodels/live_session_viewmodel.dart';
import '../../../viewmodels/dashboard_viewmodel.dart';
import '../../../data/models/history_student.dart';
import '../../../data/models/class_section_model.dart';
import '../../../core/services/history_download.dart';

Future<void> exportHistory(BuildContext context) async {
  final vm = context.read<AttendanceHistoryViewModel>();
  final file = await vm.export();
  if (file == null || !context.mounted) return;
  try {
    final location = await downloadHistory(
      file.filename,
      file.base64,
      file.mimeType,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(location)));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Không thể tải tệp: $e')));
    }
  }
}

Future<void> showHistoryMatrix(BuildContext context) async {
  final vm = context.read<AttendanceHistoryViewModel>();
  final matrix = await vm.loadMatrix();
  if (matrix == null || !context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Ma trận điểm danh các buổi học'),
      content: SizedBox(
        width: 1000,
        height: 500,
        child: matrix.sessions.isEmpty
            ? const Center(child: Text('Chưa có phiên điểm danh.'))
            : SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      const DataColumn(label: Text('MSSV')),
                      const DataColumn(label: Text('Họ tên')),
                      ...matrix.sessions.map(
                        (s) => DataColumn(
                          label: Text(
                            '${historyDate(s.sessionDate)}\nCa ${s.slotCode}',
                          ),
                        ),
                      ),
                    ],
                    rows: matrix.students
                        .map(
                          (s) => DataRow(
                            cells: [
                              DataCell(Text(s.rollNumber)),
                              DataCell(Text(s.fullName)),
                              ...s.statuses.map(
                                (status) => DataCell(
                                  Text(
                                    attendanceStatusLabels[status] ?? status,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    ),
  );
}

Future<void> openHistorySession(BuildContext context) async {
  final vm = context.read<AttendanceHistoryViewModel>();
  final detail = vm.detail;
  if (detail == null || detail.slotCodes.isEmpty) return;
  final live = context.read<LiveSessionViewModel>();
  if (live.session?.isOpen == true) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Bạn đang có phiên điểm danh mở. Hãy kết thúc phiên trước.',
        ),
      ),
    );
    return;
  }
  var slot = detail.slotCodes.first;
  final ip = TextEditingController();
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text('Mở phiên ${detail.classInfo.classCode}'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: slot,
                decoration: const InputDecoration(labelText: 'Ca học'),
                items: detail.slotCodes
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (s) {
                  if (s != null) setState(() => slot = s);
                },
              ),
              TextField(
                controller: ip,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'IP công khai của mạng giảng viên',
                ),
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
            onPressed: ip.text.trim().isEmpty
                ? null
                : () => Navigator.pop(context, true),
            child: const Text('Mở phiên'),
          ),
        ],
      ),
    ),
  );
  final address = ip.text.trim();
  Future<void>.delayed(const Duration(milliseconds: 400), ip.dispose);
  if (accepted != true || !context.mounted) return;
  final session = await vm.startSession(slot, address);
  if (session == null || !context.mounted) return;
  final c = detail.classInfo;
  live.adoptSession(
    session,
    ClassSectionModel(
      classCode: c.classCode,
      subjectCode: c.subjectCode,
      subjectName: c.subjectName,
      room: c.room,
      studentCount: c.studentCount,
      teacherMemberCode: context.read<DashboardViewModel>().teacherMemberCode,
      timeLabel: '',
      completedSessions: c.completedSessions,
      totalSessions: c.totalSessions + 1,
      averageAttendance: c.attendanceRate * 100,
      isActive: true,
      activeSessionId: session.sessionId,
    ),
    address,
  );
  context.read<DashboardViewModel>().navigate('diem-danh-qr');
}
