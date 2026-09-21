import '../../core/network/json_values.dart';

/// Model for ClassSection from API (getClasses action)
class ClassSectionModel {
  final String classCode;
  final String subjectCode;
  final String subjectName;
  final String room;
  final int studentCount;
  final String teacherMemberCode;

  // Enriched fields
  final String timeLabel;
  final int completedSessions;
  final int totalSessions;
  final double averageAttendance;
  final bool isActive;
  final String? activeSessionId;

  const ClassSectionModel({
    required this.classCode,
    required this.subjectCode,
    required this.subjectName,
    required this.room,
    required this.studentCount,
    required this.teacherMemberCode,
    required this.timeLabel,
    required this.completedSessions,
    required this.totalSessions,
    required this.averageAttendance,
    required this.isActive,
    this.activeSessionId,
  });

  factory ClassSectionModel.fromJson(Map<String, dynamic> json) {
    return ClassSectionModel(
      classCode: jsonText(json['classCode']) ?? '',
      subjectCode: jsonText(json['subjectCode']) ?? 'UNK',
      subjectName: jsonText(json['subjectName']) ?? '',
      room: jsonText(json['room']) ?? '',
      studentCount: jsonNumber(json['studentCount'])?.toInt() ?? 0,
      teacherMemberCode: jsonText(json['teacherMemberCode']) ?? '',
      timeLabel: jsonText(json['timeLabel']) ?? 'Chưa rõ',
      completedSessions: jsonNumber(json['completedSessions'])?.toInt() ?? 0,
      totalSessions: jsonNumber(json['totalSessions'])?.toInt() ?? 30,
      averageAttendance:
          jsonNumber(json['averageAttendance'])?.toDouble() ?? 0.0,
      isActive: jsonBool(json['isActive']) ?? false,
      activeSessionId: jsonText(json['activeSessionId']),
    );
  }

  Map<String, dynamic> toJson() => {
    'classCode': classCode,
    'subjectCode': subjectCode,
    'subjectName': subjectName,
    'room': room,
    'studentCount': studentCount,
    'teacherMemberCode': teacherMemberCode,
    'timeLabel': timeLabel,
    'completedSessions': completedSessions,
    'totalSessions': totalSessions,
    'averageAttendance': averageAttendance,
    'isActive': isActive,
    'activeSessionId': activeSessionId,
  };
}
