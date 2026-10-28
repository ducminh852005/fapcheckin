import 'package:flutter/material.dart';
import '../report_colors.dart';

/// Header của màn hình Báo cáo:
/// - Subtitle uppercase: "DỮ LIỆU ĐỂ THẤU HIỂU LỚP HỌC"
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DỮ LIỆU ĐỂ THẤU HIỂU LỚP HỌC',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: ReportColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
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
