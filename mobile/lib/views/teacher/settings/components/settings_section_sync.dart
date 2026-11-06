import 'package:flutter/material.dart';
import '../../../../core/widgets/app_toast.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin_core/constants/app_colors.dart';
import 'package:fapcheckin_core/constants/app_spacing.dart';
import 'package:fapcheckin_core/constants/app_text_styles.dart';
import 'package:fapcheckin_core/result/api_result.dart';
import 'package:fapcheckin_core/models/sync_result_model.dart';
import '../../../../viewmodels/dashboard_viewmodel.dart';

class SettingsSectionSync extends StatefulWidget {
  const SettingsSectionSync({super.key});

  @override
  State<SettingsSectionSync> createState() => _SettingsSectionSyncState();
}

class _SettingsSectionSyncState extends State<SettingsSectionSync> {
  bool _autoPush = true;
  bool _leaveApp = true;
  bool _syncing = false;
  String? _lastSyncMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.statusManualBg,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: Icon(
                      Icons.cloud_sync,
                      color: AppColors.statusManual,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đồng bộ Cổng Đào tạo FAP',
                        style: AppTextStyles.headlineMd,
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tích hợp và ghi điểm danh trực tiếp vào cơ sở dữ liệu học vụ tập trung',
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.statusPresentBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.statusPresent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'API FPT Academic Cloud v2.4 (Ping: 18ms)',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.statusPresent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),

          // Manual Sync Button
          ElevatedButton.icon(
            onPressed: _syncing
                ? null
                : () async {
                    setState(() {
                      _syncing = true;
                      _lastSyncMessage = null;
                    });
                    final dashVm = context.read<DashboardViewModel>();
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
                    setState(() {
                      _syncing = false;
                      _lastSyncMessage = msg;
                    });
                    showAppToast(
                      context,
                      message: msg,
                      type: result is ApiSuccess<SyncResult>
                          ? AppToastType.success
                          : AppToastType.error,
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusManual,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            icon: _syncing
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(Icons.cloud_upload_outlined, size: 18),
            label: Text(
              _syncing ? 'Đang đồng bộ...' : 'Đồng bộ ngay lên FAP',
              style: AppTextStyles.labelMd.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_lastSyncMessage != null) ...[
            SizedBox(height: 8),
            Text(
              _lastSyncMessage!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],

          SizedBox(height: AppSpacing.lg),

          // Sync Details Grid
          Row(
            children: [
              Expanded(
                child: _buildDetailCard(
                  'Cơ sở (Campus)',
                  'FPT Hòa Lạc (HL)',
                  'DB Node: HL-PRD-01',
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildDetailCard(
                  'Kỳ học Hiện tại',
                  'Fall 2024 (FA24)',
                  'Tuần đào tạo: 08 / 10',
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildDetailCard(
                  'Lần đồng bộ cuối',
                  '10 phút trước',
                  '14:45:12 - OK',
                  isHighlight: true,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),

          // Toggles
          _buildToggleItem(
            icon: Icons.publish,
            iconColor: AppColors.statusManual,
            iconBg: AppColors.statusManualBg,
            title: 'Tự động đẩy kết quả điểm danh lên hệ thống FAP chính thức',
            desc: 'Dữ liệu vắng/có mặt tự động chuyển trạng thái FAP sau khi kết thúc khung giờ học 15 phút mà không cần ấn tay.',
            value: _autoPush,
            onChanged: (v) => setState(() => _autoPush = v),
          ),
          SizedBox(height: AppSpacing.sm),
          _buildToggleItem(
            icon: Icons.approval,
            iconColor: AppColors.secondary,
            iconBg: AppColors.secondaryContainer,
            title: 'Cho phép sinh viên nộp đơn xin phép vắng online',
            desc: 'Hiển thị nút xin nghỉ kèm minh chứng bệnh viện/sự cố trước giờ điểm danh 60 phút để giảng viên duyệt.',
            value: _leaveApp,
            onChanged: (v) => setState(() => _leaveApp = v),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(
    String title,
    String mainText,
    String subText, {
    bool isHighlight = false,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            mainText,
            style: AppTextStyles.headlineSm.copyWith(
              color: isHighlight
                  ? AppColors.statusPresent
                  : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            subText,
            style: AppTextStyles.code.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String desc,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelMd.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  desc,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.onPrimary,
            activeTrackColor: AppColors.primaryContainer,
            inactiveThumbColor: AppColors.surface,
            inactiveTrackColor: AppColors.surfaceMuted,
          ),
        ],
      ),
    );
  }
}
