import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';
import 'package:fapcheckin/core/responsive/breakpoints.dart';
import 'package:fapcheckin/viewmodels/live_session_viewmodel.dart';
import 'package:fapcheckin/viewmodels/dashboard_viewmodel.dart';
import 'package:flutter/services.dart';

String kCheckinBaseUrl =
    'https://script.google.com/macros/s/AKfycbwhbrv6Y76dGETuwDeMqObH1Dvf9RwQ5obDkxuuR-x5m2T3JoCByY0EuuB4ptuTHC3cwA/exec';

/// Left column: class info + QR code + session controls
class QrPanel extends StatelessWidget {
  final double? minHeight;

  const QrPanel({super.key, this.minHeight});

  @override
  Widget build(BuildContext context) {
    return Consumer<LiveSessionViewModel>(
      builder: (context, vm, _) {
        return Container(
          width: double.infinity,
          constraints: minHeight == null || context.isMobile
              ? null
              : BoxConstraints(minHeight: minHeight!),
          padding: EdgeInsets.all(context.isMobile ? 12 : AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            boxShadow: [
              BoxShadow(
                color: Color(0x0A142433),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ClassInfoHeader(vm: vm),
              SizedBox(height: AppSpacing.md),
              _QrCodeDisplay(vm: vm),
              SizedBox(height: AppSpacing.md),
              _SessionInfoGrid(vm: vm),
              SizedBox(height: AppSpacing.md),
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
          children: [
            Expanded(
              child: Text(
                vm.courseCategory.toUpperCase(),
                style: AppTextStyles.codeSm.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            SizedBox(width: 8),
            _ActiveBadge(),
          ],
        ),
        SizedBox(height: 4),
        Text(
          '${vm.courseCode} — ${vm.courseName}',
          style: AppTextStyles.headlineMd.copyWith(
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 8),
        // Meta chips row
        Container(
          padding: EdgeInsets.all(10),
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
              Text(
                '•',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              _MetaItem(icon: Icons.schedule_outlined, label: vm.slot),
              Text(
                '•',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
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
      duration: Duration(milliseconds: 1000),
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
    final liveVm = context.watch<LiveSessionViewModel>();
    final isClosed = liveVm.isClosed;

    if (isClosed) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.statusAbsentBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          boxShadow: [
            BoxShadow(
              color: Color(0x0A142433),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.statusAbsent,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 6),
            Text(
              'Phiên đã đóng',
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.statusAbsent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.statusPresentBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A142433),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
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
                decoration: BoxDecoration(
                  color: AppColors.statusPresent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          SizedBox(width: 6),
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
        SizedBox(width: 4),
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

/// QR code display with a one-minute rotation countdown.
class _QrCodeDisplay extends StatelessWidget {
  final LiveSessionViewModel vm;
  const _QrCodeDisplay({required this.vm});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final outerPad = context.isMobile ? 12.0 : 20.0;
        final width = constraints.maxWidth < 360 ? constraints.maxWidth : 360.0;
        // outer padding + inner (12) padding on both sides
        final qrSize = (width - 2 * outerPad - 24).clamp(140.0, 220.0);
        return _buildQr(context, outerPad, qrSize);
      },
    );
  }

  Widget _buildQr(BuildContext context, double outerPad, double qrSize) {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: 360),
        padding: EdgeInsets.all(outerPad),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: [
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
                child: SizedBox.shrink(),
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
                child: SizedBox.shrink(),
              ),
            ),
            // QR + rotation status
            Column(
              children: [
                // QR Code placeholder
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x12142433),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: vm.session == null
                      ? SizedBox(
                          width: qrSize,
                          height: qrSize,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 48,
                                color: AppColors.textTertiary,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Phiên đã kết thúc',
                                style: AppTextStyles.labelMd.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : vm.qrToken.isEmpty
                      ? SizedBox(
                          width: qrSize,
                          height: qrSize,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : QrImageView(
                          data: vm.checkinUrl,
                          version: QrVersions.auto,
                          size: qrSize,
                          backgroundColor: Colors.white,
                        ),
                ),
                SizedBox(height: 16),
                // One-minute QR countdown
                if (vm.session != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x0A142433),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: Size(36, 36),
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
                        SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Đổi mã bảo mật: ${vm.qrRefreshSeconds}s / ${LiveSessionViewModel.qrCycleDuration}s',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.labelSm.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Chu kỳ làm mới 1 phút',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
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
    final timeTile = _InfoTile(
      icon: Icons.timer_outlined,
      label: 'Thời gian phiên còn lại',
      value: vm.sessionTimeDisplay,
      valueSuffix: 'phút',
      valueColor: AppColors.primaryDark,
    );
    final ipTile = vm.ipCheck
        ? _InfoTile(
            icon: Icons.wifi_lock_outlined,
            label: 'IP Wi-Fi FPT Giảng viên',
            value: vm.teacherIp,
            showVerified: true,
          )
        : const _InfoTile(
            icon: Icons.wifi_off_outlined,
            label: 'Kiểm tra IP mạng',
            value: 'Tắt',
          );
    return Column(
      children: [
        if (context.isMobile)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              timeTile,
              SizedBox(height: AppSpacing.sm),
              ipTile,
            ],
          )
        else
          Row(
            children: [
              Expanded(child: timeTile),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: ipTile),
            ],
          ),
        SizedBox(height: AppSpacing.sm),
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
      padding: EdgeInsets.all(12),
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
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
              ),
              if (valueSuffix != null) ...[
                SizedBox(width: 4),
                Text(
                  valueSuffix!,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
              if (showVerified) ...[
                SizedBox(width: 6),
                Icon(Icons.verified, size: 16, color: AppColors.statusPresent),
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
      duration: Duration(milliseconds: 1500),
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
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A142433),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
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
                decoration: BoxDecoration(
                  color: AppColors.statusPresent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
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
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
    final vm = context.watch<LiveSessionViewModel>();
    final refreshBtn = _ControlBtn(
      icon: Icons.sync,
      iconColor: AppColors.primary,
      label: 'Làm mới QR ngay',
      onTap: vm.isClosed ? () {} : () => vm.refreshQrNow(),
    );
    final copyBtn = _ControlBtn(
      icon: Icons.content_copy_outlined,
      iconColor: AppColors.textSecondary,
      label: 'Sao chép URL dự phòng',
      onTap: () async {
        if (vm.checkinUrl.isEmpty) return;
        await Clipboard.setData(ClipboardData(text: vm.checkinUrl));
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Đã sao chép URL điểm danh.')));
        }
      },
    );
    return Column(
      children: [
        if (context.isMobile)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [refreshBtn, SizedBox(height: 8), copyBtn],
          )
        else
          Row(
            children: [
              Expanded(child: refreshBtn),
              SizedBox(width: 8),
              Expanded(child: copyBtn),
            ],
          ),
        SizedBox(height: 8),
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
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: context.isMobile ? 14 : 10,
          ),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.surfaceContainerHigh
                : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            boxShadow: [
              BoxShadow(
                color: Color(0x0A142433),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 18, color: widget.iconColor),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.label,
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.textPrimary,
                  ),
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
    final liveVm = context.watch<LiveSessionViewModel>();
    final isClosed = liveVm.isClosed;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: isClosed
            ? null
            : () async {
                final dashVm = context.read<DashboardViewModel>();

                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('Kết thúc phiên điểm danh?'),
                    content: Text(
                      'Hệ thống sẽ tự động chuyển trạng thái phiên thành Đã đóng và ghi nhận Vắng mặt cho các sinh viên chưa quét QR.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text('Hủy'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.statusAbsent,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: Text('Kết thúc phiên'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && context.mounted) {
                  final classCode = liveVm.classInfo?.classCode;
                  final success = await liveVm.closeCurrentSession();
                  if (context.mounted) {
                    if (success) {
                      if (classCode != null) {
                        dashVm.markClassInactive(classCode);
                      }
                      dashVm.loadClasses();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            liveVm.errorMessage ??
                                'Không thể kết thúc phiên điểm danh',
                          ),
                          backgroundColor: AppColors.statusAbsent,
                        ),
                      );
                    }
                  }
                }
              },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: context.isMobile ? 14 : 10),
          decoration: BoxDecoration(
            color: isClosed
                ? AppColors.surfaceMuted
                : (_hovered
                      ? AppColors.statusAbsent
                      : AppColors.statusAbsentBg),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            boxShadow: [
              BoxShadow(
                color: Color(0x0A142433),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isClosed
                    ? Icons.check_circle_outline
                    : Icons.stop_circle_outlined,
                size: 20,
                color: isClosed
                    ? AppColors.textSecondary
                    : (_hovered ? AppColors.onError : AppColors.statusAbsent),
              ),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  isClosed
                      ? 'Phiên điểm danh đã kết thúc'
                      : 'Kết thúc phiên điểm danh',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMd.copyWith(
                    color: isClosed
                        ? AppColors.textSecondary
                        : (_hovered
                              ? AppColors.onError
                              : AppColors.statusAbsent),
                    fontWeight: FontWeight.w600,
                  ),
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
    final dark = Paint()..color = Color(0xFF142433);
    final teal = Paint()..color = Color(0xFF0C7489);
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
        if ((col < 7 && row < 7) ||
            (col >= 14 && row < 7) ||
            (col < 7 && row >= 14)) {
          continue;
        }
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
    final tealPaint = Paint()..color = Color(0xFF0C7489);
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

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

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
