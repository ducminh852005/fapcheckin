import '../../core/network/json_values.dart';
import 'session_model.dart';

class HistoryClass {
  final String classCode, subjectCode, subjectName, room;
  final int studentCount, completedSessions, totalSessions, atRiskCount;
  final double attendanceRate, lateRate;
  final SessionModel? latestSession;
  HistoryClass.fromJson(Map<String, dynamic> json)
    : classCode = jsonText(json['classCode']) ?? '',
      subjectCode = jsonText(json['subjectCode']) ?? '',
      subjectName = jsonText(json['subjectName']) ?? '',
      room = jsonText(json['room']) ?? '',
      studentCount = jsonNumber(json['studentCount'])?.toInt() ?? 0,
      completedSessions = jsonNumber(json['completedSessions'])?.toInt() ?? 0,
      totalSessions = jsonNumber(json['totalSessions'])?.toInt() ?? 0,
      atRiskCount = jsonNumber(json['atRiskCount'])?.toInt() ?? 0,
      attendanceRate = jsonNumber(json['attendanceRate'])?.toDouble() ?? 0,
      lateRate = jsonNumber(json['lateRate'])?.toDouble() ?? 0,
      latestSession = json['latestSession'] == null
          ? null
          : SessionModel.fromJson(
              Map<String, dynamic>.from(json['latestSession']),
            );
}
