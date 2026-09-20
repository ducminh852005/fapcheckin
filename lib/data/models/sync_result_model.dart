/// Model for result of syncToFap action
class SyncResult {
  final int syncedCount;
  final String message;

  const SyncResult({
    required this.syncedCount,
    required this.message,
  });

  factory SyncResult.fromJson(Map<String, dynamic> json) {
    return SyncResult(
      syncedCount: (json['syncedCount'] as num?)?.toInt() ?? 0,
      message: json['message'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'syncedCount': syncedCount,
        'message': message,
      };
}
