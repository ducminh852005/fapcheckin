import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';
import 'package:fapcheckin/viewmodels/dashboard_viewmodel.dart';

/// Active session banner shown at the top of dashboard
class ActiveSessionBanner extends StatelessWidget {
  const ActiveSessionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardViewModel>(
      builder: (context, vm, _) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A142433),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              // Spinning sync icon
              _SpinningIcon(),
              const SizedBox(width: 12),
              // Session info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Status badge
                        _PulsingBadge(),
                        Text(
                          '${vm.activeSessionCourse} — ${vm.activeSessionGroup}',
                          style: AppTextStyles.headlineSm.copyWith(
                            color: AppColors.primaryDark,
                          ),
                        ),
                        // Room chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.meeting_room_outlined,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Phòng ${vm.activeSessionRoom}',
                                style: AppTextStyles.labelSm.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Countdown
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              size: 18,
                              color: AppColors.primaryContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Thời gian còn lại: ',
                              style: AppTextStyles.labelMd.copyWith(
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              ),
                              child: Text(
                                vm.countdownDisplay,
                                style: AppTextStyles.code.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.statusLate,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Scanned count
                        RichText(
                          text: TextSpan(
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            children: [
                              const TextSpan(text: 'Đã quét QR: '),
                              TextSpan(
                                text:
                                    '${vm.activeSessionScanned}/${vm.activeSessionTotal}',
                                style: AppTextStyles.code.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const TextSpan(text: ' sinh viên ('),
                              TextSpan(
                                text:
                                    '${(vm.activeSessionScanned / vm.activeSessionTotal * 100).round()}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const TextSpan(text: ')'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // CTA button
              _LiveSessionButton(),
            ],
          ),
        );
      },
    );
  }
}

class _SpinningIcon extends StatefulWidget {
  @override
  State<_SpinningIcon> createState() => _SpinningIconState();
}

class _SpinningIconState extends State<_SpinningIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A005A6B),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.rotate(
          angle: _ctrl.value * 2 * math.pi,
          child: child,
        ),
        child: const Icon(Icons.sync, size: 24, color: AppColors.onPrimary),
      ),
    );
  }
}

class _PulsingBadge extends StatefulWidget {
  @override
  State<_PulsingBadge> createState() => _PulsingBadgeState();
}

class _PulsingBadgeState extends State<_PulsingBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.statusPresentBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: AppColors.statusPresentBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => Opacity(
              opacity: _anim.value,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.statusPresent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Đang mở điểm danh',
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.statusPresent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveSessionButton extends StatefulWidget {
  @override
  State<_LiveSessionButton> createState() => _LiveSessionButtonState();
}

class _LiveSessionButtonState extends State<_LiveSessionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {
          context.read<DashboardViewModel>().navigate('diem-danh-qr');
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.primaryDark : AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A005A6B),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Vào phòng điểm danh trực tiếp',
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.onPrimary,
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(left: _hovered ? 8 : 6),
                child: const Icon(
                  Icons.arrow_forward,
                  size: 18,
                  color: AppColors.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
