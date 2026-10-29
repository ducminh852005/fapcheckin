import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../styles/login_styles.dart';
import 'login_google_button.dart';

class LoginSignInCard extends StatelessWidget {
  const LoginSignInCard({
    super.key,
    required this.isLoading,
    required this.onGoogleSignIn,
    this.onDevSignIn,
  });
  final bool isLoading;
  final VoidCallback onGoogleSignIn;
  final VoidCallback? onDevSignIn;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(LoginStyles.cardRadius),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Chào mừng thầy cô', style: LoginStyles.title),
        const SizedBox(height: 16),
        LoginGoogleButton(isLoading: isLoading, onPressed: onGoogleSignIn),
        if (kDebugMode && onDevSignIn != null) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: isLoading ? null : onDevSignIn,
              icon: const Icon(Icons.bolt, size: 16, color: LoginStyles.orange),
              label: const Text(
                'Vào nhanh tài khoản thử nghiệm (Dev)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: LoginStyles.orange,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 16,
              color: LoginStyles.green,
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Chỉ dành cho @fpt.edu.vn / @fe.edu.vn',
                style: LoginStyles.caption,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
