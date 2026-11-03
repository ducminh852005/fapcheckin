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
            // Ánh ấm góc trên bên phải (Warm peach glow)
            const Positioned(
              top: -60,
              right: -100,
              width: 480,
              height: 480,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      LoginStyles.warmGlow,
                      Color(0x00FFF5EB),
                    ],
                  ),
                ),
              ),
            ),
            // Ánh mát dịu góc trên bên trái (Cool blue/grey glow)
            const Positioned(
              top: 40,
              left: -160,
              width: 520,
              height: 520,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      LoginStyles.coolGlow,
                      Color(0x00EFF6FF),
                    ],
                  ),
                ),
              ),
            ),
            child,
          ],
        ),
      );
}
