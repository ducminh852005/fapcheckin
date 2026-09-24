import 'package:flutter/material.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';
import 'package:fapcheckin/views/teacher/report/report_colors.dart';

class RegulatoryNotice extends StatelessWidget {
  const RegulatoryNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, ReportColors.warningBackground],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: [
          // Content
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: AppColors.statusAbsentBg,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: const Icon(
                    Icons.policy,
                    color: AppColors.statusAbsent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quy chế đào tạo FPT University (QĐ số 868/QĐ-ĐHFPT):',
                        style: AppTextStyles.labelMd,
                      ),
                      const SizedBox(height: 2),
                      RichText(
                        text: TextSpan(
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          children: [
                            const TextSpan(text: 'Sinh viên vắng '),
                            TextSpan(
                              text: 'từ slot thứ 7 trở đi',
                              style: AppTextStyles.bodySm.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(
                              text: ' (vượt quá 20% tổng số 30 slot học quy định) sẽ tự động bị hệ thống FAP gán trạng thái ',
                            ),
                            TextSpan(
                              text: 'NOT QUALIFIED (Cấm thi cuối kỳ)',
                              style: AppTextStyles.code.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.statusAbsent,
                              ),
                            ),
                            const TextSpan(
                              text: '. Giảng viên cần xuất dữ liệu trước buổi 28 để phòng Đào tạo kịp thời công bố danh sách chính thức.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBtn(
                'Xem quy chế FAP 2025',
                ReportColors.background,
                ReportColors.text,
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildBtn(
                'Xác nhận số liệu kỳ này',
                ReportColors.primary,
                Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBtn(String label, Color bgColor, Color textColor) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelSm.copyWith(color: textColor),
          ),
        ),
      ),
    );
  }
}
