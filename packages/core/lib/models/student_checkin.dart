/// Check-in status for a student
enum CheckinStatus { present, late, absent, unchecked }

/// Method used for check-in
enum CheckinMethod { qrCode, manual }

/// A single student check-in record
class StudentCheckin {
  final int index;
  final String studentId;
  final String fullName;
  final String initials;
  final String checkInTime; // "07:35:12" or "--:--:--"
  final CheckinStatus status;
  final String? lateMinutes; // "+22m"
  final String ipAddress; // or "--"
  final CheckinMethod? method;

  const StudentCheckin({
    required this.index,
    required this.studentId,
    required this.fullName,
    required this.initials,
    required this.checkInTime,
    required this.status,
    this.lateMinutes,
    required this.ipAddress,
    this.method,
  });
}
