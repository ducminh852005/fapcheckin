import '../../core/network/json_values.dart';

import 'user_model.dart';

class AuthSessionModel {
  final String token;
  final UserModel user;

  const AuthSessionModel({required this.token, required this.user});

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      token: jsonText(json['token']) ?? '',
      user: UserModel.fromJson(
        json['user'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
    );
  }
}
