import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';
import 'package:fapcheckin/views/teacher/report/report_colors.dart';
import 'package:fapcheckin/data/models/report_model.dart';
import 'package:fapcheckin/core/network/api_result.dart';
import 'package:fapcheckin/data/models/sync_result_model.dart';
import 'package:fapcheckin/viewmodels/dashboard_viewmodel.dart';

class WarningTable extends StatefulWidget {
  final ReportData data;
  const WarningTable({super.key, required this.data});

  @override
  State<WarningTable> createState() => _WarningTableState();
}

class _WarningTableState extends State<WarningTable> {
  bool _syncing = false;
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 680;

        return Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: AppSpacing.md),
              _buildActionBar(),
              SizedBox(height: AppSpacing.md),
              if (widget.data.warnings.isEmpty)
                _buildEmptyState()
              else if (compact)
                _buildWarningCards()
              else
                _buildTable(),
              if (widget.data.warnings.length > _pageSize) ...[
                SizedBox(height: AppSpacing.sm),
                _buildPagination(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 360),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cảnh báo vắng quá quy định',
                style: AppTextStyles.headlineSm,
              ),
              SizedBox(height: 2),
              Text(
                'Sinh viên có tỷ lệ vắng trên 15% trong các phiên đã kết thúc',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: () {},
          icon: Icon(Icons.filter_list, size: 16),
          label: Text('Lọc nâng cao'),
          style: TextButton.styleFrom(
            foregroundColor: ReportColors.primary,
            textStyle: AppTextStyles.labelSm,
          ),
        ),
      ],
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: ReportColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          _buildActionBtn(
            'Gửi cảnh báo Email FPT',
            Icons.mail,
            AppColors.statusAbsent,
            AppColors.onError,
          ),
          GestureDetector(
            onTap: _syncing ? null : _syncToFap,
            child: _syncing
                ? Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 6),
                        Text('Đang đồng bộ...'),
                      ],
                    ),
                  )
                : _buildActionBtn(
                    'Đồng bộ Cổng Khảo Thí',
                    Icons.sync,
                    AppColors.surface,
                    ReportColors.text,
                    iconColor: ReportColors.primary,
                  ),
          ),
        ],
      ),
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
              child: _WarningCard(warning: warning),
            ),
          )
          .toList(),
    );
  }

  Widget _buildTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: 640),
        child: Table(
          columnWidths: {
            0: FlexColumnWidth(3),
            1: FlexColumnWidth(1.35),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1.45),
            4: FlexColumnWidth(1),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: ReportColors.background),
              children: [
                _headerCell('Sinh viên'),
                _headerCell('Lớp'),
                _headerCell('Vắng'),
                _headerCell('Trạng thái'),
                _headerCell('Thao tác'),
              ],
            ),
            ..._visibleWarnings.map(
              (warning) => TableRow(
                children: [
                  _dataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(warning.fullName),
                        Text(warning.rollNumber, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  _dataCell(Text(warning.classCode)),
                  _dataCell(
                    Text(
                      '${warning.absent}/${warning.total}\n'
                      '${(warning.absenceRate * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: warning.absenceRate > .2
                            ? AppColors.statusAbsent
                            : AppColors.statusLate,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _dataCell(
                    Text(
                      warning.status,
                      style: TextStyle(
                        color: warning.absenceRate > .2
                            ? AppColors.statusAbsent
                            : AppColors.statusLate,
                      ),
                    ),
                  ),
                  _dataCell(SizedBox.shrink()),
                ],
              ),
            ),
          ],
        ),
      ),
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

  Widget _headerCell(String label) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        label,
        style: AppTextStyles.labelSm.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _dataCell(Widget child) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: child,
    );
  }

  Widget _buildActionBtn(
    String label,
    IconData icon,
    Color bgColor,
    Color fgColor, {
    Color? iconColor,
  }) {
    return Container(
      constraints: BoxConstraints(maxWidth: 260),
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor ?? fgColor),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSm.copyWith(color: fgColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  final ReportWarning warning;
  const _WarningCard({required this.warning});

  @override
  Widget build(BuildContext context) {
    final alertColor = warning.absenceRate > .2
        ? AppColors.statusAbsent
        : AppColors.statusLate;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: ReportColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
                      warning.fullName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(warning.rollNumber, style: AppTextStyles.caption),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                '${warning.absent}/${warning.total}',
                style: AppTextStyles.labelSm.copyWith(
                  color: alertColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MetaPill(text: warning.classCode),
              _MetaPill(
                text: '${(warning.absenceRate * 100).toStringAsFixed(1)}%',
                color: alertColor,
              ),
              _MetaPill(text: warning.status, color: alertColor),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String text;
  final Color? color;
  const _MetaPill({required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.caption.copyWith(
          color: color ?? AppColors.textSecondary,
          fontWeight: color == null ? FontWeight.w400 : FontWeight.w600,
        ),
      ),
    );
  }
}
