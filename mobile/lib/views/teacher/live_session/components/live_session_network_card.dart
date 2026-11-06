import 'package:flutter/material.dart';

import '../live_session_colors.dart';

/// Thẻ kiểm tra IP mạng:
/// - Icon khiên bảo mật màu xanh ngọc
/// - Tiêu đề: "Kiểm tra IP mạng"
/// - Nút gạt chuyển đổi trạng thái "Tắt" / "Bật" (màu cam khi chọn)
/// - Phụ đề: "Sinh viên cần dùng cùng IP công khai với giảng viên"
class LiveSessionNetworkCard extends StatelessWidget {
  final bool isEnforced;
  final ValueChanged<bool>? onToggle;

  const LiveSessionNetworkCard({
    super.key,
    this.isEnforced = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = LiveSessionColors.getCardBg(context);
    final cardBorder = LiveSessionColors.getBorder(context);
    final textDark = LiveSessionColors.getTextDark(context);
    final textMuted = LiveSessionColors.getTextMuted(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: isDark ? null : LiveSessionColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 20,
                color: LiveSessionColors.tealNetwork,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Kiểm tra IP mạng',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Nếu onToggle != null hiển thị switch tương tác; nếu chỉ đọc (trong phiên đang mở) hiển thị badge trạng thái rõ ràng
              if (onToggle != null)
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SwitchSegment(
                        title: 'Tắt',
                        isSelected: !isEnforced,
                        onTap: () => onToggle?.call(false),
                      ),
                      _SwitchSegment(
                        title: 'Bật',
                        isSelected: isEnforced,
                        onTap: () => onToggle?.call(true),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isEnforced
                        ? (isDark ? const Color(0xFF431407) : LiveSessionColors.orangeLight)
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isEnforced
                            ? Icons.lock_outline_rounded
                            : Icons.lock_open_rounded,
                        size: 13,
                        color: isEnforced
                            ? LiveSessionColors.orangePrimary
                            : textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isEnforced ? 'Đang bật' : 'Đang tắt',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isEnforced
                              ? LiveSessionColors.orangePrimary
                              : textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              isEnforced
                  ? 'Sinh viên cần dùng cùng IP công khai với giảng viên (cố định trong phiên)'
                  : 'Không giới hạn IP mạng trong phiên điểm danh này',
              style: TextStyle(
                fontSize: 11,
                color: textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchSegment extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _SwitchSegment({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? LiveSessionColors.orangePrimary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: LiveSessionColors.orangePrimary.withValues(
                      alpha: 0.3,
                    ),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : LiveSessionColors.textMuted,
          ),
        ),
      ),
    );
  }
}
