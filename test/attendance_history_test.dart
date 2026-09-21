import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin/core/network/api_result.dart';
import 'package:fapcheckin/core/network/api_response.dart';
import 'package:fapcheckin/core/network/api_service.dart';
import 'package:fapcheckin/data/models/history_class.dart';
import 'package:fapcheckin/data/models/history_detail.dart';
import 'package:fapcheckin/data/repositories/attendance_history_repository.dart';
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
HistoryDetail detail(String code, {String? session = 'S1'}) =>
    HistoryDetail.fromJson({
      'classInfo': classJson(code),
      'teacherName': 'Teacher',
      'slots': [
        {'slotCode': 'A1'},
      ],
      'sessions': session == null
          ? []
          : [
              {
                'sessionId': session,
                'sessionDate': '2026-09-20',
                'slotCode': 'A1',
                'sessionStatus': 'closed',
              },
            ],
      'selectedSession': session == null
          ? null
          : {
              'sessionId': session,
              'sessionDate': '2026-09-20',
              'slotCode': 'A1',
              'sessionStatus': 'closed',
            },
      'students': [
        {
          'rollNumber': 'SE1',
          'fullName': 'Student One',
          'email': 'one@example.test',
          'status': session == null ? 'Unchecked' : 'Present',
          'absenceCount': 0,
          'totalSessions': session == null ? 0 : 1,
          'revision': 'r1',
        },
        {
          'rollNumber': 'SE2',
          'fullName': 'Student Two',
          'email': 'two@example.test',
          'status': session == null ? 'Unchecked' : 'Absent',
          'absenceCount': session == null ? 0 : 1,
          'totalSessions': session == null ? 0 : 1,
          'revision': 'r2',
        },
      ],
    });

class FakeHistoryRepository extends AttendanceHistoryRepository {
  FakeHistoryRepository() : super(ApiService());
  List<HistoryClass> classList = [
    HistoryClass.fromJson(classJson('C1')),
    HistoryClass.fromJson(classJson('C2')),
  ];
  bool fail = false, emptySessions = false;
  Map<String, Completer<ApiResult<HistoryDetail>>> pending = {};
  List<Map<String, dynamic>>? savedChanges;
  @override
  Future<ApiResult<List<HistoryClass>>> getClasses() async => fail
      ? ApiFailure(ApiError(code: 'NETWORK_ERROR', message: 'Offline'))
      : ApiSuccess(classList);
  @override
  Future<ApiResult<HistoryDetail>> getDetail(
    String classCode, {
    String? sessionId,
  }) =>
      pending[classCode]?.future ??
      Future.value(
        ApiSuccess(
          detail(classCode, session: emptySessions ? null : sessionId ?? 'S1'),
        ),
      );
  @override
  Future<ApiResult<HistoryDetail>> save(
    String classCode,
    String sessionId,
    List<Map<String, dynamic>> changes,
  ) async {
    savedChanges = changes;
    return fail
        ? ApiFailure(ApiError(code: 'CONFLICT', message: 'Changed'))
        : ApiSuccess(detail(classCode));
  }
}

void main() {
  test('loads server classes and real selected session; search and filters derive from roster', () async {
    final vm = AttendanceHistoryViewModel(FakeHistoryRepository());
    addTearDown(vm.dispose);
    await vm.loadClasses();
    expect(vm.classes.length, 2);
    expect(vm.selectedClassCode, 'C1');
    expect(vm.detail!.classInfo.room, '303');
    vm.setStatusFilter('Absent');
    expect(vm.filteredStudents.single.rollNumber, 'SE2');
    vm.setStatusFilter('all');
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
    expect(vm.detail, isNull);
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
      repo.pending['C2']!.complete(ApiSuccess(detail('C2')));
      await next;
      repo.pending['C1']!.complete(ApiSuccess(detail('C1')));
      await old;
      expect(vm.selectedClassCode, 'C2');
      expect(vm.detail!.classInfo.classCode, 'C2');
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
    repo.pending['C1']!.complete(ApiSuccess(detail('C1')));
    await pending;
    expect(vm.detail, isNull);
    expect(vm.students, isEmpty);
    expect(vm.loadingDetail, false);
  });
  test(
    'failed save keeps drafts and revision, successful save clears them',
    () async {
      final repo = FakeHistoryRepository();
      final vm = AttendanceHistoryViewModel(repo);
      addTearDown(vm.dispose);
      await vm.loadClasses();
      vm.edit(vm.students[1], 'ManualByGV', 'Verified in class');
      await vm.selectClass('C2');
      expect(vm.selectedClassCode, 'C1');
      repo.fail = true;
      expect(await vm.saveChanges(), false);
      expect(vm.hasChanges, true);
      expect(repo.savedChanges!.single['revision'], 'r2');
      expect(repo.savedChanges!.single['note'], 'Verified in class');
      repo.fail = false;
      expect(await vm.saveChanges(), true);
      expect(vm.hasChanges, false);
    },
  );
  test('no-session roster cannot be edited or saved', () async {
    final repo = FakeHistoryRepository()..emptySessions = true;
    final vm = AttendanceHistoryViewModel(repo);
    addTearDown(vm.dispose);
    await vm.loadClasses();
    expect(vm.students.length, 2);
    expect(vm.students.first.absenceRate, 0);
    vm.edit(vm.students.first, 'Present', '');
    expect(vm.hasChanges, false);
    expect(await vm.saveChanges(), false);
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
