import '../utils/json_values.dart';

class HistoryStudent {
  final String rollNumber,
      fullName,
      email,
      status,
      checkinTime,
      note,
      revision,
      method;
  final int absenceCount, totalSessions;

  /// Ngành và ảnh đại diện (nếu dữ liệu ghi danh có); rỗng khi chưa có. Dùng ở màn hồ sơ sinh viên.
  final String major, avatarPath;
  const HistoryStudent({
    required this.rollNumber,
    required this.fullName,
    required this.email,
    required this.status,
    required this.checkinTime,
    required this.note,
    required this.revision,
    required this.method,
    required this.absenceCount,
    required this.totalSessions,
    this.major = '',
    this.avatarPath = '',
  });
  factory HistoryStudent.fromJson(Map<String, dynamic> json) => HistoryStudent(
    rollNumber: jsonText(json['rollNumber']) ?? '',
    fullName: jsonText(json['fullName']) ?? '',
    email: jsonText(json['email']) ?? '',
    status: jsonText(json['status']) ?? 'Unchecked',
    checkinTime: jsonText(json['checkinTime']) ?? '',
    note: jsonText(json['note']) ?? '',
    revision: jsonText(json['revision']) ?? '',
    method: jsonText(json['networkVerificationResult']) ?? '',
    absenceCount: jsonNumber(json['absenceCount'])?.toInt() ?? 0,
    totalSessions: jsonNumber(json['totalSessions'])?.toInt() ?? 0,
    major: jsonText(json['major']) ?? '',
    avatarPath: jsonText(json['avatarPath']) ?? '',
  );
  double get absenceRate =>
      totalSessions == 0 ? 0 : absenceCount / totalSessions;
  HistoryStudent edit({String? status, String? note}) => HistoryStudent(
    rollNumber: rollNumber,
    fullName: fullName,
    email: email,
    status: status ?? this.status,
    checkinTime: checkinTime,
    note: note ?? this.note,
    revision: revision,
    method: method,
    absenceCount: absenceCount,
    totalSessions: totalSessions,
    major: major,
    avatarPath: avatarPath,
  );
}

const attendanceStatusLabels = {
  'Present': 'Có mặt',
  'Late': 'Đi trễ',
  'Absent': 'Vắng mặt',
  'ManualByGV': 'Có mặt (GV xác nhận)',
  'Unchecked': 'Chưa điểm danh',
};
String historyDate(String value, {bool includeTime = false}) {
  if (value.isEmpty) return '—';
  final date = DateTime.tryParse(value)?.toLocal();
  if (date == null) return value;
  String pad(int n) => n.toString().padLeft(2, '0');
  final day = '${pad(date.day)}/${pad(date.month)}/${date.year}';
  return includeTime
      ? '$day ${pad(date.hour)}:${pad(date.minute)}:${pad(date.second)}'
      : day;
}
