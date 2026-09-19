import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';
import 'package:fapcheckin/viewmodels/dashboard_viewmodel.dart';

class AllClassesGrid extends StatelessWidget {
  const AllClassesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Tất cả lớp học kỳ Fall 2023',
                  style: AppTextStyles.headlineMd.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    '6 Lớp phân công',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                _ViewToggleButton(icon: Icons.grid_view, isActive: false),
                const SizedBox(width: 4),
                _ViewToggleButton(icon: Icons.view_list, isActive: true),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(color: AppColors.surfaceContainerHigh),
            boxShadow: const [
              BoxShadow(
                color: Color(0x05142433),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _ClassListTile(
                iconData: Icons.terminal,
                iconColor: AppColors.primaryDark,
                iconBgColor: AppColors.primaryLight,
                subjectCode: 'SWP391',
                subjectTextColor: AppColors.primaryDark,
                title: 'Dự án Phát triển Phần mềm',
                groupCode: 'SE1704',
                groupBgColor: AppColors.statusPresentBg,
                groupTextColor: AppColors.statusPresent,
                statusLabel: 'Đang mở phiên',
                isStatusActive: true,
                timeLabel: 'Thứ 3 & Thứ 6 • Ca 1 (07:30 - 09:50)',
                roomLabel: 'P.302 (Tòa Alpha)',
                studentCount: '35 SV',
                progressLabel: '12/30',
                progressPercentage: 40,
                attendanceLabel: '94.2%',
                attendanceColor: AppColors.statusPresent,
                buttonLabel: 'Vào điểm danh',
                buttonIcon: Icons.qr_code_scanner,
                isPrimaryAction: true,
                onTap: () {
                  context.read<DashboardViewModel>().navigate('diem-danh-qr');
                },
              ),
              const Divider(height: 1, color: AppColors.surfaceContainerHigh),
              _ClassListTile(
                iconData: Icons.data_object,
                iconColor: AppColors.textSecondary,
                iconBgColor: AppColors.surfaceMuted,
                subjectCode: 'PRN211',
                title: 'Lập trình C# & .NET',
                groupCode: 'SE1706',
                groupBgColor: AppColors.surfaceMuted,
                groupTextColor: AppColors.textSecondary,
                statusLabel: 'Ca kế tiếp',
                timeLabel: 'Thứ 3 & Thứ 6 • Ca 2 (10:00 - 12:20)',
                roomLabel: 'P.405 (Tòa Alpha)',
                studentCount: '32 SV',
                progressLabel: '08/30',
                progressPercentage: 27,
                attendanceLabel: '96.8%',
                attendanceColor: AppColors.statusPresent,
                buttonLabel: 'Vào phòng',
                buttonIcon: Icons.qr_code,
                onTap: () {
                  context.read<DashboardViewModel>().navigate('diem-danh-qr');
                },
              ),
              const Divider(height: 1, color: AppColors.surfaceContainerHigh),
              _ClassListTile(
                iconData: Icons.developer_mode,
                iconColor: AppColors.primaryDark,
                iconBgColor: AppColors.surfaceMuted,
                subjectCode: 'PRJ301',
                title: 'Java Web Applications',
                groupCode: 'SE1612',
                groupBgColor: AppColors.surfaceMuted,
                groupTextColor: AppColors.textSecondary,
                timeLabel: 'Thứ 4 & Thứ 7 • Ca 3 (12:50 - 15:10)',
                roomLabel: 'Phòng 204 • Tòa Beta',
                studentCount: '34 SV',
                progressLabel: '14/30',
                progressPercentage: 47,
                attendanceLabel: '92.5%',
                attendanceColor: AppColors.statusPresent,
                buttonLabel: 'Vào phòng',
                buttonIcon: Icons.qr_code,
                onTap: () {
                  context.read<DashboardViewModel>().navigate('diem-danh-qr');
                },
              ),
              const Divider(height: 1, color: AppColors.surfaceContainerHigh),
              _ClassListTile(
                iconData: Icons.calculate,
                iconColor: AppColors.primaryDark,
                iconBgColor: AppColors.surfaceMuted,
                subjectCode: 'MAS291',
                title: 'Thống kê ứng dụng & Xác suất cho CNTT',
                groupCode: 'AI1701',
                groupBgColor: AppColors.surfaceMuted,
                groupTextColor: AppColors.textSecondary,
                timeLabel: 'Thứ 2 & Thứ 5 • Ca 4 (15:20 - 17:40)',
                roomLabel: 'Phòng 108 • Tòa Gamma',
                studentCount: '38 SV',
                progressLabel: '16/30',
                progressPercentage: 53,
                progressColor: AppColors.statusLate,
                attendanceLabel: '88.4%',
                attendanceColor: AppColors.statusLate,
                buttonLabel: 'Vào phòng',
                buttonIcon: Icons.qr_code,
                onTap: () {
                  context.read<DashboardViewModel>().navigate('diem-danh-qr');
                },
              ),
              const Divider(height: 1, color: AppColors.surfaceContainerHigh),
              _ClassListTile(
                iconData: Icons.bug_report,
                iconColor: AppColors.primaryDark,
                iconBgColor: AppColors.surfaceMuted,
                subjectCode: 'SWT301',
                title: 'Kiểm thử phần mềm QA (Testing)',
                groupCode: 'SE1620',
                groupBgColor: AppColors.surfaceMuted,
                groupTextColor: AppColors.textSecondary,
                timeLabel: 'Thứ 3 & Thứ 6 • Ca 5 (17:50 - 20:10)',
                roomLabel: 'Lab 3 • Tòa Innovation',
                studentCount: '30 SV',
                progressLabel: '11/30',
                progressPercentage: 37,
                attendanceLabel: '95.0%',
                attendanceColor: AppColors.statusPresent,
                buttonLabel: 'Vào phòng',
                buttonIcon: Icons.qr_code,
                onTap: () {
                  context.read<DashboardViewModel>().navigate('diem-danh-qr');
                },
              ),
              const Divider(height: 1, color: AppColors.surfaceContainerHigh),
              _ClassListTile(
                iconData: Icons.workspace_premium,
                iconColor: AppColors.onTertiaryFixed,
                iconBgColor: AppColors.tertiaryFixed,
                subjectCode: 'CPV301',
                subjectTextColor: AppColors.tertiary,
                title: 'Đồ án tốt nghiệp Capstone',
                groupCode: 'GD1601',
                groupBgColor: AppColors.tertiaryFixed,
                groupTextColor: AppColors.onTertiaryFixed,
                statusLabel: 'Sprint Review 3',
                timeLabel: 'Lịch Mentoring linh hoạt theo tuần',
                roomLabel: 'Co-working Hub',
                studentCount: '6 Nhóm (24 SV)',
                progressLabel: 'Tiến độ họp',
                progressLabelPrefix: '',
                progressPercentage: 100,
                progressColor: AppColors.primaryContainer,
                attendanceLabel: '100%',
                attendanceColor: AppColors.statusPresent,
                buttonLabel: 'Quản lý nhóm',
                buttonIcon: Icons.hub,
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ViewToggleButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;

  const _ViewToggleButton({required this.icon, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isActive ? AppColors.surfaceMuted : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Icon(
        icon,
        size: 20,
        color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
      ),
    );
  }
}

class _ClassListTile extends StatelessWidget {
  final IconData iconData;
  final Color iconColor;
  final Color iconBgColor;
  final String subjectCode;
  final Color? subjectTextColor;
  final String title;
  final String groupCode;
  final Color groupBgColor;
  final Color groupTextColor;
  final String? statusLabel;
  final bool isStatusActive;
  final String timeLabel;
  final String roomLabel;
  final String studentCount;
  final String progressLabel;
  final String progressLabelPrefix;
  final int progressPercentage;
  final Color? progressColor;
  final String attendanceLabel;
  final Color attendanceColor;
  final String buttonLabel;
  final IconData buttonIcon;
  final bool isPrimaryAction;
  final VoidCallback onTap;

  const _ClassListTile({
    required this.iconData,
    required this.iconColor,
    required this.iconBgColor,
    required this.subjectCode,
    this.subjectTextColor,
    required this.title,
    required this.groupCode,
    required this.groupBgColor,
    required this.groupTextColor,
    this.statusLabel,
    this.isStatusActive = false,
    required this.timeLabel,
    required this.roomLabel,
    required this.studentCount,
    required this.progressLabel,
    this.progressLabelPrefix = 'Tiến độ: ',
    required this.progressPercentage,
    this.progressColor,
    required this.attendanceLabel,
    required this.attendanceColor,
    required this.buttonLabel,
    required this.buttonIcon,
    this.isPrimaryAction = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onHover: (hovering) {}, // Could update color here if stateful, but simple Material ripple is ok
        onTap: () {}, // row tap maybe
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      ),
                      alignment: Alignment.center,
                      child: Icon(iconData, size: 22, color: iconColor),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                subjectCode,
                                style: AppTextStyles.code.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: subjectTextColor ?? AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                title,
                                style: AppTextStyles.headlineSm.copyWith(color: AppColors.textPrimary),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: groupBgColor,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                ),
                                child: Text(
                                  groupCode,
                                  style: AppTextStyles.caption.copyWith(
                                    color: groupTextColor,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'JetBrains Mono',
                                  ),
                                ),
                              ),
                              if (statusLabel != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isStatusActive ? AppColors.statusPresentBg : AppColors.surfaceMuted,
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isStatusActive) ...[
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: AppColors.statusPresent,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(
                                        statusLabel!,
                                        style: AppTextStyles.caption.copyWith(
                                          color: isStatusActive ? AppColors.statusPresent : AppColors.textSecondary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 16,
                            runSpacing: 4,
                            children: [
                              _InfoItem(icon: Icons.calendar_today, text: timeLabel),
                              _InfoItem(icon: Icons.meeting_room, text: roomLabel),
                              _InfoItem(icon: Icons.groups, text: studentCount),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 140,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                                children: [
                                  if (progressLabelPrefix.isNotEmpty)
                                    TextSpan(text: progressLabelPrefix),
                                  TextSpan(
                                    text: progressLabel,
                                    style: AppTextStyles.caption.copyWith(
                                      color: progressLabelPrefix.isEmpty ? AppColors.textSecondary : AppColors.textPrimary,
                                      fontWeight: progressLabelPrefix.isEmpty ? FontWeight.normal : FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              attendanceLabel,
                              style: AppTextStyles.caption.copyWith(
                                color: attendanceColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 6,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progressPercentage / 100.0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: progressColor ?? attendanceColor,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Material(
                    color: isPrimaryAction ? AppColors.primaryContainer : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              buttonIcon,
                              size: 18,
                              color: isPrimaryAction ? AppColors.onPrimary : AppColors.textPrimary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              buttonLabel,
                              style: AppTextStyles.labelMd.copyWith(
                                color: isPrimaryAction ? AppColors.onPrimary : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}
