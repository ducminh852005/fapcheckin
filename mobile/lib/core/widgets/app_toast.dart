import 'dart:async';

import 'package:flutter/material.dart';

enum AppToastType { success, error, warning, info }

OverlayEntry? _activeToast;
Timer? _toastTimer;

void showAppToast(
  BuildContext context, {
  required String message,
  AppToastType type = AppToastType.info,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  _toastTimer?.cancel();
  _activeToast?.remove();

  late final OverlayEntry entry;
  void dismiss() {
    if (_activeToast == entry) {
      _activeToast = null;
      entry.remove();
    }
    _toastTimer?.cancel();
  }

  entry = OverlayEntry(
    builder: (overlayContext) {
      final colors = _toastColors(type);
      return Positioned(
        top: MediaQuery.paddingOf(overlayContext).top + 12,
        left: 16,
        right: 16,
        child: SafeArea(
          top: false,
          bottom: false,
          child: Material(
            color: Colors.transparent,
            child: Semantics(
              liveRegion: true,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 560),
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x290F172A),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(colors.icon, color: colors.foreground, size: 21),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        message,
                        style: TextStyle(
                          color: colors.foreground,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                    if (actionLabel != null && onAction != null) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          dismiss();
                          onAction();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: colors.foreground,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(actionLabel),
                      ),
                    ],
                    IconButton(
                      tooltip: 'Đóng',
                      onPressed: dismiss,
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.close_rounded,
                        color: colors.foreground,
                        size: 19,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  _activeToast = entry;
  overlay.insert(entry);
  _toastTimer = Timer(duration, dismiss);
}

({Color background, Color foreground, Color border, IconData icon})
_toastColors(AppToastType type) {
  return switch (type) {
    AppToastType.success => (
      background: const Color(0xFFECFDF5),
      foreground: const Color(0xFF047857),
      border: const Color(0xFFA7F3D0),
      icon: Icons.check_circle_outline_rounded,
    ),
    AppToastType.error => (
      background: const Color(0xFFFEF2F2),
      foreground: const Color(0xFFB91C1C),
      border: const Color(0xFFFECACA),
      icon: Icons.error_outline_rounded,
    ),
    AppToastType.warning => (
      background: const Color(0xFFFFFBEB),
      foreground: const Color(0xFFB45309),
      border: const Color(0xFFFDE68A),
      icon: Icons.warning_amber_rounded,
    ),
    AppToastType.info => (
      background: const Color(0xFFEFF6FF),
      foreground: const Color(0xFF1D4ED8),
      border: const Color(0xFFBFDBFE),
      icon: Icons.info_outline_rounded,
    ),
  };
}
