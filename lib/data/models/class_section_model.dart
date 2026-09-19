/// Model for ClassSection from API (getClasses action)
class ClassSectionModel {
  final String classCode;
  final String subjectName;
  final int credits;
  final String room;
  final int studentCount;
  final String teacherMemberCode;

  const ClassSectionModel({
    required this.classCode,
    required this.subjectName,
    required this.credits,
    required this.room,
    required this.studentCount,
    required this.teacherMemberCode,
  });

  factory ClassSectionModel.fromJson(Map<String, dynamic> json) {
    return ClassSectionModel(
      classCode: json['classCode'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      credits: (json['credits'] as num?)?.toInt() ?? 0,
      room: json['room'] as String? ?? '',
      studentCount: (json['studentCount'] as num?)?.toInt() ?? 0,
      teacherMemberCode: json['teacherMemberCode'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'classCode': classCode,
        'subjectName': subjectName,
        'credits': credits,
        'room': room,
        'studentCount': studentCount,
        'teacherMemberCode': teacherMemberCode,
      };
}
