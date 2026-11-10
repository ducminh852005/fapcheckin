import 'package:flutter/material.dart';
import '../schedule_colors.dart';

/// Phần Header của trang Lịch dạy:
/// - Tiêu đề lớn "Lịch dạy của tôi"
/// - Nút chuông thông báo & Nút quét TKB
class ScheduleHeader extends StatelessWidget {
  final VoidCallback? onScanTimetable;

  const ScheduleHeader({super.key, this.onScanTimetable});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFF8FAFC) : ScheduleColors.textDark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'Lịch dạy của tôi',
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ),

        // Nút Scan TKB
        if (onScanTimetable != null)
          IconButton(
            icon: Icon(
              Icons.document_scanner_rounded,
              size: 26,
              color: textColor,
            ),
            tooltip: 'Quét thời khóa biểu bằng OCR',
            onPressed: onScanTimetable,
          ),
      ],
    );
  }
}
