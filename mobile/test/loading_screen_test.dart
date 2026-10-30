import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin_core/models/auth_session_model.dart';
import 'package:fapcheckin_core/models/user_model.dart';
import 'package:fapcheckin_core/repositories/auth_repository.dart';
import 'package:fapcheckin_core/repositories/teacher_repository.dart';
import 'package:fapcheckin_core/session/current_user.dart';
import 'package:fapcheckin/core/services/google_auth_service.dart';
import 'package:fapcheckin/viewmodels/auth_viewmodel.dart';
import 'package:fapcheckin/viewmodels/dashboard_viewmodel.dart';
import 'package:fapcheckin/views/auth/widgets/login_brand.dart';
import 'package:fapcheckin/views/loading/loading_screen.dart';

void main() {
  testWidgets('LoadingScreen renders synchronized LoginBrandCard logo and navigates to teacher when authenticated', (
    tester,
  ) async {
    final user = CurrentUser();
    final authVm = AuthViewModel(
      AuthRepository(currentUser: user),
      GoogleAuthService(),
    );
    authVm.setSessionForTesting(
      const AuthSessionModel(
        token: 'test_token',
        user: UserModel(
          email: 'teacher@fpt.edu.vn',
          fullName: 'Nguyen Van A',
          memberCode: 'GV001',
          rollNumber: 'GV001',
          role: 'teacher',
        ),
      ),
    );
    final dashboardVm = DashboardViewModel(TeacherRepository(currentUser: user));

    final router = GoRouter(
      initialLocation: '/loading',
      routes: [
        GoRoute(
          path: '/loading',
          builder: (context, state) => const LoadingScreen(
            minDuration: Duration(milliseconds: 100),
          ),
        ),
        GoRoute(
          path: '/teacher',
          builder: (context, state) => const Scaffold(body: Text('Teacher Screen')),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const Scaffold(body: Text('Login Screen')),
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authVm),
          ChangeNotifierProvider.value(value: dashboardVm),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    // Verify brand card and logo badge exist on LoadingScreen
    expect(find.byType(LoginBrandCard), findsOneWidget);
    expect(find.byType(FapCheckinLogoBadge), findsOneWidget);
    expect(find.text('FAP Check-in'), findsOneWidget);
    expect(find.text('Quick & Easy Attendance'), findsOneWidget);
    expect(find.text('Đang khởi động ứng dụng...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Let initialization finish and navigate to teacher
    await tester.pumpAndSettle();
    expect(find.text('Teacher Screen'), findsOneWidget);
  });

  testWidgets('LoadingScreen navigates to login when unauthenticated', (
    tester,
  ) async {
    final user = CurrentUser();
    final authVm = AuthViewModel(
      AuthRepository(currentUser: user),
      GoogleAuthService(),
    );
    final dashboardVm = DashboardViewModel(TeacherRepository(currentUser: user));

    final router = GoRouter(
      initialLocation: '/loading',
      routes: [
        GoRoute(
          path: '/loading',
          builder: (context, state) => const LoadingScreen(
            minDuration: Duration(milliseconds: 100),
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const Scaffold(body: Text('Login Screen')),
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authVm),
          ChangeNotifierProvider.value(value: dashboardVm),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Login Screen'), findsOneWidget);
  });
}
