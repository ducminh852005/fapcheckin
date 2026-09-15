enum AttendanceStatus { present, late, absent, manualByGV }

extension AttendanceStatusX on AttendanceStatus {
  static AttendanceStatus fromSheetValue(String value) {
    switch (value.toLowerCase()) {
      case 'present':
        return AttendanceStatus.present;
      case 'late':
        return AttendanceStatus.late;
      case 'absent':
        return AttendanceStatus.absent;
      case 'manual':
      case 'manualbygv':
        return AttendanceStatus.manualByGV;
      default:
        throw ArgumentError('Giá trị status không hợp lệ: $value');
    }
  }

  String get label {
    switch (this) {
      case AttendanceStatus.present:
        return 'Có mặt';
      case AttendanceStatus.late:
        return 'Trễ';
      case AttendanceStatus.absent:
        return 'Vắng';
      case AttendanceStatus.manualByGV:
        return 'GV điểm danh tay';
    }
  }
}

enum CheckinMethod { qr, manual }

extension CheckinMethodX on CheckinMethod {
  static CheckinMethod fromSheetValue(String value) {
    return value.toLowerCase() == 'manual' ? CheckinMethod.manual : CheckinMethod.qr;
  }
}

/// Một dòng trong sheet "AttendanceLog".
///
/// [studentName] không có sẵn trong log thô (chỉ có studentId) — trường này
/// được Repository "làm giàu" thêm (join với danh sách lớp) trước khi trả
/// về cho ViewModel, để View không phải tự tra cứu tên sinh viên.
class AttendanceModel {
  final String logId;
  final String sessionId;
  final String studentId;
  final String? studentName;
  final DateTime? checkinTime;
  final AttendanceStatus status;
  final CheckinMethod method;
  final String? studentIp;
  final bool ipMatch;
  final bool syncedToFap;

  const AttendanceModel({
    required this.logId,
    required this.sessionId,
    required this.studentId,
    this.studentName,
    required this.checkinTime,
    required this.status,
    required this.method,
    this.studentIp,
    required this.ipMatch,
    required this.syncedToFap,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      logId: json['logId'] as String,
      sessionId: json['sessionId'] as String,
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String?,
      checkinTime: json['checkinTime'] != null
          ? DateTime.tryParse(json['checkinTime'] as String)
          : null,
      status: AttendanceStatusX.fromSheetValue(json['status'] as String),
      method: CheckinMethodX.fromSheetValue(json['method'] as String? ?? 'qr'),
      studentIp: json['studentIp'] as String?,
      ipMatch: json['ipMatch'] as bool? ?? false,
      syncedToFap: json['syncedToFap'] as bool? ?? false,
    );
  }
}
