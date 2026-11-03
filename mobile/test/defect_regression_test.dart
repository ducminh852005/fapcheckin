import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin_core/models/class_section_model.dart';
import 'package:fapcheckin_core/models/session_model.dart';
import 'package:fapcheckin_core/models/roster_entry_model.dart';
import 'package:fapcheckin_core/repositories/teacher_repository.dart';
import 'package:fapcheckin_core/repositories/auth_repository.dart';
import 'package:fapcheckin_core/session/current_user.dart';
import 'package:fapcheckin_core/result/api_result.dart';
import 'package:fapcheckin/viewmodels/dashboard_viewmodel.dart';
import 'package:fapcheckin/viewmodels/live_session_viewmodel.dart';
import 'package:fapcheckin/viewmodels/auth_viewmodel.dart';
import 'package:fapcheckin/core/services/google_auth_service.dart';
import 'package:fapcheckin/views/teacher/dashboard/dashboard_body.dart';

class _Repository extends TeacherRepository {
  _Repository() : super(currentUser: CurrentUser());
  final sessions = StreamController<SessionModel?>.broadcast();
  bool offline = true;
  int calls = 0;
  @override
  Stream<SessionModel?> watchSession(String id) => sessions.stream;
  @override
  Future<ApiResult<List<RosterEntryModel>>> getRoster({
    required String sessionId,
  }) async => ApiSuccess([]);
  @override
  Future<ApiResult<List<ClassSectionModel>>> getClasses({
    required String teacherMemberCode,
  }) async {
    calls++;
    return offline
        ? ApiFailure(ApiError(code: 'unavailable', message: 'Mất kết nối mạng'))
        : ApiSuccess([]);
  }
}

void main() {
  test(
    'TC03: external close updates active session; reset cancels old listener',
    () async {
      final repo = _Repository();
      final vm = LiveSessionViewModel(repo);
      const session = SessionModel(
        sessionId: 'S1',
        classCode: 'C1',
        sessionDate: '2026-11-02',
        slotCode: '1',
        sessionStatus: 'open',
        qrToken: 'secret',
      );
      vm.adoptSession(
        session,
        ClassSectionModel.fromJson({'classCode': 'C1'}),
        '',
      );
      repo.sessions.add(session.copyWith(sessionStatus: 'closed'));
      await Future<void>.delayed(Duration.zero);
      expect(vm.isClosed, isTrue);
      vm.resetSession();
      repo.sessions.add(session);
      await Future<void>.delayed(Duration.zero);
      expect(vm.session, isNull);
      vm.dispose();
      await repo.sessions.close();
    },
  );

  testWidgets('TC09: offline never shows empty data; retry recovers', (
    tester,
  ) async {
    final repo = _Repository();
    final dashboard = DashboardViewModel(repo)
      ..setTeacherInfo(name: 'GV', email: '', memberCode: 'GV1');
    final live = LiveSessionViewModel(repo);
    final auth = AuthViewModel(
      AuthRepository(currentUser: CurrentUser()),
      GoogleAuthService(),
    );
    await dashboard.loadClasses();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: dashboard),
          ChangeNotifierProvider.value(value: live),
          ChangeNotifierProvider.value(value: auth),
        ],
        child: const MaterialApp(home: DashboardBody()),
      ),
    );
    expect(find.text('Mất kết nối mạng'), findsOneWidget);
    expect(find.text('Chưa có lớp được phân công.'), findsNothing);
    expect(find.text('Chưa có lớp học được phân công'), findsNothing);
    repo.offline = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(repo.calls, 2);
    expect(find.text('Mất kết nối mạng'), findsNothing);
    expect(find.text('Chưa có lớp được phân công.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    dashboard.dispose();
    live.dispose();
    auth.dispose();
    await repo.sessions.close();
  });
}
