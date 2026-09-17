import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';
import 'package:fapcheckin/views/main_screen.dart';

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
              // Left Column (Auth Interface)
              Expanded(
                child: _AuthFormColumn(),
              ),
              
              // Right Column (Campus Hero Visual)
              if (isDesktop)
                const Expanded(
                  child: _HeroVisualColumn(),
                ),
            ],
          );
        }
      ),
    );
  }
}

class _AuthFormColumn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo
              Image.asset(
                'assets/images/Logo_FPT_Education-Photoroom.png',
                height: 48,
              ),
              // Language & Help
              Row(
                children: [
                  // MouseRegion(
                  //   cursor: SystemMouseCursors.click,
                  //   child: Row(
                  //     children: [
                  //       const Text(
                  //         'Tiếng Việt (Vietnam)',
                  //         style: TextStyle(
                  //           fontSize: 12,
                  //           fontWeight: FontWeight.w500,
                  //           color: Color(0xFF475569), // slate-600
                  //         ),
                  //       ),
                  //       const SizedBox(width: 4),
                  //       const Icon(
                  //         Icons.expand_more,
                  //         size: 16,
                  //         color: Color(0xFF94A3B8), // slate-400
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  // const SizedBox(width: 12),
                  // InkWell(
                  //   onTap: () {},
                  //   borderRadius: BorderRadius.circular(8),
                  //   child: Container(
                  //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  //     decoration: BoxDecoration(
                  //       border: Border.all(color: const Color(0xFFCBD5E1)), // slate-300
                  //       borderRadius: BorderRadius.circular(8),
                  //     ),
                  //     child: const Text(
                  //       'Trợ giúp',
                  //       style: TextStyle(
                  //         fontSize: 12,
                  //         fontWeight: FontWeight.w600,
                  //         color: Color(0xFF334155), // slate-700
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ],
          ),
          
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Subtitle
                    Text(
                      'Đăng nhập hệ thống\nđiểm danh FAP',
                      style: AppTextStyles.headlineLg.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Dành cho Cán bộ, Giảng viên & Sinh viên Đại học FPT. Vui lòng sử dụng tài khoản nội bộ để tiếp tục.',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // SSO Buttons
                    _SsoButton(
                      label: 'Tiếp tục với Google (@fpt.edu.vn)',
                      svgContent: '''<svg viewBox="0 0 24 24">
                        <path d="M23.745 12.27c0-.7-.06-1.4-.19-2.07H12v4.51h6.6c-.29 1.52-1.14 2.82-2.4 3.68v3.05h3.88c2.27-2.09 3.66-5.17 3.66-9.17z" fill="#4285F4"></path>
                        <path d="M12 24c3.24 0 5.95-1.08 7.93-2.91l-3.88-3.05c-1.08.72-2.45 1.16-4.05 1.16-3.12 0-5.77-2.1-6.72-4.93H1.25v3.15C3.26 21.36 7.33 24 12 24z" fill="#34A853"></path>
                        <path d="M5.28 14.27c-.25-.72-.38-1.49-.38-2.27s.13-1.55.38-2.27V6.58H1.25C.45 8.18 0 10.02 0 12s.45 3.82 1.25 5.42l4.03-3.15z" fill="#FBBC05"></path>
                        <path d="M12 4.75c1.77 0 3.35.61 4.6 1.8l3.42-3.42C17.95 1.19 15.24 0 12 0 7.33 0 3.26 2.64 1.25 6.58l4.03 3.15c.95-2.83 3.6-4.98 6.72-4.98z" fill="#EA4335"></path>
                      </svg>''',
                      onTap: () => _login(context),
                    ),
                    const SizedBox(height: 12),
                    _SsoButton(
                      label: 'Tiếp tục với Office 365',
                      svgContent: '''<svg viewBox="0 0 23 23">
                        <path d="M1 1h10v10H1z" fill="#f35325"></path>
                        <path d="M12 1h10v10H12z" fill="#81bc06"></path>
                        <path d="M1 12h10v10H1z" fill="#05a6f0"></path>
                        <path d="M12 12h10v10H12z" fill="#ffba08"></path>
                      </svg>''',
                      onTap: () => _login(context),
                    ),
                    const SizedBox(height: 12),
                    _SsoButton(
                      label: 'Đăng nhập với FE Edu SSO',
                      svgContent: '''<svg viewBox="0 0 24 24">
                        <path fill="#1E293B" fill-rule="evenodd" clip-rule="evenodd" d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.53 1.032 1.53 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z"></path>
                      </svg>''',
                      onTap: () => _login(context),
                    ),
                    
                    // Divider
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Divider(color: Color(0xFFE2E8F0)), // slate-200
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            color: Colors.white,
                            child: const Text(
                              'HOẶC',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF94A3B8), // slate-400
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Primary Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => _login(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary, // slate-900 -> primary
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        child: const Text(
                          'Đăng nhập với email & mật khẩu',
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
          
          // Bottom Notice
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Text.rich(
              TextSpan(
                text: 'Bằng việc đăng nhập, bạn đồng ý với ',
                children: [
                  TextSpan(
                    text: 'Điều khoản dịch vụ',
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                  TextSpan(text: '\nvà '),
                  TextSpan(
                    text: 'Chính sách quyền riêng tư',
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                  TextSpan(text: ' của FAP Edu.'),
                ],
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8), // slate-400
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _login(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }
}

class _SsoButton extends StatefulWidget {
  final String label;
  final String svgContent;
  final VoidCallback onTap;

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
          height: 48,
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.primaryLight.withValues(alpha: 0.3) : Colors.white,
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
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _isHovered ? AppColors.primary : const Color(0xFF334155),
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
          // Image
          Image.asset(
            'assets/images/fpt_hcm_campus.jpg',
            fit: BoxFit.cover,
          ),
          // Gradient overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Color(0x66000000), // black/40
                  Colors.transparent,
                  Color(0x1A000000), // black/10
                ],
              ),
            ),
          ),
          // Text overlay
          const Positioned(
            left: 32,
            right: 32,
            bottom: 32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CƠ SỞ GIẢNG ĐƯỜNG & THƯ VIỆN SỐ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE2E8F0), // slate-200
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Môi trường học tập chủ động và sáng tạo không ngừng',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    color: Color(0xFFF1F5F9), // slate-100
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
