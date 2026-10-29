import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin_core/responsive/breakpoints.dart';

import '../../../viewmodels/dashboard_viewmodel.dart';
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
class DashboardBody extends StatelessWidget {
  const DashboardBody({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardVm = context.watch<DashboardViewModel>();
    final horizontalPadding = context.isMobile ? 18.0 : context.pagePadding;

    return Scaffold(
      backgroundColor: DashboardColors.pageBg,
      body: RefreshIndicator(
        color: DashboardColors.orangePrimary,
        onRefresh: () async {
          await dashboardVm.loadClasses();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Stack(
            children: [
              // Lớp nền Gradient nhẹ ở góc trên (Hiệu ứng ánh sáng ấm áp)
              Container(
                height: 220,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: DashboardColors.headerGradient,
                ),
              ),

              // Nội dung chính
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 14,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (dashboardVm.isLoading)
                            const LinearProgressIndicator(),
                          if (dashboardVm.errorMessage != null)
                            Text(dashboardVm.errorMessage!),
                          if (!dashboardVm.isLoading &&
                              dashboardVm.classes.isEmpty)
                            const Text('Chưa có lớp được phân công.'),
                          // 1. Header
                          DashboardHeader(),
                          SizedBox(height: 18),

                          // 2. Ca đang diễn ra
                          ActiveSessionCard(),
                          SizedBox(height: 24),

                          // 3. Tổng quan tuần này
                          WeeklyOverviewCards(),
                          SizedBox(height: 24),

                          // 4. Ca dạy kế tiếp
                          UpcomingSessionsList(),
                          SizedBox(height: 36),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
