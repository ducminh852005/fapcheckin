import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fapcheckin_core/ai/ai_tool_executor.dart';
import 'package:fapcheckin_core/repositories/ai_assistant_repository.dart';
import 'package:fapcheckin_core/repositories/attendance_history_repository.dart';
import 'package:fapcheckin_core/repositories/report_repository.dart';
import 'package:fapcheckin_core/repositories/teacher_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  late FakeFirebaseFirestore db;
  late AiToolExecutor ai;
  late TeacherRepository teacherRepo;
  // 2026-10-21 01:00 UTC = 08:00 giờ Việt Nam (trong slot A1, thứ Tư).
  final now = DateTime.utc(2026, 10, 21, 1);

  AiToolCall call(String name, [Map<String, dynamic> args = const {}]) =>
      AiToolCall(name: name, args: args);

  Future<Map<String, dynamic>> result(
    String name, [
    Map<String, dynamic> args = const {},
  ]) async {
    final out = await ai.run(call(name, args));
    expect(out.pending, isNull, reason: 'tool đọc không được tạo pending');
    return out.result!;
  }

  Future<String> openSession({String slot = 'A1'}) async {
    final id = db.collection('sessions').doc().id;
    await db.collection('sessions').doc(id).set({
      'classCode': 'PRN232_SE1917',
      'teacherMemberCode': 'GV001',
      'sessionDate': '2026-10-21',
      'slotCode': slot,
      'sessionStatus': 'open',
      'qrSecret': 'x' * 16,
      'ipCheck': false,
      'startsAt': Timestamp.fromDate(DateTime.utc(2026, 10, 21, 0)),
      'endsAt': Timestamp.fromDate(DateTime.utc(2026, 10, 21, 2, 15)),
      'createdAt': Timestamp.fromDate(now),
    });
    return id;
  }

  setUp(() async {
    db = await seededDb();
    final user = teacher();
    teacherRepo = TeacherRepository(
      currentUser: user,
      firestore: db,
      now: () => now,
    );
    ai = AiToolExecutor(
      teacher: teacherRepo,
      history: AttendanceHistoryRepository(
        currentUser: user,
        firestore: db,
        now: () => now,
      ),
      report: ReportRepository(currentUser: user, firestore: db, now: () => now),
      currentUser: user,
      now: () => now,
    );
  });

  group('tool đọc', () {
    test('list_my_classes chỉ trả lớp của giảng viên và báo phiên đang mở', () async {
      await openSession();
      final r = await result('list_my_classes');
      final classes = r['classes'] as List;
      expect(classes.map((c) => c['classCode']), ['PRN232_SE1917']);
      expect(classes.single['hasOpenSession'], isTrue);
      expect(r['today'], '2026-10-21');
    });

    test('find_student theo MSSV (không phân biệt hoa thường) và theo tên không dấu', () async {
      await db.collection('enrollments').doc('PRN232_SE1917_SE1001').update({
        'fullName': 'Nguyễn Văn Đức',
      });
      final byRoll = await result('find_student', {'query': 'se1001'});
      expect((byRoll['students'] as List).single['fullName'], 'Nguyễn Văn Đức');
      final byName = await result('find_student', {'query': 'nguyen van duc'});
      expect((byName['students'] as List).single['rollNumber'], 'SE1001');
      final none = await result('find_student', {'query': 'HE999999'});
      expect(none['count'], 0);
    });

    test('find_student không lộ sinh viên của lớp giảng viên khác', () async {
      final r = await result('find_student', {'query': 'SE2001'});
      expect(r['count'], 0);
      final forced = await result('find_student', {
        'query': 'SE2001',
        'classCode': 'SWD392_SE1801',
      });
      expect(forced['code'], 'FORBIDDEN');
    });

    test('get_session_attendance trả trạng thái từng SV của buổi hôm nay', () async {
      final sid = await openSession();
      await putRecord(db, sid, 'SE1001', 'Present');
      final r = await result('get_session_attendance', {
        'classCode': 'PRN232_SE1917',
      });
      expect((r['session'] as Map)['date'], '2026-10-21');
      final students = r['students'] as List;
      expect(students.firstWhere((s) => s['rollNumber'] == 'SE1001')['status'], 'Present');
      expect(r['total'], 3);
    });

    test('get_session_attendance báo lỗi khi lớp chưa có buổi nào', () async {
      final r = await result('get_session_attendance', {'classCode': 'PRN232_SE1917'});
      expect(r['code'], 'NO_SESSION');
    });

    test('get_attendance_stats sắp xếp từ chuyên cần thấp đến cao', () async {
      final sid = await openSession();
      await putRecord(db, sid, 'SE1001', 'Present');
      await putRecord(db, sid, 'SE1002', 'Absent');
      await db.collection('sessions').doc(sid).update({'sessionStatus': 'closed'});
      final r = await result('get_attendance_stats', {'classCode': 'PRN232_SE1917'});
      final rows = r['students'] as List;
      expect(rows.first['attendancePercent'], lessThanOrEqualTo(rows.last['attendancePercent']));
      expect(rows.firstWhere((s) => s['rollNumber'] == 'SE1001')['attendancePercent'], 100.0);
    });

    test('get_attendance_report trả KPI; ngày thiếu một đầu bị từ chối', () async {
      final sid = await openSession();
      await putRecord(db, sid, 'SE1001', 'Present');
      await db.collection('sessions').doc(sid).update({'sessionStatus': 'closed'});
      final r = await result('get_attendance_report');
      expect(r['kpis'], isA<Map>());
      expect(r['classCount'], 1);
      final bad = await result('get_attendance_report', {'from': '2026-10-01'});
      expect(bad['code'], 'VALIDATION_ERROR');
    });

    test('tool lạ trả lỗi thay vì ném', () async {
      final r = await result('drop_database');
      expect(r['code'], 'UNKNOWN_TOOL');
    });
  });

  group('mark_attendance', () {
    Map<String, dynamic> args(List<Map<String, String>> students, {String? slot}) => {
      'classCode': 'PRN232_SE1917',
      'slotCode': ?slot,
      'students': students,
    };

    test('tạo pending với họ tên thật + trạng thái cũ; chưa ghi gì cho đến khi confirm', () async {
      final sid = await openSession();
      await putRecord(db, sid, 'SE1002', 'Absent');
      final out = await ai.run(call('mark_attendance', args([
        {'rollNumber': 'se1001', 'status': 'ManualByGV'},
        {'rollNumber': 'SE1002', 'status': 'Late'},
      ], slot: 'A1')));
      final p = out.pending!;
      expect(p.sessionId, sid);
      expect(p.slotCode, 'A1');
      expect(p.students.map((s) => s.rollNumber), ['SE1001', 'SE1002']);
      expect(p.students.first.fullName, 'SV SE1001');
      expect(p.students.last.previousStatus, 'Absent');
      // chưa ghi
      expect((await db.collection('attendance_records').doc('${sid}_SE1001').get()).exists, isFalse);

      final done = await ai.confirm(p);
      expect(done['ok'], isTrue);
      expect(done['marked'], 2);
      final rec = await db.collection('attendance_records').doc('${sid}_SE1001').get();
      expect(rec.data()!['status'], 'ManualByGV');
      expect(rec.data()!['networkVerificationResult'], 'Manual');
      expect((await db.collection('attendance_records').doc('${sid}_SE1002').get()).data()!['status'], 'Late');
    });

    test('huỷ không ghi gì', () async {
      final sid = await openSession();
      final out = await ai.run(call('mark_attendance', args([
        {'rollNumber': 'SE1001', 'status': 'ManualByGV'},
      ])));
      expect(out.pending, isNotNull);
      expect(ai.cancelled()['cancelled'], isTrue);
      expect((await db.collection('attendance_records').doc('${sid}_SE1001').get()).exists, isFalse);
    });

    test('MSSV không thuộc lớp -> lỗi, không tạo pending', () async {
      await openSession();
      final out = await ai.run(call('mark_attendance', args([
        {'rollNumber': 'SE1001', 'status': 'ManualByGV'},
        {'rollNumber': 'SE2001', 'status': 'ManualByGV'}, // SV lớp GV khác
      ])));
      expect(out.pending, isNull);
      expect(out.result!['code'], 'STUDENT_NOT_ENROLLED');
      expect(out.result!['unknown'], ['SE2001']);
    });

    test('chưa có phiên hôm nay -> hướng dẫn mở phiên', () async {
      final out = await ai.run(call('mark_attendance', args([
        {'rollNumber': 'SE1001', 'status': 'ManualByGV'},
      ])));
      expect(out.pending, isNull);
      expect(out.result!['code'], 'NO_SESSION_TODAY');
      expect(out.result!['error'], contains('Quản lý lớp'));
    });

    test('phiên của ngày khác không được dùng để điểm danh', () async {
      final id = db.collection('sessions').doc().id;
      await db.collection('sessions').doc(id).set({
        'classCode': 'PRN232_SE1917',
        'teacherMemberCode': 'GV001',
        'sessionDate': '2026-10-20',
        'slotCode': 'A1',
        'sessionStatus': 'closed',
        'qrSecret': 'x' * 16,
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 10, 20, 1)),
      });
      final out = await ai.run(call('mark_attendance', args([
        {'rollNumber': 'SE1001', 'status': 'ManualByGV'},
      ])));
      expect(out.result!['code'], 'NO_SESSION_TODAY');
    });

    test('nhiều buổi hôm nay mà không nói slot -> hỏi lại', () async {
      await openSession(slot: 'A1');
      await openSession(slot: 'A2');
      final out = await ai.run(call('mark_attendance', args([
        {'rollNumber': 'SE1001', 'status': 'ManualByGV'},
      ])));
      expect(out.result!['code'], 'AMBIGUOUS_SESSION');
      expect(out.result!['slots'], containsAll(['A1', 'A2']));
    });

    test('trạng thái lạ / thiếu dữ liệu bị từ chối trước khi chạm DB', () async {
      await openSession();
      for (final bad in [
        args([{'rollNumber': 'SE1001', 'status': 'Hacked'}]),
        args([{'rollNumber': '', 'status': 'Present'}]),
        args([]),
        {'students': []},
      ]) {
        final out = await ai.run(call('mark_attendance', bad));
        expect(out.pending, isNull);
        expect(out.result!['code'], 'VALIDATION_ERROR');
      }
    });

    test('lớp của giảng viên khác -> FORBIDDEN', () async {
      final out = await ai.run(call('mark_attendance', {
        'classCode': 'SWD392_SE1801',
        'students': [{'rollNumber': 'SE2001', 'status': 'ManualByGV'}],
      }));
      expect(out.result!['code'], 'FORBIDDEN');
    });

    test('confirm khi phiên đã sang ngày khác -> MANUAL_ATTENDANCE_EXPIRED, không ghi', () async {
      final sid = await openSession();
      final out = await ai.run(call('mark_attendance', args([
        {'rollNumber': 'SE1001', 'status': 'ManualByGV'},
      ])));
      // GV để thẻ xác nhận treo qua nửa đêm giờ VN rồi mới bấm Xác nhận.
      final late = AiToolExecutor(
        teacher: TeacherRepository(
          currentUser: teacher(),
          firestore: db,
          now: () => DateTime.utc(2026, 10, 21, 18),
        ),
        history: AttendanceHistoryRepository(currentUser: teacher(), firestore: db),
        report: ReportRepository(currentUser: teacher(), firestore: db),
        currentUser: teacher(),
      );
      final done = await late.confirm(out.pending!);
      expect(done['code'], 'MANUAL_ATTENDANCE_EXPIRED');
      expect((await db.collection('attendance_records').doc('${sid}_SE1001').get()).exists, isFalse);
    });
  });

  test('AiTurn.fromJson đọc text và tool_calls', () {
    final t = AiTurn.fromJson({
      'type': 'tool_calls',
      'calls': [
        {'name': 'find_student', 'args': {'query': 'a'}, 'thoughtSignature': 's'},
      ],
    });
    expect(t.hasToolCalls, isTrue);
    expect(t.calls.single.toJson()['thoughtSignature'], 's');
    expect(AiTurn.fromJson({'type': 'text', 'text': 'hi'}).text, 'hi');
  });
}
