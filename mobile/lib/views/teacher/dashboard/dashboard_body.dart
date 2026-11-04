import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin_core/responsive/breakpoints.dart';

import '../../../viewmodels/dashboard_viewmodel.dart';
import '../../../viewmodels/live_session_viewmodel.dart' show ViewStatus;
import 'dashboard_colors.dart';
import 'components/dashboard_header.dart';
import 'components/active_session_card.dart';
import 'components/weekly_overview_cards.dart';
import 'components/upcoming_sessions_list.dart';

/// Màn hình Dashboard (Tổng quan) sau khi giảng viên đăng nhập thành công.
/// Tổ chức các khối giao diện:
/// 1. Header (Avatar, Chào hỏi, Khoa/Kỳ, Chuông thông báo)
/// 2. Ca đang diễn ra (ActiveSessionCard - Tiến độ & Thao tác nhanh)
/// 3. Tổng quan tuần này (WeeklyOverviewCards - Lớp phụ trách & Chuyên cần)
/// 4. Ca dạy kế tiếp (UpcomingSessionsList - Danh sách ca học tiếp theo)
class DashboardBody extends StatefulWidget {
  const DashboardBody({super.key});

  @override
  State<DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<DashboardBody> {
  @override
  Widget build(BuildContext context) {
    final dashboardVm = context.watch<DashboardViewModel>();
    final horizontalPadding = context.isMobile ? 18.0 : context.pagePadding;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Lớp nền Gradient nhẹ ở góc trên (Hiệu ứng ánh sáng ấm áp)
          if (!isDark)
            Container(
              height: 320,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: DashboardColors.headerGradient,
              ),
            ),

          // Nội dung chính
          SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PHẦN CỐ ĐỊNH (HEADER + CA ĐANG DIỄN RA + TỔNG QUAN TUẦN NÀY)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        14,
                        horizontalPadding,
                        12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (dashboardVm.isLoading)
                            const LinearProgressIndicator(),
                          // 1. Header
                          const DashboardHeader(),
                          const SizedBox(height: 16),

                          if (dashboardVm.status == ViewStatus.success ||
                              dashboardVm.classes.isNotEmpty) ...[
                            // 2. Ca đang diễn ra (nếu có)
                            const ActiveSessionCard(),

                            // 3. Tổng quan tuần này
                            const WeeklyOverviewCards(),
                          ],
                        ],
                      ),
                    ),

                    // PHẦN CUỘN (CHỈ DANH SÁCH CA DẠY KẾ TIẾP PHÍA DƯỚI)
                    Expanded(
                      child: RefreshIndicator(
                        color: DashboardColors.orangePrimary,
                        onRefresh: dashboardVm.loadClasses,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            4,
                            horizontalPadding,
                            context.isMobile ? 108 : 36,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (dashboardVm.errorMessage != null)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: dashboardVm.errorCode == 'FORBIDDEN' ||
                                            dashboardVm.errorMessage!.contains('quyền')
                                        ? const Color(0xFFFEF2F2)
                                        : DashboardColors.cardBg,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: dashboardVm.errorCode == 'FORBIDDEN' ||
                                              dashboardVm.errorMessage!.contains('quyền')
                                          ? const Color(0xFFFECACA)
                                          : DashboardColors.cardBorder,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        dashboardVm.errorCode == 'FORBIDDEN' ||
                                                dashboardVm.errorMessage!.contains('quyền')
                                            ? Icons.lock_person_outlined
                                            : Icons.wifi_off_rounded,
                                        size: 40,
                                        color: dashboardVm.errorCode == 'FORBIDDEN' ||
                                                dashboardVm.errorMessage!.contains('quyền')
                                            ? const Color(0xFFDC2626)
                                            : DashboardColors.orangePrimary,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        dashboardVm.errorCode == 'FORBIDDEN' ||
                                                dashboardVm.errorMessage!.contains('quyền')
                                            ? 'Chưa được cấp quyền giảng viên'
                                            : 'Không tải được dữ liệu',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: DashboardColors.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        dashboardVm.errorMessage!,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: dashboardVm.errorCode == 'FORBIDDEN' ||
                                                  dashboardVm.errorMessage!.contains('quyền')
                                              ? const Color(0xFFB91C1C)
                                              : DashboardColors.textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      ElevatedButton.icon(
                                        onPressed: dashboardVm.loadClasses,
                                        icon: const Icon(Icons.refresh, size: 18),
                                        label: const Text('Thử lại'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: DashboardColors.orangePrimary,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (dashboardVm.status == ViewStatus.success &&
                                  dashboardVm.classes.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('Chưa có lớp được phân công.'),
                                ),
                              if (dashboardVm.status == ViewStatus.success ||
                                  dashboardVm.classes.isNotEmpty)
                                // 4. Ca dạy kế tiếp
                                const UpcomingSessionsList(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
