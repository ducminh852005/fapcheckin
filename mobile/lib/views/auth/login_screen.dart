import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../../app/app_router.dart';
import '../../core/widgets/app_toast.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import 'layouts/login_desktop_layout.dart';
import 'layouts/login_mobile_layout.dart';

/// Owns authentication lifecycle and navigation; layouts only render UI.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleSubscription;
  bool _isHandlingGoogle = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthViewModel>();
    _googleSubscription = auth.googleAuthenticationEvents.listen(
      _handleGoogleEvent,
    );
    unawaited(_initializeGoogle(auth));
  }

  Future<void> _initializeGoogle(AuthViewModel auth) async {
    try {
      await auth.initializeGoogleSignIn();
    } catch (_) {
      if (!mounted) return;
      showAppToast(
        context,
        message: 'Không thể khởi tạo Google. Vui lòng thử đăng nhập lại.',
        type: AppToastType.error,
      );
    }
  }

  @override
  void dispose() {
    _googleSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final loading = auth.isLoading || _isHandlingGoogle;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 768) {
            return LoginMobileLayout(
              isLoading: loading,
              onGoogleSignIn: _loginWithGoogle,
            );
          }
          return LoginDesktopLayout(
            isLoading: loading,
            onGoogleSignIn: _loginWithGoogle,
            onUnsupportedLogin: _showUnsupportedLogin,
          );
        },
      ),
    );
  }

  Future<void> _handleGoogleEvent(GoogleSignInAuthenticationEvent event) async {
    if (event is! GoogleSignInAuthenticationEventSignIn) return;
    if (_isHandlingGoogle) return;

    setState(() => _isHandlingGoogle = true);
    final success = await context.read<AuthViewModel>().loginWithGoogleAccount(
      event.user,
    );
    if (!mounted) return;
    setState(() => _isHandlingGoogle = false);

    if (success) {
      _enterMainScreen();
    } else {
      _showAuthError();
    }
  }

  Future<void> _loginWithGoogle() async {
    if (_isHandlingGoogle) return;

    setState(() => _isHandlingGoogle = true);
    final success = await context.read<AuthViewModel>().loginWithGoogle();
    if (!mounted) return;
    setState(() => _isHandlingGoogle = false);

    if (success) {
      _enterMainScreen();
    } else {
      _showAuthError();
    }
  }

  void _enterMainScreen() {
    final authSession = context.read<AuthViewModel>().session;
    if (authSession != null) {
      context.read<DashboardViewModel>().setTeacherInfo(
        name: authSession.user.displayName,
        email: authSession.user.email,
        memberCode: authSession.user.memberCode,
      );
    }

    // Chuyển sang màn hình Loading Page khởi động ứng dụng
    context.go(AppRoutes.loading);
  }

  void _showAuthError() {
    final message =
        context.read<AuthViewModel>().errorMessage ??
        'Không thể đăng nhập bằng Google.';
    showAppToast(context, message: message, type: AppToastType.error);
  }

  void _showUnsupportedLogin() {
    showAppToast(
      context,
      message: 'Chức năng này chưa được kết nối.',
      type: AppToastType.warning,
    );
  }
}
