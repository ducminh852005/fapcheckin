import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin_core/constants/app_colors.dart';
import 'package:fapcheckin_core/constants/app_spacing.dart';
import 'package:fapcheckin_core/constants/app_text_styles.dart';
import '../report_colors.dart';
import 'package:fapcheckin_core/models/report_model.dart';
import 'package:fapcheckin_core/result/api_result.dart';
import 'package:fapcheckin_core/models/sync_result_model.dart';
import '../../../../viewmodels/dashboard_viewmodel.dart';
import '../../../../viewmodels/auth_viewmodel.dart';
import 'package:fapcheckin_core/repositories/request_repository.dart';

class WarningTable extends StatefulWidget {
  final ReportData data;
  const WarningTable({super.key, required this.data});

  @override
  State<WarningTable> createState() => _WarningTableState();
}

class _WarningTableState extends State<WarningTable> {
  bool _syncing = false;
  bool _reportingAll = false;
  final Set<String> _submitting = {};
  final Set<String> _reported = {};
  static const _pageSize = 8;
  int _currentPage = 0;

  List<ReportWarning> get _visibleWarnings {
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, widget.data.warnings.length);
    return widget.data.warnings.sublist(start, end);
  }

  int get _pageCount => (widget.data.warnings.length / _pageSize)
      .ceil()
      .clamp(1, double.infinity)
      .toInt();

  @override
  void didUpdateWidget(covariant WarningTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.warnings.length != widget.data.warnings.length) {
      _currentPage = _currentPage.clamp(0, _pageCount - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA),
        ),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x140F172A),
                  blurRadius: 18,
                  offset: Offset(0, 7),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 14),
          if (widget.data.warnings.isEmpty)
            _buildEmptyState()
          else
            _buildWarningCards(),
          if (widget.data.warnings.length > _pageSize) ...[
            const SizedBox(height: 4),
            _buildPagination(),
          ],
          const SizedBox(height: 12),
          _buildActionBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1F2),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFFD4D8)),
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            size: 19,
            color: Color(0xFFE11D48),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cảnh báo vắng quá quy định',
                style: TextStyle(
                  color: Color(0xFF9F1239),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .5,
                ),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4E6),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  'Vượt ngưỡng >20%',
                  style: TextStyle(
                    color: Color(0xFFBE123C),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Danh sách sinh viên có nguy cơ cấm thi cần lưu ý học vụ',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: _reportingAll ? null : _reportAll,
          icon: _reportingAll
              ? const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_rounded, size: 18),
          label: Text(
            _reportingAll ? 'Đang gửi báo cáo...' : 'Báo cáo tất cả cho Admin',
          ),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(46),
            backgroundColor: const Color(0xFFEA1748),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _syncing ? null : _syncToFap,
          icon: _syncing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync_rounded, size: 18),
          label: Text(
            _syncing ? 'Đang đồng bộ...' : 'Đồng bộ Cổng Khảo Thí',
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
            foregroundColor: const Color(0xFF475569),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _syncToFap() async {
    setState(() => _syncing = true);
    final dashVm = context.read<DashboardViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await dashVm.syncToFap();
    if (!mounted) return;

    final msg = switch (result) {
      ApiSuccess<SyncResult>() =>
        result.data.message.isNotEmpty
            ? result.data.message
            : 'Đồng bộ thành công ${result.data.syncedCount} bản ghi.',
      ApiFailure<SyncResult>() => 'Lỗi: ${result.error.message}',
      _ => 'Đồng bộ hoàn tất.',
    };

    setState(() => _syncing = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: result is ApiSuccess<SyncResult>
            ? AppColors.statusPresent
            : AppColors.statusAbsent,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: ReportColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Text('Không có dữ liệu cảnh báo', style: AppTextStyles.caption),
    );
  }

  Widget _buildWarningCards() {
    return Column(
      children: _visibleWarnings
          .map(
            (warning) => Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: _WarningCard(
                warning: warning,
                action: _reportButton(warning),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildPagination() {
    final firstItem = _currentPage * _pageSize + 1;
    final lastItem = ((_currentPage + 1) * _pageSize).clamp(
      0,
      widget.data.warnings.length,
    );

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        Text(
          '$firstItem-$lastItem / ${widget.data.warnings.length} sinh viên',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Trang trước',
              onPressed: _currentPage == 0
                  ? null
                  : () => setState(() => _currentPage--),
              icon: Icon(Icons.chevron_left, size: 20),
              visualDensity: VisualDensity.compact,
            ),
            Text(
              '${_currentPage + 1} / $_pageCount',
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              tooltip: 'Trang sau',
              onPressed: _currentPage >= _pageCount - 1
                  ? null
                  : () => setState(() => _currentPage++),
              icon: Icon(Icons.chevron_right, size: 20),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _reportAll() async {
    setState(() => _reportingAll = true);
    final exceeded = widget.data.warnings.where((warning) {
      final key = '${warning.classCode}|${warning.rollNumber}';
      return warning.absent > (warning.total * .2).floor() &&
          !_reported.contains(key);
    }).toList();
    var succeeded = 0;
    var failed = 0;
    for (final warning in exceeded) {
      if (!mounted) return;
      if (await _report(warning, showMessage: false)) {
        succeeded++;
      } else {
        failed++;
      }
    }
    if (mounted) {
      setState(() => _reportingAll = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            exceeded.isEmpty
                ? 'Tất cả trường hợp vượt ngưỡng đã được báo cáo.'
                : failed == 0
                    ? 'Đã gửi $succeeded trường hợp vượt ngưỡng cho Admin.'
                    : 'Đã gửi $succeeded trường hợp, $failed trường hợp gửi thất bại.',
          ),
          backgroundColor: failed == 0
              ? AppColors.statusPresent
              : AppColors.statusAbsent,
        ),
      );
    }
  }

  Widget _reportButton(ReportWarning warning) {
    final key = '${warning.classCode}|${warning.rollNumber}';
    final loading = _submitting.contains(key);
    final done = _reported.contains(key);
    final exceeded = warning.absent > (warning.total * .2).floor();
    return IconButton(
      tooltip: done
          ? 'Đã gửi Admin'
          : exceeded
              ? 'Báo cáo sinh viên này cho Admin'
              : 'Sinh viên đang ở mức nguy cơ',
      onPressed: loading || done || !exceeded ? null : () => _report(warning),
      icon: loading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              done ? Icons.check_circle_rounded : Icons.flag_outlined,
              size: 18,
            ),
      color: const Color(0xFFE11D48),
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
    );
  }

  Future<bool> _report(
    ReportWarning warning, {
    bool showMessage = true,
  }) async {
    final session = context.read<AuthViewModel>().session;
    if (session == null) return false;
    final key = '${warning.classCode}|${warning.rollNumber}';
    setState(() => _submitting.add(key));
    final repo = RequestRepository(
      uid: session.token,
      memberCode: session.user.memberCode,
    );
    final result = await repo.submitAbsenceEscalation(
      classCode: warning.classCode,
      subjectName: warning.subjectName,
      studentMemberCode: warning.rollNumber,
      studentName: warning.fullName,
      studentEmail: warning.email,
      absentCount: warning.absent,
      totalSessions: warning.total,
      absenceRate: warning.absenceRate,
    );
    if (!mounted) return false;
    final succeeded = result is ApiSuccess<String>;
    setState(() {
      _submitting.remove(key);
      if (succeeded) _reported.add(key);
    });
    if (showMessage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result is ApiSuccess<String>
                ? 'Đã gửi báo cáo ${warning.rollNumber} cho Admin.'
                : 'Không thể gửi báo cáo: ${(result as ApiFailure<String>).error.message}',
          ),
        ),
      );
    }
    return succeeded;
  }
}

class _WarningCard extends StatelessWidget {
  final ReportWarning warning;
  final Widget action;
  const _WarningCard({required this.warning, required this.action});

  @override
  Widget build(BuildContext context) {
    final exceeded = warning.absenceRate > .2;
    final alertColor = exceeded
        ? const Color(0xFFE11D48)
        : const Color(0xFFD97706);
    final percentage = (warning.absenceRate * 100).toStringAsFixed(1);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF30191F) : const Color(0xFFFFF6F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFFD5D8),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 7,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      warning.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Text(
                        warning.rollNumber,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${warning.classCode} (${warning.subjectName})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: exceeded
                          ? const Color(0xFFFFE4E6)
                          : const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      exceeded ? 'Quá 20%' : 'Nguy cơ',
                      style: TextStyle(
                        color: alertColor,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  action,
                ],
              ),
              Text(
                'Vắng ${warning.absent}/${warning.total} buổi ($percentage%)',
                style: TextStyle(
                  color: alertColor,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
