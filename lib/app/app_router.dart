import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../viewmodels/auth_viewmodel.dart';
import '../views/auth/login_screen.dart';
import '../views/main_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String teacher = '/teacher';
}

GoRouter createAppRouter(AuthViewModel authViewModel) {
  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: authViewModel,
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = authViewModel.isAuthenticated;
      if (!isLoggedIn && state.matchedLocation != AppRoutes.login) {
        return AppRoutes.login;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (_, __) =>
            authViewModel.isAuthenticated ? AppRoutes.teacher : AppRoutes.login,
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.teacher,
        name: 'teacher',
        builder: (context, state) => const MainScreen(),
      ),
    ],
  );
}
