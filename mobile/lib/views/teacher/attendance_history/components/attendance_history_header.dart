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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? const Color(0xFFF8FAFC)
        : AttendanceHistoryColors.textDark;
    final subtitleColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final btnBg = isDark ? Theme.of(context).colorScheme.surface : Colors.white;
    final btnBorder = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

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
                      color: btnBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: btnBorder),
                      boxShadow: isDark
                          ? null
                          : [
                              BoxShadow(
                                color: const Color(
                                  0xFF0F172A,
                                ).withValues(alpha: 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: textColor,
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
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 1.5),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: subtitleColor,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? const Color(0xFFF8FAFC)
        : AttendanceHistoryColors.textDark;
    final btnBg = isDark ? Theme.of(context).colorScheme.surface : Colors.white;
    final btnBorder = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

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
                color: btnBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: btnBorder),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(
                            0xFF0F172A,
                          ).withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Icon(
                icon,
                size: 19,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
