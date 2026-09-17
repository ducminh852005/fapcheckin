import 'package:fapcheckin/data/models/student_checkin.dart';

class HistoryStudent {
  final int index;
  final String studentId;
  final String fullName;
  final String initials;
  final String email;
  final String checkInTime; // e.g. "07:35:12" or "--:--:--"
  final CheckinStatus status;
  final String methodLabel; // e.g. "QR Động 20s", "Điểm danh bù bởi GV", "Không quét QR"
  final String methodIcon; // e.g. "qr_code_2", "how_to_reg", "block"
  final int absenceCount; // e.g. 1
  final int totalSessions; // e.g. 30
  final String absenceStatusText; // e.g. "An toàn", "Nguy cơ", "Cho phép"
  final String? lateLabel; // e.g. "+18m"

  const HistoryStudent({
    required this.index,
    required this.studentId,
    required this.fullName,
    required this.initials,
    required this.email,
    required this.checkInTime,
    required this.status,
    required this.methodLabel,
    required this.methodIcon,
    required this.absenceCount,
    required this.totalSessions,
    required this.absenceStatusText,
    this.lateLabel,
  });
  
  double get absenceRate => absenceCount / totalSessions;
}
