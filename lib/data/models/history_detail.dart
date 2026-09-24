import 'history_class.dart';
import 'history_student.dart';
import 'session_model.dart';
import '../../core/network/json_values.dart';

class HistoryDetail {
  final HistoryClass classInfo;
  final String teacherName;
  final List<SessionModel> sessions;
  final SessionModel? selectedSession;
  final List<HistoryStudent> students;
  final List<String> slotCodes;
  HistoryDetail.fromJson(Map<String, dynamic> json)
    : classInfo = HistoryClass.fromJson(
        Map<String, dynamic>.from(json['classInfo']),
      ),
      teacherName = jsonText(json['teacherName']) ?? '',
      sessions = (json['sessions'] as List)
          .map((s) => SessionModel.fromJson(Map<String, dynamic>.from(s)))
          .toList(),
      selectedSession = json['selectedSession'] == null
          ? null
          : SessionModel.fromJson(
              Map<String, dynamic>.from(json['selectedSession']),
            ),
      students = (json['students'] as List)
          .map((s) => HistoryStudent.fromJson(Map<String, dynamic>.from(s)))
          .toList(),
      slotCodes = (json['slots'] as List)
          .map((s) => jsonText(s['slotCode']) ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
}

class AttendanceMatrix {
  final List<SessionModel> sessions;
  final List<MatrixStudent> students;
  AttendanceMatrix.fromJson(Map<String, dynamic> json)
    : sessions = (json['sessions'] as List)
          .map((s) => SessionModel.fromJson(Map<String, dynamic>.from(s)))
          .toList(),
      students = (json['students'] as List)
          .map((s) => MatrixStudent.fromJson(Map<String, dynamic>.from(s)))
          .toList();
}

class MatrixStudent {
  final String rollNumber, fullName;
  final List<MatrixCell> cells;
  MatrixStudent.fromJson(Map<String, dynamic> json)
    : rollNumber = jsonText(json['rollNumber']) ?? '',
      fullName = jsonText(json['fullName']) ?? '',
      cells = (json['cells'] as List)
          .map((c) => MatrixCell.fromJson(Map<String, dynamic>.from(c)))
          .toList();
}

class MatrixCell {
  final String sessionId, status, note, checkinTime, revision;
  MatrixCell.fromJson(Map<String, dynamic> json)
    : sessionId = jsonText(json['sessionId']) ?? '',
      status = jsonText(json['status']) ?? 'Unchecked',
      note = jsonText(json['note']) ?? '',
      checkinTime = jsonText(json['checkinTime']) ?? '',
      revision = jsonText(json['revision']) ?? '';
}

class HistoryExport {
  final String filename, mimeType, base64;
  HistoryExport.fromJson(Map<String, dynamic> json)
    : filename = json['filename'] as String,
      mimeType = json['mimeType'] as String,
      base64 = json['base64'] as String;
}
