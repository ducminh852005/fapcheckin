import 'package:flutter/material.dart';
import '../live_session_colors.dart';

/// Nút "Điểm danh tay"
class LiveSessionManualButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const LiveSessionManualButton({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = LiveSessionColors.getCardBg(context);
    final textDark = LiveSessionColors.getTextDark(context);

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          Icons.person_add_outlined,
          size: 20,
          color: textDark,
        ),
        label: Text(
          'Điểm danh tay',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: cardBg,
          foregroundColor: textDark,
          side: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
