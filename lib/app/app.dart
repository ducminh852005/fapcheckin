import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'app_router.dart';
import '../core/theme/app_theme.dart';
import '../core/network/api_service.dart';
import '../core/services/google_auth_service.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/teacher_repository.dart';
import '../data/repositories/attendance_history_repository.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../viewmodels/live_session_viewmodel.dart';
import '../viewmodels/attendance_history_viewmodel.dart';

class FapCheckinApp extends StatefulWidget {
  const FapCheckinApp({super.key});

  @override
  State<FapCheckinApp> createState() => _FapCheckinAppState();
}

class _FapCheckinAppState extends State<FapCheckinApp> {
  late final ApiService _apiService;
  late final GoogleAuthService _googleAuthService;
  late final AuthRepository _authRepo;
  late final TeacherRepository _teacherRepo;
  late final AuthViewModel _authViewModel;
  late final DashboardViewModel _dashboardViewModel;
  late final LiveSessionViewModel _liveSessionViewModel;
  late final AttendanceHistoryViewModel _attendanceHistoryViewModel;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _googleAuthService = GoogleAuthService();
    _authRepo = AuthRepository(_apiService);
    _teacherRepo = TeacherRepository(_apiService);
    _authViewModel = AuthViewModel(_authRepo, _googleAuthService);
    _dashboardViewModel = DashboardViewModel(_teacherRepo);
    _liveSessionViewModel = LiveSessionViewModel(_teacherRepo);
    _attendanceHistoryViewModel = AttendanceHistoryViewModel(
      AttendanceHistoryRepository(_apiService),
    );
    _authViewModel.addListener(_syncHistoryAccount);
    _router = createAppRouter(_authViewModel);
  }

  void _syncHistoryAccount() {
    _attendanceHistoryViewModel.bindAccount(_authViewModel.session?.token);
  }

  @override
  void dispose() {
    _authViewModel.removeListener(_syncHistoryAccount);
    _router.dispose();
    _authViewModel.dispose();
    _dashboardViewModel.dispose();
    _liveSessionViewModel.dispose();
    _attendanceHistoryViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authViewModel),
        ChangeNotifierProvider.value(value: _dashboardViewModel),
        ChangeNotifierProvider.value(value: _liveSessionViewModel),
        ChangeNotifierProvider.value(value: _attendanceHistoryViewModel),
      ],
      child: MaterialApp.router(
        title: 'FAP Check-in',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
