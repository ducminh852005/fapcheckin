import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fapcheckin_core/repositories/attendance_history_repository.dart';
import 'package:fapcheckin_core/repositories/report_repository.dart';
import 'package:fapcheckin_core/repositories/schedule_repository.dart';
import 'package:fapcheckin_core/repositories/internal/teacher_data.dart';
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

Future<void> putSession(
  FakeFirebaseFirestore db,
  String id,
  String date,
  String status,
) => db.collection('sessions').doc(id).set({
  'classCode': 'PRN232_SE1917',
  'teacherMemberCode': 'GV001',
  'sessionDate': date,
  'slotCode': 'A1',
  'sessionStatus': status,
  'qrSecret': 'secret-$id-0123456789',
  'ipCheck': false,
  'teacherIp': '',
});

void main() {
  late FakeFirebaseFirestore db;
  // 2026-10-21 01:00 UTC = 08:00 giờ Việt Nam (trong slot A1).
  final now = DateTime.utc(2026, 10, 21, 1);

  setUp(() async {
    db = await seededDb();
  });

  group('AttendanceHistoryRepository', () {
    late AttendanceHistoryRepository repo;
    setUp(() {
      repo = AttendanceHistoryRepository(
        currentUser: teacher(),
        firestore: db,
        now: () => now,
      );
    });

    Future<void> twoClosedSessions() async {
      await putSession(db, 's1', '2026-10-21', 'closed');
      await putSession(db, 's2', '2026-10-21', 'closed');
      await putRecord(db, 's1', 'SE1001', 'Present');
      await putRecord(db, 's1', 'SE1002', 'Late');
      await putRecord(db, 's1', 'SE1003', 'Absent');
      await putRecord(db, 's2', 'SE1001', 'Present');
      // SE1002, SE1003 không có bản ghi ở s2 (phiên đã đóng -> tính vắng)
    }

    test('getClasses tính tỉ lệ có mặt, đi trễ và số SV nguy cơ', () async {
      await twoClosedSessions();
      final c = ok(await repo.getClasses()).single;
      expect(c.classCode, 'PRN232_SE1917');
      expect(c.studentCount, 3);
      expect(c.completedSessions, 2);
      // có mặt (Present+Late): SE1001 x2, SE1002 x1 = 3 / (2*3)
      expect(c.attendanceRate, closeTo(0.5, 1e-9));
      expect(c.lateRate, closeTo(1 / 6, 1e-9));
      expect(c.atRiskCount, 2); // SE1002 vắng 1/2, SE1003 vắng 2/2 (> 20%)
      expect(c.latestSession!.sessionId, 's2');
    });

    test('getSummary thống kê từng sinh viên', () async {
      await twoClosedSessions();
      final s = ok(await repo.getSummary('PRN232_SE1917'));
      expect(s.teacherName, 'GV Một');
      expect(s.slotCodes, ['A1']);
      final se1002 = s.students.firstWhere((x) => x.rollNumber == 'SE1002');
      expect(
        (se1002.presentCount, se1002.lateCount, se1002.absentCount),
        (0, 1, 1),
      );
      expect(se1002.attendanceRate, 0.5);
    });

    test('từ chối lớp không thuộc GV', () async {
      expect(failCode(await repo.getSummary('SWD392_SE1801')), 'FORBIDDEN');
    });

    test(
      'getDetail trả revision và trạng thái; phiên lạ → SESSION_NOT_FOUND',
      () async {
        await twoClosedSessions();
        final d = ok(await repo.getDetail('PRN232_SE1917', sessionId: 's1'));
        expect(d.selectedSession!.sessionId, 's1');
        final se1001 = d.students.firstWhere((x) => x.rollNumber == 'SE1001');
        expect(se1001.status, 'Present');
        expect(se1001.revision, isNotEmpty);
        expect(
          failCode(await repo.getDetail('PRN232_SE1917', sessionId: 'nope')),
          'SESSION_NOT_FOUND',
        );
      },
    );

    test('save ghi thay đổi, đánh dấu Manual, và trả chi tiết mới', () async {
      await twoClosedSessions();
      final before = ok(await repo.getDetail('PRN232_SE1917', sessionId: 's1'));
      final se1003 = before.students.firstWhere(
        (x) => x.rollNumber == 'SE1003',
      );
      final after = ok(
        await repo.save('PRN232_SE1917', 's1', [
          {
            'rollNumber': 'SE1003',
            'status': 'Present',
            'note': 'Có phép',
            'revision': se1003.revision,
          },
        ]),
      );
      expect(
        after.students.firstWhere((x) => x.rollNumber == 'SE1003').status,
        'Present',
      );
      final doc = await db
          .collection('attendance_records')
          .doc('s1_SE1003')
          .get();
      expect(doc['networkVerificationResult'], 'Manual');
      expect(doc['note'], 'Có phép');
      expect(doc['updatedBy'], 'GV001');
      expect(doc['syncedToFap'], false);
    });

    test('save tạo bản ghi mới cho SV chưa có (revision rỗng)', () async {
      await twoClosedSessions();
      ok(
        await repo.save('PRN232_SE1917', 's2', [
          {
            'rollNumber': 'SE1002',
            'status': 'Late',
            'note': '',
            'revision': '',
          },
        ]),
      );
      final doc = await db
          .collection('attendance_records')
          .doc('s2_SE1002')
          .get();
      expect(doc['classCode'], 'PRN232_SE1917');
      expect(doc['teacherMemberCode'], 'GV001');
      expect(doc['checkinTime'], isNotNull);
      final reloaded = ok(
        await repo.getDetail('PRN232_SE1917', sessionId: 's2'),
      );
      expect(
        reloaded.students
            .firstWhere((student) => student.rollNumber == 'SE1002')
            .status,
        'Late',
      );
    });

    test('save phát hiện xung đột khi dữ liệu đã đổi', () async {
      await twoClosedSessions();
      final d = ok(await repo.getDetail('PRN232_SE1917', sessionId: 's1'));
      final revision = d.students
          .firstWhere((x) => x.rollNumber == 'SE1001')
          .revision;
      // Người khác sửa bản ghi sau khi GV tải trang
      await db.collection('attendance_records').doc('s1_SE1001').update({
        'status': 'Late',
        'note': 'đổi',
      });
      expect(
        failCode(
          await repo.save('PRN232_SE1917', 's1', [
            {
              'rollNumber': 'SE1001',
              'status': 'Absent',
              'note': '',
              'revision': revision,
            },
          ]),
        ),
        'CONFLICT',
      );
      expect(
        (await db
            .collection('attendance_records')
            .doc('s1_SE1001')
            .get())['status'],
        'Late',
      );
    });

    test('save từ chối điểm danh tay sau 23:59 của ngày học', () async {
      await putSession(db, 'old-session', '2026-10-20', 'closed');
      expect(
        failCode(
          await repo.save('PRN232_SE1917', 'old-session', [
            {
              'rollNumber': 'SE1001',
              'status': 'ManualByGV',
              'note': 'Bổ sung muộn',
              'revision': '',
            },
          ]),
        ),
        'MANUAL_ATTENDANCE_EXPIRED',
      );
      expect(
        await db
            .collection('attendance_records')
            .doc('old-session_SE1001')
            .get()
            .then((doc) => doc.exists),
        false,
      );
    });

    test('save kiểm tra dữ liệu đầu vào', () async {
      await twoClosedSessions();
      Future<String> code(List<Map<String, dynamic>> changes) async =>
          failCode(await repo.save('PRN232_SE1917', 's1', changes));
      expect(await code([]), 'VALIDATION_ERROR');
      expect(
        await code([
          {
            'rollNumber': 'SE9999',
            'status': 'Present',
            'note': '',
            'revision': '',
          },
        ]),
        'VALIDATION_ERROR',
      );
      expect(
        await code([
          {
            'rollNumber': 'SE1001',
            'status': 'Bogus',
            'note': '',
            'revision': '',
          },
        ]),
        'VALIDATION_ERROR',
      );
      expect(
        await code([
          {
            'rollNumber': 'SE1001',
            'status': 'Present',
            'note': 'x' * 2001,
            'revision': '',
          },
        ]),
        'VALIDATION_ERROR',
      );
      expect(
        await code([
          {
            'rollNumber': 'SE1001',
            'status': 'Present',
            'note': '',
            'revision': '',
          },
          {
            'rollNumber': 'SE1001',
            'status': 'Late',
            'note': '',
            'revision': '',
          },
        ]),
        'VALIDATION_ERROR',
      );
    });

    test('getMatrix có một ô cho mỗi (sinh viên, buổi)', () async {
      await twoClosedSessions();
      final m = ok(await repo.getMatrix('PRN232_SE1917'));
      expect(m.sessions.length, 2);
      expect(m.students.length, 3);
      expect(m.students.every((s) => s.cells.length == 2), true);
      final se1003 = m.students.firstWhere((s) => s.rollNumber == 'SE1003');
      expect(se1003.cells.map((c) => c.status), ['Absent', 'Absent']);
    });

    test('export tạo file .xlsx hợp lệ', () async {
      await twoClosedSessions();
      for (final sid in [null, 's1']) {
        final file = ok(await repo.export('PRN232_SE1917', sid));
        expect(file.filename, 'Attendance_PRN232_SE1917.xlsx');
        final zip = ZipDecoder().decodeBytes(base64Decode(file.base64));
        final sheet = zip.files.firstWhere(
          (f) => f.name == 'xl/worksheets/sheet1.xml',
        );
        final xml = utf8.decode(sheet.content as List<int>);
        expect(xml, contains('SE1001'));
        expect(xml, contains('Mã lớp'));
      }
    });

    test(
      'startSession từ chối khi lớp đang có phiên mở hoặc slot sai',
      () async {
        expect(
          failCode(await repo.startSession('PRN232_SE1917', 'ZZ', '')),
          'VALIDATION_ERROR',
        );
        ok(await repo.startSession('PRN232_SE1917', 'A1', ''));
        expect(
          failCode(await repo.startSession('PRN232_SE1917', 'A1', '')),
          'SESSION_ALREADY_OPEN',
        );
      },
    );
  });

  group('ReportRepository.buildReport', () {
    test('tổng hợp KPI, phương thức điểm danh, tuần và cảnh báo', () async {
      await putSession(db, 's1', '2026-10-05', 'closed');
      await putSession(db, 's2', '2026-10-14', 'closed');
      await putRecord(db, 's1', 'SE1001', 'Present', network: 'Match');
      await putRecord(db, 's1', 'SE1002', 'Late', network: 'Skipped');
      await putRecord(db, 's1', 'SE1003', 'ManualByGV', network: 'Manual');
      await putRecord(db, 's2', 'SE1001', 'Present', network: 'Match');
      // SE1002, SE1003 vắng buổi 2

      final tables = await TeacherTables.load(db, 'GV001');
      final report = ReportRepository.buildReport(tables, now: now);
      final kpis = report['kpis'] as Map;
      expect(kpis['totalCheckins'], 4);
      expect(kpis['absentCount'], 2);
      expect((report['subjects'] as List).single['presentCount'], 4);
      expect((report['subjects'] as List).single['expectedCount'], 6);
      expect(kpis['attendanceRate'], closeTo(4 / 6, 1e-9));
      expect(kpis['lateRate'], closeTo(1 / 6, 1e-9));
      expect(report['closedSessionCount'], 2);
      expect(report['classCount'], 1);
      expect(report['semester'], 'Fall 2026');

      final methods = {
        for (final m in report['methods'] as List) m['key']: m['count'],
      };
      expect(methods, {'qr': 3, 'other': 0, 'manual': 1});

      final weekly = report['weekly'] as List;
      expect(weekly.map((w) => w['label']), ['W1', 'W2']);
      expect(weekly[0]['presentRate'], closeTo(1, 1e-9));
      expect(weekly[1]['absentRate'], closeTo(2 / 3, 1e-9));

      final warnings = report['warnings'] as List;
      expect(warnings.map((w) => w['rollNumber']).toSet(), {
        'SE1002',
        'SE1003',
      });
      expect(warnings.first['absenceRate'], 0.5);
      expect(warnings.first['status'], 'Cần lưu ý');
      expect(kpis['atRiskCount'], 2);
    });

    test('không có dữ liệu → báo cáo rỗng hợp lệ', () async {
      final repo = ReportRepository(
        currentUser: teacher(),
        firestore: FakeFirebaseFirestore(),
        now: () => now,
      );
      final data = ok(await repo.getReport());
      expect(data.kpis.attendanceRate, 0);
      expect(data.classCount, 0);
    });
  });

  group('ScheduleRepository', () {
    late ScheduleRepository repo;
    setUp(() {
      repo = ScheduleRepository(
        currentUser: teacher(),
        firestore: db,
        now: () => now,
      );
    });

    Map<String, dynamic> input({
      String requestId = 'req-0001-abcd',
      String date = '2026-10-28',
    }) => {
      'requestId': requestId,
      'classCode': 'PRN232_SE1917',
      'scheduleDate': date,
      'slotCode': 'A1',
      'room': '303',
      'lessonType': 'makeup',
      'teachingMethod': 'onCampus',
      'note': 'Học bù',
    };

    test('options trả lớp, slot, phòng và lịch đã tạo', () async {
      final o = ok(await repo.options());
      expect(o['teacherName'], 'GV Một');
      expect(o['today'], '2026-10-21');
      expect((o['classes'] as List).single['studentCount'], 3);
      expect(o['rooms'], ['303']);
      expect((o['slots'] as List).single, {
        'slotCode': 'A1',
        'startTime': '07:00',
        'endTime': '09:15',
        'weekdays': [2, 5],
        'available': true,
      });
    });

    test('create ghi lịch, retry cùng requestId là idempotent', () async {
      final first = ok(await repo.create(input()));
      expect(first['status'], 'scheduled');
      expect(first['teacherMemberCode'], 'GV001');
      final again = ok(await repo.create(input()));
      expect(again['scheduleId'], first['scheduleId']);
      expect((await db.collection('class_schedules').get()).docs.length, 1);
      // cùng requestId nhưng nội dung khác → CONFLICT
      expect(
        failCode(await repo.create(input(date: '2026-10-29'))),
        'CONFLICT',
      );
    });

    test('create từ chối dữ liệu sai', () async {
      expect(
        failCode(await repo.create({...input(), 'classCode': 'SWD392_SE1801'})),
        'FORBIDDEN',
      );
      expect(
        failCode(await repo.create(input(requestId: 'ab'))),
        'VALIDATION_ERROR',
      );
      expect(
        failCode(await repo.create({...input(), 'slotCode': 'ZZ'})),
        'VALIDATION_ERROR',
      );
      expect(
        failCode(await repo.create({...input(), 'scheduleDate': '2026-02-30'})),
        'VALIDATION_ERROR',
      );
      expect(
        failCode(await repo.create({...input(), 'lessonType': 'party'})),
        'VALIDATION_ERROR',
      );
      expect(
        failCode(await repo.create({...input(), 'room': '999'})),
        'VALIDATION_ERROR',
      );
      expect(
        failCode(await repo.create({...input(), 'autoQR': true})),
        'NOT_SUPPORTED',
      );
      expect(
        failCode(await repo.create(input(date: '2026-10-21'))),
        'VALIDATION_ERROR',
      ); // ca đã bắt đầu
    });

    test('create phát hiện trùng khung giờ trong ngày', () async {
      ok(await repo.create(input()));
      expect(
        failCode(await repo.create(input(requestId: 'req-0002-abcd'))),
        'SCHEDULE_CONFLICT',
      );
    });

    test(
      'create từ chối trùng lịch chính khóa theo thứ và khung giờ',
      () async {
        // 22/10/2026 là Thứ Năm; slot A1 có weekdays [2, 5]
        // (Thứ Hai và Thứ Năm theo quy ước dữ liệu Firestore).
        expect(
          failCode(await repo.create(input(date: '2026-10-22'))),
          'SCHEDULE_CONFLICT',
        );
        expect((await db.collection('class_schedules').get()).docs, isEmpty);
      },
    );
  });
}
