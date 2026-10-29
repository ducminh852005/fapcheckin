import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../viewmodels/auth_viewmodel.dart';
import '../views/auth/login_screen.dart';
import '../views/loading/loading_screen.dart';
import '../views/main_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String loading = '/loading';
  static const String teacher = '/teacher';
}

GoRouter createAppRouter(AuthViewModel authViewModel) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: authViewModel,
    errorBuilder: (context, state) => const LoadingScreen(),
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = authViewModel.isAuthenticated;
      final isLoginRoute = state.matchedLocation == AppRoutes.login;

      if (!isLoggedIn && !isLoginRoute) {
        return AppRoutes.login;
      }

      if (isLoggedIn && isLoginRoute) {
        return AppRoutes.teacher;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (_, _) =>
            authViewModel.isAuthenticated ? AppRoutes.teacher : AppRoutes.login,
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.loading,
        name: 'loading',
        builder: (context, state) => const LoadingScreen(),
      ),
      GoRoute(
        path: AppRoutes.teacher,
        name: 'teacher',
        builder: (context, state) => const MainScreen(),
      ),
    ],
  );
}
