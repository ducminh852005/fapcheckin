import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/timetable_parser.dart';

import '../firebase/firestore_json.dart';
import '../models/timetable_scan_model.dart';
import '../result/api_result.dart';
import '../result/guard.dart';
import '../session/current_user.dart';

/// Import thời khóa biểu từ ảnh: OCR trên thiết bị -> đối chiếu lớp được phép đọc.
/// -> GV chọn lớp -> nhận lớp bằng cách ghi `teacherMemberCode` (Security Rules chỉ cho nhận lớp
/// chưa có giảng viên).
class TimetableRepository {
  TimetableRepository({
    required this.currentUser,
    FirebaseFirestore? firestore,
    this.recognizeText,
    FirebaseAuth? auth,
  }) : _injectedDb = firestore,
       _injectedAuth = auth;

  final CurrentUser currentUser;
  final FirebaseFirestore? _injectedDb;
  final Future<String> Function(Uint8List bytes)? recognizeText;
  final FirebaseAuth? _injectedAuth;

  FirebaseFirestore get _db => _injectedDb ?? FirebaseFirestore.instance;
  FirebaseAuth get _auth => _injectedAuth ?? FirebaseAuth.instance;

  /// Lớp được phép nhận theo từng lần quét (thay cho scanToken lưu cache ở backend cũ).
  final Map<String, Set<String>> _scans = {};
  List<Map<String, dynamic>>? _classCache;
  String? _cacheAccount;
  DateTime? _cacheTime;

  Future<ApiResult<TimetableScanResult>> scanImage({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) => guardApi(() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw ApiException(
        'UNAUTHORIZED',
        'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
      );
    }
    if (bytes.isEmpty ||
        bytes.length > 5 * 1024 * 1024 ||
        !{'image/jpeg', 'image/png'}.contains(mimeType)) {
      throw ApiException('INVALID_IMAGE', 'Chọn ảnh JPG/PNG không quá 5 MB.');
    }
    final recognize = recognizeText;
    if (recognize == null) {
      throw ApiException(
        'OCR_UNSUPPORTED',
        'OCR offline chưa hỗ trợ nền tảng này.',
      );
    }
    final extracted = await recognize(bytes);
    final parsed = parseTimetable(extracted);
    if (parsed.entries.isEmpty) {
      throw ApiException(
        'OCR_EMPTY',
        'Không nhận ra mã lớp–môn. Hãy chọn ảnh rõ hơn (ví dụ SE1917-PRN232).',
      );
    }
    final me = currentUser.memberCode;
    if (me.isEmpty) {
      throw ApiException('UNAUTHORIZED', 'Vui lòng đăng nhập lại.');
    }
    // Match only classes permitted by existing Firestore rules. Never widen access.
    final account = '$uid|$me';
    if (_cacheAccount != account ||
        _classCache == null ||
        DateTime.now().difference(_cacheTime!) > const Duration(minutes: 2)) {
      final docs = await _db
          .collection('classes')
          .where('teacherMemberCode', whereIn: ['', me])
          .get();
      _classCache = docs.docs
          .map((d) => {
            ...d.data(),
            'classCode': text(d.data()['classCode']).isEmpty
                ? d.id
                : text(d.data()['classCode']),
            'documentId': d.id,
          })
          .toList();
      _cacheAccount = account;
      _cacheTime = DateTime.now();
    }
    final result = TimetableScanResult(
      scanToken: '${DateTime.now().microsecondsSinceEpoch}',
      entries: matchTimetable(parsed, _classCache!, me),
      detectedDates: parsed.dates,
    );
    _scans.clear();
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
    if (_cacheAccount != '${_auth.currentUser?.uid}|$me' || me.isEmpty) {
      throw ApiException(
        'SCAN_EXPIRED',
        'Phiên đăng nhập đã thay đổi. Hãy quét lại.',
      );
    }
    final allowed = _scans[scanToken];
    if (allowed == null) {
      throw ApiException(
        'SCAN_EXPIRED',
        'Kết quả quét đã hết hạn. Vui lòng quét lại ảnh.',
      );
    }
    final requested = {
      for (final c in classCodes)
        if (c.trim().isNotEmpty) c.trim(),
    }.toList();
    if (requested.isEmpty) {
      throw ApiException('VALIDATION_ERROR', 'Chưa chọn lớp nào để thêm.');
    }
    if (requested.any((c) => !allowed.contains(c))) {
      throw ApiException(
        'FORBIDDEN',
        'Danh sách lớp không khớp với kết quả quét đã xác thực.',
      );
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
        throw ApiException(
          'ASSIGNMENT_CONFLICT',
          'Lớp $code vừa được phân công cho giáo viên khác.',
        );
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
            batch.update(_db.collection('classes').doc(code), {
              'teacherMemberCode': me,
            });
          }
          for (final e in docs.skip(i).take(450)) {
            batch.update(e.reference, {'teacherMemberCode': me});
          }
          await batch.commit();
        }
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw ApiException(
          'ASSIGNMENT_CONFLICT',
          'Lớp vừa được phân công cho giáo viên khác. Hãy quét lại.',
        );
      }
      rethrow;
    }

    _scans.remove(scanToken);
    _classCache = null;
    return TimetableImportResult(
      assignedCount: toAssign.length,
      alreadyAssignedCount: already,
      classCodes: requested,
    );
  });
}
