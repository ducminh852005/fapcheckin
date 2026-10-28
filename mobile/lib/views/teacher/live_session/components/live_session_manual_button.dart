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
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: LiveSessionColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: LiveSessionColors.borderSubtle),
          boxShadow: LiveSessionColors.cardShadow,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.person_add_outlined,
                size: 20,
                color: LiveSessionColors.textDark,
              ),
              SizedBox(width: 8),
              Text(
                'Điểm danh tay',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: LiveSessionColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

