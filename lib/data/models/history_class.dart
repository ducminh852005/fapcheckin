class HistoryClass {
  final String courseCode; // e.g. SWP391
  final String className; // e.g. SE1704
  final String courseName; // e.g. Dự án Phát triển Phần mềm
  final double attendanceRate; // e.g. 0.942
  final int completedSessions; // e.g. 12
  final int totalSessions; // e.g. 30
  final String latestSessionDate; // e.g. "Hôm nay 24/10"
  final String latestSessionName; // e.g. "Buổi 12"
  final bool isActive;
  final bool isWarning;

  const HistoryClass({
    required this.courseCode,
    required this.className,
    required this.courseName,
    required this.attendanceRate,
    required this.completedSessions,
    required this.totalSessions,
    required this.latestSessionDate,
    required this.latestSessionName,
    this.isActive = false,
    this.isWarning = false,
  });
}
