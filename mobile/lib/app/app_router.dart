import '../views/teacher/requests/requests_body.dart';

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
    initialLocation: AppRoutes.loading,
    redirect: (context, state) {
      // 1. Đang kiểm tra/khôi phục session khi bật app: giữ ở màn hình Loading
      if (authViewModel.isRestoringSession) {
        return state.matchedLocation == AppRoutes.loading
            ? null
            : AppRoutes.loading;
      }

      // 2. Chưa đăng nhập: chuyển về trang Login
      if (!authViewModel.isAuthenticated) {
        return state.matchedLocation == AppRoutes.login
            ? null
            : AppRoutes.login;
      }

      // 3. Đã có phiên đăng nhập: nếu đang ở Login thì qua Loading trước khi vào Teacher
      if (state.matchedLocation == AppRoutes.login) {
        return AppRoutes.loading;
      }

      return null;
    },
    refreshListenable: authViewModel,
    errorBuilder: (context, state) => const LoadingScreen(),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => AppRoutes.teacher),
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
        builder: (context, state) => authViewModel.session?.user.role == 'user'
            ? const RequestsBody()
            : MainScreen(initialRoute: state.uri.queryParameters['tab']),
        routes: [
          GoRoute(
            path: ':tab',
            builder: (context, state) =>
                authViewModel.session?.user.role == 'user'
                ? const RequestsBody()
                : MainScreen(initialRoute: state.pathParameters['tab']),
          ),
        ],
      ),
    ],
  );
}
