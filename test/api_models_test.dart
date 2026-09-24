import 'package:flutter_test/flutter_test.dart';
import 'package:fapcheckin/core/network/api_result.dart';
import 'package:fapcheckin/core/network/api_service.dart';
import 'package:fapcheckin/core/network/json_values.dart';
import 'package:fapcheckin/data/models/class_section_model.dart';
import 'package:fapcheckin/data/models/roster_entry_model.dart';
import 'package:fapcheckin/data/models/session_model.dart';
import 'package:fapcheckin/data/models/stats_entry_model.dart';
import 'package:fapcheckin/data/models/user_model.dart';
import 'package:fapcheckin/data/repositories/teacher_repository.dart';
import 'package:fapcheckin/viewmodels/dashboard_viewmodel.dart';
import 'package:fapcheckin/viewmodels/live_session_viewmodel.dart';

const sheetClass = <String, dynamic>{
  'classCode': 101,
  'teacherMemberCode': 7,
  'subjectName': 'Project',
  'room': 303,
  'studentCount': '30',
  'completedSessions': '2',
  'totalSessions': 30,
  'averageAttendance': '92.5',
  'isActive': 'TRUE',
  'activeSessionId': 10,
};

class SheetFixtureRepository extends TeacherRepository {
  SheetFixtureRepository() : super(ApiService());

  @override
  Future<ApiResult<List<ClassSectionModel>>> getClasses({
    required String teacherMemberCode,
  }) async {
    expect(teacherMemberCode, '7');
    return ApiSuccess([ClassSectionModel.fromJson(sheetClass)]);
  }
}

class SortFixtureRepository extends TeacherRepository {
  SortFixtureRepository() : super(ApiService());

  @override
  Future<ApiResult<List<ClassSectionModel>>> getClasses({
    required String teacherMemberCode,
  }) async {
    return ApiSuccess([
      ClassSectionModel.fromJson({
        ...sheetClass,
        'classCode': 'DONE',
        'isActive': false,
        'startTime': '00:00',
        'endTime': '00:01',
        'timeLabel': '00:00 - 00:01',
      }),
      ClassSectionModel.fromJson({
        ...sheetClass,
        'classCode': 'NEXT',
        'isActive': false,
        'timeLabel': '',
      }),
      ClassSectionModel.fromJson({
        ...sheetClass,
        'classCode': 'OVERNIGHT',
        'isActive': false,
        'startTime': '20:00',
        'endTime': '04:15',
        'timeLabel': '20:00 - 04:15',
      }),
      ClassSectionModel.fromJson({
        ...sheetClass,
        'classCode': 'ACTIVE',
        'isActive': true,
        'startTime': '08:00',
        'endTime': '10:00',
        'timeLabel': '08:00 - 10:00',
      }),
    ]);
  }
}

void main() {
  test('numeric room 303 and spreadsheet text numbers parse correctly', () {
    final model = ClassSectionModel.fromJson(sheetClass);
    expect(model.room, '303');
    expect(model.classCode, '101');
    expect(model.teacherMemberCode, '7');
    expect(model.studentCount, 30);
    expect(model.completedSessions, 2);
    expect(model.averageAttendance, 92.5);
    expect(model.isActive, true);
    expect(model.activeSessionId, '10');
    expect(ClassSectionModel.fromJson(model.toJson()).toJson(), model.toJson());
  });

  test('missing optional fields retain defaults and null session ID', () {
    final model = ClassSectionModel.fromJson({'room': 'A-303'});
    expect(model.room, 'A-303');
    expect(model.studentCount, 0);
    expect(model.activeSessionId, isNull);
    expect(model.isActive, false);
  });

  test(
    'dashboard loads class list instead of failing on numeric room',
    () async {
      final dashboard = DashboardViewModel(SheetFixtureRepository());
      addTearDown(dashboard.dispose);
      dashboard.setTeacherInfo(
        name: 'Teacher',
        email: 'teacher@example.test',
        memberCode: '7',
      );
      await dashboard.loadClasses();
      expect(dashboard.status, ViewStatus.success);
      expect(dashboard.errorMessage, isNull);
      expect(dashboard.classes.single.room, '303');
      expect(dashboard.totalClassesToday, 1);
      expect(dashboard.totalStudents, 30);
    },
  );

  test('dashboard prioritizes active, upcoming, then completed classes', () async {
    final dashboard = DashboardViewModel(
      SortFixtureRepository(),
      now: () => DateTime(2026, 9, 24, 12),
    );
    addTearDown(dashboard.dispose);
    dashboard.setTeacherInfo(
      name: 'Teacher',
      email: 'teacher@example.test',
      memberCode: '7',
    );

    await dashboard.loadClasses();

    expect(
      dashboard.classes.map((c) => c.classCode),
      ['ACTIVE', 'OVERNIGHT', 'NEXT', 'DONE'],
    );
  });

  test('session and roster accept numeric IDs and slot numbers', () {
    final session = SessionModel.fromJson({
      'session': {'sessionId': 10, 'classCode': 101, 'slotCode': 2},
      'qrToken': 'secret',
    });
    expect(session.sessionId, '10');
    expect(session.slotCode, '2');
    expect(session.qrToken, 'secret');
    final roster = RosterEntryModel.fromJson({
      'student': {'rollNumber': 123, 'memberCode': 8},
      'record': {'recordId': 20, 'sessionId': 10, 'status': 'Present'},
    });
    expect(roster.rollNumber, '123');
    expect(roster.recordId, '20');
    expect(roster.hasCheckedIn, true);
    expect(
      RosterEntryModel.fromJson({
        'student': <String, dynamic>{},
        'record': null,
      }).recordId,
      isNull,
    );
  });

  test('user and statistics preserve numeric IDs and text percentages', () {
    expect(UserModel.fromJson({'memberCode': 7}).memberCode, '7');
    final stats = StatsEntryModel.fromJson({
      'rollNumber': 123,
      'attendancePercentage': '92.5',
    });
    expect(stats.rollNumber, '123');
    expect(stats.attendancePercentage, 92.5);
  });

  test('roster displays sheet fullName instead of an email username', () {
    final roster = RosterEntryModel.fromJson({
      'student': {
        'rollNumber': 'TEST001',
        'fullName': 'Sinh viên kiểm thử',
        'email': 'unrelated-account@example.test',
      },
      'record': null,
    });
    expect(roster.fullName, 'Sinh viên kiểm thử');
    expect(roster.displayName, 'Sinh viên kiểm thử');
    expect(
      RosterEntryModel.fromJson({
        'student': {'rollNumber': 'TEST002', 'fullName': '  '},
      }).displayName,
      'TEST002',
    );
  });

  test('invalid structured values are rejected rather than shown as data', () {
    expect(() => jsonText({'room': 303}), throwsFormatException);
    expect(() => jsonNumber('unknown'), throwsFormatException);
    expect(() => jsonBool('unknown'), throwsFormatException);
    expect(jsonText('00123'), '00123');
    expect(jsonBool('FALSE'), false);
  });
}
