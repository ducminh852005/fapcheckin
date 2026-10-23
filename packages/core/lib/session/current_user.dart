import '../models/user_model.dart';
import '../result/guard.dart';

/// Hồ sơ người dùng đang đăng nhập. [AuthRepository] ghi, các repository khác đọc
/// để biết `memberCode` của giảng viên (khóa sở hữu trong Security Rules).
class CurrentUser {
  UserModel? _value;

  UserModel? get value => _value;
  void set(UserModel? user) => _value = user;
  void clear() => _value = null;

  UserModel get requireUser {
    final user = _value;
    if (user == null) {
      throw ApiException('UNAUTHORIZED', 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
    }
    return user;
  }

  String get memberCode => requireUser.memberCode;
}
