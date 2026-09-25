import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/history_summary.dart';
import '../../../../data/models/session_model.dart';
import '../../../../data/models/history_student.dart';
import '../../../../viewmodels/attendance_history_viewmodel.dart';
import 'session_detail_dialog.dart';

class SessionsTab extends StatelessWidget {
  const SessionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final summary = context.select<AttendanceHistoryViewModel, HistorySummary?>(
      (vm) => vm.summary,
    );
    final loadingSummary = context.select<AttendanceHistoryViewModel, bool>(
      (vm) => vm.loadingSummary,
    );

    if (summary == null) return const SizedBox.shrink();

    final sessions = summary.sessions;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Danh sách buổi học',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Nhấn vào một buổi để xem chi tiết điểm danh',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (sessions.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${sessions.length} buổi',
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Loading overlay or content
          if (loadingSummary)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
            )
          else if (sessions.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 32, 20, 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.event_busy_outlined,
                      size: 40,
                      color: AppColors.textTertiary,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Lớp này chưa có buổi điểm danh nào.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sessions.length,
              separatorBuilder: (context, idx) =>
                  const Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, index) {
                // Show sessions in reverse order (newest first)
                final session = sessions[sessions.length - 1 - index];
                return _SessionRow(session: session, index: sessions.length - index);
              },
            ),
        ],
      ),
    );
  }
}

class _SessionRow extends StatefulWidget {
  final SessionModel session;
  final int index;

  const _SessionRow({required this.session, required this.index});

  @override
  State<_SessionRow> createState() => _SessionRowState();
}

class _SessionRowState extends State<_SessionRow> {
  bool _hovering = false;

  Color get _statusColor {
    switch (widget.session.sessionStatus) {
      case 'open':
        return AppColors.statusPresent;
      case 'closed':
        return AppColors.textSecondary;
      case 'planned':
        return AppColors.statusLate;
      default:
        return AppColors.textSecondary;
    }
  }

  Color get _statusBg {
    switch (widget.session.sessionStatus) {
      case 'open':
        return AppColors.statusPresentBg;
      case 'closed':
        return AppColors.surfaceContainerLow;
      case 'planned':
        return AppColors.statusLateBg;
      default:
        return AppColors.surfaceContainerLow;
    }
  }

  String get _statusLabel {
    switch (widget.session.sessionStatus) {
      case 'open':
        return 'Đang mở';
      case 'closed':
        return 'Đã kết thúc';
      case 'planned':
        return 'Dự kiến';
      default:
        return widget.session.sessionStatus;
    }
  }

  void _openDetail() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => SessionDetailDialog(session: widget.session),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = historyDate(widget.session.sessionDate);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: _openDetail,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: _hovering
              ? AppColors.primaryLight.withValues(alpha: 0.3)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              // Session index badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${widget.index}',
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Date & slot info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buổi ${widget.index} — $dateStr',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_outlined,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Ca ${widget.session.slotCode}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        if (widget.session.sessionId.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          const Text(
                            '·',
                            style: TextStyle(color: AppColors.textTertiary),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'ID: ${widget.session.sessionId.length > 8 ? widget.session.sessionId.substring(0, 8) : widget.session.sessionId}…',
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _statusColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Arrow
              Icon(
                Icons.chevron_right,
                color: _hovering ? AppColors.primary : AppColors.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
