import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/auth_session_model.dart';
import '../models/user_model.dart';
import '../result/api_result.dart';
import '../result/guard.dart';
import '../session/current_user.dart';

/// Đăng nhập bằng Firebase Auth (Google) và nạp hồ sơ `users/{uid}`.
///
/// Lần đăng nhập đầu, hồ sơ được tạo từ `user_invites/{email}` do admin cấp;
/// Security Rules chỉ cho tạo khi khớp invite nên người dùng không tự đặt role.
class AuthRepository {
  AuthRepository({
    required this.currentUser,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _injectedAuth = auth,
       _injectedDb = firestore;

  final CurrentUser currentUser;
  final FirebaseAuth? _injectedAuth;
  final FirebaseFirestore? _injectedDb;

  FirebaseAuth get _auth => _injectedAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _injectedDb ?? FirebaseFirestore.instance;

  /// Đổi Google ID token lấy phiên Firebase. `AuthSessionModel.token` là uid.
  Future<ApiResult<AuthSessionModel>> loginWithGoogleIdToken({
    required String idToken,
  }) => guardApi(() async {
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final signedIn = await _auth.signInWithCredential(credential);
    final user = signedIn.user;
    final email = user?.email?.toLowerCase();
    if (user == null || email == null || email.isEmpty) {
      await _auth.signOut();
      throw ApiException(
        'INVALID_TOKEN',
        'Không lấy được email từ tài khoản Google.',
      );
    }
    try {
      final profile = await _loadOrCreateProfile(user.uid, email);
      currentUser.set(profile);
      return AuthSessionModel(token: user.uid, user: profile);
    } catch (_) {
      await _auth.signOut();
      rethrow;
    }
  });

  Future<UserModel> _loadOrCreateProfile(String uid, String email) async {
    final ref = _db.collection('users').doc(uid);
    var snap = await ref.get();
    if (!snap.exists) {
      final invite = await _db.collection('user_invites').doc(email).get();
      if (!invite.exists) {
        throw ApiException(
          'DOMAIN_NOT_ALLOWED',
          'Tài khoản không thuộc hệ thống nhà trường hoặc chưa được phân quyền: $email',
        );
      }
      final data = invite.data()!;
      final created = UserModel(
        memberCode: (data['memberCode'] ?? '').toString(),
        fullName: (data['fullName'] ?? '').toString(),
        role: (data['role'] ?? '').toString(),
        rollNumber: (data['rollNumber'] ?? '').toString(),
        email: email,
      );
      await ref.set(created.toFirestore());
      snap = await ref.get();
    }
    final data = snap.data() ?? const <String, dynamic>{};
    if (data['active'] == false) {
      throw ApiException(
        'FORBIDDEN',
        'Tài khoản đã bị khóa. Liên hệ quản trị viên.',
      );
    }
    final user = UserModel.fromFirestore(snap);
    if (user.department.isEmpty &&
        user.division.isEmpty &&
        user.employmentDate.isEmpty &&
        user.contractType.isEmpty) {
      try {
        final invite = await _db.collection('user_invites').doc(email).get();
        if (invite.exists) {
          final inv = invite.data() ?? const <String, dynamic>{};
          return UserModel(
            memberCode: user.memberCode,
            fullName: user.fullName,
            role: user.role,
            rollNumber: user.rollNumber,
            email: user.email,
            phone: user.phone.isNotEmpty
                ? user.phone
                : (inv['phone'] ?? '').toString(),
            birthDate: user.birthDate.isNotEmpty
                ? user.birthDate
                : (inv['birthDate'] ?? '').toString(),
            avatarPath: user.avatarPath,
            department: (inv['department'] ?? '').toString(),
            division: (inv['division'] ?? '').toString(),
            jobTitle: user.jobTitle.isNotEmpty
                ? user.jobTitle
                : (inv['jobTitle'] ?? '').toString(),
            employmentDate: (inv['employmentDate'] ?? '').toString(),
            contractType: (inv['contractType'] ?? '').toString(),
            active: user.active,
            createdAt: user.createdAt,
          );
        }
      } catch (_) {}
    }
    return user;
  }

  /// Khôi phục phiên khi mở lại app (Firebase Auth giữ đăng nhập trên thiết bị).
  Future<ApiResult<AuthSessionModel?>> restoreSession() => guardApi(() async {
    final user = _auth.currentUser;
    final email = user?.email?.toLowerCase();
    if (user == null || email == null) return null;
    final profile = await _loadOrCreateProfile(user.uid, email);
    currentUser.set(profile);
    return AuthSessionModel(token: user.uid, user: profile);
  });

  Future<ApiResult<AuthSessionModel>> updateName(String value) =>
      guardApi(() async {
        final name = value.trim();
        if (name.isEmpty || name.length > 200) {
          throw ApiException(
            'VALIDATION_ERROR',
            'Tên phải có từ 1 đến 200 ký tự.',
          );
        }
        final uid = _auth.currentUser?.uid;
        if (uid == null) {
          throw ApiException('UNAUTHENTICATED', 'Vui lòng đăng nhập lại.');
        }
        await _db.collection('users').doc(uid).update({'fullName': name});
        final profile = UserModel.fromFirestore(
          await _db.collection('users').doc(uid).get(),
        );
        currentUser.set(profile);
        return AuthSessionModel(token: uid, user: profile);
      });

  Future<ApiResult<AuthSessionModel>> updateProfile({required String name, required String phone, required String birthDate}) => guardApi(() async {
    final cleanName = name.trim(), cleanPhone = phone.trim(), date = birthDate.trim();
    final parsed = date.isEmpty ? null : DateTime.tryParse(date);
    if (cleanName.isEmpty || cleanName.length > 200 || !RegExp(r'^[+0-9 ()-]{0,25}$').hasMatch(cleanPhone) ||
      (date.isNotEmpty && (parsed == null || parsed.toIso8601String().substring(0, 10) != date || parsed.isAfter(DateTime.now()) || parsed.year < 1900))) {
      throw ApiException('VALIDATION_ERROR', 'Kiểm tra họ tên, số điện thoại và ngày sinh (YYYY-MM-DD).');
    }
    final account = _auth.currentUser;
    if (account == null) throw ApiException('UNAUTHORIZED', 'Vui lòng đăng nhập lại.');
    await _db.collection('users').doc(account.uid).update({'fullName': cleanName, 'phone': cleanPhone, 'birthDate': date});
    final profile = UserModel.fromFirestore(await _db.collection('users').doc(account.uid).get());
    if (_auth.currentUser?.uid != account.uid) throw ApiException('UNAUTHORIZED', 'Tài khoản đã thay đổi.');
    currentUser.set(profile);
    return AuthSessionModel(token: account.uid, user: profile);
  });

  Future<void> signOut() async {
    currentUser.clear();
    await _auth.signOut();
  }
}
