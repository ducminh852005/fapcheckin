import 'package:flutter/material.dart';
import '../attendance_history_colors.dart';

/// Header thanh điều hướng trên cùng của màn hình Điểm danh sinh viên:
/// - Nút quay lại (Back)
/// - Tiêu đề "Điểm danh sinh viên"
/// - Thông tin lớp "PRN231 · SE1801 · Buổi 12 · Ca 2 (Phòng AL-204)"
/// - 2 nút chức năng: Xuất file & Tuỳ chọn (...)
class AttendanceHistoryHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onBack;
  final bool showBackButton;
  final VoidCallback? onExport;
  final VoidCallback? onOptions;

  const AttendanceHistoryHeader({
    super.key,
    this.title = 'Điểm danh sinh viên',
    this.subtitle = 'PRN231 · SE1801 · Buổi 12 · Ca 2 (Phòng AL-204)',
    this.onBack,
    this.showBackButton = false,
    this.onExport,
    this.onOptions,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Nút quay lại
        if (showBackButton && onBack != null) ...[
          Tooltip(
            message: 'Quay lại',
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: AttendanceHistoryColors.textDark,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],

        // Tiêu đề & Thông tin lớp
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AttendanceHistoryColors.textDark,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 1.5),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 6),

        // Nút xuất báo cáo/tải xuống
        if (onExport != null)
          _CircleActionButton(
            icon: Icons.file_download_outlined,
            tooltip: 'Xuất bảng điểm danh',
            onTap: onExport,
          ),

        // Nút tuỳ chọn thêm (ẩn nếu không truyền hoặc truyền null)
        if (onOptions != null) ...[
          const SizedBox(width: 8),
          _CircleActionButton(
            icon: Icons.more_horiz_rounded,
            tooltip: 'Tuỳ chọn thêm',
            onTap: onOptions,
          ),
        ],
      ],
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _CircleActionButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 19,
                color: AttendanceHistoryColors.textDark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
