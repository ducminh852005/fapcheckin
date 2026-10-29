import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../viewmodels/dashboard_viewmodel.dart';
import '../dashboard_colors.dart';

/// Mục "TỔNG QUAN LỚP HỌC" gồm 2 thẻ chỉ số: Lớp phụ trách và Tỉ lệ Chuyên cần TB.
class WeeklyOverviewCards extends StatelessWidget {
  const WeeklyOverviewCards({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardVm = context.watch<DashboardViewModel>();

    // Số lớp & số sinh viên thực tế (hoặc fallback theo mockup)
    final classCount = dashboardVm.classes.isNotEmpty
        ? dashboardVm.classes.length
        : 0;
    final studentCount = dashboardVm.totalStudents > 0
        ? dashboardVm.totalStudents
        : 0;

    // Tỉ lệ chuyên cần
    final attendanceRate = dashboardVm.avgAttendance > 0
        ? '${(dashboardVm.avgAttendance * 100).toStringAsFixed(1)}%'
        : '—';

    // Giờ cập nhật hiện tại (format HH:mm)
    final now = DateTime.now();
    final updateTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề: TỔNG QUAN LỚP HỌC + Cập nhật 09:41
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: Text(
                'TỔNG QUAN LỚP HỌC',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: DashboardColors.textMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Lúc $updateTime',
              style: const TextStyle(
                color: DashboardColors.textSubtle,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 2 thẻ chỉ số thống kê
        Row(
          children: [
            // Thẻ 1: Lớp phụ trách
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: DashboardColors.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: DashboardColors.cardBorder,
                    width: 1,
                  ),
                  boxShadow: DashboardColors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lớp phụ trách',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: DashboardColors.textMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '$classCount',
                                  style: const TextStyle(
                                    color: DashboardColors.textDark,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'lớp',
                                  style: TextStyle(
                                    color: DashboardColors.textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '$studentCount SV',
                            style: const TextStyle(
                              color: DashboardColors.textSubtle,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Thẻ 2: Chuyên cần TB
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: DashboardColors.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: DashboardColors.cardBorder,
                    width: 1,
                  ),
                  boxShadow: DashboardColors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          child: Text(
                            'Chuyên cần TB',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: DashboardColors.textMuted,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Badge tăng trưởng xanh lá +2.3%
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: DashboardColors.statusGreenBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Lịch sử',
                            style: TextStyle(
                              color: DashboardColors.statusGreen,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        attendanceRate,
                        style: const TextStyle(
                          color: DashboardColors.orangePrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
