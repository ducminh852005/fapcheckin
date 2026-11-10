import 'package:flutter/material.dart';
import 'package:fapcheckin_core/constants/app_palette.dart';

/// Bong bóng chat. Văn bản trả lời của AI hỗ trợ **in đậm** và gạch đầu dòng (markdown tối giản).
class AiMessageBubble extends StatelessWidget {
  const AiMessageBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.isError = false,
    this.onRetry,
  });

  final String text;
  final bool isUser;
  final bool isError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    final Color bg;
    final Color fg;
    if (isUser) {
      bg = AppPalette.primary;
      fg = Colors.white;
    } else if (isError) {
      bg = isDark ? const Color(0xFF3B1D1D) : AppPalette.statusRedBg;
      fg = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C);
    } else {
      bg = isDark ? scheme.surface : Colors.white;
      fg = isDark ? const Color(0xFFE2E8F0) : AppPalette.textDark;
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.86),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isUser ? 18 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 18),
            ),
            border: isUser || isError
                ? null
                : Border.all(color: isDark ? scheme.outline : AppPalette.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SelectableText.rich(
                TextSpan(
                  style: TextStyle(color: fg, fontSize: 14.5, height: 1.45),
                  children: _spans(text),
                ),
              ),
              if (onRetry != null)
                TextButton.icon(
                  key: const Key('ai-retry'),
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Thử lại'),
                  style: TextButton.styleFrom(
                    foregroundColor: fg,
                    minimumSize: const Size(48, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static List<InlineSpan> _spans(String raw) {
    final spans = <InlineSpan>[];
    final lines = raw.split('\n');
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];
      final bullet = RegExp(r'^\s*[*\-•]\s+').firstMatch(line);
      if (bullet != null) line = '•  ${line.substring(bullet.end)}';
      final parts = line.split('**');
      for (var j = 0; j < parts.length; j++) {
        if (parts[j].isEmpty) continue;
        spans.add(TextSpan(
          text: parts[j],
          style: j.isOdd ? const TextStyle(fontWeight: FontWeight.w800) : null,
        ));
      }
      if (i < lines.length - 1) spans.add(const TextSpan(text: '\n'));
    }
    return spans;
  }
}
