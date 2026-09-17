import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/viewmodels/attendance_history_viewmodel.dart';

class KpiDashboard extends StatelessWidget {
  const KpiDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AttendanceHistoryViewModel>();
    final selectedClassCode = vm.selectedClassCode;
    final selectedClass = vm.classes.firstWhere(
      (c) => c.courseCode == selectedClassCode,
      orElse: () => vm.classes.first,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Class Meta Header
          Container(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Flex(
              direction: Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(color: Color(0x10000000), blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          selectedClass.courseCode.substring(0, 2).toUpperCase(),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.onPrimary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              children: [
                                Text(
                                  '${selectedClass.courseCode} — ${selectedClass.courseName} (Lớp ${selectedClass.className})',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.statusPresentBg,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: const Text(
                                    'Đang giảng dạy',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.statusPresent),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Wrap(
                              spacing: 16,
                              runSpacing: 4,
                              children: [
                                _MetaItem(icon: Icons.groups, label: 'Sĩ số: ', value: '35 sinh viên'),
                                _MetaItem(icon: Icons.badge, label: 'Giảng viên: ', value: 'TS. Nguyễn Văn An'),
                                _MetaItem(icon: Icons.meeting_room, label: 'Phòng: ', value: 'P.302 - Tòa Alpha'),
                                _MetaItem(icon: Icons.schedule, label: 'Ca 1: ', value: '07:30 - 09:50'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Action Utilities
                Wrap(
                  spacing: 8,
                  children: [
                    _ActionButton(icon: Icons.qr_code_scanner, label: 'Tạo mã QR mới'),
                    _ActionButton(icon: Icons.grid_view, label: 'Matrix Grid Cả Kỳ'),
                  ],
                ),
              ],
            ),
          ),
          
          // 4 KPI Cards
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 600;
              final crossAxisCount = isSmall ? 2 : 4;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: isSmall ? 2.5 : 2.0,
                children: [
                  _KpiCard(
                    title: 'Tiến độ điểm danh',
                    icon: Icons.event_available,
                    iconColor: AppColors.primaryContainer,
                    bgColor: AppColors.surfaceContainerLow,
                    value: '12',
                    suffix: '/ 30 buổi',
                    progressValue: 0.4,
                    progressLabel: '40%',
                  ),
                  const _KpiCard(
                    title: 'Tỷ lệ có mặt TB',
                    icon: Icons.check_circle,
                    iconColor: AppColors.statusPresent,
                    bgColor: Color(0xFFF1F8F3),
                    value: '94.2%',
                    suffix: 'Lũy kế 12 slot',
                    subtitleIcon: Icons.trending_up,
                    subtitle: 'Chỉ số chuyên cần tốt',
                  ),
                  const _KpiCard(
                    title: 'Đi trễ trung bình',
                    icon: Icons.alarm,
                    iconColor: AppColors.statusLate,
                    bgColor: Color(0xFFFFF9EE),
                    value: '3.8%',
                    suffix: 'Khoảng 1.3 sv/buổi',
                    subtitleIcon: Icons.schedule,
                    subtitle: 'TB vào muộn: 12 phút',
                  ),
                  const _KpiCard(
                    title: 'Nguy cơ cấm thi (>20%)',
                    icon: Icons.warning,
                    iconColor: AppColors.statusAbsent,
                    bgColor: Color(0xFFFDF2F3),
                    value: '02',
                    suffix: 'sinh viên',
                    subtitleIcon: Icons.notification_important,
                    subtitle: 'Đã vắng từ 5-6 buổi',
                  ),
                ],
              );
            },
          ),
          
          // Session Timeline Scroller
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.view_timeline, size: 18, color: AppColors.textSecondary),
                  SizedBox(width: 6),
                  Text('Các buổi học đã diễn ra:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                ],
              ),
              Row(
                children: [
                  _IconButton(icon: Icons.chevron_left),
                  const SizedBox(width: 4),
                  _IconButton(icon: Icons.chevron_right),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: vm.sessions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final session = vm.sessions[index];
                final slot = session['slot'] as int;
                final date = session['date'] as String;
                final isSelected = slot == vm.selectedSessionSlot;
                
                return GestureDetector(
                  onTap: () => vm.selectSession(slot),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryContainer : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isSelected ? [const BoxShadow(color: Color(0x15000000), blurRadius: 4, offset: Offset(0, 1))] : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Buổi $slot',
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? AppColors.onPrimary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
                          ),
                        ),
                        if (session['isActive'] == true) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.statusPresentBorder,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 12),
          // Session Detail Strip
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                Wrap(
                  spacing: 16,
                  children: [
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer, size: 16, color: AppColors.primaryContainer),
                        SizedBox(width: 6),
                        Text('Khung giờ mở quét QR: ', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                        Text('07:30:00 - 08:15:00', style: TextStyle(fontSize: 14, fontFamily: 'JetBrains Mono', fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.security, size: 16, color: AppColors.primaryContainer),
                        const SizedBox(width: 6),
                        const Text('Chế độ: ', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Dynamic QR 20s + Khóa BSSID FPT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        ),
                      ],
                    ),
                  ],
                ),
                Wrap(
                  spacing: 12,
                  children: [
                    _StatusCount(color: AppColors.statusPresent, label: '30 Có mặt'),
                    _StatusCount(color: AppColors.statusLate, label: '3 Đi trễ'),
                    _StatusCount(color: AppColors.statusAbsent, label: '2 Vắng'),
                  ],
                ),
              ],
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
  final String value;

  const _MetaItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ActionButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.textPrimary),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String value;
  final String suffix;
  final double? progressValue;
  final String? progressLabel;
  final IconData? subtitleIcon;
  final String? subtitle;

  const _KpiCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.value,
    required this.suffix,
    this.progressValue,
    this.progressLabel,
    this.subtitleIcon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: iconColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 20, color: iconColor),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: iconColor == AppColors.primaryContainer ? AppColors.textPrimary : iconColor, letterSpacing: -0.5),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  suffix,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: iconColor == AppColors.primaryContainer ? AppColors.textTertiary : iconColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (progressValue != null)
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: AppColors.surfaceContainerHighest,
                    color: AppColors.primaryContainer,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  progressLabel!,
                  style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            )
          else if (subtitle != null)
            Row(
              children: [
                Icon(subtitleIcon, size: 16, color: iconColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    subtitle!,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: iconColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  const _IconButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: AppColors.textSecondary),
      ),
    );
  }
}

class _StatusCount extends StatelessWidget {
  final Color color;
  final String label;

  const _StatusCount({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}
