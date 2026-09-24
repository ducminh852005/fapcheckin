import '../../core/network/json_values.dart';

/// Model for ClassSection from API (getClasses action)
class ClassSectionModel {
  final String classCode;
  final String subjectCode;
  final String subjectName;
  final String room;
  final int studentCount;
  final String teacherMemberCode;
  final String slotCode;
  final String? startTime;
  final String? endTime;
  final String? period;

  // Enriched fields
  final String timeLabel;
  final int completedSessions;
  final int totalSessions;
  final double averageAttendance;
  final bool isActive;
  final String? activeSessionId;
  final bool isMakeup;

  const ClassSectionModel({
    required this.classCode,
    required this.subjectCode,
    required this.subjectName,
    required this.room,
    required this.studentCount,
    required this.teacherMemberCode,
    this.slotCode = '',
    this.startTime,
    this.endTime,
    this.period,
    required this.timeLabel,
    required this.completedSessions,
    required this.totalSessions,
    required this.averageAttendance,
    required this.isActive,
    this.activeSessionId,
    this.isMakeup = false,
  });

  factory ClassSectionModel.fromJson(Map<String, dynamic> json) {
    final start = jsonText(json['startTime']);
    final end = jsonText(json['endTime']);
    final rawLabel = jsonText(json['timeLabel']);
    return ClassSectionModel(
      classCode: jsonText(json['classCode']) ?? '',
      subjectCode: jsonText(json['subjectCode']) ?? 'UNK',
      subjectName: jsonText(json['subjectName']) ?? '',
      room: jsonText(json['room']) ?? '',
      studentCount: jsonNumber(json['studentCount'])?.toInt() ?? 0,
      teacherMemberCode: jsonText(json['teacherMemberCode']) ?? '',
      slotCode: jsonText(json['slotCode']) ?? '',
      startTime: start != null ? formatTimeLabel(start) : null,
      endTime: end != null ? formatTimeLabel(end) : null,
      period: jsonText(json['period']),
      timeLabel: formatTimeLabel(rawLabel ?? (start != null && end != null ? '$start - $end' : 'Chưa rõ')),
      completedSessions: jsonNumber(json['completedSessions'])?.toInt() ?? 0,
      totalSessions: jsonNumber(json['totalSessions'])?.toInt() ?? 30,
      averageAttendance:
          jsonNumber(json['averageAttendance'])?.toDouble() ?? 0.0,
      isActive: jsonBool(json['isActive']) ?? false,
      activeSessionId: jsonText(json['activeSessionId']),
      isMakeup: jsonBool(json['isMakeup']) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'classCode': classCode,
    'subjectCode': subjectCode,
    'subjectName': subjectName,
    'room': room,
    'studentCount': studentCount,
    'teacherMemberCode': teacherMemberCode,
    'slotCode': slotCode,
    if (startTime != null) 'startTime': startTime,
    if (endTime != null) 'endTime': endTime,
    if (period != null) 'period': period,
    'timeLabel': timeLabel,
    'completedSessions': completedSessions,
    'totalSessions': totalSessions,
    'averageAttendance': averageAttendance,
    'isActive': isActive,
    'activeSessionId': activeSessionId,
    'isMakeup': isMakeup,
  };

  ClassSectionModel copyWith({
    String? classCode,
    String? subjectCode,
    String? subjectName,
    String? room,
    int? studentCount,
    String? teacherMemberCode,
    String? timeLabel,
    int? completedSessions,
    int? totalSessions,
    double? averageAttendance,
    bool? isActive,
    String? activeSessionId,
    bool? isMakeup,
  }) {
    return ClassSectionModel(
      classCode: classCode ?? this.classCode,
      subjectCode: subjectCode ?? this.subjectCode,
      subjectName: subjectName ?? this.subjectName,
      room: room ?? this.room,
      studentCount: studentCount ?? this.studentCount,
      teacherMemberCode: teacherMemberCode ?? this.teacherMemberCode,
      timeLabel: timeLabel ?? this.timeLabel,
      completedSessions: completedSessions ?? this.completedSessions,
      totalSessions: totalSessions ?? this.totalSessions,
      averageAttendance: averageAttendance ?? this.averageAttendance,
      isActive: isActive ?? this.isActive,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      isMakeup: isMakeup ?? this.isMakeup,
    );
  }
}
