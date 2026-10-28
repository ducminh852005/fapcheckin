import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin_core/constants/app_palette.dart';
import '../../app/app_router.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/dashboard_viewmodel.dart';

/// Màn hình Loading chuyển tiếp sau khi đăng nhập thành công:
/// 1. Nền trắng với hiệu ứng ánh sáng cam ấm áp ở góc trên bên phải
/// 2. Logo FAP CHECK-IN ở chính giữa màn hình
/// 3. Vòng tròn tải (CircularProgressIndicator) màu cam FPT
/// 4. Dòng chữ thông báo: "Đang khởi động ứng dụng..." & "Vui lòng chờ trong giây lát."
/// 5. Logo Đại học FPT kèm nhãn phiên bản ở chân trang
/// 6. Tự động tải dữ liệu và chuyển mượt sang Trang tổng quan (Trang chủ)
class LoadingScreen extends StatefulWidget {
  final Duration minDuration;

  const LoadingScreen({
    super.key,
    this.minDuration = const Duration(milliseconds: 2000),
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndNavigate();
    });
  }

  Future<void> _initializeAndNavigate() async {
    final authVm = context.read<AuthViewModel>();
    final dashboardVm = context.read<DashboardViewModel>();

    // 1. Nạp hồ sơ Giảng viên từ session đăng nhập
    if (authVm.session != null && dashboardVm.teacherMemberCode.isEmpty) {
      dashboardVm.setTeacherInfo(
        name: authVm.session!.user.displayName,
        email: authVm.session!.user.email,
        memberCode: authVm.session!.user.memberCode,
      );
    }

    // 2. Chờ tải danh sách lớp học song song với hiệu ứng loading mượt mà
    final timer = Future.delayed(widget.minDuration);
    final loadTask = dashboardVm.loadClasses();

    try {
      await Future.wait([timer, loadTask]);
    } catch (_) {
      await timer;
    }

    if (!mounted) return;

    // 3. Chuyển tiếp tới Trang tổng quan (Trang chủ)
    context.go(AppRoutes.teacher);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          // Ánh sáng cam ấm áp tỏa nhẹ từ góc trên bên phải như thiết kế
          gradient: RadialGradient(
            center: Alignment(0.85, -0.65),
            radius: 1.25,
            colors: [
              Color(0xFFFFEDE3),
              Color(0xFFFFF9F5),
              Colors.white,
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),

              // ── Khối Logo FAP CHECK-IN ở giữa ─────────────────────────────
              Image.asset(
                'assets/logos/fap_checkin_logo.png',
                width: 210,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    _buildFallbackLogo(),
              ),
              const SizedBox(height: 38),

              // ── Vòng xoay tải màu cam FPT ──────────────────────────────────
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 2.8,
                  valueColor: AlwaysStoppedAnimation<Color>(AppPalette.primary),
                ),
              ),
              const SizedBox(height: 22),

              // ── Văn bản trạng thái ─────────────────────────────────────────
              const Text(
                'Đang khởi động ứng dụng...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.textDark,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Vui lòng chờ trong giây lát.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppPalette.textMuted,
                ),
              ),

              const Spacer(flex: 4),

              // ── Khối Logo FPT Education & Phiên bản ở chân trang ────────────
              Image.asset(
                'assets/images/Logo_FPT_Education-Photoroom.png',
                width: 105,
                height: 44,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
              const SizedBox(height: 10),
              const Text(
                'FAP CHECK-IN · PHIÊN BẢN 1.0.0',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.8,
                  color: AppPalette.textSubtle,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Logo dự phòng vẽ bằng Flutter nếu file ảnh chưa nạp xong
  Widget _buildFallbackLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppPalette.orangeLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppPalette.orangeBorder),
          ),
          child: const Icon(
            Icons.qr_code_scanner_rounded,
            color: AppPalette.primary,
            size: 26,
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'FAP',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E3A8A),
                letterSpacing: -0.5,
                height: 1.0,
              ),
            ),
            Text(
              'CHECK-IN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F766E),
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
