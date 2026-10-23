import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../firebase/firestore_json.dart';
import '../models/timetable_scan_model.dart';
import '../result/api_result.dart';
import '../result/guard.dart';
import '../session/current_user.dart';

/// Import thời khóa biểu từ ảnh: ảnh -> Storage -> Cloud Function `scanTimetable` (OCR)
/// -> GV chọn lớp -> nhận lớp bằng cách ghi `teacherMemberCode` (Security Rules chỉ cho nhận lớp
/// chưa có giảng viên).
class TimetableRepository {
  TimetableRepository({
    required this.currentUser,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
  }) : _injectedDb = firestore,
       _injectedStorage = storage,
       _injectedFunctions = functions,
       _injectedAuth = auth;

  /// Phải trùng `region` trong `firebase/functions/index.js`.
  static const functionsRegion = 'asia-southeast1';

  final CurrentUser currentUser;
  final FirebaseFirestore? _injectedDb;
  final FirebaseStorage? _injectedStorage;
  final FirebaseFunctions? _injectedFunctions;
  final FirebaseAuth? _injectedAuth;

  FirebaseFirestore get _db => _injectedDb ?? FirebaseFirestore.instance;
  FirebaseStorage get _storage => _injectedStorage ?? FirebaseStorage.instance;
  FirebaseFunctions get _functions =>
      _injectedFunctions ?? FirebaseFunctions.instanceFor(region: functionsRegion);
  FirebaseAuth get _auth => _injectedAuth ?? FirebaseAuth.instance;

  /// Lớp được phép nhận theo từng lần quét (thay cho scanToken lưu cache ở backend cũ).
  final Map<String, Set<String>> _scans = {};

  Future<ApiResult<TimetableScanResult>> scanImage({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) => guardApi(() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw ApiException('UNAUTHORIZED', 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
    }
    final safe = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
    final path = 'timetable_scans/$uid/${DateTime.now().millisecondsSinceEpoch}_$safe';
    await _storage
        .ref(path)
        .putData(bytes, SettableMetadata(contentType: mimeType));

    final response = await _functions
        .httpsCallable('scanTimetable')
        .call<Map<Object?, Object?>>({'storagePath': path});
    final data = Map<String, dynamic>.from(response.data);
    final result = TimetableScanResult.fromJson(data);
    _scans[result.scanToken] = {
      for (final e in result.entries)
        if (e.canImport && e.matchedClassCode != null) e.matchedClassCode!,
    };
    return result;
  });

  Future<ApiResult<TimetableImportResult>> importAssignments({
    required String scanToken,
    required List<String> classCodes,
  }) => guardApi(() async {
    final me = currentUser.memberCode;
    final allowed = _scans[scanToken];
    if (allowed == null) {
      throw ApiException('SCAN_EXPIRED', 'Kết quả quét đã hết hạn. Vui lòng quét lại ảnh.');
    }
    final requested = {
      for (final c in classCodes)
        if (c.trim().isNotEmpty) c.trim(),
    }.toList();
    if (requested.isEmpty) {
      throw ApiException('VALIDATION_ERROR', 'Chưa chọn lớp nào để thêm.');
    }
    if (requested.any((c) => !allowed.contains(c))) {
      throw ApiException('FORBIDDEN', 'Danh sách lớp không khớp với kết quả quét đã xác thực.');
    }

    // Kiểm tra toàn bộ lô trước khi ghi để không nhận dở dang.
    final toAssign = <String>[];
    var already = 0;
    for (final code in requested) {
      final snap = await _db.collection('classes').doc(code).get();
      if (!snap.exists) {
        throw ApiException('CLASS_NOT_FOUND', 'Lớp $code không còn tồn tại.');
      }
      final owner = text(snap.data()!['teacherMemberCode']);
      if (owner.isNotEmpty && owner != me) {
        throw ApiException('ASSIGNMENT_CONFLICT', 'Lớp $code vừa được phân công cho giáo viên khác.');
      }
      if (owner == me) {
        already++;
      } else {
        toAssign.add(code);
      }
    }

    try {
      for (final code in toAssign) {
        final enrollments = await _db
            .collection('enrollments')
            .where('teacherMemberCode', isEqualTo: '')
            .where('classCode', isEqualTo: code)
            .get();
        // Mỗi lớp một batch (lớp + ghi danh); rules từ chối nếu lớp đã có GV khác.
        final docs = enrollments.docs;
        for (var i = 0; i < docs.length || i == 0; i += 450) {
          final batch = _db.batch();
          if (i == 0) {
            batch.update(_db.collection('classes').doc(code), {'teacherMemberCode': me});
          }
          for (final e in docs.skip(i).take(450)) {
            batch.update(e.reference, {'teacherMemberCode': me});
          }
          await batch.commit();
        }
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw ApiException('ASSIGNMENT_CONFLICT', 'Lớp vừa được phân công cho giáo viên khác. Hãy quét lại.');
      }
      rethrow;
    }

    _scans.remove(scanToken);
    return TimetableImportResult(
      assignedCount: toAssign.length,
      alreadyAssignedCount: already,
      classCodes: requested,
    );
  });
}
