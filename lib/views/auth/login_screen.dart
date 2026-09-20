import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin/app/app_router.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';
import 'package:fapcheckin/viewmodels/auth_viewmodel.dart';
import 'package:fapcheckin/viewmodels/dashboard_viewmodel.dart';
import 'package:fapcheckin/views/auth/widgets/google_web_sign_in_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 768;

          return Row(
            children: [
              Expanded(
                child: _AuthFormColumn(),
              ),
              if (isDesktop)
                const Expanded(
                  child: _HeroVisualColumn(),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AuthFormColumn extends StatefulWidget {
  @override
  State<_AuthFormColumn> createState() => _AuthFormColumnState();
}

class _AuthFormColumnState extends State<_AuthFormColumn> {
  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleSubscription;
  bool _isHandlingGoogle = false;

  @override
  void initState() {
    super.initState();
    final authViewModel = context.read<AuthViewModel>();
    unawaited(authViewModel.initializeGoogleSignIn());
    _googleSubscription =
        authViewModel.googleAuthenticationEvents.listen(_handleGoogleEvent);
  }

  @override
  void dispose() {
    _googleSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final isGoogleLoading = authViewModel.isLoading || _isHandlingGoogle;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                'assets/images/Logo_FPT_Education-Photoroom.png',
                height: 48,
              ),
              Row(
                children: const [],
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Hệ thống điểm danh FAP',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headlineLg.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 0,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Dành cho Cán bộ, Giảng viên & Sinh viên Đại học FPT. Vui lòng sử dụng tài khoản nội bộ để tiếp tục.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (kIsWeb)
                      buildGoogleWebSignInButton(isLoading: isGoogleLoading)
                    else
                      _SsoButton(
                        label: 'Tiếp tục với Google',
                        svgContent: '''<svg viewBox="0 0 24 24">
                          <path d="M23.745 12.27c0-.7-.06-1.4-.19-2.07H12v4.51h6.6c-.29 1.52-1.14 2.82-2.4 3.68v3.05h3.88c2.27-2.09 3.66-5.17 3.66-9.17z" fill="#4285F4"></path>
                          <path d="M12 24c3.24 0 5.95-1.08 7.93-2.91l-3.88-3.05c-1.08.72-2.45 1.16-4.05 1.16-3.12 0-5.77-2.1-6.72-4.93H1.25v3.15C3.26 21.36 7.33 24 12 24z" fill="#34A853"></path>
                          <path d="M5.28 14.27c-.25-.72-.38-1.49-.38-2.27s.13-1.55.38-2.27V6.58H1.25C.45 8.18 0 10.02 0 12s.45 3.82 1.25 5.42l4.03-3.15z" fill="#FBBC05"></path>
                          <path d="M12 4.75c1.77 0 3.35.61 4.6 1.8l3.42-3.42C17.95 1.19 15.24 0 12 0 7.33 0 3.26 2.64 1.25 6.58l4.03 3.15c.95-2.83 3.6-4.98 6.72-4.98z" fill="#EA4335"></path>
                        </svg>''',
                        onTap: isGoogleLoading ? null : _loginWithGoogle,
                      ),

                    const SizedBox(height: 12),
                    _SsoButton(
                      label: '\u0110\u0103ng nh\u1eadp v\u1edbi FE Edu SSO',
                      svgContent: '''<svg viewBox="0 0 24 24">
                        <path fill="#1E293B" d="M12 3 1 9l11 6 9-4.91V17h2V9L12 3Zm0 14.2L5 13.38V17c0 1.66 3.13 3 7 3s7-1.34 7-3v-3.62l-7 3.82Z"></path>
                      </svg>''',
                      onTap: _showUnsupportedLogin,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Divider(color: Color(0xFFE2E8F0)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            color: Colors.white,
                            child: const Text(
                              'HO\u1eb6C',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF94A3B8),
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton(
                        onPressed: _showUnsupportedLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        child: const Text(
                          '\u0110\u0103ng nh\u1eadp v\u1edbi email & m\u1eadt kh\u1ea9u',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Text.rich(
              TextSpan(
                text: 'B\u1eb1ng vi\u1ec7c \u0111\u0103ng nh\u1eadp, b\u1ea1n \u0111\u1ed3ng \u00fd v\u1edbi ',
                children: [
                  TextSpan(
                    text: '\u0110i\u1ec1u kho\u1ea3n d\u1ecbch v\u1ee5',
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                  TextSpan(text: '\nv\u00e0 '),
                  TextSpan(
                    text: 'Ch\u00ednh s\u00e1ch quy\u1ec1n ri\u00eang t\u01b0',
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                  TextSpan(text: ' c\u1ee7a FAP Edu.'),
                ],
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGoogleEvent(GoogleSignInAuthenticationEvent event) async {
    if (event is! GoogleSignInAuthenticationEventSignIn) return;
    if (_isHandlingGoogle) return;

    setState(() => _isHandlingGoogle = true);
    final success =
        await context.read<AuthViewModel>().loginWithGoogleAccount(event.user);
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

    context.go(AppRoutes.teacher);
  }

  void _showAuthError() {
    final message = context.read<AuthViewModel>().errorMessage ??
        'Kh\u00f4ng th\u1ec3 \u0111\u0103ng nh\u1eadp b\u1eb1ng Google.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showUnsupportedLogin() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Ch\u1ee9c n\u0103ng n\u00e0y ch\u01b0a \u0111\u01b0\u1ee3c k\u1ebft n\u1ed1i.',
        ),
      ),
    );
  }
}

class _SsoButton extends StatefulWidget {
  final String label;
  final String svgContent;
  final VoidCallback? onTap;

  const _SsoButton({
    required this.label,
    required this.svgContent,
    required this.onTap,
  });

  @override
  State<_SsoButton> createState() => _SsoButtonState();
}

class _SsoButtonState extends State<_SsoButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(99),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 40,
          decoration: BoxDecoration(
            color: _isHovered
                ? AppColors.primaryLight.withValues(alpha: 0.3)
                : Colors.white,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: _isHovered ? AppColors.primary : const Color(0xFFCBD5E1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.string(
                widget.svgContent,
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _isHovered
                        ? AppColors.primary
                        : const Color(0xFF334155),
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

class _HeroVisualColumn extends StatelessWidget {
  const _HeroVisualColumn();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/fpt_hcm_campus.jpg',
            fit: BoxFit.cover,
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Color(0x66000000),
                  Colors.transparent,
                  Color(0x1A000000),
                ],
              ),
            ),
          ),
          const Positioned(
            left: 32,
            right: 32,
            bottom: 32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'C\u01a0 S\u1ede GI\u1ea2NG \u0110\u01af\u1edcNG & TH\u01af VI\u1ec6N S\u1ed0',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE2E8F0),
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'M\u00f4i tr\u01b0\u1eddng h\u1ecdc t\u1eadp ch\u1ee7 \u0111\u1ed9ng v\u00e0 s\u00e1ng t\u1ea1o kh\u00f4ng ng\u1eebng',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    color: Color(0xFFF1F5F9),
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
