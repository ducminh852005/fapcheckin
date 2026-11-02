import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin_core/models/class_section_model.dart';

import '../../../../viewmodels/dashboard_viewmodel.dart';
import '../dashboard_colors.dart';
import 'weekly_timetable.dart';

/// Mục "CA DẠY KẾ TIẾP" liệt kê các ca học sắp diễn ra trong ngày.
class UpcomingSessionsList extends StatelessWidget {
  const UpcomingSessionsList({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardVm = context.watch<DashboardViewModel>();

    // Lọc các lớp chưa diễn ra trong danh sách classes
    final upcomingFromClasses = dashboardVm.classes
        .where(
          (c) =>
              !c.isActive &&
              (SlotCodeParser.parse(c.slotCode)?.weekdays
                      .contains(DateTime.now().weekday) ??
                  false),
        )
        .toList();

    final List<_UpcomingSessionItemData> items = [];
    if (upcomingFromClasses.isNotEmpty) {
      for (final c in upcomingFromClasses) {
        items.add(_UpcomingSessionItemData.fromModel(c));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề + Badge Hôm nay + Xem lịch tuần >
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'CA DẠY KẾ TIẾP',
                      style: TextStyle(
                        color: DashboardColors.textMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Badge "Hôm nay"
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: DashboardColors.orangeLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Hôm nay',
                        style: TextStyle(
                          color: DashboardColors.orangePrimary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Nút "Xem lịch tuần >"
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () => dashboardVm.navigate('lich-hoc'),
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Xem lịch tuần',
                          style: TextStyle(
                            color: DashboardColors.orangePrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: DashboardColors.orangePrimary,
                          size: 15,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Danh sách các ca học hoặc Empty State
        if (items.isEmpty)
          _buildEmptyState(context, dashboardVm)
        else
          Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _buildSessionCard(context, items[i], dashboardVm),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, DashboardViewModel vm) {
    final hasNoClasses = vm.classes.isEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: DashboardColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DashboardColors.cardBorder, width: 1),
        boxShadow: DashboardColors.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: DashboardColors.orangeLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              hasNoClasses
                  ? Icons.calendar_month_outlined
                  : Icons.event_available_rounded,
              color: DashboardColors.orangePrimary,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            hasNoClasses
                ? 'Chưa có lớp học được phân công'
                : 'Không còn ca dạy kế tiếp hôm nay',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: DashboardColors.textDark,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasNoClasses
                ? 'Vào mục Lịch dạy để quét thời khóa biểu FAP hoặc kiểm tra lịch phân công.'
                : 'Bạn đã hoàn thành các ca dạy trong ngày hoặc có thể xem toàn bộ lịch tuần.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: DashboardColors.textMuted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 38,
            child: OutlinedButton.icon(
              onPressed: () => vm.navigate('lich-hoc'),
              icon: const Icon(
                Icons.calendar_today_rounded,
                size: 15,
                color: DashboardColors.orangePrimary,
              ),
              label: Text(
                hasNoClasses ? 'Mở Lịch dạy & Quét TKB' : 'Xem lịch dạy tuần',
                style: const TextStyle(
                  color: DashboardColors.orangePrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: Color(0xFFFED7AA),
                  width: 1.2,
                ),
                backgroundColor: const Color(0xFFFFF7ED),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(
    BuildContext context,
    _UpcomingSessionItemData item,
    DashboardViewModel vm,
  ) {
    return InkWell(
      onTap: () => vm.navigate('lich-hoc'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: DashboardColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: DashboardColors.cardBorder, width: 1),
          boxShadow: DashboardColors.cardShadow,
        ),
        child: Row(
          children: [
            // Badge số CA (CA 3, CA 4)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'CA',
                    style: TextStyle(
                      color: DashboardColors.textMuted,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    item.slot,
                    style: const TextStyle(
                      color: DashboardColors.textDark,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Thông tin môn & Giờ học / Phòng học
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: item.courseCode,
                            style: const TextStyle(
                              color: DashboardColors.textDark,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const TextSpan(
                            text: '  •  ',
                            style: TextStyle(
                              color: DashboardColors.textSubtle,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: item.classCode,
                            style: const TextStyle(
                              color: DashboardColors.textMuted,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${item.timeRange} • Phòng ${item.room}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: DashboardColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Pill badge: "Chưa bắt đầu"
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: DashboardColors.statusNeutralBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Chưa bắt đầu',
                  style: TextStyle(
                    color: DashboardColors.statusNeutral,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingSessionItemData {
  final String slot;
  final String courseCode;
  final String classCode;
  final String timeRange;
  final String room;

  const _UpcomingSessionItemData({
    required this.slot,
    required this.courseCode,
    required this.classCode,
    required this.timeRange,
    required this.room,
  });

  factory _UpcomingSessionItemData.fromModel(ClassSectionModel model) {
    String slot = model.slotCode.isNotEmpty ? model.slotCode : '—';
    // Xóa chữ "Ca" nếu có trong slotCode
    slot = slot.replaceAll(RegExp(r'[^0-9]'), '');
    if (slot.isEmpty) slot = '—';

    return _UpcomingSessionItemData(
      slot: slot,
      courseCode: model.subjectCode,
      classCode: model.classCode,
      timeRange: model.timeLabel,
      room: model.room,
    );
  }
}
