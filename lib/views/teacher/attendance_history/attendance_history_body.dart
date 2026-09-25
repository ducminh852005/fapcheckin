import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../viewmodels/attendance_history_viewmodel.dart';
import 'components/class_selector.dart';
import 'components/kpi_dashboard.dart';
import 'components/history_table.dart';
import 'components/sessions_tab.dart';

class AttendanceHistoryBody extends StatefulWidget {
  const AttendanceHistoryBody({super.key});
  @override
  State<AttendanceHistoryBody> createState() => _AttendanceHistoryBodyState();
}

class _AttendanceHistoryBodyState extends State<AttendanceHistoryBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AttendanceHistoryViewModel>().loadClasses();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    final hasSummary = context.select<AttendanceHistoryViewModel, bool>(
      (value) => value.summary != null,
    );
    final loadingSummary = context.select<AttendanceHistoryViewModel, bool>(
      (value) => value.loadingSummary,
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
          // ── Tab view ──
          if (hasSummary) ...[
            const SizedBox(height: AppSpacing.md),
            // Tab bar
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primaryContainer,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primaryContainer,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.bar_chart_outlined, size: 18),
                    text: 'Tổng quan',
                  ),
                  Tab(
                    icon: Icon(Icons.list_alt_outlined, size: 18),
                    text: 'Buổi học',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Tab content
            Stack(
              children: [
                _TabContent(
                  controller: _tabController,
                  overviewTab: const Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      KpiDashboard(),
                      SizedBox(height: AppSpacing.md),
                      HistoryTable(),
                    ],
                  ),
                  sessionsTab: const SessionsTab(),
                ),
                if (loadingSummary)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Custom animated tab content that doesn't clip the scrollable body
class _TabContent extends StatefulWidget {
  final TabController controller;
  final Widget overviewTab;
  final Widget sessionsTab;

  const _TabContent({
    required this.controller,
    required this.overviewTab,
    required this.sessionsTab,
  });

  @override
  State<_TabContent> createState() => _TabContentState();
}

class _TabContentState extends State<_TabContent> {
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTabChange);
  }

  void _onTabChange() {
    if (widget.controller.indexIsChanging) return;
    setState(() => _activeIndex = widget.controller.index);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTabChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _activeIndex == 0
          ? KeyedSubtree(
              key: const ValueKey('overview'),
              child: widget.overviewTab,
            )
          : KeyedSubtree(
              key: const ValueKey('sessions'),
              child: widget.sessionsTab,
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
