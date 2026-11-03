import 'package:cloud_firestore/cloud_firestore.dart';

import '../firebase/firestore_json.dart';
import '../utils/json_values.dart';

class UserModel {
  final String memberCode;
  final String fullName;
  final String role;
  final String rollNumber;
  final String email;
  final String phone, birthDate, avatarPath, department, division, jobTitle, employmentDate, contractType;
  final bool active;
  final DateTime? createdAt;

  const UserModel({
    required this.memberCode,
    required this.fullName,
    required this.role,
    required this.rollNumber,
    required this.email,
    this.phone = '',
    this.birthDate = '',
    this.avatarPath = '',
    this.department = '',
    this.division = '',
    this.jobTitle = '',
    this.employmentDate = '',
    this.contractType = '',
    this.active = true,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      memberCode: jsonText(json['memberCode']) ?? '',
      fullName: jsonText(json['fullName']) ?? '',
      role: jsonText(json['role']) ?? '',
      rollNumber: jsonText(json['rollNumber']) ?? '',
      email: jsonText(json['email']) ?? '',
      phone: jsonText(json['phone']) ?? '',
      birthDate: jsonText(json['birthDate']) ?? '',
      avatarPath: jsonText(json['avatarPath']) ?? '',
      department: jsonText(json['department']) ?? '',
      division: jsonText(json['division']) ?? '',
      jobTitle: jsonText(json['jobTitle']) ?? '',
      employmentDate: jsonText(json['employmentDate']) ?? '',
      contractType: jsonText(json['contractType']) ?? '',

      active: jsonBool(json['active']) ?? true,
      createdAt: DateTime.tryParse(jsonText(json['createdAt']) ?? ''),
    );
  }

  /// Role chuẩn (khớp firestore.rules): `user` | `staff` | `admin`.
  bool get isTeacher {
    final normalized = role.trim().toLowerCase();
    return normalized == 'staff' || normalized == 'admin';
  }

  /// Hồ sơ `users/{uid}`.
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) =>
      UserModel.fromJson(docToJson(doc));

  /// Dữ liệu tạo `users/{uid}` từ `user_invites/{email}` (khớp Security Rules).
  Map<String, dynamic> toFirestore() => {
    'memberCode': memberCode,
    'fullName': fullName,
    'email': email,
    'role': role,
    if (rollNumber.isNotEmpty) 'rollNumber': rollNumber,
    'active': true,
    'createdAt': FieldValue.serverTimestamp(),
  };

  String get displayName => fullName.isNotEmpty ? fullName : email;

  Map<String, dynamic> toJson() => {
    'memberCode': memberCode,
    'fullName': fullName,
    'role': role,
    'rollNumber': rollNumber,
    'email': email,
    'active': active,
    'phone': phone,
    'birthDate': birthDate,
    'avatarPath': avatarPath,
    'department': department,
    'division': division,
    'jobTitle': jobTitle,
    'employmentDate': employmentDate,
    'contractType': contractType,

    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
  };
}
