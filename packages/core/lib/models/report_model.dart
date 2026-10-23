import '../utils/json_values.dart';

class ReportData {
  final String generatedAt;
  final String semester;
  final ReportKpiSummary kpis;
  final List<ReportMethod> methods;
  final List<ReportWeek> weekly;
  final List<ReportSubject> subjects;
  final List<ReportWarning> warnings;
  final int classCount;
  final int closedSessionCount;

  ReportData.fromJson(Map<String, dynamic> json)
    : generatedAt = jsonText(json['generatedAt']) ?? '',
      semester = jsonText(json['semester']) ?? '',
      kpis = ReportKpiSummary.fromJson(
        Map<String, dynamic>.from(json['kpis'] ?? {}),
      ),
      methods = (json['methods'] as List? ?? [])
          .map((e) => ReportMethod.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      weekly = (json['weekly'] as List? ?? [])
          .map((e) => ReportWeek.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      subjects = (json['subjects'] as List? ?? [])
          .map((e) => ReportSubject.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      warnings = (json['warnings'] as List? ?? [])
          .map((e) => ReportWarning.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      classCount = jsonNumber(json['classCount'])?.toInt() ?? 0,
      closedSessionCount = jsonNumber(json['closedSessionCount'])?.toInt() ?? 0;
}

class ReportKpiSummary {
  final double attendanceRate, lateRate;
  final int totalCheckins, atRiskCount, studentCount;
  ReportKpiSummary.fromJson(Map<String, dynamic> json)
    : attendanceRate = jsonNumber(json['attendanceRate'])?.toDouble() ?? 0,
      lateRate = jsonNumber(json['lateRate'])?.toDouble() ?? 0,
      totalCheckins = jsonNumber(json['totalCheckins'])?.toInt() ?? 0,
      atRiskCount = jsonNumber(json['atRiskCount'])?.toInt() ?? 0,
      studentCount = jsonNumber(json['studentCount'])?.toInt() ?? 0;
}

class ReportMethod {
  final String key, label;
  final int count;
  final double rate;
  ReportMethod.fromJson(Map<String, dynamic> json)
    : key = jsonText(json['key']) ?? '',
      label = jsonText(json['label']) ?? '',
      count = jsonNumber(json['count'])?.toInt() ?? 0,
      rate = jsonNumber(json['rate'])?.toDouble() ?? 0;
}

class ReportWeek {
  final String label;
  final double presentRate, lateRate, absentRate;
  ReportWeek.fromJson(Map<String, dynamic> json)
    : label = jsonText(json['label']) ?? '',
      presentRate = jsonNumber(json['presentRate'])?.toDouble() ?? 0,
      lateRate = jsonNumber(json['lateRate'])?.toDouble() ?? 0,
      absentRate = jsonNumber(json['absentRate'])?.toDouble() ?? 0;
}

class ReportSubject {
  final String classCode, subjectName;
  final double attendanceRate, absentRate;
  final int studentCount;
  ReportSubject.fromJson(Map<String, dynamic> json)
    : classCode = jsonText(json['classCode']) ?? '',
      subjectName = jsonText(json['subjectName']) ?? '',
      attendanceRate = jsonNumber(json['attendanceRate'])?.toDouble() ?? 0,
      absentRate = jsonNumber(json['absentRate'])?.toDouble() ?? 0,
      studentCount = jsonNumber(json['studentCount'])?.toInt() ?? 0;
}

class ReportWarning {
  final String classCode, subjectName, rollNumber, fullName, email, status;
  final int absent, total;
  final double absenceRate;
  ReportWarning.fromJson(Map<String, dynamic> json)
    : classCode = jsonText(json['classCode']) ?? '',
      subjectName = jsonText(json['subjectName']) ?? '',
      rollNumber = jsonText(json['rollNumber']) ?? '',
      fullName = jsonText(json['fullName']) ?? '',
      email = jsonText(json['email']) ?? '',
      status = jsonText(json['status']) ?? '',
      absent = jsonNumber(json['absent'])?.toInt() ?? 0,
      total = jsonNumber(json['total'])?.toInt() ?? 0,
      absenceRate = jsonNumber(json['absenceRate'])?.toDouble() ?? 0;
}
