import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';
import 'package:fapcheckin/viewmodels/live_session_viewmodel.dart';
import 'package:fapcheckin/viewmodels/dashboard_viewmodel.dart';

/// Left column: class info + QR code + session controls
class QrPanel extends StatelessWidget {
  const QrPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LiveSessionViewModel>(
      builder: (context, vm, _) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A142433),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              _ClassInfoHeader(vm: vm),
              const SizedBox(height: AppSpacing.md),
              _QrCodeDisplay(vm: vm),
              const SizedBox(height: AppSpacing.md),
              _SessionInfoGrid(vm: vm),
              const SizedBox(height: AppSpacing.md),
              _ControlButtons(),
            ],
          ),
        );
      },
    );
  }
}

/// Course name, room, time header
class _ClassInfoHeader extends StatelessWidget {
  final LiveSessionViewModel vm;
  const _ClassInfoHeader({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vm.courseCategory.toUpperCase(),
                    style: AppTextStyles.codeSm.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${vm.courseCode} — ${vm.courseName}',
                    style: AppTextStyles.headlineMd.copyWith(
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _ActiveBadge(),
          ],
        ),
        const SizedBox(height: 8),
        // Meta chips row
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MetaItem(
                icon: Icons.meeting_room_outlined,
                label: 'Phòng ${vm.room}',
                bold: true,
                iconColor: AppColors.primary,
              ),
              Text('•', style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
              _MetaItem(icon: Icons.schedule_outlined, label: vm.slot),
              Text('•', style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
              _MetaItem(icon: Icons.today_outlined, label: vm.dateLabel),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActiveBadge extends StatefulWidget {
  @override
  State<_ActiveBadge> createState() => _ActiveBadgeState();
}

class _ActiveBadgeState extends State<_ActiveBadge>
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
        boxShadow: const [
          BoxShadow(color: Color(0x0A142433), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _anim,
            builder: (_, _) => Opacity(
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
            'Phiên đang mở',
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

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool bold;
  final Color? iconColor;

  const _MetaItem({
    required this.icon,
    required this.label,
    this.bold = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: iconColor ?? AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.labelSm.copyWith(
            color: bold ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

/// QR code display with circular countdown timer
class _QrCodeDisplay extends StatelessWidget {
  final LiveSessionViewModel vm;
  const _QrCodeDisplay({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: const [
          BoxShadow(color: Color(0x05142433), blurRadius: 8, spreadRadius: 2),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background blurs
          Positioned(
            top: -48,
            right: -48,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: const SizedBox.shrink(),
            ),
          ),
          Positioned(
            bottom: -48,
            left: -48,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.secondaryFixed.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: const SizedBox.shrink(),
            ),
          ),
          // QR + Timer column
          Column(
            children: [
              // QR Code placeholder
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12142433),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: vm.session == null
                    ? SizedBox(
                        width: 220,
                        height: 220,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, size: 48, color: AppColors.textTertiary),
                            const SizedBox(height: 16),
                            Text(
                              'Phiên đã kết thúc',
                              style: AppTextStyles.labelMd.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : vm.qrToken.isEmpty 
                        ? const SizedBox(width: 220, height: 220, child: Center(child: CircularProgressIndicator()))
                        : QrImageView(
                            data: vm.qrToken,
                            version: QrVersions.auto,
                            size: 220.0,
                            backgroundColor: Colors.white,
                          ),
              ),
              const SizedBox(height: 16),
              // Circular countdown timer bar
              if (vm.session != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    boxShadow: const [
                      BoxShadow(color: Color(0x0A142433), blurRadius: 3, offset: Offset(0, 1)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Circular progress
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(36, 36),
                              painter: _CircularTimerPainter(
                                progress: vm.qrProgress,
                                trackColor: AppColors.surfaceMuted,
                                progressColor: AppColors.primaryContainer,
                              ),
                            ),
                            Text(
                              '${vm.qrRefreshSeconds}s',
                              style: AppTextStyles.codeSm.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đổi mã bảo mật: ${vm.qrRefreshSeconds}s / ${LiveSessionViewModel.qrCycleDuration}s',
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Chống gian lận vị trí & chụp màn hình',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Session remaining time & IP info grid
class _SessionInfoGrid extends StatelessWidget {
  final LiveSessionViewModel vm;
  const _SessionInfoGrid({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _InfoTile(
              icon: Icons.timer_outlined,
              label: 'Thời gian phiên còn lại',
              value: vm.sessionTimeDisplay,
              valueSuffix: 'phút',
              valueColor: AppColors.primaryDark,
            )),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: _InfoTile(
              icon: Icons.wifi_lock_outlined,
              label: 'IP Wi-Fi FPT Giảng viên',
              value: vm.teacherIp,
              showVerified: true,
            )),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _WebSocketBar(),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? valueSuffix;
  final Color? valueColor;
  final bool showVerified;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueSuffix,
    this.valueColor,
    this.showVerified = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                value,
                style: valueSuffix != null
                    ? AppTextStyles.code.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: valueColor ?? AppColors.textPrimary,
                        letterSpacing: -0.5,
                      )
                    : AppTextStyles.labelMd.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
              ),
              if (valueSuffix != null) ...[
                const SizedBox(width: 4),
                Text(valueSuffix!, style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.textTertiary)),
              ],
              if (showVerified) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified, size: 16, color: AppColors.statusPresent),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _WebSocketBar extends StatefulWidget {
  @override
  State<_WebSocketBar> createState() => _WebSocketBarState();
}

class _WebSocketBarState extends State<_WebSocketBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: const [
          BoxShadow(color: Color(0x0A142433), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _anim,
            builder: (_, _) => Opacity(
              opacity: _anim.value,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.statusPresent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Kết nối WebSocket ổn định (24ms)',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'SSL / TLS 1.3',
              style: AppTextStyles.codeSm.copyWith(
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Control buttons: Refresh QR, Copy URL, End session
class _ControlButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _ControlBtn(
              icon: Icons.sync,
              iconColor: AppColors.primary,
              label: 'Làm mới QR ngay',
              onTap: () {},
            )),
            const SizedBox(width: 8),
            Expanded(child: _ControlBtn(
              icon: Icons.content_copy_outlined,
              iconColor: AppColors.textSecondary,
              label: 'Sao chép URL dự phòng',
              onTap: () {},
            )),
          ],
        ),
        const SizedBox(height: 8),
        _EndSessionButton(),
      ],
    );
  }
}

class _ControlBtn extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _ControlBtn({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  State<_ControlBtn> createState() => _ControlBtnState();
}

class _ControlBtnState extends State<_ControlBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.surfaceContainerHigh : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            boxShadow: const [
              BoxShadow(color: Color(0x0A142433), blurRadius: 2, offset: Offset(0, 1)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 18, color: widget.iconColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.label,
                  style: AppTextStyles.labelMd.copyWith(color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EndSessionButton extends StatefulWidget {
  @override
  State<_EndSessionButton> createState() => _EndSessionButtonState();
}

class _EndSessionButtonState extends State<_EndSessionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              title: const Text('Xác nhận kết thúc'),
              content: const Text('Bạn có chắc chắn muốn kết thúc phiên điểm danh này?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    'Hủy bỏ',
                    style: AppTextStyles.labelMd.copyWith(color: AppColors.textSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.statusAbsent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: const Text('Xác nhận'),
                ),
              ],
            ),
          );

          if (confirm != true || !context.mounted) return;

          final vm = context.read<LiveSessionViewModel>();
          final classCode = vm.classInfo?.classCode;
          final success = await vm.closeSession();

          if (success && context.mounted) {
            if (classCode != null) {
              context.read<DashboardViewModel>().markClassInactive(classCode);
            }
            context.read<DashboardViewModel>().navigate('tong-quan');
            context.read<DashboardViewModel>().loadClasses();
          } else if (context.mounted) {
            final error = context.read<LiveSessionViewModel>().errorMessage ?? 'Lỗi khi kết thúc phiên';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error)),
            );
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.statusAbsent : AppColors.statusAbsentBg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            boxShadow: const [
              BoxShadow(color: Color(0x0A142433), blurRadius: 2, offset: Offset(0, 1)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.stop_circle_outlined,
                size: 20,
                color: _hovered ? AppColors.onError : AppColors.statusAbsent,
              ),
              const SizedBox(width: 8),
              Text(
                'Kết thúc phiên điểm danh',
                style: AppTextStyles.labelMd.copyWith(
                  color: _hovered ? AppColors.onError : AppColors.statusAbsent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple mock QR code painter
class _QrCodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dark = Paint()..color = const Color(0xFF142433);
    final teal = Paint()..color = const Color(0xFF0C7489);
    final white = Paint()..color = Colors.white;
    final scale = size.width / 160;

    void rect(Paint p, double x, double y, double w, double h, {double r = 0}) {
      final rr = RRect.fromRectAndRadius(
        Rect.fromLTWH(x * scale, y * scale, w * scale, h * scale),
        Radius.circular(r * scale),
      );
      canvas.drawRRect(rr, p);
    }

    // Top-Left target
    rect(dark, 10, 10, 40, 40, r: 4);
    rect(white, 16, 16, 28, 28);
    rect(teal, 22, 22, 16, 16, r: 2);
    // Top-Right target
    rect(dark, 110, 10, 40, 40, r: 4);
    rect(white, 116, 16, 28, 28);
    rect(teal, 122, 22, 16, 16, r: 2);
    // Bottom-Left target
    rect(dark, 10, 110, 40, 40, r: 4);
    rect(white, 16, 116, 28, 28);
    rect(teal, 22, 122, 16, 16, r: 2);

    // Matrix data dots
    final rng = math.Random(42);
    for (int row = 0; row < 20; row++) {
      for (int col = 0; col < 20; col++) {
        final x = 10 + col * 7.0;
        final y = 10 + row * 7.0;
        // Skip target zones
        if ((col < 7 && row < 7) || (col >= 14 && row < 7) || (col < 7 && row >= 14)) continue;
        // Skip center
        if (col >= 8 && col <= 12 && row >= 8 && row <= 12) continue;
        if (rng.nextDouble() < 0.4) {
          rect(dark, x, y, 5, 5);
        }
      }
    }

    // Center circle
    final centerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(80 * scale, 80 * scale), 14 * scale, centerPaint);
    final tealPaint = Paint()..color = const Color(0xFF0C7489);
    canvas.drawCircle(Offset(80 * scale, 80 * scale), 11 * scale, tealPaint);
    // Checkmark
    final checkPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(74 * scale, 80 * scale)
      ..lineTo(78 * scale, 84 * scale)
      ..lineTo(87 * scale, 75 * scale);
    canvas.drawPath(path, checkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Circular timer painter
class _CircularTimerPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  _CircularTimerPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 2;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularTimerPainter old) =>
      old.progress != progress;
}
