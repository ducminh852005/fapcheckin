import 'package:flutter/material.dart';

import '../styles/login_styles.dart';
import '../widgets/login_background.dart';
import '../widgets/login_brand.dart';
import '../widgets/login_footer.dart';
import '../widgets/login_sign_in_card.dart';

/// Bố cục trang đăng nhập trên thiết bị di động (Mobile).
/// Logo nổi trực tiếp trên nền gradient, phía dưới là thẻ trắng đăng nhập Google.
class LoginMobileLayout extends StatelessWidget {
  const LoginMobileLayout({
    super.key,
    required this.isLoading,
    required this.onGoogleSignIn,
  });

  final bool isLoading;
  final VoidCallback onGoogleSignIn;

  @override
  Widget build(BuildContext context) => LoginBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              LoginStyles.pagePadding,
              16,
              LoginStyles.pagePadding,
              24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: LoginStyles.contentWidth,
                ),
                child: Column(
                  children: [
                    const LoginHeader(),
                    const SizedBox(height: 34),
                    const LoginBrandCard(),
                    const SizedBox(height: 34),
                    LoginSignInCard(
                      isLoading: isLoading,
                      onGoogleSignIn: onGoogleSignIn,
                    ),
                    const SizedBox(height: 20),
                    const LoginFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
