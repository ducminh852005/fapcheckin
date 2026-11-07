import 'package:flutter/material.dart';

import 'login_google_button.dart';

/// Khung đăng nhập bằng Google với thiết kế thẻ trắng bo góc hiện đại.
class LoginSignInCard extends StatelessWidget {
  const LoginSignInCard({
    super.key,
    required this.isLoading,
    required this.onGoogleSignIn,
  });

  final bool isLoading;
  final VoidCallback onGoogleSignIn;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final badgeBg = isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFE8FDF3);
    final badgeBorder = isDark ? const Color(0xFF065F46) : const Color(0xFFBBF7D0);
    final badgeText = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: cardBorder),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Chào mừng thầy cô',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: titleColor,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Đăng nhập hệ thống quản lý & điểm danh giảng đường',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: subtitleColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          LoginGoogleButton(
            isLoading: isLoading,
            onPressed: onGoogleSignIn,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: badgeBorder,
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  size: 14,
                  color: Color(0xFF059669),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Chỉ dành cho @fpt.edu.vn / @fe.edu.vn',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: badgeText,
                    ),
                    textAlign: TextAlign.center,
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
