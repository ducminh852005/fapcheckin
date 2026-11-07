import 'dart:async';

import 'package:flutter/material.dart';

enum AppToastType { success, error, warning, info }

OverlayEntry? _activeToast;
Timer? _toastTimer;

void showAppToast(
  BuildContext context, {
  required String message,
  String? title,
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
      final appearance = _toastAppearance(type);
      final isDark = Theme.of(overlayContext).brightness == Brightness.dark;

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
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 560),
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE5E7EB),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x240F172A),
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: appearance.color,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(appearance.icon, color: Colors.white, size: 25),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title ?? appearance.title,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF404040),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              message,
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF8A8A8A),
                                fontSize: 13,
                                height: 1.25,
                              ),
                            ),
                          ],
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
                            foregroundColor: appearance.color,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: Text(actionLabel),
                        ),
                      ],
                      IconButton(
                        tooltip: 'Đóng',
                        onPressed: dismiss,
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        icon: Icon(
                          Icons.close_rounded,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF8A8A8A),
                          size: 22,
                        ),
                      ),
                    ],
                  ),
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

({Color color, IconData icon, String title}) _toastAppearance(AppToastType type) {
  return switch (type) {
    AppToastType.success => (color: const Color(0xFF22A45D), icon: Icons.check_rounded, title: 'Thành công'),
    AppToastType.error => (color: const Color(0xFFDC2626), icon: Icons.close_rounded, title: 'Có lỗi xảy ra'),
    AppToastType.warning => (color: const Color(0xFFF59E0B), icon: Icons.priority_high_rounded, title: 'Cảnh báo'),
    AppToastType.info => (color: const Color(0xFF2563EB), icon: Icons.info_rounded, title: 'Thông báo'),
  };
}
