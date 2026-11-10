import 'package:flutter/material.dart';
import 'package:fapcheckin_core/ai/ai_tool_executor.dart';
import 'package:fapcheckin_core/constants/app_palette.dart';

import '../../../../viewmodels/ai_chat_viewmodel.dart';

/// Thẻ xác nhận trước khi AI ghi điểm danh. Toàn bộ nội dung (MSSV, họ tên, lớp, slot,
/// trạng thái cũ → mới) lấy từ dữ liệu thật, để giảng viên bắt được MSSV nghe nhầm.
class AiConfirmCard extends StatelessWidget {
  const AiConfirmCard({
    super.key,
    required this.action,
    required this.state,
    required this.busy,
    required this.onConfirm,
    required this.onCancel,
  });

  final AiPendingAction action;
  final AiActionState state;
  final bool busy;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final muted = isDark ? const Color(0xFF94A3B8) : AppPalette.textMuted;
    final awaiting = state == AiActionState.awaiting;

    return Container(
      key: const Key('ai-confirm-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? scheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: awaiting
              ? AppPalette.primary.withValues(alpha: 0.55)
              : (isDark ? scheme.outline : AppPalette.borderSubtle),
          width: awaiting ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check_rounded, size: 20, color: AppPalette.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Xác nhận điểm danh',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppPalette.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${action.classCode} · ${action.subjectName}\n'
            'Slot ${action.slotCode} · ${_vnDate(action.sessionDate)}',
            style: TextStyle(fontSize: 12.5, height: 1.4, color: muted),
          ),
          const SizedBox(height: 10),
          for (final s in action.students) _StudentRow(student: s, isDark: isDark),
          if (action.note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Ghi chú: ${action.note}', style: TextStyle(fontSize: 12.5, color: muted)),
          ],
          const SizedBox(height: 12),
          if (awaiting)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('ai-cancel'),
                    onPressed: busy ? null : onCancel,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Huỷ'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    key: const Key('ai-confirm'),
                    onPressed: busy ? null : onConfirm,
                    icon: const Icon(Icons.check_rounded, size: 20),
                    label: Text('Xác nhận (${action.students.length})'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: AppPalette.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            )
          else
            _ResultBadge(state: state),
        ],
      ),
    );
  }

  static String _vnDate(String iso) {
    final p = iso.split('-');
    return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : iso;
  }
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({required this.student, required this.isDark});

  final AiPendingStudent student;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? const Color(0xFF94A3B8) : AppPalette.textMuted;
    final label = aiStatusLabels[student.status] ?? student.status;
    final before = aiStatusLabels[student.previousStatus] ?? student.previousStatus;
    final color = switch (student.status) {
      'Absent' => AppPalette.statusRed,
      'Late' => const Color(0xFFD97706),
      'Unchecked' => muted,
      _ => AppPalette.statusGreen,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.rollNumber,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: isDark ? Colors.white : AppPalette.textDark,
                  ),
                ),
                Text(student.fullName, style: TextStyle(fontSize: 12.5, color: muted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                label,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color),
              ),
              Text('trước: $before', style: TextStyle(fontSize: 11, color: muted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.state});

  final AiActionState state;

  @override
  Widget build(BuildContext context) {
    final (icon, text, color) = switch (state) {
      AiActionState.confirmed => (Icons.check_circle_rounded, 'Đã ghi điểm danh', AppPalette.statusGreen),
      AiActionState.cancelled => (Icons.cancel_rounded, 'Đã huỷ — chưa ghi gì', const Color(0xFF64748B)),
      _ => (Icons.error_rounded, 'Không ghi được điểm danh', AppPalette.statusRed),
    };
    return Row(
      key: Key('ai-result-${state.name}'),
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: color)),
        ),
      ],
    );
  }
}
