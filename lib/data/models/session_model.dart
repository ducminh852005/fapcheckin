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
      sessionId: session['sessionId'] as String? ?? '',
      classCode: session['classCode'] as String? ?? '',
      sessionDate: session['sessionDate'] as String? ?? '',
      slotCode: session['slotCode'] as String? ?? '',
      sessionStatus: session['sessionStatus'] as String? ?? 'open',
      qrToken: json['qrToken'] as String? ?? session['qrToken'] as String? ?? '',
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
