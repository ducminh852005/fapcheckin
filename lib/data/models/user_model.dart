import '../../core/network/json_values.dart';

class UserModel {
  final String memberCode;
  final String fullName;
  final String role;
  final String rollNumber;
  final String email;

  const UserModel({
    required this.memberCode,
    required this.fullName,
    required this.role,
    required this.rollNumber,
    required this.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      memberCode: jsonText(json['memberCode']) ?? '',
      fullName: jsonText(json['fullName']) ?? '',
      role: jsonText(json['role']) ?? '',
      rollNumber: jsonText(json['rollNumber']) ?? '',
      email: jsonText(json['email']) ?? '',
    );
  }

  bool get isTeacher {
    final normalized = role.trim().toUpperCase();
    return normalized == 'TEACHER' ||
        normalized == 'GV' ||
        normalized == 'GIANG_VIEN' ||
        normalized == 'GIẢNG VIÊN';
  }

  String get displayName => fullName.isNotEmpty ? fullName : email;

  Map<String, dynamic> toJson() => {
    'memberCode': memberCode,
    'fullName': fullName,
    'role': role,
    'rollNumber': rollNumber,
    'email': email,
  };
}
