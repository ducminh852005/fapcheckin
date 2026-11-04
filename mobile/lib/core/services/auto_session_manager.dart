import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fapcheckin_core/constants/app_colors.dart';
import 'package:fapcheckin_core/models/class_section_model.dart';
import 'package:fapcheckin_core/repositories/teacher_repository.dart';

import '../../viewmodels/dashboard_viewmodel.dart';
import '../../viewmodels/live_session_viewmodel.dart';
import '../../views/teacher/dashboard/components/weekly_timetable.dart';

/// Hỗ trợ xác định thời gian bắt đầu và kết thúc của ca học theo ngày.
class TimeSlotHelper {
  static (DateTime?, DateTime?) resolveStandardSlotRange(
    DateTime date,
    ClassSectionModel c,
  ) {
    DateTime? start = _parseTime(date, c.startTime);
    DateTime? end = _parseTime(date, c.endTime);
    if (start != null && end != null) return (start, end);

    final m = RegExp(r'(\d{1,2}:\d{2})\s*[–-]\s*(\d{1,2}:\d{2})')
        .firstMatch(c.timeLabel);
    if (m != null) {
      start ??= _parseTime(date, m.group(1));
      end ??= _parseTime(date, m.group(2));
    }
    if (start != null && end != null) return (start, end);

    final slotInfo = SlotCodeParser.parse(c.slotCode);
    final slotNum =
        slotInfo?.slot ??
        int.tryParse(c.slotCode.replaceAll(RegExp(r'\D'), '')) ??
        1;

    switch (slotNum) {
      case 1:
        start = DateTime(date.year, date.month, date.day, 7, 0);
        end = DateTime(date.year, date.month, date.day, 9, 15);
        break;
      case 2:
        start = DateTime(date.year, date.month, date.day, 9, 30);
        end = DateTime(date.year, date.month, date.day, 11, 45);
        break;
      case 3:
        start = DateTime(date.year, date.month, date.day, 12, 30);
        end = DateTime(date.year, date.month, date.day, 14, 45);
        break;
      case 4:
        start = DateTime(date.year, date.month, date.day, 15, 0);
        end = DateTime(date.year, date.month, date.day, 17, 15);
        break;
      case 5:
        start = DateTime(date.year, date.month, date.day, 17, 30);
        end = DateTime(date.year, date.month, date.day, 19, 45);
        break;
      case 6:
        start = DateTime(date.year, date.month, date.day, 20, 0);
        end = DateTime(date.year, date.month, date.day, 22, 15);
        break;
      default:
        start = DateTime(date.year, date.month, date.day, 7, 0);
        end = DateTime(date.year, date.month, date.day, 9, 15);
        break;
    }
    return (start, end);
  }

  static (DateTime?, DateTime?) resolveSlotRange(
    DateTime date,
    ClassSectionModel c,
  ) {
    return resolveStandardSlotRange(date, c);
  }

  static DateTime? _parseTime(DateTime date, String? s) {
    if (s == null || s.trim().isEmpty) return null;
    final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(s.trim());
    if (m == null) return null;
    final h = int.tryParse(m.group(1)!);
    final min = int.tryParse(m.group(2)!);
    if (h == null || min == null) return null;
    return DateTime(date.year, date.month, date.day, h, min);
  }
}

/// Tự động quản lý vòng đời phiên học theo thời gian thực (Real-time Session Manager):
/// 1. Tự động mở phiên khi chạm vào khung giờ ca học (now >= startDt && now < endDt)
/// 2. Tự động kết thúc phiên khi hết giờ ca học (now >= endDt)
class AutoSessionManager {
  final LiveSessionViewModel liveSessionViewModel;
  final DashboardViewModel dashboardViewModel;
  final TeacherRepository teacherRepository;
  final DateTime Function() _now;

  AutoSessionManager({
    required this.liveSessionViewModel,
    required this.dashboardViewModel,
    required this.teacherRepository,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  Timer? _timer;
  final Set<String> _autoClosedSessionsToday = {};
  String? _currentDayKey;
  bool _isProcessing = false;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => checkRealtimeSessions(),
    );
    checkRealtimeSessions();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> checkRealtimeSessions() async {
    if (_isProcessing) return;
    final classes = dashboardViewModel.classes;
    if (classes.isEmpty) return;

    _isProcessing = true;
    try {
      final now = _now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      if (_currentDayKey != todayStr) {
        _currentDayKey = todayStr;
        _autoClosedSessionsToday.clear();
      }

      for (final c in classes) {
        final info = SlotCodeParser.parse(c.slotCode);
        final isToday = info != null
            ? info.weekdays.contains(now.weekday)
            : false;
        if (!isToday) continue;

        final (startDt, endDt) = TimeSlotHelper.resolveSlotRange(now, c);
        if (startDt == null || endDt == null) continue;

        final classKey = '${c.classCode}_${todayStr}_${c.slotCode}';

        // 1. Tự động đóng lớp khi hết thời gian ca học (now >= endDt)
        if (now.isAfter(endDt) || now.isAtSameMomentAs(endDt)) {
          if (!_autoClosedSessionsToday.contains(classKey)) {
            if (liveSessionViewModel.session?.isOpen == true &&
                liveSessionViewModel.session?.classCode == c.classCode) {
              _autoClosedSessionsToday.add(classKey);
              await liveSessionViewModel.closeCurrentSession();
              await dashboardViewModel.loadClasses();
              liveSessionViewModel.triggerToast(
                type: ToastType.closeSession,
                title: 'Ca học đã kết thúc!',
                message:
                    'Lớp ${c.classCode} (${c.subjectCode}) đã hết giờ và tự động đóng điểm danh.',
                icon: Icons.check_circle_outline,
                accentColor: AppColors.statusPresent,
              );
            } else if (c.isActive && (c.activeSessionId?.isNotEmpty ?? false)) {
              _autoClosedSessionsToday.add(classKey);
              await teacherRepository.closeSession(
                sessionId: c.activeSessionId!,
              );
              await dashboardViewModel.loadClasses();
              liveSessionViewModel.triggerToast(
                type: ToastType.closeSession,
                title: 'Ca học đã kết thúc!',
                message:
                    'Lớp ${c.classCode} (${c.subjectCode}) đã hết giờ và tự động đóng điểm danh.',
                icon: Icons.check_circle_outline,
                accentColor: AppColors.statusPresent,
              );
            }
          }
        }
        // 2. Tự động mở lớp khi đến thời gian ca học (now >= startDt && now < endDt)
        else if ((now.isAfter(startDt) || now.isAtSameMomentAs(startDt)) &&
            now.isBefore(endDt)) {
          if (!c.isActive &&
              !_autoClosedSessionsToday.contains(classKey) &&
              !liveSessionViewModel.isLoading &&
              (liveSessionViewModel.session == null ||
                  !liveSessionViewModel.session!.isOpen)) {
            await liveSessionViewModel.startSession(
              classSection: c,
              slotCode: c.slotCode,
              ipCheck: liveSessionViewModel.ipCheckDefault,
            );
            await dashboardViewModel.loadClasses();
            liveSessionViewModel.triggerToast(
              type: ToastType.startSession,
              title: 'Tự động mở lớp học!',
              message:
                  'Đã đến giờ ca dạy lớp ${c.classCode} (${c.subjectCode}). Phiên điểm danh đã sẵn sàng.',
              icon: Icons.qr_code_scanner,
              accentColor: AppColors.statusPresent,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('AutoSessionManager error: $e');
    } finally {
      _isProcessing = false;
    }
  }
}
