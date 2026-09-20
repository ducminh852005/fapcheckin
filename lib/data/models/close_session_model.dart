/// Model for result of closeSession action
class CloseSessionResult {
  final String sessionId;
  final String sessionStatus;
  final int autoAbsentCount;

  const CloseSessionResult({
    required this.sessionId,
    required this.sessionStatus,
    required this.autoAbsentCount,
  });

  factory CloseSessionResult.fromJson(Map<String, dynamic> json) {
    return CloseSessionResult(
      sessionId: json['sessionId'] as String? ?? '',
      sessionStatus: json['sessionStatus'] as String? ?? 'closed',
      autoAbsentCount: (json['autoAbsentCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'sessionStatus': sessionStatus,
        'autoAbsentCount': autoAbsentCount,
      };
}
