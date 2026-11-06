import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../result/api_result.dart';
import '../result/guard.dart';

class AccountFeaturesRepository {
  AccountFeaturesRepository({
    required this.uid,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _injectedDb = firestore,
       _injectedStorage = storage;
  final String Function() uid;
  final FirebaseFirestore? _injectedDb;
  final FirebaseStorage? _injectedStorage;
  FirebaseFirestore get _db => _injectedDb ?? FirebaseFirestore.instance;
  FirebaseStorage get _storage => _injectedStorage ?? FirebaseStorage.instance;
  String get _uid {
    final id = uid();
    if (id.isEmpty)
      throw ApiException('UNAUTHORIZED', 'Vui lòng đăng nhập lại.');
    return id;
  }

  Future<ApiResult<Map<String, dynamic>>> preferences() => guardApi(
    () async =>
        (await _db.collection('user_preferences').doc(_uid).get()).data() ??
        {'theme': 'light', 'language': 'vi', 'reminders': false},
  );
  Future<ApiResult<void>> savePreferences({
    required String theme,
    required String language,
    required bool reminders,
  }) => guardApi(() async {
    if (!['light', 'dark', 'system'].contains(theme) ||
        !['vi', 'en'].contains(language))
      throw ApiException('VALIDATION_ERROR', 'Tùy chọn không hợp lệ.');
    await _db.collection('user_preferences').doc(_uid).set({
      'theme': theme,
      'language': language,
      'reminders': reminders,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  });
  Future<ApiResult<Map<String, dynamic>>> support() => guardApi(
    () async =>
        (await _db.collection('support_config').doc('public').get()).data() ??
        {},
  );
  Stream<Map<String, dynamic>> systemSettings() => _db
      .collection('system_settings')
      .doc('global_config')
      .snapshots()
      .map((s) => s.data() ?? {});
  Future<ApiResult<String>> sendFeedback(
    String category,
    String message, {
    required String requestId,
    List<String> attachments = const [],
  }) => guardApi(() async {
    final body = message.trim();
    if (!['bug', 'suggestion', 'other'].contains(category) ||
        body.isEmpty ||
        body.length > 2000 ||
        !RegExp(r'^[a-zA-Z0-9_-]{8,100}$').hasMatch(requestId))
      throw ApiException('VALIDATION_ERROR', 'Nội dung phải có 1–2000 ký tự.');
    if (attachments.length > 3 ||
        attachments.any(
          (path) => !path.startsWith('feedback_attachments/$_uid/'),
        ))
      throw ApiException('VALIDATION_ERROR', 'Tệp đính kèm không hợp lệ.');
    final ref = _db.collection('feedback').doc('${_uid}_$requestId');
    // A retry after a lost response must not create a second ticket.
    await _db.runTransaction((tx) async {
      final prior = await tx.get(ref);
      if (prior.exists) {
        if (prior.data()?['message'] != body ||
            prior.data()?['category'] != category)
          throw ApiException(
            'CONFLICT',
            'Yêu cầu đã được dùng cho nội dung khác.',
          );
        return;
      }
      tx.set(ref, {
        'authorUid': _uid,
        'category': category,
        'message': body,
        'attachments': attachments,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
    return ref.id;
  });
  Future<ApiResult<String>> uploadFeedbackAttachment(
    Uint8List bytes,
    String mime, {
    required String requestId,
    required int index,
  }) => guardApi(() async {
    final isPng =
        bytes.length >= 8 &&
        bytes[0] == 137 &&
        bytes[1] == 80 &&
        bytes[2] == 78 &&
        bytes[3] == 71;
    final isJpeg =
        bytes.length >= 3 &&
        bytes[0] == 255 &&
        bytes[1] == 216 &&
        bytes[2] == 255;
    if (bytes.isEmpty ||
        bytes.length > 5 * 1024 * 1024 ||
        index < 0 ||
        index > 2 ||
        !RegExp(r'^[a-zA-Z0-9_-]{8,100}$').hasMatch(requestId) ||
        !(mime == 'image/png' && isPng || mime == 'image/jpeg' && isJpeg))
      throw ApiException(
        'VALIDATION_ERROR',
        'Ảnh đính kèm phải là JPG/PNG thật, tối đa 5 MB.',
      );
    final extension = mime == 'image/png' ? 'png' : 'jpg';
    final path = 'feedback_attachments/$_uid/${requestId}_$index.$extension';
    await _storage
        .ref(path)
        .putData(bytes, SettableMetadata(contentType: mime));
    return path;
  });
  Stream<List<Map<String, dynamic>>> feedback() => _db
      .collection('feedback')
      .where('authorUid', isEqualTo: _uid)
      .snapshots()
      .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  Stream<List<Map<String, dynamic>>> notifications() => _db
      .collection('user_notifications')
      .doc(_uid)
      .collection('items')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  Future<ApiResult<void>> markRead(String id) => guardApi(
    () => _db
        .collection('user_notifications')
        .doc(_uid)
        .collection('items')
        .doc(id)
        .update({'read': true}),
  );
  Future<ApiResult<void>> registerDevice(String id, String token) => guardApi(
    () => _db
        .collection('device_tokens')
        .doc(_uid)
        .collection('tokens')
        .doc(id)
        .set({'token': token, 'updatedAt': FieldValue.serverTimestamp()}),
  );
  Future<ApiResult<void>> removeDevice(String id) => guardApi(
    () => _db
        .collection('device_tokens')
        .doc(_uid)
        .collection('tokens')
        .doc(id)
        .delete(),
  );

  Future<ApiResult<String>> uploadAvatar(
    Uint8List bytes,
    String mime, {
    String? customUrl,
  }) => guardApi(() async {
    final isPng =
        bytes.length >= 8 &&
        bytes[0] == 137 &&
        bytes[1] == 80 &&
        bytes[2] == 78 &&
        bytes[3] == 71;
    final isJpeg =
        bytes.length >= 3 &&
        bytes[0] == 255 &&
        bytes[1] == 216 &&
        bytes[2] == 255;
    if (bytes.length > 5 * 1024 * 1024 ||
        !(mime == 'image/png' && isPng || mime == 'image/jpeg' && isJpeg))
      throw ApiException(
        'VALIDATION_ERROR',
        'Chọn ảnh JPG/PNG thật, tối đa 5 MB.',
      );
    final account = _uid;
    if (customUrl != null && customUrl.isNotEmpty) {
      if (uid() != account)
        throw ApiException('UNAUTHORIZED', 'Tài khoản đã thay đổi.');
      await _db.collection('users').doc(account).update({
        'avatarPath': customUrl,
      });
      return customUrl;
    }
    final path =
        'avatars/$account/profile.${mime == 'image/png' ? 'png' : 'jpg'}';
    await _storage
        .ref(path)
        .putData(bytes, SettableMetadata(contentType: mime));
    if (uid() != account)
      throw ApiException('UNAUTHORIZED', 'Tài khoản đã thay đổi.');
    await _db.collection('users').doc(account).update({'avatarPath': path});
    return path;
  });
  Future<Uint8List?> avatar(String path) {
    if (![
      'avatars/$_uid/profile.jpg',
      'avatars/$_uid/profile.png',
    ].contains(path))
      return Future.value(null);
    return _storage.ref(path).getData(5 * 1024 * 1024);
  }

  Future<ApiResult<Map<String, dynamic>>> security() => guardApi(() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw ApiException('UNAUTHORIZED', 'Vui lòng đăng nhập.');
    await user.reload();
    return {
      'email': user.email,
      'emailVerified': user.emailVerified,
      'providers': user.providerData.map((p) => p.providerId).toList(),
      'lastSignIn': user.metadata.lastSignInTime?.toIso8601String(),
      'managementUrl': 'https://myaccount.google.com/security',
    };
  });
}
