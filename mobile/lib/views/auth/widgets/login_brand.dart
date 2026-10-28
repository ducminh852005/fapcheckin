import 'package:flutter/material.dart';

import '../styles/login_styles.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Image.asset(
            'assets/images/Logo_FPT_Education-Photoroom.png',
            width: 92,
            height: 42,
            fit: BoxFit.contain,
            semanticLabel: 'Đại học FPT',
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'DÀNH CHO GIẢNG VIÊN',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.4,
                color: LoginStyles.ink,
              ),
            ),
          ),
        ],
      );
}

class LoginBrandCard extends StatelessWidget {
  const LoginBrandCard({super.key});
  @override
  Widget build(BuildContext context) => Container(
        width: 240,
        height: 190,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: LoginStyles.ink.withValues(alpha: 0.05),
              blurRadius: 36,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Center(
          child: Image.asset(
            'assets/logos/fap_checkin_logo.png',
            width: 195,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: LoginStyles.orange,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'FAP Check-in.',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: LoginStyles.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
