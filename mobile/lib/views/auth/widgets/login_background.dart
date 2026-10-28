import 'package:flutter/material.dart';

import '../styles/login_styles.dart';

class LoginBackground extends StatelessWidget {
  const LoginBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(color: LoginStyles.background),
    child: Stack(
      fit: StackFit.expand,
      children: [
        const Positioned(
          top: -45,
          right: -150,
          width: 450,
          height: 470,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [LoginStyles.warmGlow, Color(0x00FFE0C5)],
              ),
            ),
          ),
        ),
        const Positioned(
          top: 200,
          left: -230,
          width: 640,
          height: 650,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [LoginStyles.coolGlow, Color(0x00CFDFF7)],
              ),
            ),
          ),
        ),
        child,
      ],
    ),
  );
}
