import 'package:flutter/material.dart';
import 'package:fapcheckin_core/constants/app_colors.dart';
import 'package:fapcheckin_core/constants/app_spacing.dart';
import 'package:fapcheckin_core/constants/app_text_styles.dart';
import '../report_colors.dart';
import 'package:fapcheckin_core/models/report_model.dart';

class ReportKpis extends StatelessWidget {
  final ReportData data;
  const ReportKpis({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 4;
        if (constraints.maxWidth < 700) {
          crossAxisCount = 1;
        } else if (constraints.maxWidth < 1200) {
          crossAxisCount = 2;
        }

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          childAspectRatio: constraints.maxWidth >= 1200 ? 2.0 : 1.85,
          children: [
            _buildKpiCard(
              title: 'Tỷ lệ điểm danh TB',
              value: '${(data.kpis.attendanceRate * 100).toStringAsFixed(1)}%',
              icon: Icons.check_circle_outline,
              iconColor: AppColors.statusPresent,
              iconBg: AppColors.statusPresentBg,
              bottomLeft: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 16,
                    color: AppColors.statusPresent,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${data.closedSessionCount} phiên đã kết thúc',
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.statusPresent,
                    ),
                  ),
                ],
              ),
              badgeText: 'Tốt',
              badgeColor: AppColors.statusPresent,
              badgeBg: AppColors.statusPresentBg,
            ),
            _buildKpiCard(
              title: 'Tổng số lượt điểm danh',
              value: '${data.kpis.totalCheckins}',
              icon: Icons.qr_code_scanner,
              iconColor: ReportColors.primary,
              iconBg: ReportColors.primaryLight,
              bottomLeft: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tổng lượt có mặt: ',
                    style: AppTextStyles.caption.copyWith(
                      color: ReportColors.muted,
                    ),
                  ),
                  Text(
                    '${data.kpis.totalCheckins}',
                    style: AppTextStyles.code.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              bottomRight: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lớp phụ trách: ',
                    style: AppTextStyles.caption.copyWith(
                      color: ReportColors.muted,
                    ),
                  ),
                  Text(
                    '${data.classCount}',
                    style: AppTextStyles.code.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            _buildKpiCard(
              title: 'Nguy cơ cấm thi (>20%)',
              value: '${data.kpis.atRiskCount}',
              valueSuffix: '/ ${data.kpis.studentCount} sinh viên',
              valueColor: AppColors.statusAbsent,
              icon: Icons.warning_amber_rounded,
              iconColor: AppColors.statusAbsent,
              iconBg: AppColors.statusAbsentBg,
              bottomLeft: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.statusAbsent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Theo dữ liệu phiên đã đóng',
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.statusAbsent,
                    ),
                  ),
                ],
              ),
              badgeText: 'Báo động',
              badgeColor: AppColors.statusAbsent,
              badgeBg: AppColors.statusAbsentBg,
            ),
            _buildKpiCard(
              title: 'Tỷ lệ đi trễ TB',
              value: '${(data.kpis.lateRate * 100).toStringAsFixed(1)}%',
              valueColor: AppColors.statusLate,
              icon: Icons.schedule,
              iconColor: AppColors.statusLate,
              iconBg: AppColors.statusLateBg,
              bottomLeft: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tổng số sinh viên: ',
                    style: AppTextStyles.caption.copyWith(
                      color: ReportColors.muted,
                    ),
                  ),
                  Text(
                    '${data.kpis.studentCount}',
                    style: AppTextStyles.caption.copyWith(
                      color: ReportColors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              badgeText: 'Chấp nhận',
              badgeColor: AppColors.statusLate,
              badgeBg: AppColors.statusLateBg,
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    String? valueSuffix,
    Color? valueColor,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required Widget bottomLeft,
    Widget? bottomRight,
    String? badgeText,
    Color? badgeColor,
    Color? badgeBg,
  }) {
    return Container(
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
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.toUpperCase(),
                          style: AppTextStyles.labelSm.copyWith(
                            color: ReportColors.muted,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              value,
                              style: AppTextStyles.headlineLg.copyWith(
                                color: valueColor ?? ReportColors.text,
                              ),
                            ),
                            if (valueSuffix != null) ...[
                              SizedBox(width: 4),
                              Text(valueSuffix, style: AppTextStyles.caption),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(icon, color: iconColor, size: 19),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: ReportColors.background,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(AppSpacing.radiusXl),
                bottomRight: Radius.circular(AppSpacing.radiusXl),
              ),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                bottomLeft,
                ?bottomRight,
                if (badgeText != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                    ),
                    child: Text(
                      badgeText,
                      style: AppTextStyles.labelSm.copyWith(color: badgeColor),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
