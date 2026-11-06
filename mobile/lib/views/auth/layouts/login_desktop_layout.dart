import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fapcheckin_core/constants/app_colors.dart';
import 'package:fapcheckin_core/constants/app_text_styles.dart';

import '../widgets/google_web_sign_in_button.dart';
import '../widgets/login_brand.dart';

class LoginDesktopLayout extends StatelessWidget {
  const LoginDesktopLayout({
    super.key,
    required this.isLoading,
    required this.onGoogleSignIn,
    required this.onUnsupportedLogin,
  });
  final bool isLoading;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onUnsupportedLogin;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: box.maxHeight),
                  child: _buildContent(context, false, isLoading),
                ),
              ),
            ),
          ),
          const Expanded(child: _HeroVisualColumn()),
        ],
      );
  Widget _buildContent(
    BuildContext context,
    bool mobile,
    bool isGoogleLoading,
  ) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: mobile ? 20 : 24,
        vertical: mobile ? 20 : 32,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(height: 16),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const LoginBrandCard(),
                  const SizedBox(height: 16),
                  Text(
                    'Dành cho Cán bộ, Giảng viên & Sinh viên Đại học FPT. Vui lòng sử dụng tài khoản nội bộ để tiếp tục.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 32),
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
                      onTap: isGoogleLoading ? null : onGoogleSignIn,
                    ),
                  SizedBox(height: 12),
                  _SsoButton(
                    label: '\u0110\u0103ng nh\u1eadp v\u1edbi FE Edu SSO',
                    svgContent: '''<svg viewBox="0 0 24 24">
                        <path fill="#1E293B" d="M12 3 1 9l11 6 9-4.91V17h2V9L12 3Zm0 14.2L5 13.38V17c0 1.66 3.13 3 7 3s7-1.34 7-3v-3.62l-7 3.82Z"></path>
                      </svg>''',
                    onTap: onUnsupportedLogin,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Divider(color: Color(0xFFE2E8F0)),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          color: Colors.white,
                          child: Text(
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
                    height: 48,
                    child: ElevatedButton(
                      onPressed: onUnsupportedLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      child: Text(
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
          Padding(
            padding: EdgeInsets.only(top: 24),
            child: Text.rich(
              TextSpan(
                text:
                    'B\u1eb1ng vi\u1ec7c \u0111\u0103ng nh\u1eadp, b\u1ea1n \u0111\u1ed3ng \u00fd v\u1edbi ',
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
          duration: Duration(milliseconds: 150),
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: _isHovered
                ? AppColors.primaryLight.withValues(alpha: 0.3)
                : Colors.white,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: _isHovered ? AppColors.primary : Color(0xFFCBD5E1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.string(widget.svgContent, width: 20, height: 20),
              SizedBox(width: 12),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _isHovered ? AppColors.primary : Color(0xFF334155),
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
      color: Color(0xFF0F172A),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/fpt_hcm_campus.jpg', fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
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
          Positioned(
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
