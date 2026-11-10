import 'package:flutter/material.dart';
import '../report_colors.dart';

/// Header của màn hình Báo cáo:
/// - Title: "Báo cáo chuyên cần"
/// - Nút tải xuống (download icon) bên phải để xuất báo cáo Excel
class ReportCustomHeader extends StatelessWidget {
  final VoidCallback? onDownload;

  const ReportCustomHeader({
    super.key,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFF8FAFC) : ReportColors.textDark;
    final iconColor = isDark
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF334155);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            'Báo cáo chuyên cần',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
        ),
        if (onDownload != null)
          Tooltip(
            message: 'Xuất báo cáo Excel',
            child: IconButton(
              onPressed: onDownload,
              icon: Icon(
                Icons.file_download_outlined,
                size: 25,
                color: iconColor,
              ),
            ),
          ),
      ],
    );
  }
}
