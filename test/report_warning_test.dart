import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin/core/network/api_response.dart';
import 'package:fapcheckin/core/network/api_result.dart';
import 'package:fapcheckin/core/network/api_service.dart';
import 'package:fapcheckin/core/services/google_auth_service.dart';
import 'package:fapcheckin/data/models/auth_session_model.dart';
import 'package:fapcheckin/data/repositories/auth_repository.dart';
import 'package:fapcheckin/viewmodels/auth_viewmodel.dart';
import 'package:fapcheckin/data/models/report_model.dart';
import 'package:fapcheckin/views/teacher/report/components/warning_table.dart';

class ReportApi extends ApiService {
  bool fail = false;
  @override
  Future<ApiResult<T>> postAction<T>(
    String action, {
    Map<String, dynamic>? payload,
    T Function(dynamic)? fromJsonT,
  }) async {
    if (fail) {
      return ApiFailure(
        ApiError(code: 'NETWORK_ERROR', message: 'Sheet unavailable'),
      );
    }
    final dynamic data;
    if (action == 'getHistoryClasses') {
      data = [
        {'classCode': 'REAL_CLASS'},
      ];
    } else {
      expect(action, 'getHistoryDetail');
      expect(payload?['classCode'], 'REAL_CLASS');
      data = {
        'classInfo': {'classCode': 'REAL_CLASS'},
        'sessions': [],
        'slots': [],
        'students': [
          {
            'rollNumber': 'TEST001',
            'fullName': 'Student from API',
            'absenceCount': 3,
            'totalSessions': 10,
          },
          {
            'rollNumber': 'TEST002',
            'fullName': 'Below threshold',
            'absenceCount': 1,
            'totalSessions': 10,
          },
          {
            'rollNumber': 'TEST003',
            'fullName': 'No sessions yet',
            'absenceCount': 0,
            'totalSessions': 0,
          },
        ],
      };
    }
    return ApiSuccess(fromJsonT!(data));
  }
}

class ReportAuth extends AuthViewModel {
  ReportAuth(ApiService api) : super(AuthRepository(api), GoogleAuthService());
  @override
  AuthSessionModel get session => AuthSessionModel.fromJson({
    'token': 'test-token',
    'user': {'memberCode': 'TEACHER', 'role': 'GV'},
  });
}

void main() {
  testWidgets(
    'warning table uses API roster and shows errors without demo fallback',
    (tester) async {
      final api = ReportApi();
      final auth = ReportAuth(api);
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiService>.value(value: api),
            ChangeNotifierProvider<AuthViewModel>.value(value: auth),
          ],
          child: MaterialApp(
            home: Scaffold(body: WarningTable(data: ReportData.fromJson({}))),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Student from API'), findsOneWidget);
      expect(find.text('REAL_CLASS'), findsOneWidget);
      expect(find.text('Below threshold'), findsNothing);
      expect(find.text('No sessions yet'), findsNothing);
      expect(find.text('Vượt 20%'), findsOneWidget);
      expect(tester.takeException(), isNull);

      api.fail = true;
      await tester.tap(find.byTooltip('Tải lại từ Google Sheet'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Sheet unavailable'), findsOneWidget);
      expect(find.text('Student from API'), findsNothing);
      expect(find.text('Thử lại'), findsOneWidget);
    },
  );
}
