import 'package:flutter/widgets.dart';

/// Width breakpoints (logical px) used across the app.
class Breakpoints {
  Breakpoints._();

  /// Below this width: phone layout.
  static const double mobile = 600;

  /// Below this width (and >= mobile): tablet layout.
  static const double tablet = 1024;
}

enum ScreenSize { mobile, tablet, desktop }

ScreenSize screenSizeForWidth(double width) {
  if (width < Breakpoints.mobile) return ScreenSize.mobile;
  if (width < Breakpoints.tablet) return ScreenSize.tablet;
  return ScreenSize.desktop;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  ScreenSize get screenSize => screenSizeForWidth(screenWidth);

  bool get isMobile => screenSize == ScreenSize.mobile;
  bool get isTablet => screenSize == ScreenSize.tablet;
  bool get isDesktop => screenSize == ScreenSize.desktop;

  /// Pick a value by screen size. [tablet] falls back to [desktop].
  T responsive<T>({required T mobile, T? tablet, required T desktop}) {
    switch (screenSize) {
      case ScreenSize.mobile:
        return mobile;
      case ScreenSize.tablet:
        return tablet ?? desktop;
      case ScreenSize.desktop:
        return desktop;
    }
  }

  /// Horizontal page padding: tighter on phones.
  double get pagePadding => isMobile ? 16.0 : 24.0;
}
