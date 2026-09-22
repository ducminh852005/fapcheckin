import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';
import 'package:fapcheckin/data/models/class_section_model.dart';
import 'package:fapcheckin/viewmodels/dashboard_viewmodel.dart';
import 'package:fapcheckin/viewmodels/live_session_viewmodel.dart';
import 'package:fapcheckin/views/teacher/class_management/dialogs/create_class_dialog.dart';
import 'package:fapcheckin/views/teacher/class_management/dialogs/class_detail_dialog.dart';
class AllClassesGrid extends StatefulWidget {
  const AllClassesGrid({super.key});

  @override
  State<AllClassesGrid> createState() => _AllClassesGridState();
}

class _AllClassesGridState extends State<AllClassesGrid> {
  int _currentPage = 0;
  static const int _itemsPerPage = 10;
  bool _isGridView = false;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardViewModel>();
    final classes = viewModel.classes;

    final totalClasses = classes.length;
    final totalPages = (totalClasses / _itemsPerPage).ceil();
    if (_currentPage >= totalPages && totalPages > 0) {
      _currentPage = totalPages - 1;
    }
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage > totalClasses) 
        ? totalClasses 
        : startIndex + _itemsPerPage;
        
    final paginatedClasses = totalClasses > 0 ? classes.sublist(startIndex, endIndex) : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Tất cả lớp học kỳ ${viewModel.semester}',
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
                    '${classes.length} Lớp phân công',
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
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await showDialog<Map<String, dynamic>>(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const CreateClassDialog(),
                    );
                    if (!context.mounted || result == null) return;
                    context.read<DashboardViewModel>().loadClasses();

                    context.read<LiveSessionViewModel>().triggerToast(
                      type: ToastType.custom,
                      title: 'Đăng ký dạy bù thành công!',
                      message: 'Lớp ${result['classCode']} - Ngày ${result['scheduleDate']} (Ca ${result['slotCode']}).',
                      icon: Icons.check_circle_outline,
                      accentColor: AppColors.statusPresent,
                      duration: const Duration(seconds: 4),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tạo lịch học mới'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    textStyle: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                GestureDetector(
                  onTap: () => setState(() => _isGridView = true),
                  child: _ViewToggleButton(icon: Icons.grid_view, isActive: _isGridView),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => setState(() => _isGridView = false),
                  child: _ViewToggleButton(icon: Icons.view_list, isActive: !_isGridView),
                ),
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
              if (!_isGridView)
                ...paginatedClasses.asMap().entries.map((entry) {
                  final index = entry.key;
                  final classData = entry.value;
                  final isLast = index == paginatedClasses.length - 1;

                  final progressPercentage = classData.totalSessions > 0
                      ? ((classData.completedSessions / classData.totalSessions) * 100).toInt()
                      : 0;

                  Widget tile = _ClassListTile(
                    iconData: Icons.class_outlined,
                    iconColor: AppColors.textSecondary,
                    iconBgColor: AppColors.surfaceMuted,
                    subjectCode: classData.subjectCode,
                    subjectTextColor: null,
                    title: classData.subjectName,
                    groupCode: classData.classCode,
                    groupBgColor: AppColors.surfaceMuted,
                    groupTextColor: AppColors.textSecondary,
                    statusLabel: null,
                    isStatusActive: false,
                    timeLabel: classData.timeLabel,
                    roomLabel: classData.room,
                    studentCount: '${classData.studentCount} SV',
                    progressLabel: '${classData.completedSessions}/${classData.totalSessions}',
                    progressPercentage: progressPercentage,
                    attendanceLabel: '${classData.averageAttendance.toStringAsFixed(1)}%',
                    attendanceColor: AppColors.statusPresent,
                    buttonLabel: 'Xem chi tiết',
                    buttonIcon: Icons.visibility_outlined,
                    isPrimaryAction: false,
                    onTap: () => _showClassDetailDialog(context, classData),
                  );

                  return Column(
                    children: [
                      tile,
                      if (!isLast || totalPages > 1)
                        const Divider(height: 1, color: AppColors.surfaceContainerHigh),
                    ],
                  );
                }),
              if (_isGridView)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 350,
                      mainAxisExtent: 260,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                    ),
                    itemCount: paginatedClasses.length,
                    itemBuilder: (context, index) {
                      final classData = paginatedClasses[index];
                      final progressPercentage = classData.totalSessions > 0
                          ? ((classData.completedSessions / classData.totalSessions) * 100).toInt()
                          : 0;
                      return _ClassGridCard(
                        iconData: Icons.class_outlined,
                        iconColor: AppColors.textSecondary,
                        iconBgColor: AppColors.surfaceMuted,
                        subjectCode: classData.subjectCode,
                        subjectTextColor: null,
                        title: classData.subjectName,
                        groupCode: classData.classCode,
                        groupBgColor: AppColors.surfaceMuted,
                        groupTextColor: AppColors.textSecondary,
                        statusLabel: null,
                        isStatusActive: false,
                        timeLabel: classData.timeLabel,
                        roomLabel: classData.room,
                        studentCount: '${classData.studentCount} SV',
                        progressLabel: '${classData.completedSessions}/${classData.totalSessions}',
                        progressPercentage: progressPercentage,
                        attendanceLabel: '${classData.averageAttendance.toStringAsFixed(1)}%',
                        attendanceColor: AppColors.statusPresent,
                        buttonLabel: 'Xem chi tiết',
                        buttonIcon: Icons.visibility_outlined,
                        isPrimaryAction: false,
                        onTap: () => _showClassDetailDialog(context, classData),
                      );
                    },
                  ),
                ),
              if (totalPages > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _currentPage > 0
                            ? () => setState(() => _currentPage--)
                            : null,
                        color: AppColors.textSecondary,
                      ),
                      Text(
                        'Trang ${_currentPage + 1} / $totalPages',
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _currentPage < totalPages - 1
                            ? () => setState(() => _currentPage++)
                            : null,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
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
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  iconData,
                  size: 20,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('Xem chi tiết'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
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

class _ClassGridCard extends StatelessWidget {
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

  const _ClassGridCard({
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(
                  iconData,
                  size: 18,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.headlineSm.copyWith(color: AppColors.textPrimary, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
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
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.visibility_outlined, size: 16),
              label: const Text('Xem chi tiết'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _showClassDetailDialog(BuildContext context, ClassSectionModel classData) {
  ClassDetailDialog.show(context, classData);
}
