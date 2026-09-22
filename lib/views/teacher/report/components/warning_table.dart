import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';
import 'package:fapcheckin/core/network/api_result.dart';
import 'package:fapcheckin/data/models/sync_result_model.dart';
import 'package:fapcheckin/viewmodels/dashboard_viewmodel.dart';

class WarningTable extends StatefulWidget {
  const WarningTable({super.key});

  @override
  State<WarningTable> createState() => _WarningTableState();
}

class _WarningTableState extends State<WarningTable> {
  bool _syncing = false;

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
                      'Cảnh báo vắng học',
                      style: AppTextStyles.headlineSm,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sinh viên chạm ngưỡng >15% và vượt mốc >20%',
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
                  foregroundColor: AppColors.primary,
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
              color: AppColors.surfaceMuted,
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
                          AppColors.textPrimary,
                          iconColor: AppColors.primary,
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
                      color: AppColors.surfaceMuted,
                    ),
                    children: [
                      _headerCell('Sinh viên'),
                      _headerCell('Lớp'),
                      _headerCell('Vắng'),
                      _headerCell('Trạng thái'),
                      _headerCell('Thao tác'),
                    ],
                  ),
                  // Placeholder row
                  TableRow(
                    children: [
                      _dataCell(
                        const Text(
                          'Không có dữ liệu cảnh báo',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        span: 5,
                      ),
                      _dataCell(const SizedBox.shrink()),
                      _dataCell(const SizedBox.shrink()),
                      _dataCell(const SizedBox.shrink()),
                      _dataCell(const SizedBox.shrink()),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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

  Widget _dataCell(Widget child, {int span = 1}) {
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor ?? fgColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(color: fgColor),
          ),
        ],
      ),
    );
  }
}
