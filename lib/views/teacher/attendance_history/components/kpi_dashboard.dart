import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/history_summary.dart';
import '../../../../viewmodels/attendance_history_viewmodel.dart';
import '../../../../data/models/history_student.dart';
import '../history_actions.dart';
import '../../../../core/responsive/breakpoints.dart';

class KpiDashboard extends StatelessWidget {
  const KpiDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    final summary = context.select<AttendanceHistoryViewModel, HistorySummary?>(
      (value) => value.summary,
    );
    final busy = context.select<AttendanceHistoryViewModel, bool>(
      (value) => value.busy,
    );
    if (summary == null) return SizedBox.shrink();
    final c = summary.classInfo;
    final mobile = context.isMobile;
    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: busy || summary.slotCodes.isEmpty
              ? null
              : () => openHistorySession(context),
          icon: Icon(Icons.qr_code_2_outlined, size: 18),
          label: Text('Tạo phiên QR'),
        ),
        OutlinedButton.icon(
          onPressed: busy ? null : () => showHistoryMatrix(context),
          icon: Icon(Icons.grid_on_outlined, size: 18),
          label: Text('Ma trận'),
        ),
      ],
    );
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${c.classCode} — ${c.subjectName}',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: mobile ? 18 : 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Giảng viên: ${summary.teacherName} · Phòng: ${c.room.isEmpty ? "Chưa cập nhật" : c.room} · ${c.studentCount} sinh viên',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
    return Container(
      padding: EdgeInsets.all(mobile ? 14 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [titleBlock, SizedBox(height: 12), actions],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: titleBlock),
                actions,
              ],
            ),
          SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, box) {
              final kpiWidth = box.maxWidth < 460 ? box.maxWidth : 205.0;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _Kpi(
                    'Buổi đã kết thúc',
                    '${c.completedSessions}/${c.totalSessions}',
                    icon: Icons.event_available_outlined,
                    color: AppColors.primary,
                    width: kpiWidth,
                  ),
                  _Kpi(
                    'Tỷ lệ có mặt TB',
                    c.completedSessions == 0
                        ? '—'
                        : '${(c.attendanceRate * 100).toStringAsFixed(1)}%',
                    icon: Icons.check_circle_outline,
                    color: AppColors.statusPresent,
                    width: kpiWidth,
                  ),
                  _Kpi(
                    'Tỷ lệ đi trễ',
                    c.completedSessions == 0
                        ? '—'
                        : '${(c.lateRate * 100).toStringAsFixed(1)}%',
                    icon: Icons.schedule_outlined,
                    color: AppColors.statusLate,
                    width: kpiWidth,
                  ),
                  _Kpi(
                    'Vắng trên 20%',
                    '${c.atRiskCount} sinh viên',
                    icon: Icons.warning_amber_outlined,
                    color: AppColors.statusAbsent,
                    width: kpiWidth,
                  ),
                ],
              );
            },
          ),
          SizedBox(height: 14),
          Text(
            'Tỷ lệ được tính trên các buổi đã kết thúc. Cảnh báo vắng không phải kết luận cấm thi.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.6),
              ),
            ),
            child: c.latestSession == null
                ? Text(
                    'Lớp chưa có phiên điểm danh. Danh sách bên dưới lấy từ Enrollment; chưa có kết quả điểm danh.',
                    style: TextStyle(color: AppColors.textSecondary),
                  )
                : Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Buổi gần nhất',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${historyDate(c.latestSession!.sessionDate)} · Ca ${c.latestSession!.slotCode}',
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
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
  final double width;

  const _Kpi(
    this.title,
    this.value, {
    required this.icon,
    required this.color,
    required this.width,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 5),
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
