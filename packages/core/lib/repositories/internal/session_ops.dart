import 'package:cloud_firestore/cloud_firestore.dart';

import '../../firebase/firestore_json.dart';
import '../../models/session_model.dart';
import '../../result/guard.dart';
import 'teacher_data.dart';

/// Mở một phiên điểm danh cho lớp của giảng viên [memberCode].
///
/// - Kiểm tra lớp thuộc giảng viên (Security Rules cũng kiểm tra lại).
/// - [rejectIfOpen] = true: báo `SESSION_ALREADY_OPEN` nếu lớp đang có phiên mở;
///   false: tự đóng các phiên đang mở rồi mở phiên mới (hành vi của dashboard).
/// - `teacherIp` chỉ được lưu khi [ipCheck] bật.
Future<SessionModel> createSession(
  FirebaseFirestore db, {
  required String memberCode,
  required String classCode,
  required String slotCode,
  required bool ipCheck,
  required String teacherIp,
  required DateTime now,
  required bool rejectIfOpen,
}) async {
  var slot = slotCode.trim();
  final ip = ipCheck ? teacherIp.trim() : '';

  final classSnap = await db.collection('classes').doc(classCode).get();
  final cls = classSnap.data();
  if (cls == null || text(cls['teacherMemberCode']) != memberCode) {
    throw ApiException('FORBIDDEN', 'Lớp không thuộc giảng viên đang đăng nhập.');
  }
  if (slot.isEmpty) slot = text(cls['slotCode']);
  if (classCode.isEmpty || slot.isEmpty) {
    throw ApiException('VALIDATION_ERROR', 'Thiếu dữ liệu mở phiên.');
  }
  if (ipCheck && ip.isEmpty) {
    throw ApiException(
      'VALIDATION_ERROR',
      'Thiếu IP mạng giảng viên để bật kiểm tra IP.',
    );
  }

  final open = await db
      .collection('sessions')
      .where('teacherMemberCode', isEqualTo: memberCode)
      .where('classCode', isEqualTo: classCode)
      .where('sessionStatus', isEqualTo: 'open')
      .get();
  if (rejectIfOpen && open.docs.isNotEmpty) {
    throw ApiException(
      'SESSION_ALREADY_OPEN',
      'Lớp đang có phiên mở. Kết thúc phiên đó trước khi tạo phiên mới.',
    );
  }

  final ref = db.collection('sessions').doc();
  final secret = randomSecret();
  final date = vnDate(now);
  final batch = db.batch();
  for (final doc in open.docs) {
    batch.update(doc.reference, {'sessionStatus': 'closed'});
  }
  batch.set(ref, {
    'classCode': classCode,
    'teacherMemberCode': memberCode,
    'sessionDate': date,
    'slotCode': slot,
    'sessionStatus': 'open',
    'qrSecret': secret,
    'ipCheck': ipCheck,
    'teacherIp': ip,
    'createdAt': FieldValue.serverTimestamp(),
  });
  await batch.commit();

  return SessionModel(
    sessionId: ref.id,
    classCode: classCode,
    sessionDate: date,
    slotCode: slot,
    sessionStatus: 'open',
    qrToken: secret,
    ipCheck: ipCheck,
  );
}
