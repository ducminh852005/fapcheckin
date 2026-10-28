import 'package:flutter/material.dart';
import '../live_session_colors.dart';

/// Thẻ kiểm tra IP mạng:
/// - Icon khiên bảo mật màu xanh ngọc
/// - Tiêu đề: "Kiểm tra IP mạng"
/// - Nút gạt chuyển đổi trạng thái "Tắt" / "Bật" (màu cam khi chọn)
/// - Phụ đề: "Chỉ chấp nhận mạng FPTU-Campus · IP 10.22.*.*"
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: LiveSessionColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LiveSessionColors.borderSubtle),
        boxShadow: LiveSessionColors.cardShadow,
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
              const Expanded(
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Kiểm tra IP mạng',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: LiveSessionColors.textDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Segmented switch Tắt / Bật
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
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
              ),
            ],
          ),
          const SizedBox(height: 8),
          const FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              'Chỉ chấp nhận mạng FPTU-Campus · IP 10.22.*.*',
              style: TextStyle(
                fontSize: 11,
                color: LiveSessionColors.textMuted,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? LiveSessionColors.orangePrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: LiveSessionColors.orangePrimary.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : LiveSessionColors.textMuted,
          ),
        ),
      ),
    );
  }
}

