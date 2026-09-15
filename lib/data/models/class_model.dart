class ClassModel {
  final String classId;
  final String className;
  final String subjectCode;
  final String teacherId;
  final String room;
  final String schedule; // Ví dụ: "Thứ 3 · Tiết 4-6"

  const ClassModel({
    required this.classId,
    required this.className,
    required this.subjectCode,
    required this.teacherId,
    required this.room,
    required this.schedule,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      classId: json['classId'] as String,
      className: json['className'] as String,
      subjectCode: json['subjectCode'] as String,
      teacherId: json['teacherId'] as String,
      room: json['room'] as String,
      schedule: json['schedule'] as String,
    );
  }
}
