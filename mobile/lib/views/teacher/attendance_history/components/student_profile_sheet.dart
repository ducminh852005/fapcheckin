import 'package:fapcheckin_core/models/history_summary.dart';
import 'package:flutter/material.dart';

import '../attendance_history_colors.dart';
import '../../profile/account_dialogs.dart';
import 'attendance_student_card.dart';

class StudentProfileSheet extends StatelessWidget {
  const StudentProfileSheet({
    super.key,
    required this.student,
    required this.subjectCode,
    required this.subjectName,
    required this.classCode,
    required this.summary,
    required this.major,
    required this.avatarPath,
    required this.onChangeStatus,
    required this.onReport,
  });

  final StudentAttendanceModel student;
  final String subjectCode;
  final String subjectName;
  final String classCode;
  final StudentSummary? summary;
  final String major;
  final String avatarPath;
  final VoidCallback onChangeStatus;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final data = summary;
    final attended = data == null ? 0 : data.presentCount + data.lateCount;
    final closed = data?.closedSessions ?? 0;
    final absent = data?.absentCount ?? 0;
    final late = data?.lateCount ?? 0;
    final rate = data?.attendanceRate ?? 0;
    final safeRate = rate.clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = Theme.of(context).colorScheme.surface;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final muted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    AccountAvatar(
                      path: avatarPath,
                      initials: student.initials,
                      radius: 28,
                      backgroundColor: student.avatarBgColor,
                      textStyle: TextStyle(
                        color: student.avatarTextColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.fullName,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            student.rollNumber,
                            style: const TextStyle(
                              color: AttendanceHistoryColors.orangePrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.school_outlined,
                                size: 14,
                                color: muted,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  major.isNotEmpty
                                      ? major
                                      : 'Chưa cập nhật ngành học',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: muted,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _AttendanceStatusCard(student: student),
                const SizedBox(height: 12),
                _CourseProgressCard(
                  subjectCode: subjectCode,
                  subjectName: subjectName,
                  classCode: classCode,
                  rate: safeRate,
                  textColor: textColor,
                  muted: muted,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        label: 'Đã tham gia',
                        value: '$attended/$closed buổi',
                        color: const Color(0xFF059669),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricCard(
                        label: 'Số buổi vắng',
                        value: '$absent buổi',
                        color: absent > 0
                            ? const Color(0xFFEA580C)
                            : const Color(0xFF059669),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricCard(
                        label: 'Đi muộn',
                        value: '$late buổi',
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onChangeStatus,
                        icon: Icon(
                          student.isPresent
                              ? Icons.person_off_outlined
                              : Icons.how_to_reg_outlined,
                          size: 17,
                        ),
                        label: Text(
                          student.isPresent
                              ? 'Chuyển vắng mặt'
                              : 'Chuyển có mặt',
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                          foregroundColor: student.isPresent
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF059669),
                          side: BorderSide(
                            color: student.isPresent
                                ? const Color(0xFFFCA5A5)
                                : const Color(0xFF6EE7B7),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReport,
                        icon: const Icon(Icons.flag_outlined, size: 17),
                        label: const Text('Báo cáo'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                          foregroundColor: const Color(0xFFB45309),
                          side: const BorderSide(color: Color(0xFFFCD34D)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Xác nhận'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AttendanceHistoryColors.orangePrimary,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttendanceStatusCard extends StatelessWidget {
  const _AttendanceStatusCard({required this.student});
  final StudentAttendanceModel student;

  @override
  Widget build(BuildContext context) {
    final present = student.isPresent;
    final color = present ? const Color(0xFF059669) : const Color(0xFFDC2626);
    final background = present
        ? const Color(0xFFECFDF5)
        : const Color(0xFFFEF2F2);
    final border = present ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA);
    final method = student.state == StudentAttendanceState.presentQr
        ? 'Điểm danh bằng mã QR'
        : student.state == StudentAttendanceState.presentManual
        ? 'Giảng viên xác nhận thủ công'
        : student.state == StudentAttendanceState.absentExcused
        ? 'Vắng có phép'
        : 'Chưa ghi nhận điểm danh';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            present ? Icons.verified_rounded : Icons.cancel_outlined,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  present ? 'Đã điểm danh có mặt' : 'Vắng mặt',
                  style: TextStyle(
                    color: color,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(method, style: TextStyle(color: color, fontSize: 11.5)),
              ],
            ),
          ),
          if (student.checkinTime != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .75),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                student.checkinTime!,
                style: TextStyle(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CourseProgressCard extends StatelessWidget {
  const _CourseProgressCard({
    required this.subjectCode,
    required this.subjectName,
    required this.classCode,
    required this.rate,
    required this.textColor,
    required this.muted,
  });

  final String subjectCode, subjectName, classCode;
  final double rate;
  final Color textColor, muted;

  @override
  Widget build(BuildContext context) {
    final percentage = (rate * 100).toStringAsFixed(1);
    final safe = rate >= .8;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF172033)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.school_outlined,
                size: 18,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$subjectCode · $classCode',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: safe
                      ? const Color(0xFFD1FAE5)
                      : const Color(0xFFFFE4E6),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  safe ? 'An toàn ($percentage%)' : 'Cảnh báo ($percentage%)',
                  style: TextStyle(
                    color: safe
                        ? const Color(0xFF047857)
                        : const Color(0xFFBE123C),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subjectName, style: TextStyle(color: muted, fontSize: 12)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 9,
              color: safe ? const Color(0xFF10B981) : const Color(0xFFF97316),
              backgroundColor: const Color(0xFFE2E8F0),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Tỷ lệ điểm danh môn học: $percentage%',
            style: TextStyle(color: muted, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}
