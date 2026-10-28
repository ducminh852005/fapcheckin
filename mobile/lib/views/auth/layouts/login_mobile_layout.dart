import 'package:flutter/material.dart';

import '../styles/login_styles.dart';
import '../widgets/login_background.dart';
import '../widgets/login_brand.dart';
import '../widgets/login_footer.dart';
import '../widgets/login_sign_in_card.dart';

/// Scrolls on small/landscape screens; no authentication or navigation here.
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
          20,
          LoginStyles.pagePadding,
          32,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: LoginStyles.contentWidth,
            ),
            child: Column(
              children: [
                const LoginHeader(),
                const SizedBox(height: 50),
                const LoginBrandCard(),
                const SizedBox(height: 52),
                LoginSignInCard(
                  isLoading: isLoading,
                  onGoogleSignIn: onGoogleSignIn,
                ),
                const SizedBox(height: 8),
                const LoginFooter(),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
