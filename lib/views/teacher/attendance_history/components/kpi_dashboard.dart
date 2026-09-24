import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/history_summary.dart';
import '../../../../viewmodels/attendance_history_viewmodel.dart';
import '../../../../data/models/history_student.dart';
import '../history_actions.dart';

class KpiDashboard extends StatelessWidget {
  const KpiDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    final summary = context
        .select<AttendanceHistoryViewModel, HistorySummary?>(
      (value) => value.summary,
    );
    final busy = context.select<AttendanceHistoryViewModel, bool>(
      (value) => value.busy,
    );
    if (summary == null) return const SizedBox.shrink();
    final c = summary.classInfo;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${c.classCode} — ${c.subjectName}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Giảng viên: ${summary.teacherName} · Phòng: ${c.room.isEmpty ? "Chưa cập nhật" : c.room} · ${c.studentCount} sinh viên',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: busy || summary.slotCodes.isEmpty
                        ? null
                        : () => openHistorySession(context),
                    icon: const Icon(Icons.qr_code_2_outlined, size: 18),
                    label: const Text('Tạo phiên QR'),
                  ),
                  OutlinedButton.icon(
                    onPressed: busy ? null : () => showHistoryMatrix(context),
                    icon: const Icon(Icons.grid_on_outlined, size: 18),
                    label: const Text('Ma trận'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _Kpi(
                'Buổi đã kết thúc',
                '${c.completedSessions}/${c.totalSessions}',
                icon: Icons.event_available_outlined,
                color: AppColors.primary,
              ),
              _Kpi(
                'Tỷ lệ có mặt TB',
                c.completedSessions == 0
                    ? '—'
                    : '${(c.attendanceRate * 100).toStringAsFixed(1)}%',
                icon: Icons.check_circle_outline,
                color: AppColors.statusPresent,
              ),
              _Kpi(
                'Tỷ lệ đi trễ',
                c.completedSessions == 0
                    ? '—'
                    : '${(c.lateRate * 100).toStringAsFixed(1)}%',
                icon: Icons.schedule_outlined,
                color: AppColors.statusLate,
              ),
              _Kpi(
                'Vắng trên 20%',
                '${c.atRiskCount} sinh viên',
                icon: Icons.warning_amber_outlined,
                color: AppColors.statusAbsent,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Tỷ lệ được tính trên các buổi đã kết thúc. Cảnh báo vắng không phải kết luận cấm thi.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
            ),
            child: c.latestSession == null
                ? const Text(
                    'Lớp chưa có phiên điểm danh. Danh sách bên dưới lấy từ Enrollment; chưa có kết quả điểm danh.',
                    style: TextStyle(color: AppColors.textSecondary),
                  )
                : Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Buổi gần nhất',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${historyDate(c.latestSession!.sessionDate)} · Ca ${c.latestSession!.slotCode}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;

  const _Kpi(this.title, this.value, {required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 205,
    child: Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
