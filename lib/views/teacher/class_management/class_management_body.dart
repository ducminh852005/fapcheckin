import 'package:fapcheckin/views/teacher/live_session/dialogs/start_session_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';
import 'package:fapcheckin/core/responsive/breakpoints.dart';
import 'package:fapcheckin/data/models/class_section_model.dart';
import 'package:fapcheckin/data/models/class_session.dart';
import 'package:fapcheckin/core/network/json_values.dart';
import 'package:fapcheckin/viewmodels/dashboard_viewmodel.dart';
import 'package:fapcheckin/viewmodels/live_session_viewmodel.dart';

import '../dashboard/components/class_card.dart';
import '../dashboard/components/stat_card.dart';

class ClassManagementBody extends StatelessWidget {
  const ClassManagementBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(context.isMobile ? 12 : AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatsRow(),
            SizedBox(height: AppSpacing.md),
            _MainContent(),
          ],
        ),
      ),
    );
  }
}

/// 4-column stats row
class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardViewModel>(
      builder: (context, vm, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 800) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SizedBox(
                      width: 240,
                      child: TodayScheduleStatCard(
                        totalClasses: vm.totalClassesToday,
                        morningClasses: vm.morningClasses,
                        afternoonClasses: vm.afternoonClasses,
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    SizedBox(
                      width: 240,
                      child: SessionProgressStatCard(
                        completed: vm.completedSessions,
                        total: vm.totalSessions,
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    SizedBox(
                      width: 240,
                      child: PresentStudentsStatCard(
                        present: vm.presentStudents,
                        total: vm.totalStudents,
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    SizedBox(
                      width: 240,
                      child: AvgAttendanceStatCard(
                        rate: vm.avgAttendance,
                        prevRate: vm.prevWeekAttendance,
                      ),
                    ),
                  ],
                ),
              );
            }
            return Row(
              children: [
                Expanded(
                  child: TodayScheduleStatCard(
                    totalClasses: vm.totalClassesToday,
                    morningClasses: vm.morningClasses,
                    afternoonClasses: vm.afternoonClasses,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: SessionProgressStatCard(
                    completed: vm.completedSessions,
                    total: vm.totalSessions,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: PresentStudentsStatCard(
                    present: vm.presentStudents,
                    total: vm.totalStudents,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AvgAttendanceStatCard(
                    rate: vm.avgAttendance,
                    prevRate: vm.prevWeekAttendance,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Main schedule list layout.
class _MainContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardViewModel>(
      builder: (context, vm, _) {
        return _SchedulePanel(vm: vm);
      },
    );
  }
}

/// Today's schedule panel with class list
class _SchedulePanel extends StatefulWidget {
  final DashboardViewModel vm;
  const _SchedulePanel({required this.vm});

  @override
  State<_SchedulePanel> createState() => _SchedulePanelState();
}

class _SchedulePanelState extends State<_SchedulePanel> {
  int _currentPage = 0;
  static const int _itemsPerPage = 10;

  String _getSlotTimeRange(int slot) {
    switch (slot) {
      case 1:
        return '07:30 - 09:50';
      case 2:
        return '10:00 - 12:20';
      case 3:
        return '12:50 - 15:10';
      case 4:
        return '15:20 - 17:40';
      case 5:
        return '18:00 - 20:20';
      case 6:
        return '20:30 - 22:50';
      default:
        return '-- : --';
    }
  }

  SessionStatus _deriveStatus(String timeRange, bool isActive) {
    if (timeRange.contains('--')) {
      return isActive ? SessionStatus.active : SessionStatus.notStarted;
    }
    try {
      final parts = timeRange.split('-');
      if (parts.length != 2) {
        return isActive ? SessionStatus.active : SessionStatus.notStarted;
      }

      final startParts = parts[0].trim().split(':');
      final endParts = parts[1].trim().split(':');

      if (startParts.length != 2 || endParts.length != 2) {
        return isActive ? SessionStatus.active : SessionStatus.notStarted;
      }

      final h1 = int.parse(startParts[0]);
      final m1 = int.parse(startParts[1]);

      final h2 = int.parse(endParts[0]);
      final m2 = int.parse(endParts[1]);

      final now = DateTime.now();
      final start = DateTime(
        now.year,
        now.month,
        now.day,
        h1,
        m1,
      ).subtract(Duration(minutes: 15));
      var end = DateTime(now.year, now.month, now.day, h2, m2);
      if (end.hour * 60 + end.minute <= h1 * 60 + m1) {
        end = end.add(Duration(days: 1));
      }

      if (now.isAfter(end)) return SessionStatus.completed;
      if (isActive) return SessionStatus.active;
      if (now.isBefore(start)) return SessionStatus.notStarted;

      return SessionStatus.ready;
    } catch (_) {
      return isActive ? SessionStatus.active : SessionStatus.notStarted;
    }
  }

  /// Convert ClassSectionModel to the legacy ClassSession expected by ClassCard
  ClassSession _toClassSession(ClassSectionModel model, int index) {
    final slotNumber = index + 1;
    final rawRange =
        (model.startTime != null &&
            model.endTime != null &&
            model.startTime!.isNotEmpty)
        ? '${model.startTime} - ${model.endTime}'
        : (model.timeLabel.isNotEmpty
              ? model.timeLabel
              : _getSlotTimeRange(slotNumber));
    final timeRange = formatTimeLabel(rawRange);
    return ClassSession(
      courseCode: model.classCode,
      courseName: model.subjectName,
      slot: model.slotCode.isNotEmpty ? model.slotCode : slotNumber.toString(),
      timeRange: timeRange,
      room: model.room,
      studentCount: model.studentCount,
      status: _deriveStatus(timeRange, model.isActive),
      isMakeup: model.isMakeup,
    );
  }

  @override
  void didUpdateWidget(covariant _SchedulePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.vm.classes.length != oldWidget.vm.classes.length) {
      _currentPage = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;

    // Pagination logic
    final totalClasses = vm.classes.length;
    final totalPages = (totalClasses / _itemsPerPage).ceil();
    if (_currentPage >= totalPages && totalPages > 0) {
      _currentPage = totalPages - 1;
    }
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage > totalClasses)
        ? totalClasses
        : startIndex + _itemsPerPage;

    return Container(
      padding: EdgeInsets.all(context.isMobile ? 12 : AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
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
          // Header
          Row(
            children: [
              Container(
                width: 10,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Lịch dạy hôm nay',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headlineMd.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  '$totalClasses tiết',
                  style: AppTextStyles.codeSm.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Spacer(),
              _IconButton(
                icon: Icons.refresh,
                tooltip: 'Làm mới lịch',
                onTap: () {
                  setState(() => _currentPage = 0);
                  vm.loadClasses();
                },
              ),
              SizedBox(width: 4),
              _IconButton(
                icon: Icons.filter_list,
                tooltip: 'Bộ lọc',
                onTap: () {},
              ),
            ],
          ),
          SizedBox(height: 12),
          // Body: loading / error / empty / class cards
          if (vm.isLoading)
            Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (vm.status == ViewStatus.error)
            _ErrorRetry(
              message: vm.errorMessage ?? 'Lỗi tải dữ liệu',
              onRetry: () {
                setState(() => _currentPage = 0);
                vm.loadClasses();
              },
            )
          else if (vm.classes.isEmpty)
            Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Không có tiết học hôm nay.',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else ...[
            for (int i = startIndex; i < endIndex; i++)
              Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: ClassCard(
                  session: _toClassSession(vm.classes[i], i),
                  onStart: () async {
                    final started = await startSessionWithOptions(
                      context,
                      classSection: vm.classes[i],
                      slotCode: vm.classes[i].slotCode.isNotEmpty
                          ? vm.classes[i].slotCode
                          : (i + 1).toString(),
                    );
                    if (started) vm.navigate('diem-danh-qr');
                  },
                ),
              ),
            if (totalPages > 1)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left),
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
                      icon: Icon(Icons.chevron_right),
                      onPressed: _currentPage < totalPages - 1
                          ? () => setState(() => _currentPage++)
                          : null,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            message,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.statusAbsent),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: Icon(Icons.refresh, size: 16),
            label: Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_IconButton> createState() => _IconButtonState();
}

class _IconButtonState extends State<_IconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 150),
            padding: EdgeInsets.all(context.isMobile ? 10 : 6),
            decoration: BoxDecoration(
              color: _hovered ? AppColors.surfaceMuted : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(widget.icon, size: 18, color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}
