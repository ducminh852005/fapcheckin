import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin_core/repositories/teacher_repository.dart';
import 'package:fapcheckin_core/repositories/auth_repository.dart';
import 'package:fapcheckin_core/session/current_user.dart';
import 'package:fapcheckin/core/services/google_auth_service.dart';
import 'package:fapcheckin/viewmodels/auth_viewmodel.dart';
import 'package:fapcheckin/viewmodels/dashboard_viewmodel.dart';
import 'package:fapcheckin/viewmodels/live_session_viewmodel.dart';
import 'package:fapcheckin/views/teacher/dashboard/dashboard_body.dart';
import 'package:fapcheckin/views/teacher/dashboard/components/dashboard_header.dart';

void main() {
  testWidgets('DashboardBody shows floating toast when no classes are assigned, not above header', (
    tester,
  ) async {
    final user = CurrentUser();
    final authVm = AuthViewModel(
      AuthRepository(currentUser: user),
      GoogleAuthService(),
    );
    final teacherRepo = TeacherRepository(currentUser: user);
    final dashboardVm = DashboardViewModel(teacherRepo);
    final liveSessionVm = LiveSessionViewModel(teacherRepo);

    dashboardVm.setTeacherInfo(
      name: 'Lê Trần Anh Khoa',
      email: 'daocrisdevilgamer@gmail.com',
      memberCode: 'GV001',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authVm),
          ChangeNotifierProvider.value(value: dashboardVm),
          ChangeNotifierProvider.value(value: liveSessionVm),
        ],
        child: const MaterialApp(
          home: Scaffold(body: DashboardBody()),
        ),
      ),
    );

    // Let the post frame callback fire to display the toast/SnackBar
    await tester.pump();

    // Verify DashboardHeader exists and is present
    expect(find.byType(DashboardHeader), findsOneWidget);

    // Verify the static Text widget is NOT present above DashboardHeader
    // The only place where 'Chưa có lớp được phân công.' appears is inside the SnackBar
    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.text('Chưa có lớp được phân công.'),
      ),
      findsOneWidget,
    );

    // Verify Empty State card in UpcomingSessionsList is rendered
    expect(find.text('Chưa có lớp học được phân công'), findsOneWidget);
    expect(find.text('Mở Lịch dạy & Quét TKB'), findsOneWidget);

    // Verify WeeklyOverviewCards keeps 0.0% and navigates to lich-su-diem-danh on tap
    expect(find.text('Chuyên cần'), findsOneWidget);
    expect(find.text('0.0%'), findsOneWidget);
    await tester.tap(find.text('Lịch sử'));
    await tester.pump();
    expect(dashboardVm.currentRoute, 'lich-su-diem-danh');
  });
}
