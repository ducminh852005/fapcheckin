import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin_core/models/auth_session_model.dart';
import 'package:fapcheckin_core/models/user_model.dart';
import 'package:fapcheckin_core/repositories/auth_repository.dart';
import 'package:fapcheckin_core/repositories/request_repository.dart';
import 'package:fapcheckin_core/result/api_result.dart';
import 'package:fapcheckin_core/session/current_user.dart';
import 'package:fapcheckin/core/services/google_auth_service.dart';
import 'package:fapcheckin/viewmodels/auth_viewmodel.dart';
import 'package:fapcheckin/views/teacher/requests/requests_body.dart';

const _session = AuthSessionModel(token: 'student', user: UserModel(
  memberCode: 'S1', fullName: 'Student', role: 'user', rollNumber: 'S1', email: 'student@example.com'));
class _AuthRepository extends AuthRepository {
  _AuthRepository() : super(currentUser: CurrentUser());
  @override
  Future<ApiResult<AuthSessionModel?>> restoreSession() async => ApiSuccess(_session);
}
class _Requests extends RequestRepository {
  _Requests() : super(uid: 'student', memberCode: 'S1');
  final changes = StreamController<List<Map<String, dynamic>>>.broadcast();
  Map<String, dynamic>? submitted;
  @override
  Stream<List<Map<String, dynamic>>> watchMine() async* { yield submitted == null ? [] : [submitted!]; yield* changes.stream; }
  @override
  Future<ApiResult<List<Map<String, dynamic>>>> classOptions() async => ApiSuccess([{'classCode': 'C1'}]);
  @override
  Future<ApiResult<void>> submit({required String id, required String type, required String reason,
    required String classCode, String? sessionId, String? mainReason, String? slot, String? date, String? room, List<String>? attachments}) async {
    submitted = {'id': id, 'type': type, 'reason': reason, 'classCode': classCode, 'sessionId': sessionId, 'status': 'pending'};
    changes.add([submitted!]);
    return ApiSuccess(null);
  }
}

void main() {
  test('TC08: student session is restored instead of signed out', () async {
    final auth = AuthViewModel(_AuthRepository(), GoogleAuthService());
    await auth.restoreSession();
    expect(auth.session?.user.role, 'user');
    expect(auth.isAuthenticated, isTrue);
    auth.dispose();
  });
  testWidgets('TC08: submit request and display subsequent approval/rejection from stream', (tester) async {
    final repo = _Requests();
    final auth = AuthViewModel(_AuthRepository(), GoogleAuthService())..setSessionForTesting(_session);
    await tester.pumpWidget(ChangeNotifierProvider.value(value: auth,
      child: MaterialApp(home: RequestsBody(repository: repo))));
    await tester.pumpAndSettle();
    expect(find.text('Bạn chưa gửi yêu cầu nào.'), findsOneWidget);
    await tester.tap(find.text('Gửi yêu cầu'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'SESSION1');
    await tester.enterText(fields.at(2), 'Xin nghỉ buổi học');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Gửi yêu cầu'));
    await tester.pumpAndSettle();
    expect(repo.submitted?['type'], 'leave');
    expect(repo.submitted?['sessionId'], 'SESSION1');
    Navigator.of(tester.element(find.byType(RequestsBody))).pop();
    await tester.pumpAndSettle();
    expect(find.textContaining('Chờ duyệt'), findsOneWidget);
    repo.changes.add([{...repo.submitted!, 'status': 'approved', 'adminNote': 'Đã xác minh'}]);
    await tester.pumpAndSettle();
    expect(find.textContaining('Đã duyệt'), findsOneWidget);
    expect(find.textContaining('Đã xác minh'), findsOneWidget);
    repo.changes.add([{...repo.submitted!, 'status': 'rejected', 'adminNote': 'Thiếu thông tin'}]);
    await tester.pumpAndSettle();
    expect(find.textContaining('Đã từ chối'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await repo.changes.close(); auth.dispose();
  });
}
