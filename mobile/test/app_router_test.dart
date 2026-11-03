import 'package:flutter_test/flutter_test.dart';
import 'package:fapcheckin_core/models/auth_session_model.dart';
import 'package:fapcheckin_core/models/user_model.dart';
import 'package:fapcheckin_core/repositories/auth_repository.dart';
import 'package:fapcheckin_core/session/current_user.dart';
import 'package:fapcheckin/app/app_router.dart';
import 'package:fapcheckin/core/services/google_auth_service.dart';
import 'package:fapcheckin/viewmodels/auth_viewmodel.dart';

void main() {
  test('Router redirects unauthenticated user to login', () {
    final user = CurrentUser();
    final authVm = AuthViewModel(
      AuthRepository(currentUser: user),
      GoogleAuthService(),
      initialRestoring: false,
    );

    final router = createAppRouter(authVm);
    // Unauthenticated initial redirect from /loading to /login
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.loading);
  });

  test('Router keeps user on loading while isRestoringSession is true', () {
    final user = CurrentUser();
    final authVm = AuthViewModel(
      AuthRepository(currentUser: user),
      GoogleAuthService(),
      initialRestoring: true,
    );

    final router = createAppRouter(authVm);
    expect(authVm.isRestoringSession, isTrue);
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.loading);
  });

  test('Router redirects to loading when authenticated on login', () {
    final user = CurrentUser();
    final authVm = AuthViewModel(
      AuthRepository(currentUser: user),
      GoogleAuthService(),
      initialRestoring: false,
    );

    authVm.setSessionForTesting(
      const AuthSessionModel(
        token: 'test_token',
        user: UserModel(
          email: 'teacher@fpt.edu.vn',
          fullName: 'Nguyen Van A',
          memberCode: 'GV001',
          rollNumber: 'GV001',
          role: 'staff',
        ),
      ),
    );

    final router = createAppRouter(authVm);
    expect(authVm.isAuthenticated, isTrue);
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.loading);
  });
}
