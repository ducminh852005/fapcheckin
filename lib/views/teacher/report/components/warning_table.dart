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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cảnh báo vắng quá quy định',
                      style: AppTextStyles.headlineSm,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sinh viên có tỷ lệ vắng trên 15% trong các phiên đã kết thúc',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.filter_list, size: 16),
                label: const Text('Lọc nâng cao'),
                style: TextButton.styleFrom(
                  foregroundColor: ReportColors.primary,
                  textStyle: AppTextStyles.labelSm,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Action Bar
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
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
                  onTap: _syncing
                      ? null
                      : () async {
                          setState(() => _syncing = true);
                          final dashVm = context.read<DashboardViewModel>();
                          final messenger = ScaffoldMessenger.of(context);
                          final result = await dashVm.syncToFap();
                          if (!mounted) return;
                          String msg;
                          if (result is ApiSuccess<SyncResult>) {
                            msg = result.data.message.isNotEmpty
                                ? result.data.message
                                : 'Đồng bộ thành công ${result.data.syncedCount} bản ghi.';
                          } else if (result is ApiFailure<SyncResult>) {
                            msg = 'Lỗi: ${result.error.message}';
                          } else {
                            msg = 'Đồng bộ hoàn tất.';
                          }
                          setState(() => _syncing = false);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(msg),
                              backgroundColor: result is ApiSuccess<SyncResult>
                                  ? AppColors.statusPresent
                                  : AppColors.statusAbsent,
                            ),
                          );
                        },
                  child: _syncing
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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
          ),
          const SizedBox(height: AppSpacing.md),

          // Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 600),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(3), // Sinh viên
                  1: FlexColumnWidth(1), // Lớp
                  2: FlexColumnWidth(1), // Vắng
                  3: FlexColumnWidth(1.5), // Trạng thái
                  4: FlexColumnWidth(1.2), // Thao tác
                },
                children: [
                  // Header Row
                  TableRow(
                    decoration: const BoxDecoration(
                      color: ReportColors.background,
                    ),
                    children: [
                      _headerCell('Sinh viên'),
                      _headerCell('Lớp'),
                      _headerCell('Vắng'),
                      _headerCell('Trạng thái'),
                      _headerCell('Thao tác'),
                    ],
                  ),
                  if (widget.data.warnings.isEmpty)
                    TableRow(
                      children: [
                        _dataCell(const Text('Không có dữ liệu cảnh báo')),
                        _dataCell(const SizedBox.shrink()),
                        _dataCell(const SizedBox.shrink()),
                        _dataCell(const SizedBox.shrink()),
                        _dataCell(const SizedBox.shrink()),
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
                              Text(
                                warning.rollNumber,
                                style: AppTextStyles.caption,
                              ),
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
                        _dataCell(const SizedBox.shrink()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.data.warnings.length > _pageSize) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildPagination(),
          ],
        ],
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
              icon: const Icon(Icons.chevron_left, size: 20),
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
              icon: const Icon(Icons.chevron_right, size: 20),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ],
    );
  }

  Widget _headerCell(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor ?? fgColor),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.labelSm.copyWith(color: fgColor)),
        ],
      ),
    );
  }
}
