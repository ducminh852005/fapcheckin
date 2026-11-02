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
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(
          Icons.person_add_outlined,
          size: 20,
          color: LiveSessionColors.textDark,
        ),
        label: const Text(
          'Điểm danh tay',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: LiveSessionColors.textDark,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: LiveSessionColors.textDark,
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
