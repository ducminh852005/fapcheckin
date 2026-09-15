/// Vai trò (role) của tài khoản trong hệ thống.
/// Dùng enum thay vì String thô ('GV', 'SV'...) để trình biên dịch bắt lỗi
/// gõ nhầm giúp mình, thay vì phải chờ tới lúc chạy mới phát hiện ra.
enum UserRole { teacher, student }

extension UserRoleX on UserRole {
  static UserRole fromSheetValue(String value) {
    switch (value.toUpperCase()) {
      case 'GV':
        return UserRole.teacher;
      case 'SV':
        return UserRole.student;
      default:
        throw ArgumentError('Giá trị role không hợp lệ: $value');
    }
  }
}

class UserModel {
  final String userId;
  final String email;
  final String fullName;
  final UserRole role;
  final String code; // Mã GV hoặc MSSV
  final bool active;

  const UserModel({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.role,
    required this.code,
    required this.active,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      role: UserRoleX.fromSheetValue(json['role'] as String),
      code: json['code'] as String,
      active: json['active'] as bool? ?? true,
    );
  }
}
