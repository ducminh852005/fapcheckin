import 'package:flutter/material.dart';
import '../attendance_history_colors.dart';

/// Nút lưu kết quả điểm danh ở chân trang:
/// - Nút lớn màu cam FPT: "💾 Lưu bảng điểm danh buổi 12"
/// - Dòng chú thích: "🔄 Tự động đồng bộ với hệ thống FAP Portal"
class AttendanceSaveActionButton extends StatelessWidget {
  final int sessionNumber;
  final VoidCallback onSave;

  const AttendanceSaveActionButton({
    super.key,
    this.sessionNumber = 12,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Nút cam lưu kết quả
        ElevatedButton(
          onPressed: onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AttendanceHistoryColors.orangePrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            shadowColor:
                AttendanceHistoryColors.orangePrimary.withValues(alpha: 0.35),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.save_outlined,
                size: 20,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Lưu bảng điểm danh buổi $sessionNumber',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Dòng đồng bộ FAP Portal
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sync_rounded,
              size: 15,
              color: AttendanceHistoryColors.progressGreen,
            ),
            SizedBox(width: 5),
            Flexible(
              child: Text(
                'Tự động đồng bộ với hệ thống FAP Portal',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AttendanceHistoryColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
