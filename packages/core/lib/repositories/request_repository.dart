import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../result/api_result.dart';
import '../result/guard.dart';

class RequestRepository {
  RequestRepository({
    required this.uid,
    required this.memberCode,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _injectedDb = firestore,
       _injectedStorage = storage;

  final String uid;
  final String memberCode;
  final FirebaseFirestore? _injectedDb;
  final FirebaseStorage? _injectedStorage;

  FirebaseFirestore get _db => _injectedDb ?? FirebaseFirestore.instance;
  FirebaseStorage get _storage => _injectedStorage ?? FirebaseStorage.instance;

  Stream<List<Map<String, dynamic>>> watchMine() {
    return _db
        .collection('requests')
        .where('authorUid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
          list.sort((a, b) {
            final aTime = a['createdAt'];
            final bTime = b['createdAt'];
            if (aTime is Timestamp && bTime is Timestamp) {
              return bTime.compareTo(aTime);
            }
            return 0;
          });
          return list;
        });
  }

  Future<ApiResult<List<Map<String, dynamic>>>> classOptions() =>
      guardApi(() async {
        // 1. Check teacher classes
        final teacherClasses = await _db
            .collection('classes')
            .where('teacherMemberCode', isEqualTo: memberCode)
            .get();
        if (teacherClasses.docs.isNotEmpty) {
          return teacherClasses.docs.map((doc) {
            final d = doc.data();
            return {
              'classCode': d['classCode']?.toString() ?? doc.id,
              'slotCode':
                  d['slotCode']?.toString() ??
                  d['defaultSlot']?.toString() ??
                  'Slot 1',
              'timeLabel': d['timeLabel']?.toString() ?? '07:00 - 08:30',
              'room':
                  d['room']?.toString() ??
                  d['defaultRoom']?.toString() ??
                  'Phòng học',
            };
          }).toList();
        }

        // 2. Check student enrollments
        final enrollments = await _db
            .collection('enrollments')
            .where('studentMemberCode', isEqualTo: memberCode)
            .get();
        if (enrollments.docs.isNotEmpty) {
          return enrollments.docs.map((doc) {
            final d = doc.data();
            return {
              'classCode': d['classCode']?.toString() ?? doc.id,
              'slotCode': d['slotCode']?.toString() ?? 'Slot 1',
              'timeLabel': d['timeLabel']?.toString() ?? '07:00 - 08:30',
              'room': d['room']?.toString() ?? 'Phòng học',
            };
          }).toList();
        }

        // 3. Fallback: all classes
        final allClasses = await _db.collection('classes').limit(50).get();
        return allClasses.docs.map((doc) {
          final d = doc.data();
          return {
            'classCode': d['classCode']?.toString() ?? doc.id,
            'slotCode': d['defaultSlot']?.toString() ?? 'Slot 1',
            'timeLabel': d['timeLabel']?.toString() ?? '07:00 - 08:30',
            'room':
                d['room']?.toString() ??
                d['defaultRoom']?.toString() ??
                'Phòng học',
          };
        }).toList();
      });

  Future<ApiResult<List<Map<String, dynamic>>>> sessionOptions(
    String classCode,
  ) => guardApi(() async {
    final normalizedClassCode = classCode.trim();
    if (normalizedClassCode.isEmpty) return [];

    final snapshot = await _db
        .collection('sessions')
        .where('teacherMemberCode', isEqualTo: memberCode)
        .where('classCode', isEqualTo: normalizedClassCode)
        .orderBy('sessionDate', descending: true)
        .limit(100)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return <String, dynamic>{
        'sessionId': doc.id,
        'sessionDate': data['sessionDate']?.toString() ?? '',
        'slotCode': data['slotCode']?.toString() ?? '',
        'sessionStatus': data['sessionStatus']?.toString() ?? '',
      };
    }).toList();
  });

  Future<ApiResult<String>> uploadAttachment(
    Uint8List bytes,
    String mime,
    String name,
  ) => guardApi(() async {
    final safeName = name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path =
        'requests/$uid/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final ref = _storage.ref(path);
    await ref.putData(bytes, SettableMetadata(contentType: mime));
    final url = await ref.getDownloadURL();
    return url;
  });

  Future<ApiResult<void>> submit({
    required String id,
    required String type,
    required String reason,
    required String classCode,
    String? sessionId,
    String? mainReason,
    String? slot,
    String? date,
    String? room,
    List<String>? attachments,
  }) => guardApi(() async {
    final validTypes = ['attendance_fix', 'leave'];
    final normalizedType = validTypes.contains(type) ? type : 'leave';
    final trimmedReason = reason.trim().isEmpty
        ? 'Không có lý do'
        : reason.trim();
    final clampedReason = trimmedReason.length > 2000
        ? trimmedReason.substring(0, 2000)
        : trimmedReason;

    final docRef = _db.collection('requests').doc(id.isNotEmpty ? id : null);
    final data = <String, dynamic>{
      'type': normalizedType,
      'authorUid': uid,
      'authorMemberCode': memberCode,
      'reason': clampedReason,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (classCode.isNotEmpty) {
      data['classCode'] = classCode;
    }
    if (sessionId != null && sessionId.trim().isNotEmpty) {
      data['sessionId'] = sessionId.trim();
    }
    if (attachments != null && attachments.isNotEmpty) {
      data['attachments'] = attachments;
    }

    await docRef.set(data);
  });
}
