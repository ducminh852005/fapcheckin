/// Represents a class/course session for the day's schedule
class ClassSession {
  final String courseCode;
  final String courseName;
  final String slot;
  final String timeRange;
  final String room;
  final String roomType; // 'Phòng', 'Lab', 'Hội trường', etc.
  final int studentCount;
  final SessionStatus status;
  final int? scannedCount; // Only for active sessions
  final bool isMakeup; // Indicates this is a makeup/extra class from Class_Schedule

  const ClassSession({
    required this.courseCode,
    required this.courseName,
    required this.slot,
    required this.timeRange,
    required this.room,
    this.roomType = 'Phòng',
    required this.studentCount,
    required this.status,
    this.scannedCount,
    this.isMakeup = false,
  });
}

enum SessionStatus {
  active,    // Phiên đang mở
  ready,     // Sẵn sàng (tới giờ nhưng chưa mở)
  notStarted, // Chưa bắt đầu
  completed,  // Đã hoàn thành
}
