import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';
import 'package:fapcheckin/data/models/student_checkin.dart';
import 'package:fapcheckin/viewmodels/live_session_viewmodel.dart';

/// Right column: stats + search + table
class CheckinPanel extends StatelessWidget {
  const CheckinPanel({super.key});

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PanelHeader(vm: vm),
              const SizedBox(height: AppSpacing.md),
              _StatsCards(vm: vm),
              const SizedBox(height: AppSpacing.md),
              _SearchAndFilter(vm: vm),
              const SizedBox(height: AppSpacing.md),
              _CheckinTable(vm: vm),
              const SizedBox(height: AppSpacing.sm),
              _TableFooter(vm: vm),
            ],
          ),
        );
      },
    );
  }
}

/// Header row: title + manual attendance button
class _PanelHeader extends StatelessWidget {
  final LiveSessionViewModel vm;
  const _PanelHeader({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Danh sách check-in thời gian thực',
                style: AppTextStyles.headlineMd.copyWith(
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Cập nhật tự động ngay khi sinh viên quét mã thành công',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _ManualButton(),
      ],
    );
  }
}

class _ManualButton extends StatefulWidget {
  @override
  State<_ManualButton> createState() => _ManualButtonState();
}

class _ManualButtonState extends State<_ManualButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.primaryDark : AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            boxShadow: const [
              BoxShadow(color: Color(0x0A142433), blurRadius: 2, offset: Offset(0, 1)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.edit_calendar_outlined, size: 18, color: AppColors.onPrimary),
              const SizedBox(width: 6),
              Text(
                'Điểm danh thủ công',
                style: AppTextStyles.labelMd.copyWith(color: AppColors.onPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 3 metric cards: present, late, unchecked
class _StatsCards extends StatelessWidget {
  final LiveSessionViewModel vm;
  const _StatsCards({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _MetricCard(
          label: 'ĐÃ ĐIỂM DANH',
          count: vm.checkedInCount,
          total: vm.totalStudents,
          countSuffix: '/ ${vm.totalStudents}',
          progress: vm.checkedInCount / vm.totalStudents,
          color: AppColors.statusPresent,
          bgColor: AppColors.statusPresentBg,
          barColor: AppColors.statusPresentBorder,
          icon: Icons.check_circle_outlined,
        )),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _MetricCard(
          label: 'ĐI TRỄ',
          count: vm.lateCount,
          countSuffix: 'sinh viên',
          progress: vm.lateCount / vm.totalStudents,
          color: AppColors.statusLate,
          bgColor: AppColors.statusLateBg,
          barColor: AppColors.statusLateBorder,
          icon: Icons.alarm_on_outlined,
        )),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _MetricCard(
          label: 'CHƯA CHECK-IN',
          count: vm.uncheckedCount,
          countSuffix: 'sinh viên',
          progress: vm.uncheckedCount / vm.totalStudents,
          color: AppColors.statusUnchecked,
          bgColor: AppColors.statusUncheckedBg,
          barColor: AppColors.statusUncheckedBorder,
          icon: Icons.person_off_outlined,
        )),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final int count;
  final int? total;
  final String countSuffix;
  final double progress;
  final Color color;
  final Color bgColor;
  final Color barColor;
  final IconData icon;

  const _MetricCard({
    required this.label,
    required this.count,
    this.total,
    required this.countSuffix,
    required this.progress,
    required this.color,
    required this.bgColor,
    required this.barColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$count',
                style: AppTextStyles.headlineLg.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                countSuffix,
                style: AppTextStyles.labelMd.copyWith(
                  color: color.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: barColor,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Search bar + filter tabs
class _SearchAndFilter extends StatelessWidget {
  final LiveSessionViewModel vm;
  const _SearchAndFilter({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Row(
        children: [
          // Search input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                boxShadow: const [
                  BoxShadow(color: Color(0x08142433), blurRadius: 2, offset: Offset(0, 1)),
                ],
              ),
              child: TextField(
                onChanged: vm.setSearchQuery,
                style: AppTextStyles.bodySm.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 10, right: 6),
                    child: Icon(Icons.search, size: 18, color: AppColors.textTertiary),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 36),
                  hintText: 'Tìm theo MSSV hoặc họ tên sinh viên...',
                  hintStyle: AppTextStyles.bodySm.copyWith(color: AppColors.textTertiary),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Filter tabs
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                _FilterTab(
                  label: 'Tất cả (${vm.totalStudents})',
                  isActive: vm.activeFilter == 'all',
                  onTap: () => vm.setFilter('all'),
                ),
                _FilterTab(
                  label: 'Đã check-in (${vm.checkedInCount})',
                  isActive: vm.activeFilter == 'checked',
                  onTap: () => vm.setFilter('checked'),
                ),
                _FilterTab(
                  label: 'Chưa check-in (${vm.uncheckedCount})',
                  isActive: vm.activeFilter == 'unchecked',
                  onTap: () => vm.setFilter('unchecked'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterTab({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: isActive
              ? const [BoxShadow(color: Color(0x0A142433), blurRadius: 2, offset: Offset(0, 1))]
              : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSm.copyWith(
            color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Data table for student check-in records
class _CheckinTable extends StatelessWidget {
  final LiveSessionViewModel vm;
  const _CheckinTable({required this.vm});

  @override
  Widget build(BuildContext context) {
    final students = vm.filteredStudents;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: const [
          BoxShadow(color: Color(0x05142433), blurRadius: 4, spreadRadius: 1),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 460),
        child: SingleChildScrollView(
          child: Table(
            columnWidths: const {
              0: FixedColumnWidth(50),  // STT
              1: FlexColumnWidth(1.2),  // MSSV
              2: FlexColumnWidth(2),    // Họ tên
              3: FlexColumnWidth(1.2),  // Thời gian
              4: FlexColumnWidth(1.5),  // Trạng thái
              5: FlexColumnWidth(1.3),  // IP
              6: FlexColumnWidth(1.2),  // Phương thức
              7: FixedColumnWidth(90),  // Thao tác
            },
            children: [
              // Header
              TableRow(
                decoration: const BoxDecoration(color: AppColors.surfaceMuted),
                children: [
                  _HeaderCell('STT', center: true),
                  _HeaderCell('MSSV'),
                  _HeaderCell('Họ và tên'),
                  _HeaderCell('Thời gian'),
                  _HeaderCell('Trạng thái'),
                  _HeaderCell('IP Mạng'),
                  _HeaderCell('Phương thức'),
                  _HeaderCell('Thao tác', center: true),
                ],
              ),
              // Data rows
              ...students.asMap().entries.map((e) {
                final i = e.key;
                final s = e.value;
                return TableRow(
                  decoration: BoxDecoration(
                    color: i.isOdd
                        ? AppColors.surfaceContainerLow.withValues(alpha: 0.3)
                        : Colors.transparent,
                  ),
                  children: [
                    _DataCell(
                      center: true,
                      child: Text(
                        s.index.toString().padLeft(2, '0'),
                        style: AppTextStyles.codeSm.copyWith(color: AppColors.textTertiary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    _DataCell(
                      child: Text(
                        s.studentId,
                        style: AppTextStyles.code.copyWith(
                          fontWeight: FontWeight.w600,
                          color: s.status == CheckinStatus.unchecked
                              ? AppColors.textSecondary
                              : AppColors.primary,
                        ),
                      ),
                    ),
                    _DataCell(
                      child: Row(
                        children: [
                          _AvatarCircle(initials: s.initials, status: s.status),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              s.fullName,
                              style: AppTextStyles.bodySm.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _DataCell(
                      child: Text(
                        s.checkInTime,
                        style: AppTextStyles.code.copyWith(
                          fontSize: 12,
                          color: s.status == CheckinStatus.late
                              ? AppColors.statusLate
                              : AppColors.textSecondary,
                          fontWeight: s.status == CheckinStatus.late
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    _DataCell(child: _StatusChip(status: s.status, lateMinutes: s.lateMinutes)),
                    _DataCell(
                      child: s.ipAddress == '--'
                          ? Text(
                              '--',
                              style: AppTextStyles.codeSm.copyWith(color: AppColors.textTertiary),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                s.ipAddress,
                                style: AppTextStyles.codeSm.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                    ),
                    _DataCell(
                      child: s.method == null
                          ? Text('--', style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary))
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  s.method == CheckinMethod.qrCode
                                      ? Icons.qr_code_2_outlined
                                      : Icons.edit_note_outlined,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    s.method == CheckinMethod.qrCode ? 'QR Code' : 'Thủ công',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    _DataCell(
                      center: true,
                      child: s.status == CheckinStatus.unchecked
                          ? _MarkPresentButton()
                          : IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textTertiary),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              splashRadius: 16,
                            ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final bool center;
  const _HeaderCell(this.text, {this.center = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        text,
        style: AppTextStyles.labelSm.copyWith(
          fontSize: 11,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
          fontWeight: FontWeight.w600,
        ),
        textAlign: center ? TextAlign.center : TextAlign.left,
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final Widget child;
  final bool center;
  const _DataCell({required this.child, this.center = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: center ? Center(child: child) : Align(alignment: Alignment.centerLeft, child: child),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final String initials;
  final CheckinStatus status;
  const _AvatarCircle({required this.initials, required this.status});

  Color get bg {
    switch (status) {
      case CheckinStatus.present:
        return AppColors.primaryLight;
      case CheckinStatus.late:
        return const Color(0xFFFFDCC2); // tertiary-fixed
      case CheckinStatus.absent:
        return AppColors.statusAbsentBg;
      case CheckinStatus.unchecked:
        return AppColors.surfaceContainerHigh;
    }
  }

  Color get fg {
    switch (status) {
      case CheckinStatus.present:
        return AppColors.primaryDark;
      case CheckinStatus.late:
        return const Color(0xFF2E1500); // on-tertiary-fixed
      case CheckinStatus.absent:
        return AppColors.statusAbsent;
      case CheckinStatus.unchecked:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTextStyles.codeSm.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final CheckinStatus status;
  final String? lateMinutes;
  const _StatusChip({required this.status, this.lateMinutes});

  @override
  Widget build(BuildContext context) {
    late Color dotColor, textColor, bgColor;
    late String label;

    switch (status) {
      case CheckinStatus.present:
        dotColor = AppColors.statusPresent;
        textColor = AppColors.statusPresent;
        bgColor = AppColors.statusPresentBg;
        label = 'Có mặt';
        break;
      case CheckinStatus.late:
        dotColor = AppColors.statusLate;
        textColor = AppColors.statusLate;
        bgColor = AppColors.statusLateBg;
        label = 'Đi trễ (${lateMinutes ?? ''})';
        break;
      case CheckinStatus.absent:
        dotColor = AppColors.statusAbsent;
        textColor = AppColors.statusAbsent;
        bgColor = AppColors.statusAbsentBg;
        label = 'Vắng mặt';
        break;
      case CheckinStatus.unchecked:
        dotColor = AppColors.statusUnchecked;
        textColor = AppColors.statusUnchecked;
        bgColor = AppColors.statusUncheckedBg;
        label = 'Chưa điểm danh';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: textColor,
                fontWeight: status == CheckinStatus.unchecked
                    ? FontWeight.w500
                    : FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkPresentButton extends StatefulWidget {
  @override
  State<_MarkPresentButton> createState() => _MarkPresentButtonState();
}

class _MarkPresentButtonState extends State<_MarkPresentButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.statusManual : AppColors.statusManualBg,
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [
              BoxShadow(color: Color(0x0A142433), blurRadius: 2, offset: Offset(0, 1)),
            ],
          ),
          child: Text(
            'Đánh dấu có mặt',
            style: AppTextStyles.caption.copyWith(
              color: _hovered ? AppColors.onPrimary : AppColors.statusManual,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Footer summary bar
class _TableFooter extends StatelessWidget {
  final LiveSessionViewModel vm;
  const _TableFooter({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(
            text: TextSpan(
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              children: [
                const TextSpan(text: 'Hiển thị '),
                TextSpan(
                  text: '${vm.filteredStudents.length}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const TextSpan(text: ' trên tổng số '),
                TextSpan(
                  text: '${vm.totalStudents}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const TextSpan(text: ' sinh viên'),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.statusPresent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Tự động cuộn khi có dữ liệu mới',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
