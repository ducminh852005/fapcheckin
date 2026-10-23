import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin_core/result/api_result.dart';
import 'package:fapcheckin_core/session/current_user.dart';
import 'package:fapcheckin_core/models/history_class.dart';
import 'package:fapcheckin_core/models/history_detail.dart';
import 'package:fapcheckin_core/models/history_summary.dart';
import 'package:fapcheckin_core/repositories/attendance_history_repository.dart';
import 'package:fapcheckin/viewmodels/attendance_history_viewmodel.dart';
import 'package:fapcheckin/views/teacher/attendance_history/attendance_history_body.dart';

Map<String, dynamic> classJson(String code) => {
  'classCode': code,
  'subjectCode': 'SWP391',
  'subjectName': 'Project',
  'room': 303,
  'studentCount': 2,
  'completedSessions': 1,
  'totalSessions': 2,
  'attendanceRate': .5,
  'lateRate': 0,
  'atRiskCount': 1,
};
HistorySummary summary(String code, {bool hasSessions = true}) =>
    HistorySummary.fromJson({
      'classInfo': classJson(code),
      'teacherName': 'Teacher',
      'slots': [
        {'slotCode': 'A1'},
      ],
      'sessions': hasSessions
          ? [
              {
                'sessionId': 'S1',
                'sessionDate': '2026-09-20',
                'slotCode': 'A1',
                'sessionStatus': 'closed',
              },
            ]
          : [],
      'students': [
        {
          'rollNumber': 'SE1',
          'fullName': 'Student One',
          'email': 'one@example.test',
          'presentCount': hasSessions ? 1 : 0,
          'lateCount': 0,
          'absentCount': 0,
          'closedSessions': hasSessions ? 1 : 0,
          'totalSessions': hasSessions ? 1 : 0,
        },
        {
          'rollNumber': 'SE2',
          'fullName': 'Student Two',
          'email': 'two@example.test',
          'presentCount': 0,
          'lateCount': 0,
          'absentCount': hasSessions ? 1 : 0,
          'closedSessions': hasSessions ? 1 : 0,
          'totalSessions': hasSessions ? 1 : 0,
        },
      ],
    });

HistoryDetail saveResult(String code) => HistoryDetail.fromJson({
  'classInfo': classJson(code),
  'teacherName': 'Teacher',
  'slots': [
    {'slotCode': 'A1'},
  ],
  'sessions': [
    {
      'sessionId': 'S1',
      'sessionDate': '2026-09-20',
      'slotCode': 'A1',
      'sessionStatus': 'closed',
    },
  ],
  'selectedSession': {
    'sessionId': 'S1',
    'sessionDate': '2026-09-20',
    'slotCode': 'A1',
    'sessionStatus': 'closed',
  },
  'students': [
    {
      'rollNumber': 'SE1',
      'fullName': 'Student One',
      'email': 'one@example.test',
      'status': 'Present',
      'absenceCount': 0,
      'totalSessions': 1,
      'revision': 'r1',
    },
    {
      'rollNumber': 'SE2',
      'fullName': 'Student Two',
      'email': 'two@example.test',
      'status': 'ManualByGV',
      'absenceCount': 0,
      'totalSessions': 1,
      'revision': 'r2',
    },
  ],
});

class FakeHistoryRepository extends AttendanceHistoryRepository {
  FakeHistoryRepository() : super(currentUser: CurrentUser());
  List<HistoryClass> classList = [
    HistoryClass.fromJson(classJson('C1')),
    HistoryClass.fromJson(classJson('C2')),
  ];
  bool fail = false, emptySessions = false;
  Map<String, Completer<ApiResult<HistorySummary>>> pending = {};
  List<Map<String, dynamic>>? savedChanges;
  @override
  Future<ApiResult<List<HistoryClass>>> getClasses() async => fail
      ? ApiFailure(ApiError(code: 'NETWORK_ERROR', message: 'Offline'))
      : ApiSuccess(classList);
  @override
  Future<ApiResult<HistorySummary>> getSummary(String classCode) =>
      pending[classCode]?.future ??
      Future.value(ApiSuccess(summary(classCode, hasSessions: !emptySessions)));
  @override
  Future<ApiResult<HistoryDetail>> save(
    String classCode,
    String sessionId,
    List<Map<String, dynamic>> changes,
  ) async {
    savedChanges = changes;
    return fail
        ? ApiFailure(ApiError(code: 'CONFLICT', message: 'Changed'))
        : ApiSuccess(saveResult(classCode));
  }

  @override
  Future<ApiResult<AttendanceMatrix>> getMatrix(String classCode) async =>
      ApiSuccess(
        AttendanceMatrix.fromJson({
          'sessions': [
            {
              'sessionId': 'S1',
              'sessionDate': '2026-09-20',
              'slotCode': 'A1',
              'sessionStatus': 'closed',
            },
          ],
          'students': [
            {
              'rollNumber': 'SE1',
              'fullName': 'Student One',
              'cells': [
                {
                  'sessionId': 'S1',
                  'status': 'Present',
                  'note': '',
                  'checkinTime': '',
                  'revision': 'r1',
                },
              ],
            },
            {
              'rollNumber': 'SE2',
              'fullName': 'Student Two',
              'cells': [
                {
                  'sessionId': 'S1',
                  'status': 'ManualByGV',
                  'note': 'Verified in class',
                  'checkinTime': '',
                  'revision': 'r2',
                },
              ],
            },
          ],
        }),
      );
}

void main() {
  test('loads server classes and class-wide summary; search and risk filter derive from roster', () async {
    final vm = AttendanceHistoryViewModel(FakeHistoryRepository());
    addTearDown(vm.dispose);
    await vm.loadClasses();
    expect(vm.classes.length, 2);
    expect(vm.selectedClassCode, 'C1');
    expect(vm.summary!.classInfo.room, '303');
    expect(vm.students.length, 2);
    vm.setRiskFilter('atRisk');
    expect(vm.filteredStudents.single.rollNumber, 'SE2');
    vm.setRiskFilter('all');
    vm.setSearch('ONE@');
    expect(vm.filteredStudents.single.rollNumber, 'SE1');
    vm.setClassSearch('C2');
    expect(vm.visibleClasses.single.classCode, 'C2');
  });
  test('empty data and API failure never create fake rows', () async {
    final repo = FakeHistoryRepository()..classList = [];
    final vm = AttendanceHistoryViewModel(repo);
    addTearDown(vm.dispose);
    await vm.loadClasses();
    expect(vm.students, isEmpty);
    expect(vm.summary, isNull);
    repo.fail = true;
    await vm.loadClasses();
    expect(vm.errorMessage, 'Offline');
    expect(vm.loadingClasses, false);
  });
  test(
    'late responses from another class cannot overwrite the selected class',
    () async {
      final repo = FakeHistoryRepository();
      repo.pending['C1'] = Completer();
      repo.pending['C2'] = Completer();
      final vm = AttendanceHistoryViewModel(repo);
      addTearDown(vm.dispose);
      final old = vm.selectClass('C1');
      final next = vm.selectClass('C2');
      repo.pending['C2']!.complete(ApiSuccess(summary('C2')));
      await next;
      repo.pending['C1']!.complete(ApiSuccess(summary('C1')));
      await old;
      expect(vm.selectedClassCode, 'C2');
      expect(vm.summary!.classInfo.classCode, 'C2');
    },
  );
  test('account change clears data and ignores in-flight response', () async {
    final repo = FakeHistoryRepository();
    repo.pending['C1'] = Completer();
    final vm = AttendanceHistoryViewModel(repo);
    addTearDown(vm.dispose);
    vm.bindAccount('teacher1');
    final pending = vm.selectClass('C1');
    vm.bindAccount('teacher2');
    repo.pending['C1']!.complete(ApiSuccess(summary('C1')));
    await pending;
    expect(vm.summary, isNull);
    expect(vm.students, isEmpty);
    expect(vm.loadingSummary, false);
  });
  test('empty-session class shows enrolled students as zero-attendance, not fabricated absences', () async {
    final repo = FakeHistoryRepository()..emptySessions = true;
    final vm = AttendanceHistoryViewModel(repo);
    addTearDown(vm.dispose);
    await vm.loadClasses();
    expect(vm.students.length, 2);
    expect(vm.students.first.absenceRate, 0);
    expect(vm.students.first.closedSessions, 0);
  });
  test('saving a matrix cell refreshes both the summary and the matrix; a failed save leaves them untouched', () async {
    final repo = FakeHistoryRepository();
    final vm = AttendanceHistoryViewModel(repo);
    addTearDown(vm.dispose);
    await vm.loadClasses();
    repo.fail = true;
    final failed = await vm.saveMatrixCell(
      sessionId: 'S1',
      rollNumber: 'SE2',
      status: 'ManualByGV',
      note: 'Verified in class',
      revision: 'r2',
    );
    expect(failed, isNull);
    expect(vm.errorMessage, 'Changed');
    repo.fail = false;
    final matrix = await vm.saveMatrixCell(
      sessionId: 'S1',
      rollNumber: 'SE2',
      status: 'ManualByGV',
      note: 'Verified in class',
      revision: 'r2',
    );
    expect(matrix, isNotNull);
    expect(repo.savedChanges!.single['revision'], 'r2');
    expect(repo.savedChanges!.single['note'], 'Verified in class');
  });
  testWidgets(
    'history screen displays server roster and no-session state without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = FakeHistoryRepository()..emptySessions = true;
      final vm = AttendanceHistoryViewModel(repo);
      addTearDown(vm.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: vm,
          child: const MaterialApp(
            home: Scaffold(body: AttendanceHistoryBody()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Student One'), findsOneWidget);
      expect(find.textContaining('Lớp chưa có phiên'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
