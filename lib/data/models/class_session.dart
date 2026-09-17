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
  });
}

enum SessionStatus {
  active,    // Phiên đang mở
  notStarted, // Chưa bắt đầu
  completed,  // Đã hoàn thành
}
