import 'package:flutter/material.dart';
import '../report_colors.dart';

/// Nút "Xuất báo cáo Excel"
class ReportExportButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const ReportExportButton({
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
          color: ReportColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ReportColors.borderSubtle),
          boxShadow: ReportColors.cardShadow,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.file_download_outlined,
                size: 20,
                color: Color(0xFF334155),
              ),
              SizedBox(width: 8),
              Text(
                'Xuất báo cáo Excel',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

