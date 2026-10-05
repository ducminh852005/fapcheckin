/// Activity log entry for the dashboard
class ActivityLog {
  final String title;
  final String description;
  final String timeLabel;
  final ActivityType type;
  final String? subDetail;

  const ActivityLog({
    required this.title,
    required this.description,
    required this.timeLabel,
    required this.type,
    this.subDetail,
  });
}

enum ActivityType {
  qrScan, // QR scan event
  cloudSync, // FAP cloud sync
  sessionStart, // Session started
  manualEntry, // Manual attendance
}
