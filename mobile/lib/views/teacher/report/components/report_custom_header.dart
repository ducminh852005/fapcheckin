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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Text(
            'Báo cáo chuyên cần',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: ReportColors.textDark,
              letterSpacing: -0.5,
            ),
          ),
        ),
        if (onDownload != null)
          Tooltip(
            message: 'Xuất báo cáo Excel',
            child: Semantics(
              button: true,
              label: 'Xuất báo cáo Excel',
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onDownload,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ReportColors.borderSubtle,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.file_download_outlined,
                      size: 22,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
