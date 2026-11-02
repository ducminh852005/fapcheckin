import 'package:flutter/material.dart';
import 'package:fapcheckin_core/constants/app_colors.dart';
import 'package:fapcheckin_core/constants/app_spacing.dart';
import 'package:fapcheckin_core/constants/app_text_styles.dart';

class SettingsSectionAlerts extends StatefulWidget {
  const SettingsSectionAlerts({super.key});

  @override
  State<SettingsSectionAlerts> createState() => _SettingsSectionAlertsState();
}

class _SettingsSectionAlertsState extends State<SettingsSectionAlerts> {
  bool _emailAlert = true;
  String _audioSound = 'soft-beep';
  bool _flashAvatar = true;

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
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.statusLateBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Icon(
                  Icons.forward_to_inbox,
                  color: AppColors.statusLate,
                  size: 24,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cảnh báo Học vụ & Âm thanh Thông báo',
                      style: AppTextStyles.headlineMd,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Kênh nhắc nhở tự động cho sinh viên có nguy cơ vượt quá 20% vắng',
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),

          // 15% Absenteeism Warning
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceBright,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.statusAbsentBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.warning,
                        size: 18,
                        color: AppColors.statusAbsent,
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tự động gửi email cảnh báo khi vắng chạm ngưỡng 15%',
                            style: AppTextStyles.labelMd.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Gửi thông báo tới email sinh viên (@fpt.edu.vn) và phụ huynh (nếu đăng ký) trước khi bị cấm thi (20%).',
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Switch(
                      value: _emailAlert,
                      onChanged: (v) => setState(() => _emailAlert = v),
                      activeThumbColor: AppColors.onPrimary,
                      activeTrackColor: AppColors.primaryContainer,
                      inactiveThumbColor: AppColors.surface,
                      inactiveTrackColor: AppColors.surfaceMuted,
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
                // Template Preview
                Container(
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'MẪU EMAIL CẢNH BÁO CHUẨN',
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          InkWell(
                            onTap: () {},
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Sửa Template',
                                  style: AppTextStyles.labelSm.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Container(
                        padding: EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '[FPT Academic Portal] Cảnh báo nghỉ học môn {SUBJECT_CODE}: Sinh viên {STUDENT_NAME} ({ROLL_NUMBER}) đã vắng {ABSENT_COUNT}/{TOTAL_SLOTS} buổi ({ABSENT_PERCENTAGE}%). Nguy cơ cấm thi nếu tiếp tục vắng!',
                          style: AppTextStyles.code.copyWith(
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md),

          // Audio and Flash Feedback
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Audio
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBright,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Âm thanh khi Check-in thành công',
                        style: AppTextStyles.labelMd.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Phát âm thanh xác thực qua loa máy tính giảng viên để nhận biết học sinh đã ghi nhận.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: AppSpacing.md),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _audioSound,
                            isExpanded: true,
                            icon: Icon(
                              Icons.expand_more,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'soft-beep',
                                child: Text(
                                  'Âm bíp nhẹ (Soft Beep) - Khuyên dùng',
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'chime',
                                child: Text('Tiếng chuông ngân (Chime)'),
                              ),
                              DropdownMenuItem(
                                value: 'bell',
                                child: Text('Chuông nhỏ (Bell)'),
                              ),
                              DropdownMenuItem(
                                value: 'mute',
                                child: Text('Tắt âm thanh (Im lặng hoàn toàn)'),
                              ),
                            ],
                            onChanged: (v) => setState(() => _audioSound = v!),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              // Flash Avatar
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBright,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hiệu ứng thẻ ảnh sinh viên',
                        style: AppTextStyles.labelMd.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Hiện pop-up khuôn mặt sinh viên trong 1.5 giây khi quét mã thành công.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: AppSpacing.md),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Bật Flash Avatar'),
                            Switch(
                              value: _flashAvatar,
                              onChanged: (v) =>
                                  setState(() => _flashAvatar = v),
                              activeThumbColor: AppColors.onPrimary,
                              activeTrackColor: AppColors.primaryContainer,
                              inactiveThumbColor: AppColors.surface,
                              inactiveTrackColor: AppColors.surfaceMuted,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
