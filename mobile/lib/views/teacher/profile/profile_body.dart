import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin_core/responsive/breakpoints.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/dashboard_viewmodel.dart';
import 'profile_colors.dart';
import 'components/profile_header.dart';
import 'components/profile_hero_card.dart';
import 'components/profile_account_card.dart';
import 'components/profile_settings_card.dart';
import 'components/profile_logout_button.dart';

/// Màn hình Hồ sơ giảng viên (Profile):
/// 1. Header (TÀI KHOẢN GIẢNG VIÊN, Hồ sơ, icon Edit)
/// 2. Thẻ Dark Navy Hero: Avatar viết tắt "NM", họ tên, chức vụ, bộ môn, 3 chỉ số lớp - SV - chuyên cần
/// 3. Thẻ "Tài khoản": Thông tin cá nhân, Thông tin công tác, Tài khoản & Bảo mật
/// 4. Thẻ "Cài đặt": Giao diện (Sáng), Thông báo (Bật)
/// 5. Nút "Đăng xuất"
/// 6. Ghi chú "Phiên bản 1.0.0"
class ProfileBody extends StatelessWidget {
  const ProfileBody({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final dashboardVm = context.watch<DashboardViewModel>();
    final horizontalPadding = context.isMobile ? 18.0 : context.pagePadding;

    // Lấy thông tin giảng viên từ phiên đăng nhập hoặc mặc định theo mockup
    final teacherUser = authVm.session?.user;
    final fullName = (teacherUser?.fullName.isNotEmpty ?? false)
        ? teacherUser!.fullName
        : 'Nguyễn Thị Mai';

    final initials = _extractInitials(fullName);
    final classCount = dashboardVm.classes.isNotEmpty
        ? dashboardVm.classes.length
        : 6;
    final studentCount = dashboardVm.totalStudents > 0
        ? dashboardVm.totalStudents
        : 120;
    final attendanceRate = dashboardVm.avgAttendance > 0
        ? '${(dashboardVm.avgAttendance * 100).toStringAsFixed(1).replaceAll('.', ',')}%'
        : '94,1%';

    return Scaffold(
      backgroundColor: ProfileColors.pageBg,
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          context.isMobile ? 16.0 : 24.0,
          horizontalPadding,
          context.isMobile ? 32.0 : 40.0,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header
                ProfileHeader(
                  onEdit: () => dashboardVm.navigate('thong-tin-ca-nhan'),
                ),
                const SizedBox(height: 16),

                // 2. Thẻ Hero Dark Navy
                ProfileHeroCard(
                  fullName: fullName,
                  initials: initials,
                  classCount: classCount,
                  studentCount: studentCount,
                  attendanceRate: attendanceRate,
                ),
                const SizedBox(height: 16),

                // 3. Nhóm mục Tài khoản
                ProfileAccountCard(
                  onPersonalInfoTap: () => dashboardVm.navigate('thong-tin-ca-nhan'),
                  onWorkInfoTap: () => dashboardVm.navigate('thong-tin-cong-tac'),
                  onSecurityTap: () => _showDetailSnackbar(context, 'Tài khoản & Bảo mật'),
                ),
                const SizedBox(height: 16),

                // 4. Nhóm mục Cài đặt
                ProfileSettingsCard(
                  onThemeTap: () => _showDetailSnackbar(context, 'Cài đặt giao diện'),
                  onNotificationsTap: () => _showDetailSnackbar(context, 'Cài đặt thông báo'),
                ),
                const SizedBox(height: 18),

                // 5. Nút Đăng xuất
                ProfileLogoutButton(
                  onLogout: () => _confirmSignOut(context, authVm),
                ),
                const SizedBox(height: 16),

                // 6. Phiên bản ứng dụng
                const Center(
                  child: Text(
                    'Phiên bản 1.0.0',
                    style: TextStyle(
                      fontSize: 11,
                      color: ProfileColors.textSubtle,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _extractInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'NM';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  void _showDetailSnackbar(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title đang được phát triển'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, AuthViewModel authVm) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản giảng viên?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ProfileColors.logoutRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop(true);
              authVm.signOut();
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}
