import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../viewmodels/attendance_history_viewmodel.dart';
import '../../../../data/models/history_student.dart';
import '../history_actions.dart';

class KpiDashboard extends StatelessWidget {
  const KpiDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AttendanceHistoryViewModel>();
    final detail = vm.detail;
    if (detail == null) return const SizedBox.shrink();
    final c = detail.classInfo;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${c.classCode} — ${c.subjectName}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Giảng viên: ${detail.teacherName} · Phòng: ${c.room.isEmpty ? "Chưa cập nhật" : c.room} · ${c.studentCount} sinh viên',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed:
                      vm.busy || vm.hasChanges || detail.slotCodes.isEmpty
                      ? null
                      : () => openHistorySession(context),
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Tạo phiên QR mới'),
                ),
                OutlinedButton.icon(
                  onPressed: vm.busy || vm.hasChanges
                      ? null
                      : () => showHistoryMatrix(context),
                  icon: const Icon(Icons.grid_on),
                  label: const Text('Ma trận các buổi học'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _Kpi(
                  'Buổi đã kết thúc',
                  '${c.completedSessions}/${c.totalSessions}',
                ),
                _Kpi(
                  'Tỷ lệ có mặt TB',
                  c.completedSessions == 0
                      ? '—'
                      : '${(c.attendanceRate * 100).toStringAsFixed(1)}%',
                ),
                _Kpi(
                  'Tỷ lệ đi trễ',
                  c.completedSessions == 0
                      ? '—'
                      : '${(c.lateRate * 100).toStringAsFixed(1)}%',
                ),
                _Kpi('Vắng trên 20%', '${c.atRiskCount} sinh viên'),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Tỷ lệ được tính trên các buổi đã kết thúc. Cảnh báo vắng không phải kết luận cấm thi.',
            ),
            const SizedBox(height: 20),
            if (detail.sessions.isEmpty)
              const Text(
                'Lớp chưa có phiên điểm danh. Danh sách bên dưới lấy từ Enrollment; chưa có kết quả điểm danh.',
              )
            else ...[
              const Text('Chọn buổi học:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: detail.sessions
                    .map(
                      (s) => ChoiceChip(
                        label: Text(
                          '${historyDate(s.sessionDate)} · Ca ${s.slotCode} · ${s.sessionStatus == "closed"
                              ? "Đã kết thúc"
                              : s.sessionStatus == "open"
                              ? "Đang mở"
                              : s.sessionStatus}',
                        ),
                        selected:
                            detail.selectedSession?.sessionId == s.sessionId,
                        onSelected: vm.busy || vm.hasChanges
                            ? null
                            : (_) => vm.selectSession(s.sessionId),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  final String title, value;
  const _Kpi(this.title, this.value);
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 205,
    child: Card(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    ),
  );
}
