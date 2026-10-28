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
    width: 228,
    height: 214,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.68),
      borderRadius: BorderRadius.circular(34),
      border: Border.all(color: Colors.white, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: LoginStyles.ink.withValues(alpha: 0.04),
          blurRadius: 40,
          offset: const Offset(0, 20),
        ),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: LoginStyles.orange,
            borderRadius: BorderRadius.circular(25),
          ),
          child: const Icon(
            Icons.qr_code_scanner_rounded,
            color: Colors.white,
            size: 39,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'FAP Check-in.',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w400,
            color: LoginStyles.ink,
          ),
        ),
      ],
    ),
  );
}
