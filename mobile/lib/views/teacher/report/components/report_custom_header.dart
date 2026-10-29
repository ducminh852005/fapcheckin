import 'package:flutter/material.dart';
import '../report_colors.dart';

/// Header của màn hình Báo cáo:
/// - Title: "Báo cáo chuyên cần"
/// - Nút tải xuống (download icon) bên phải
class ReportCustomHeader extends StatelessWidget {
  final VoidCallback? onDownload;

  const ReportCustomHeader({
    super.key,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Báo cáo chuyên cần',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: ReportColors.textDark,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
