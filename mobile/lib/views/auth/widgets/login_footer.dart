import 'package:flutter/material.dart';

import '../styles/login_styles.dart';

class LoginFooter extends StatelessWidget {
  const LoginFooter({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 28),
    child: Column(
      children: [
        Text(
          'Bằng việc đăng nhập, thầy cô đồng ý với\nĐiều khoản sử dụng và Chính sách bảo mật.',
          textAlign: TextAlign.center,
          style: LoginStyles.caption,
        ),
        SizedBox(height: 12),
        Text(
          'FAP CHECK-IN · PHIÊN BẢN 1.0.0',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            height: 1.5,
            letterSpacing: 0.4,
            color: LoginStyles.muted,
          ),
        ),
      ],
    ),
  );
}
