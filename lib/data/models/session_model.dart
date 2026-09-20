import '../../core/network/json_values.dart';

/// Model for AttendanceSession returned by startSession action
class SessionModel {
  final String sessionId;
  final String classCode;
  final String sessionDate;
  final String slotCode;
  final String sessionStatus; // open, closed, expired
  final String qrToken;

  const SessionModel({
    required this.sessionId,
    required this.classCode,
    required this.sessionDate,
    required this.slotCode,
    required this.sessionStatus,
    required this.qrToken,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    // The API wraps session + qrToken in the data object
    final session = json['session'] as Map<String, dynamic>? ?? json;
    return SessionModel(
      sessionId: jsonText(session['sessionId']) ?? '',
      classCode: jsonText(session['classCode']) ?? '',
      sessionDate: jsonText(session['sessionDate']) ?? '',
      slotCode: jsonText(session['slotCode']) ?? '',
      sessionStatus: jsonText(session['sessionStatus']) ?? 'open',
      qrToken: jsonText(json['qrToken']) ?? jsonText(session['qrToken']) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'classCode': classCode,
    'sessionDate': sessionDate,
    'slotCode': slotCode,
    'sessionStatus': sessionStatus,
    'qrToken': qrToken,
  };

  bool get isOpen => sessionStatus == 'open';
}
