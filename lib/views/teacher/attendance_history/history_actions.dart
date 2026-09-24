import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../viewmodels/attendance_history_viewmodel.dart';
import '../../../viewmodels/live_session_viewmodel.dart';
import '../../../viewmodels/dashboard_viewmodel.dart';
import '../../../data/models/history_detail.dart';
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
  final initial = await vm.loadMatrix();
  if (initial == null || !context.mounted) return;
  var matrix = initial;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Ma trận điểm danh các buổi học',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: SizedBox(
          width: 1000,
          height: 500,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: matrix.sessions.isEmpty
                ? const Center(
                    child: Text(
                      'Chưa có phiên điểm danh.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: const WidgetStatePropertyAll(
                          AppColors.surfaceContainerHigh,
                        ),
                        dataRowMinHeight: 54,
                        dataRowMaxHeight: 66,
                        columnSpacing: 24,
                        columns: [
                          const DataColumn(
                            label: Text(
                              'MSSV',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const DataColumn(
                            label: Text(
                              'Họ tên',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          ...matrix.sessions.map(
                            (s) => DataColumn(
                              label: Text(
                                '${historyDate(s.sessionDate)}\nCa ${s.slotCode}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                        rows: matrix.students
                            .map(
                              (s) => DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      s.rollNumber,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(s.fullName)),
                                  ...s.cells.asMap().entries.map((entry) {
                                    final session = matrix.sessions[entry.key];
                                    final cell = entry.value;
                                    return DataCell(
                                      InkWell(
                                        onTap: vm.busy
                                            ? null
                                            : () async {
                                                final updated = await _editCell(
                                                  dialogContext,
                                                  vm: vm,
                                                  rollNumber: s.rollNumber,
                                                  fullName: s.fullName,
                                                  sessionId: session.sessionId,
                                                  sessionLabel:
                                                      '${historyDate(session.sessionDate)} · Ca ${session.slotCode}',
                                                  status: cell.status,
                                                  note: cell.note,
                                                  revision: cell.revision,
                                                );
                                                if (updated != null) {
                                                  setState(() => matrix = updated);
                                                }
                                              },
                                        child: _StatusBadge(cell.status),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đóng'),
          ),
        ],
      ),
    ),
  );
}

/// Opens the same edit form as the old per-session table, scoped to one
/// (session, student) cell of the matrix. Saves immediately on apply and
/// returns the refreshed matrix so the dialog can redraw in place.
Future<AttendanceMatrix?> _editCell(
  BuildContext context, {
  required AttendanceHistoryViewModel vm,
  required String rollNumber,
  required String fullName,
  required String sessionId,
  required String sessionLabel,
  required String status,
  required String note,
  required String revision,
}) async {
  final dashVm = context.read<DashboardViewModel>();
  final noteController = TextEditingController(text: note);
  var selectedStatus = attendanceStatusLabels.containsKey(status)
      ? status
      : 'Unchecked';
  final teacherName = vm.summary?.teacherName.isNotEmpty == true
      ? vm.summary!.teacherName
      : (dashVm.teacherName.isNotEmpty
          ? dashVm.teacherName
          : 'GV. ThS Lê Trần Anh Khoa');

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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '$rollNumber · $fullName',
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
                const SizedBox(height: 6),
                Text(
                  sessionLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 24),
                const Row(
                  children: [
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
                  initialValue: selectedStatus,
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
                    if (value != null) setState(() => selectedStatus = value);
                  },
                ),
                const SizedBox(height: 20),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                  controller: noteController,
                  maxLines: 4,
                  maxLength: 2000,
                  buildCounter: (
                    context, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => null,
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
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
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
                      Expanded(
                        child: RichText(
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
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFC2410C),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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

  AttendanceMatrix? updated;
  if (saved == true) {
    updated = await vm.saveMatrixCell(
      sessionId: sessionId,
      rollNumber: rollNumber,
      status: selectedStatus,
      note: noteController.text,
      revision: revision,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated != null
                ? 'Đã lưu điểm danh và ghi chú.'
                : (vm.errorMessage ?? 'Không thể lưu thay đổi.'),
          ),
        ),
      );
    }
  }
  Future<void>.delayed(const Duration(milliseconds: 400), noteController.dispose);
  return updated;
}

Future<void> openHistorySession(BuildContext context) async {
  final vm = context.read<AttendanceHistoryViewModel>();
  final summary = vm.summary;
  if (summary == null || summary.slotCodes.isEmpty) return;
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
  var slot = summary.slotCodes.first;
  final ip = TextEditingController();
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Mở phiên ${summary.classInfo.classCode}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: slot,
                decoration: const InputDecoration(labelText: 'Ca học'),
                items: summary.slotCodes
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
  final c = summary.classInfo;
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);

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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        attendanceStatusLabels[status] ?? status,
        style: TextStyle(
          color: colors.foreground,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
