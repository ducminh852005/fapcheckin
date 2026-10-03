import 'package:flutter/material.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';
import 'package:fapcheckin/core/responsive/breakpoints.dart';
import 'package:fapcheckin/data/models/class_session.dart';

class ClassCard extends StatefulWidget {
  final ClassSession session;
  final VoidCallback? onStart;

  const ClassCard({super.key, required this.session, this.onStart});

  @override
  State<ClassCard> createState() => _ClassCardState();
}

class _ClassCardState extends State<ClassCard> {
  bool _hovered = false;

  ClassSession get s => widget.session;
  bool get isActive =>
      s.status == SessionStatus.active || s.status == SessionStatus.ready;

  Color get _bgColor {
    switch (s.status) {
      case SessionStatus.active:
      case SessionStatus.ready:
        return AppColors.primaryLight.withValues(alpha: 0.5);
      case SessionStatus.completed:
        return AppColors.statusAbsentBg.withValues(alpha: 0.5);
      case SessionStatus.notStarted:
      default:
        return AppColors.surface;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Color(0x0F142433),
              blurRadius: _hovered ? 8 : 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Slot badge
                _SlotBadge(slot: s.slot, isActive: isActive),
                SizedBox(width: 12),
                // Course info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Text(
                            s.courseCode,
                            style: AppTextStyles.headlineSm.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (s.isMakeup) ...[
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFFEDE7F6),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusFull,
                                ),
                                border: Border.all(
                                  color: Color(0xFFB39DDB),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                'Học bù',
                                style: AppTextStyles.labelSm.copyWith(
                                  color: Color(0xFF6A1B9A),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                          Text(
                            '•',
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                          Text(
                            s.courseName,
                            style: AppTextStyles.bodyMd.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Wrap(
                        spacing: 16,
                        runSpacing: 4,
                        children: [
                          _MetaChip(
                            icon: Icons.schedule_outlined,
                            label: s.timeRange,
                            isCode: true,
                            highlight: isActive,
                          ),
                          _MetaChip(
                            icon: _roomIcon(s.roomType),
                            label: '${s.roomType} ${s.room}',
                          ),
                          _MetaChip(
                            icon: Icons.group_outlined,
                            label: '${s.studentCount} sinh viên',
                            isCode: true,
                            codeColor: isActive
                                ? AppColors.primaryDark
                                : AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!context.isMobile) ...[
                  SizedBox(width: 12),
                  // Status + action
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _StatusBadge(status: s.status),
                      SizedBox(height: 8),
                      _ActionButton(session: s, onStart: widget.onStart),
                    ],
                  ),
                ],
              ],
            ),
            // Phones: status + action move below the info
            if (context.isMobile) ...[
              SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatusBadge(status: s.status),
                  _ActionButton(session: s, onStart: widget.onStart),
                ],
              ),
            ],
            // Active session QR progress footer
            if (isActive && s.scannedCount != null) ...[
              SizedBox(height: 12),
              _ActiveSessionFooter(
                scanned: s.scannedCount!,
                total: s.studentCount,
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _roomIcon(String roomType) {
    switch (roomType) {
      case 'Lab':
        return Icons.computer_outlined;
      case 'Hội trường':
        return Icons.domain_outlined;
      default:
        return Icons.meeting_room_outlined;
    }
  }
}

class _SlotBadge extends StatelessWidget {
  final String slot;
  final bool isActive;

  const _SlotBadge({required this.slot, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryLight : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Slot',
            style: AppTextStyles.codeSm.copyWith(
              fontSize: 10,
              letterSpacing: 0.5,
              color: isActive ? AppColors.primaryDark : AppColors.textSecondary,
            ),
          ),
          Text(
            slot,
            style: AppTextStyles.code.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isActive ? AppColors.primaryDark : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isCode;
  final bool highlight;
  final Color? codeColor;

  const _MetaChip({
    required this.icon,
    required this.label,
    this.isCode = false,
    this.highlight = false,
    this.codeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: isCode
                ? AppTextStyles.code.copyWith(
                    color:
                        codeColor ??
                        (highlight
                            ? AppColors.primaryDark
                            : AppColors.textPrimary),
                    fontWeight: highlight ? FontWeight.w700 : FontWeight.w400,
                  )
                : AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatefulWidget {
  final SessionStatus status;
  const _StatusBadge({required this.status});

  @override
  State<_StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<_StatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
    if (widget.status == SessionStatus.active ||
        widget.status == SessionStatus.ready) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.status) {
      case SessionStatus.active:
      case SessionStatus.ready:
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              Flexible(
                child: Text(
                  'Phiên đang mở',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.statusPresent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      case SessionStatus.notStarted:
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Text(
            'Chưa bắt đầu',
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      case SessionStatus.completed:
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.statusAbsentBg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Text(
            'Đã hoàn thành',
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.statusAbsent,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
    }
  }
}

class _ActionButton extends StatelessWidget {
  final ClassSession session;
  final VoidCallback? onStart;
  const _ActionButton({required this.session, this.onStart});

  @override
  Widget build(BuildContext context) {
    if (session.status == SessionStatus.active) {
      return _HoverButton(
        icon: Icons.visibility_outlined,
        label: 'Xem phiên',
        primary: true,
        onTap: onStart ?? () {},
      );
    }

    if (session.status != SessionStatus.ready) {
      return SizedBox.shrink();
    }

    return _HoverButton(
      icon: Icons.play_arrow,
      label: 'Mở điểm danh',
      primary: true,
      onTap: onStart ?? () {},
    );
  }
}

class _HoverButton extends StatefulWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final bool primary;
  final VoidCallback onTap;

  const _HoverButton({
    required this.icon,
    required this.label,
    required this.primary,
    required this.onTap,
  }) : iconColor = null;

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bool p = widget.primary;
    return Tooltip(
      message: widget.label,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            padding: context.isMobile
                ? EdgeInsets.symmetric(horizontal: 14, vertical: 10)
                : EdgeInsets.all(8), // Icon only
            decoration: BoxDecoration(
              color: p
                  ? (_hovered
                        ? AppColors.primaryDark
                        : AppColors.primaryContainer)
                  : (_hovered ? AppColors.surfaceMuted : AppColors.surface),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: Color(0x0A142433),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: context.isMobile
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.icon,
                        size: 20,
                        color: p
                            ? AppColors.onPrimary
                            : (widget.iconColor ?? AppColors.textPrimary),
                      ),
                      SizedBox(width: 6),
                      Text(
                        widget.label,
                        style: AppTextStyles.labelMd.copyWith(
                          color: p
                              ? AppColors.onPrimary
                              : (widget.iconColor ?? AppColors.textPrimary),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Icon(
                    widget.icon,
                    size: 20,
                    color: p
                        ? AppColors.onPrimary
                        : (widget.iconColor ?? AppColors.textPrimary),
                  ),
          ),
        ),
      ),
    );
  }
}

class _ActiveSessionFooter extends StatelessWidget {
  final int scanned;
  final int total;

  const _ActiveSessionFooter({required this.scanned, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Icon(Icons.qr_code_scanner, size: 14, color: AppColors.statusPresent),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              'Mã QR động được kích hoạt cách đây 14 phút',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            '$scanned/$total Đã quét',
            style: AppTextStyles.codeSm.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
