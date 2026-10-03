import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../viewmodels/attendance_history_viewmodel.dart';
import 'components/class_selector.dart';

class AttendanceHistoryBody extends StatefulWidget {
  const AttendanceHistoryBody({super.key});
  @override
  State<AttendanceHistoryBody> createState() => _AttendanceHistoryBodyState();
}

class _AttendanceHistoryBodyState extends State<AttendanceHistoryBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AttendanceHistoryViewModel>().loadClasses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AttendanceHistoryViewModel>();
    final errorMessage = context.select<AttendanceHistoryViewModel, String?>(
      (value) => value.errorMessage,
    );
    final busy = context.select<AttendanceHistoryViewModel, bool>(
      (value) => value.busy,
    );
    final loadingClasses = context.select<AttendanceHistoryViewModel, bool>(
      (value) => value.loadingClasses,
    );
    final hasClasses = context.select<AttendanceHistoryViewModel, bool>(
      (value) => value.classes.isNotEmpty,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Error banner ──
          if (errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            _NoticeBanner(
              icon: Icons.error_outline,
              color: AppColors.statusAbsent,
              background: AppColors.statusAbsentBg,
              message: errorMessage,
              action: TextButton(
                onPressed: busy ? null : () => vm.loadClasses(force: true),
                child: const Text('Tải lại'),
              ),
            ),
          ],
          // ── Loading bar ──
          if (busy) ...[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: const LinearProgressIndicator(minHeight: 4),
            ),
          ],
          // ── Empty state ──
          if (!loadingClasses && !hasClasses && errorMessage == null)
            const _EmptyState(
              icon: Icons.class_outlined,
              message: 'Chưa có lớp được phân công cho tài khoản này.',
            ),
          // ── Class selector ──
          if (hasClasses) ...[
            const SizedBox(height: AppSpacing.md),
            const ClassSelector(),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({
    required this.icon,
    required this.color,
    required this.background,
    required this.message,
    required this.action,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String message;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(color: color, fontSize: 13)),
          ),
          action,
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: AppSpacing.md),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: AppColors.textTertiary),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
