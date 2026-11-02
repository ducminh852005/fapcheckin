import '../utils/json_values.dart';

/// Model for a single roster entry (student + attendance record)
/// Corresponds to each item in the getRoster response data array
class RosterEntryModel {
  final String rollNumber;
  final String memberCode;
  final String email;
  final String fullName;
  final String? recordId;
  final String? sessionId;
  final String? checkinTime; // ISO datetime or null
  final String status; // Present, Late, Absent, ManualByGV, or empty
  final String? networkVerificationResult;
  final String? ipAddress;
  final String? note;

  const RosterEntryModel({
    required this.rollNumber,
    required this.memberCode,
    required this.email,
    this.fullName = '',
    this.recordId,
    this.sessionId,
    this.checkinTime,
    required this.status,
    this.networkVerificationResult,
    this.ipAddress,
    this.note,
  });

  factory RosterEntryModel.fromJson(Map<String, dynamic> json) {
    final student = json['student'] as Map<String, dynamic>? ?? {};
    final record = json['record'] as Map<String, dynamic>?;
    return RosterEntryModel(
      rollNumber: jsonText(student['rollNumber']) ?? '',
      memberCode: jsonText(student['memberCode']) ?? '',
      email: jsonText(student['email']) ?? '',
      fullName: jsonText(student['fullName']) ?? '',
      recordId: jsonText(record?['recordId']),
      sessionId: jsonText(record?['sessionId']),
      checkinTime: jsonText(record?['checkinTime']),
      status: jsonText(record?['status']) ?? '',
      networkVerificationResult: jsonText(record?['networkVerificationResult']),
      ipAddress: jsonText(record?['ipAddress']),
      note: jsonText(record?['note']),
    );
  }

  String get displayName => fullName.trim().isNotEmpty ? fullName : rollNumber;

  bool get hasCheckedIn =>
      status == 'Present' || status == 'Late' || status == 'ManualByGV';

  bool get isPresent => status == 'Present' || status == 'ManualByGV';

  bool get isLate => status == 'Late';

  bool get isAbsent => status == 'Absent';

  bool get isUnchecked => status.isEmpty;

  /// Display-friendly check-in time (extracts HH:mm:ss from ISO datetime)
  String get displayCheckinTime {
    if (checkinTime == null || checkinTime!.isEmpty) return '--:--:--';
    try {
      final dt = DateTime.parse(checkinTime!).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      final s = dt.second.toString().padLeft(2, '0');
      return '$h:$m:$s';
    } catch (_) {
      return checkinTime!;
    }
  }

  /// Initials from rollNumber or email (first two alpha chars)
  String get initials {
    final clean = rollNumber.replaceAll(RegExp(r'[^a-zA-Z]'), '');
    if (clean.length >= 2) return clean.substring(0, 2).toUpperCase();
    if (clean.isNotEmpty) return clean.toUpperCase();
    return '??';
  }
}
