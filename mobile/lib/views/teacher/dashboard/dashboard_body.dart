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

    return Scaffold(
      backgroundColor: DashboardColors.pageBg,
      body: RefreshIndicator(
        color: DashboardColors.orangePrimary,
        onRefresh: dashboardVm.loadClasses,
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
                          // 1. Header
                          DashboardHeader(),
                          SizedBox(height: 18),

                          if (dashboardVm.errorMessage != null)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    const Icon(Icons.wifi_off),
                                    const Text(
                                      'Không tải được dữ liệu. Kiểm tra kết nối mạng và thử lại.',
                                    ),
                                    Text(dashboardVm.errorMessage!),
                                    TextButton(
                                      onPressed: dashboardVm.loadClasses,
                                      child: const Text('Thử lại'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (dashboardVm.status == ViewStatus.success &&
                              dashboardVm.classes.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('Chưa có lớp được phân công.'),
                            ),
                          if (dashboardVm.status == ViewStatus.success ||
                              dashboardVm.classes.isNotEmpty) ...[
                            // 2. Ca đang diễn ra
                            ActiveSessionCard(),
                            SizedBox(height: 24),

                            // 3. Tổng quan tuần này
                            WeeklyOverviewCards(),
                            SizedBox(height: 24),

                            // 4. Ca dạy kế tiếp
                            const UpcomingSessionsList(),
                          ],
                          SizedBox(height: context.isMobile ? 108 : 36),
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
