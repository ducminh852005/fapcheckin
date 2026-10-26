import './history_student.dart';

/// Response payload for getAttendanceHistory API
class AttendanceHistoryResult {
  final String sessionId;
  final String classCode;
  final int totalSessions;
  final List<AttendanceStudentRecord> students;

  const AttendanceHistoryResult({
    required this.sessionId,
    required this.classCode,
    required this.totalSessions,
    required this.students,
  });

  factory AttendanceHistoryResult.fromJson(Map<String, dynamic> json) {
    final list = json['students'] as List<dynamic>? ?? [];
    return AttendanceHistoryResult(
      sessionId: json['sessionId'] as String? ?? '',
      classCode: json['classCode'] as String? ?? '',
      totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 0,
      students: list
          .map(
            (e) => AttendanceStudentRecord.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'classCode': classCode,
    'totalSessions': totalSessions,
    'students': students.map((s) => s.toJson()).toList(),
  };
}

/// A student's attendance record in a specific session
class AttendanceStudentRecord {
  final String rollNumber;
  final String memberCode;
  final String fullName;
  final String email;
  final String checkinTime;
  final String status;
  final String networkVerificationResult;
  final int absenceCount;
  final int totalSessions;

  const AttendanceStudentRecord({
    required this.rollNumber,
    required this.memberCode,
    required this.fullName,
    required this.email,
    required this.checkinTime,
    required this.status,
    required this.networkVerificationResult,
    required this.absenceCount,
    required this.totalSessions,
  });

  factory AttendanceStudentRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceStudentRecord(
      rollNumber: json['rollNumber'] as String? ?? '',
      memberCode: json['memberCode'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      checkinTime: json['checkinTime'] as String? ?? '',
      status: json['status'] as String? ?? 'Absent',
      networkVerificationResult:
          json['networkVerificationResult'] as String? ?? '',
      absenceCount: (json['absenceCount'] as num?)?.toInt() ?? 0,
      totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'rollNumber': rollNumber,
    'memberCode': memberCode,
    'fullName': fullName,
    'email': email,
    'checkinTime': checkinTime,
    'status': status,
    'networkVerificationResult': networkVerificationResult,
    'absenceCount': absenceCount,
    'totalSessions': totalSessions,
  };

  /// Convert to UI HistoryStudent
  HistoryStudent toHistoryStudent(int index) {
    String timeFormatted = '';
    if (checkinTime.isNotEmpty) {
      try {
        final parsed = DateTime.parse(checkinTime).toLocal();
        final h = parsed.hour.toString().padLeft(2, '0');
        final m = parsed.minute.toString().padLeft(2, '0');
        final s = parsed.second.toString().padLeft(2, '0');
        timeFormatted = '$h:$m:$s';
      } catch (_) {
        timeFormatted = checkinTime;
      }
    }

    return HistoryStudent(
      rollNumber: rollNumber,
      fullName: fullName.isNotEmpty ? fullName : rollNumber,
      email: email,
      status: status.isEmpty ? 'Unchecked' : status,
      checkinTime: timeFormatted,
      note: '',
      revision: '',
      method: networkVerificationResult,
      absenceCount: absenceCount,
      totalSessions: totalSessions > 0 ? totalSessions : 30,
    );
  }
}
