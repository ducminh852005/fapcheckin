import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fapcheckin_core/models/user_model.dart';
import 'package:fapcheckin_core/session/current_user.dart';

/// Giảng viên GV001 đã đăng nhập.
CurrentUser teacher({String memberCode = 'GV001'}) => CurrentUser()
  ..set(
    UserModel(
      memberCode: memberCode,
      fullName: 'GV Một',
      role: 'staff',
      rollNumber: '',
      email: 'gv001@fpt.edu.vn',
    ),
  );

/// Dữ liệu nền: lớp PRN232_SE1917 (GV001, 3 SV), lớp SWD392_SE1801 (GV002), slot A1.
Future<FakeFirebaseFirestore> seededDb() async {
  final db = FakeFirebaseFirestore();
  await db.collection('timeSlots').doc('A-1').set({
    'period': 'Morning',
    'startTime': '07:00',
    'endTime': '09:15',
  });
  await db.collection('slots').doc('A1').set({
    'timeSlotId': 'A-1',
    'weekdays': [2, 5],
  });
  await db.collection('classes').doc('PRN232_SE1917').set({
    'classCode': 'PRN232_SE1917',
    'subjectCode': 'PRN232',
    'subjectName': 'Web API',
    'room': '303',
    'studentCount': 3,
    'teacherMemberCode': 'GV001',
    'slotCode': 'A1',
  });
  await db.collection('classes').doc('SWD392_SE1801').set({
    'classCode': 'SWD392_SE1801',
    'subjectCode': 'SWD392',
    'subjectName': 'Architecture',
    'room': '101',
    'studentCount': 1,
    'teacherMemberCode': 'GV002',
    'slotCode': 'A1',
  });
  for (final roll in ['SE1001', 'SE1002', 'SE1003']) {
    await db.collection('enrollments').doc('PRN232_SE1917_$roll').set({
      'classCode': 'PRN232_SE1917',
      'rollNumber': roll,
      'teacherMemberCode': 'GV001',
      'fullName': 'SV $roll',
      'email': '${roll.toLowerCase()}@fpt.edu.vn',
    });
  }
  await db.collection('enrollments').doc('SWD392_SE1801_SE2001').set({
    'classCode': 'SWD392_SE1801',
    'rollNumber': 'SE2001',
    'teacherMemberCode': 'GV002',
    'fullName': 'SV khác',
    'email': 'se2001@fpt.edu.vn',
  });
  return db;
}

/// Ghi một bản ghi điểm danh như khi SV quét QR / GV chấm tay.
Future<void> putRecord(
  FakeFirebaseFirestore db,
  String sessionId,
  String roll,
  String status, {
  String classCode = 'PRN232_SE1917',
  String teacher = 'GV001',
  String network = 'Skipped',
  String? note,
}) => db.collection('attendance_records').doc('${sessionId}_$roll').set({
  'sessionId': sessionId,
  'rollNumber': roll,
  'classCode': classCode,
  'teacherMemberCode': teacher,
  'status': status,
  'networkVerificationResult': network,
  'ipAddress': '',
  'syncedToFap': false,
  'note': ?note,
});
