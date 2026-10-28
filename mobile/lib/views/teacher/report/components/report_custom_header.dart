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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Text(
                  'Báo cáo chuyên cần',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: ReportColors.textDark,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: onDownload,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ReportColors.borderSubtle),
                  boxShadow: ReportColors.cardShadow,
                ),
                child: const Icon(
                  Icons.file_download_outlined,
                  size: 22,
                  color: Color(0xFF334155),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

