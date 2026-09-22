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
    final rawCount = json['autoAbsentCount'];
    int count = 0;
    if (rawCount is num) {
      count = rawCount.toInt();
    } else if (rawCount != null) {
      count = int.tryParse(rawCount.toString()) ?? 0;
    }
    return CloseSessionResult(
      sessionId: json['sessionId']?.toString() ?? '',
      sessionStatus: json['sessionStatus']?.toString() ?? 'closed',
      autoAbsentCount: count,
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'sessionStatus': sessionStatus,
        'autoAbsentCount': autoAbsentCount,
      };
}
