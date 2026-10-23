import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fapcheckin_core/repositories/teacher_repository.dart';
import 'package:fapcheckin_core/result/api_result.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

T ok<T>(ApiResult<T> r) {
  expect(
    r,
    isA<ApiSuccess<T>>(),
    reason: r is ApiFailure<T> ? r.error.message : '',
  );
  return (r as ApiSuccess<T>).data;
}

String failCode<T>(ApiResult<T> r) {
  expect(r, isA<ApiFailure<T>>());
  return (r as ApiFailure<T>).error.code;
}

void main() {
  late FakeFirebaseFirestore db;
  late TeacherRepository repo;
  // 2026-10-21 03:00 UTC = 10:00 giờ Việt Nam
  final now = DateTime.utc(2026, 10, 21, 3);

  setUp(() async {
    db = await seededDb();
    repo = TeacherRepository(
      currentUser: teacher(),
      firestore: db,
      now: () => now,
    );
  });

  Future<String> open({bool ipCheck = false, String ip = ''}) async => ok(
    await repo.startSession(
      classCode: 'PRN232_SE1917',
      slotCode: 'A1',
      ipCheck: ipCheck,
      teacherIp: ip,
    ),
  ).sessionId;

  group('startSession', () {
    test('tạo phiên mở với qrSecret và lưu teacherMemberCode', () async {
      final s = ok(
        await repo.startSession(classCode: 'PRN232_SE1917', slotCode: 'A1'),
      );
      expect(s.isOpen, true);
      expect(s.sessionDate, '2026-10-21');
      expect(s.qrToken.length, greaterThanOrEqualTo(16));
      expect(s.ipCheck, false);
      final doc = await db.collection('sessions').doc(s.sessionId).get();
      expect(doc['teacherMemberCode'], 'GV001');
      expect(doc['qrSecret'], s.qrToken);
      expect(doc['teacherIp'], '');
    });

    test('ipCheck bật thì cần teacherIp và được lưu', () async {
      expect(
        failCode(
          await repo.startSession(
            classCode: 'PRN232_SE1917',
            slotCode: 'A1',
            ipCheck: true,
          ),
        ),
        'VALIDATION_ERROR',
      );
      final id = await open(ipCheck: true, ip: '1.2.3.4');
      expect((await db.collection('sessions').doc(id).get())['teacherIp'], '1.2.3.4');
    });

    test('tự đóng phiên đang mở của cùng lớp', () async {
      final first = await open();
      final second = await open();
      expect((await db.collection('sessions').doc(first).get())['sessionStatus'], 'closed');
      expect((await db.collection('sessions').doc(second).get())['sessionStatus'], 'open');
    });

    test('từ chối lớp của giảng viên khác', () async {
      expect(
        failCode(
          await repo.startSession(classCode: 'SWD392_SE1801', slotCode: 'A1'),
        ),
        'FORBIDDEN',
      );
    });

    test('lấy slot mặc định của lớp khi không truyền slotCode', () async {
      final s = ok(
        await repo.startSession(classCode: 'PRN232_SE1917', slotCode: ''),
      );
      expect(s.slotCode, 'A1');
    });
  });

  group('rotateQr / syncSessionTeacherIp', () {
    test('rotateQr đổi secret của phiên đang mở', () async {
      final id = await open();
      final before = (await db.collection('sessions').doc(id).get())['qrSecret'];
      final token = ok(await repo.rotateQr(sessionId: id));
      expect(token, isNot(before));
      expect((await db.collection('sessions').doc(id).get())['qrSecret'], token);
    });

    test('rotateQr báo lỗi khi phiên đã đóng', () async {
      final id = await open();
      ok(await repo.closeSession(sessionId: id));
      expect(failCode(await repo.rotateQr(sessionId: id)), 'SESSION_NOT_FOUND');
    });

    test('không thao tác được phiên của GV khác', () async {
      await db.collection('sessions').doc('other').set({
        'classCode': 'SWD392_SE1801',
        'teacherMemberCode': 'GV002',
        'sessionStatus': 'open',
        'qrSecret': 'x' * 20,
      });
      expect(failCode(await repo.rotateQr(sessionId: 'other')), 'FORBIDDEN');
      expect(failCode(await repo.closeSession(sessionId: 'other')), 'FORBIDDEN');
    });

    test('syncSessionTeacherIp cập nhật IP', () async {
      final id = await open(ipCheck: true, ip: '1.1.1.1');
      expect(
        ok(await repo.syncSessionTeacherIp(sessionId: id, teacherIp: '2.2.2.2')),
        '2.2.2.2',
      );
      expect((await db.collection('sessions').doc(id).get())['teacherIp'], '2.2.2.2');
    });
  });

  group('closeSession', () {
    test('sinh bản ghi Absent (AutoAbsent) cho SV chưa điểm danh', () async {
      final id = await open();
      await putRecord(db, id, 'SE1001', 'Present'); // SV đã tự quét QR
      final result = ok(await repo.closeSession(sessionId: id));
      expect(result.autoAbsentCount, 2);
      final records = await db
          .collection('attendance_records')
          .where('sessionId', isEqualTo: id)
          .get();
      expect(records.docs.length, 3);
      final absent = records.docs.where((d) => d['status'] == 'Absent').toList();
      expect(absent.map((d) => d['rollNumber']).toSet(), {'SE1002', 'SE1003'});
      expect(absent.every((d) => d['networkVerificationResult'] == 'AutoAbsent'), true);
      expect((await db.collection('sessions').doc(id).get())['sessionStatus'], 'closed');
    });
  });

  group('roster & điểm danh tay', () {
    test('getRoster ghép ghi danh với bản ghi; chặn Present+Mismatch cũ', () async {
      final id = await open();
      await putRecord(db, id, 'SE1001', 'Present');
      await putRecord(db, id, 'SE1002', 'Present', network: 'Mismatch');
      final roster = ok(await repo.getRoster(sessionId: id));
      expect(roster.map((r) => r.rollNumber), ['SE1001', 'SE1002', 'SE1003']);
      expect(roster[0].status, 'Present');
      expect(roster[0].fullName, 'SV SE1001');
      expect(roster[1].status, '');
      expect(roster[2].isUnchecked, true);
    });

    test('manualCheckin tạo mới rồi cập nhật cùng một bản ghi', () async {
      final id = await open();
      ok(await repo.manualCheckin(sessionId: id, rollNumber: 'SE1003'));
      var doc = await db.collection('attendance_records').doc('${id}_SE1003').get();
      expect(doc['status'], 'ManualByGV');
      expect(doc['networkVerificationResult'], 'Manual');
      expect(doc['teacherMemberCode'], 'GV001');
      expect(doc['classCode'], 'PRN232_SE1917');
      ok(await repo.manualCheckin(sessionId: id, rollNumber: 'SE1003', status: 'Late'));
      doc = await db.collection('attendance_records').doc('${id}_SE1003').get();
      expect(doc['status'], 'Late');
      expect((await db.collection('attendance_records').get()).docs.length, 1);
    });

    test('manualCheckinBulk ghi nhiều SV kèm ghi chú', () async {
      final id = await open();
      ok(
        await repo.manualCheckinBulk(
          sessionId: id,
          changes: [
            {'rollNumber': 'SE1001', 'status': 'Present', 'reason': 'Có mặt'},
            {'rollNumber': 'SE1002', 'status': 'Absent', 'reason': 'Nghỉ'},
          ],
        ),
      );
      final doc = await db.collection('attendance_records').doc('${id}_SE1002').get();
      expect(doc['status'], 'Absent');
      expect(doc['note'], 'Nghỉ');
    });
  });

  group('getClasses', () {
    test('chỉ trả lớp của GV, kèm phiên đang mở hôm nay và giờ học', () async {
      final id = await open(ipCheck: true, ip: '1.1.1.1');
      final classes = ok(await repo.getClasses(teacherMemberCode: 'GV001'));
      expect(classes.map((c) => c.classCode), ['PRN232_SE1917']);
      final c = classes.single;
      expect(c.isActive, true);
      expect(c.activeSessionId, id);
      expect(c.activeSessionIpCheck, true);
      expect(c.timeLabel, contains('07:00'));
      expect(c.subjectCode, 'PRN232');
    });

    test('tính điểm danh trung bình và số buổi đã kết thúc', () async {
      final id = await open();
      await putRecord(db, id, 'SE1001', 'Present');
      await putRecord(db, id, 'SE1002', 'Present');
      ok(await repo.closeSession(sessionId: id));
      final c = ok(await repo.getClasses(teacherMemberCode: 'GV001')).single;
      expect(c.completedSessions, 1);
      expect(c.averageAttendance, closeTo(2 / 3 * 100, 0.01));
      expect(c.isActive, false);
    });

    test('buổi học bù hôm nay thành thẻ riêng', () async {
      await db.collection('class_schedules').doc('plan1').set({
        'classCode': 'PRN232_SE1917',
        'teacherMemberCode': 'GV001',
        'scheduleDate': '2026-10-21',
        'slotCode': 'A1',
        'room': '404',
        'status': 'scheduled',
      });
      final classes = ok(await repo.getClasses(teacherMemberCode: 'GV001'));
      expect(classes.length, 2);
      final makeup = classes.firstWhere((c) => c.isMakeup);
      expect(makeup.timeLabel, contains('07:00'));
      expect(makeup.room, '404');
      expect(classes.firstWhere((c) => !c.isMakeup).room, '404');
    });
  });

  group('getSessions / getStats / getAttendanceHistory', () {
    test('getSessions gộp phiên thật và lịch kế hoạch chưa mở', () async {
      final id = await open();
      await db.collection('class_schedules').doc('planned').set({
        'classCode': 'PRN232_SE1917',
        'teacherMemberCode': 'GV001',
        'scheduleDate': '2026-10-25',
        'slotCode': 'A1',
        'status': 'scheduled',
      });
      await db.collection('class_schedules').doc('cancelled').set({
        'classCode': 'PRN232_SE1917',
        'teacherMemberCode': 'GV001',
        'scheduleDate': '2026-10-26',
        'slotCode': 'A1',
        'status': 'cancelled',
      });
      final sessions = ok(await repo.getSessions(classCode: 'PRN232_SE1917'));
      expect(sessions.map((x) => x.sessionStatus), ['open', 'planned']);
      expect(sessions.first.sessionId, id);
    });

    test('getStats tính % có mặt theo số phiên của lớp', () async {
      final a = await open();
      final b = await open();
      await putRecord(db, a, 'SE1001', 'Present');
      await putRecord(db, b, 'SE1001', 'Present');
      await putRecord(db, a, 'SE1002', 'Late');
      final stats = {
        for (final e in ok(await repo.getStats(classCode: 'PRN232_SE1917')))
          e.rollNumber: e.attendancePercentage,
      };
      expect(stats['SE1001'], 100);
      expect(stats['SE1002'], 50);
      expect(stats['SE1003'], 0);
    });

    test('getAttendanceHistory lấy phiên mới nhất khi không truyền sessionId', () async {
      final id = await open();
      ok(await repo.manualCheckin(sessionId: id, rollNumber: 'SE1001', status: 'Present'));
      final h = ok(await repo.getAttendanceHistory(classCode: 'PRN232_SE1917'));
      expect(h.sessionId, id);
      expect(h.totalSessions, 1);
      expect(h.students.firstWhere((x) => x.rollNumber == 'SE1001').status, 'Present');
      expect(h.students.firstWhere((x) => x.rollNumber == 'SE1002').status, 'Absent');
    });
  });

  test('syncToFap đánh dấu các bản ghi chưa đồng bộ', () async {
    final id = await open();
    ok(await repo.manualCheckin(sessionId: id, rollNumber: 'SE1001'));
    expect(ok(await repo.syncToFap(classCode: 'PRN232_SE1917')).syncedCount, 1);
    expect(ok(await repo.syncToFap()).syncedCount, 0);
  });

  test('chưa đăng nhập → UNAUTHORIZED', () async {
    final anon = TeacherRepository(
      currentUser: teacher()..clear(),
      firestore: db,
      now: () => now,
    );
    expect(
      failCode(await anon.startSession(classCode: 'PRN232_SE1917', slotCode: 'A1')),
      'UNAUTHORIZED',
    );
  });
}
