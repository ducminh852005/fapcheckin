import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';
import 'package:fapcheckin/viewmodels/dashboard_viewmodel.dart';
import 'package:fapcheckin/views/teacher/class_management/dialogs/create_class_dialog.dart';
import 'package:fapcheckin/data/models/class_section_model.dart';
import 'saved_schedules.dart';

class TodayClassesSection extends StatefulWidget {
  const TodayClassesSection({super.key});

  @override
  State<TodayClassesSection> createState() => _TodayClassesSectionState();
}

class _TodayClassesSectionState extends State<TodayClassesSection> {
  int _scheduleVersion = 0;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardViewModel>();
    final activeClasses = viewModel.classes.where((c) => c.isActive).toList();
    final upcomingClasses = viewModel.classes.where((c) => !c.isActive).toList();
    
    final ClassSectionModel? firstActive = activeClasses.isNotEmpty ? activeClasses.first : null;
    final ClassSectionModel? firstUpcoming = upcomingClasses.isNotEmpty ? upcomingClasses.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Lớp học hôm nay',
                  style: AppTextStyles.headlineMd.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    viewModel.todayLabel,
                    style: AppTextStyles.code.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  '${viewModel.totalClassesToday} ca giảng dạy theo thời khóa biểu',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(width: AppSpacing.md),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await showDialog<Map<String, dynamic>>(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const CreateClassDialog(),
                    );
                    if (!context.mounted || result == null) return;
                    setState(() => _scheduleVersion++);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Đã lưu lịch ${result['classCode']} ngày ${result['scheduleDate']}, ca ${result['slotCode']}.'),
                    ));
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
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SavedSchedules(key: ValueKey(_scheduleVersion)),
        if (firstActive != null || firstUpcoming != null)
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 800;
              if (isSmallScreen) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (firstActive != null)
                      _ActiveSessionCard(classData: firstActive),
                    if (firstActive != null && firstUpcoming != null)
                      const SizedBox(height: AppSpacing.md),
                    if (firstUpcoming != null)
                      _UpcomingSessionCard(classData: firstUpcoming),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (firstActive != null)
                    Expanded(
                      flex: 7,
                      child: _ActiveSessionCard(classData: firstActive),
                    ),
                  if (firstActive != null && firstUpcoming != null)
                    const SizedBox(width: AppSpacing.md),
                  if (firstUpcoming != null)
                    Expanded(
                      flex: 5,
                      child: _UpcomingSessionCard(classData: firstUpcoming),
                    ),
                ],
              );
            },
          ),
        if (firstActive == null && firstUpcoming == null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text('Không có lớp học nào hôm nay.', style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary)),
            ),
          )
      ],
    );
  }
}

class _ActiveSessionCard extends StatelessWidget {
  final ClassSectionModel classData;
  const _ActiveSessionCard({required this.classData});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14142433),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Blurred Glow Effect
          Positioned(
            top: -32,
            right: -32,
            width: 128,
            height: 128,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          // Top highlight line
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 6,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryContainer,
                    AppColors.primary,
                    AppColors.primaryLight,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.terminal, size: 28, color: AppColors.onPrimary),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  classData.subjectCode,
                                  style: AppTextStyles.code.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDark,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceMuted,
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                  ),
                                  child: Text(
                                    classData.timeLabel,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              classData.subjectName,
                              style: AppTextStyles.headlineMd.copyWith(color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.statusPresentBg,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.statusPresent.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.statusPresent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Đang mở phiên điểm danh',
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.statusPresent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Mã lớp', style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
                            Text(
                              classData.classCode,
                              style: AppTextStyles.labelMd.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'JetBrains Mono',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Phòng học', style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 16, color: AppColors.primary),
                                const SizedBox(width: 4),
                                  Text(
                                    classData.room,
                                    style: AppTextStyles.labelMd.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sĩ số danh sách', style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
                            Row(
                              children: [
                                const Icon(Icons.group, size: 16, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                  Text(
                                    '${classData.studentCount} SV',
                                    style: AppTextStyles.labelMd.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'JetBrains Mono',
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
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                        children: [
                          const TextSpan(text: 'Tiến độ khóa học: '),
                          TextSpan(
                            text: 'Buổi ${classData.completedSessions} / ${classData.totalSessions}',
                            style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.trending_up, size: 15, color: AppColors.statusPresent),
                        const SizedBox(width: 4),
                          Text(
                            'Chuyên cần TB: ${classData.averageAttendance.toStringAsFixed(1)}%',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.statusPresent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: classData.totalSessions > 0 ? classData.completedSessions / classData.totalSessions : 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Material(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  elevation: 2,
                  child: InkWell(
                    onTap: () {
                      context.read<DashboardViewModel>().navigate('diem-danh-qr');
                    },
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.onPrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.qr_code_scanner, size: 24, color: AppColors.onPrimary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'VÀO ĐIỂM DANH QR TRỰC TIẾP',
                                  style: AppTextStyles.headlineSm.copyWith(
                                    color: AppColors.onPrimary,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Mở phòng chiếu QR động 20s & theo dõi sinh viên check-in tức thì',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.onPrimaryContainer,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward, size: 24, color: AppColors.onPrimary),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingSessionCard extends StatelessWidget {
  final ClassSectionModel classData;
  const _UpcomingSessionCard({required this.classData});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05142433),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.data_object, size: 28, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            classData.subjectCode,
                            style: AppTextStyles.code.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: Text(
                              classData.timeLabel,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        classData.subjectName,
                        style: AppTextStyles.headlineMd.copyWith(color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.statusUncheckedBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule, size: 14, color: AppColors.statusUnchecked),
                    const SizedBox(width: 6),
                    Text(
                      'Bắt đầu sau 1h 45p',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.statusUnchecked,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mã lớp', style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
                      Text(
                        classData.classCode,
                        style: AppTextStyles.labelMd.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Phòng học', style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
                      Text(
                        classData.room,
                        style: AppTextStyles.labelMd.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sĩ số', style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
                      Text(
                        '${classData.studentCount} SV',
                        style: AppTextStyles.labelMd.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  children: [
                    const TextSpan(text: 'Tiến độ khóa học: '),
                    TextSpan(
                      text: 'Buổi ${classData.completedSessions} / ${classData.totalSessions}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.trending_up, size: 15, color: AppColors.statusPresent),
                  const SizedBox(width: 4),
                  Text(
                    'Chuyên cần: ${classData.averageAttendance.toStringAsFixed(1)}%',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.statusPresent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: FractionallySizedBox(
               alignment: Alignment.centerLeft,
               widthFactor: classData.totalSessions > 0 ? classData.completedSessions / classData.totalSessions : 0,
               child: Container(
                 decoration: BoxDecoration(
                   color: AppColors.secondary,
                   borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                 ),
               ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.visibility, size: 18, color: AppColors.textPrimary),
                          const SizedBox(width: 8),
                          Text(
                            'Chi tiết môn',
                            style: AppTextStyles.labelMd.copyWith(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Material(
                  color: AppColors.primaryContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.tune, size: 18, color: AppColors.primaryDark),
                          const SizedBox(width: 8),
                          Text(
                            'Chuẩn bị phiên',
                            style: AppTextStyles.labelMd.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
