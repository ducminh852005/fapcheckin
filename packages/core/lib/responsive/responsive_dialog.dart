import 'package:flutter/material.dart';

import './breakpoints.dart';

/// Frame for large dialogs. Tablet/desktop: a centered [Dialog] capped to
/// [maxWidth] x [maxHeight] (never larger than the screen). Phones: a
/// full-screen dialog with safe-area padding.
///
/// Use inside a `showDialog` builder. [child] gets bounded constraints, so a
/// `Column` with `Expanded` children works.
class ResponsiveDialogFrame extends StatelessWidget {
  final double maxWidth;
  final double maxHeight;
  final Widget child;
  final double radius;
  final Color backgroundColor;

  const ResponsiveDialogFrame({
    super.key,
    required this.child,
    this.maxWidth = 800,
    this.maxHeight = 800,
    this.radius = 16,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) {
      return Dialog.fullscreen(
        backgroundColor: backgroundColor,
        child: SafeArea(child: child),
      );
    }
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      backgroundColor: backgroundColor,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: child,
      ),
    );
  }
}
