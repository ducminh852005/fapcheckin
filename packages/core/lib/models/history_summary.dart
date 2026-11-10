import './history_class.dart';
import './session_model.dart';
import '../utils/json_values.dart';

class HistorySummary {
  final HistoryClass classInfo;
  final String teacherName;
  final List<SessionModel> sessions;
  final List<String> slotCodes;
  final List<StudentSummary> students;
  HistorySummary.fromJson(Map<String, dynamic> json)
    : classInfo = HistoryClass.fromJson(
        Map<String, dynamic>.from(json['classInfo']),
      ),
      teacherName = jsonText(json['teacherName']) ?? '',
      sessions = (json['sessions'] as List)
          .map((s) => SessionModel.fromJson(Map<String, dynamic>.from(s)))
          .toList(),
      slotCodes = (json['slots'] as List)
          .map((s) => jsonText(s['slotCode']) ?? '')
          .where((s) => s.isNotEmpty)
          .toList(),
      students = (json['students'] as List)
          .map((s) => StudentSummary.fromJson(Map<String, dynamic>.from(s)))
          .toList();
}

class StudentSummary {
  final String rollNumber, fullName, email;
  final int presentCount, lateCount, absentCount, closedSessions, totalSessions;

  /// Ngành và ảnh đại diện (nếu dữ liệu ghi danh có); rỗng khi chưa có.
  final String major, avatarPath;
  const StudentSummary({
    required this.rollNumber,
    required this.fullName,
    required this.email,
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
    required this.closedSessions,
    required this.totalSessions,
    this.major = '',
    this.avatarPath = '',
  });
  factory StudentSummary.fromJson(Map<String, dynamic> json) => StudentSummary(
    rollNumber: jsonText(json['rollNumber']) ?? '',
    fullName: jsonText(json['fullName']) ?? '',
    email: jsonText(json['email']) ?? '',
    presentCount: jsonNumber(json['presentCount'])?.toInt() ?? 0,
    lateCount: jsonNumber(json['lateCount'])?.toInt() ?? 0,
    absentCount: jsonNumber(json['absentCount'])?.toInt() ?? 0,
    closedSessions: jsonNumber(json['closedSessions'])?.toInt() ?? 0,
    totalSessions: jsonNumber(json['totalSessions'])?.toInt() ?? 0,
    major: jsonText(json['major']) ?? '',
    avatarPath: jsonText(json['avatarPath']) ?? '',
  );
  double get attendanceRate =>
      closedSessions == 0 ? 0 : (presentCount + lateCount) / closedSessions;
  double get lateRate => closedSessions == 0 ? 0 : lateCount / closedSessions;
  double get absenceRate =>
      closedSessions == 0 ? 0 : absentCount / closedSessions;
}
