import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as google_web;

Widget buildGoogleWebSignInButton({required bool isLoading}) {
  return LayoutBuilder(
    builder: (context, constraints) => _buildButton(
      isLoading: isLoading,
      // GSI minimumWidth must fit the available width (phone browsers).
      minWidth: constraints.maxWidth.isFinite
          ? constraints.maxWidth.clamp(200.0, 400.0)
          : 400.0,
    ),
  );
}

Widget _buildButton({required bool isLoading, required double minWidth}) {
  return SizedBox(
    width: double.infinity,
    height: 40,
    child: Center(
      child: IgnorePointer(
        ignoring: isLoading,
        child: Opacity(
          opacity: isLoading ? 0.55 : 1,
          child: SizedBox(
            width: double.infinity,
            height: 40,
            child: google_web.renderButton(
              configuration: google_web.GSIButtonConfiguration(
                type: google_web.GSIButtonType.standard,
                theme: google_web.GSIButtonTheme.outline,
                size: google_web.GSIButtonSize.large,
                text: google_web.GSIButtonText.signinWith,
                shape: google_web.GSIButtonShape.pill,
                logoAlignment: google_web.GSIButtonLogoAlignment.center,
                minimumWidth: minWidth,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
