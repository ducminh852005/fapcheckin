import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import './app_router.dart';
import 'package:fapcheckin_core/theme/app_theme.dart';
import '../core/services/google_auth_service.dart';
import '../core/services/remote_settings.dart';
import 'package:fapcheckin_core/repositories/auth_repository.dart';
import 'package:fapcheckin_core/repositories/schedule_repository.dart';
import 'package:fapcheckin_core/repositories/timetable_repository.dart';
import 'package:fapcheckin_core/session/current_user.dart';
import 'package:fapcheckin_core/repositories/teacher_repository.dart';
import 'package:fapcheckin_core/repositories/attendance_history_repository.dart';
import 'package:fapcheckin_core/repositories/report_repository.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../viewmodels/live_session_viewmodel.dart';
import '../viewmodels/attendance_history_viewmodel.dart';
import '../viewmodels/report_viewmodel.dart';

class FapCheckinApp extends StatefulWidget {
  const FapCheckinApp({super.key, this.remoteSettings = const RemoteSettings()});

  /// Tham số lấy từ Firebase Remote Config lúc khởi động.
  final RemoteSettings remoteSettings;

  @override
  State<FapCheckinApp> createState() => _FapCheckinAppState();
}

class _FapCheckinAppState extends State<FapCheckinApp> {
  late final CurrentUser _currentUser;
  late final GoogleAuthService _googleAuthService;
  late final AuthRepository _authRepo;
  late final TeacherRepository _teacherRepo;
  late final ScheduleRepository _scheduleRepo;
  late final TimetableRepository _timetableRepo;
  late final AuthViewModel _authViewModel;
  late final DashboardViewModel _dashboardViewModel;
  late final LiveSessionViewModel _liveSessionViewModel;
  late final AttendanceHistoryViewModel _attendanceHistoryViewModel;
  late final ReportViewModel _reportViewModel;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _currentUser = CurrentUser();
    _googleAuthService = GoogleAuthService();
    _authRepo = AuthRepository(currentUser: _currentUser);
    _teacherRepo = TeacherRepository(currentUser: _currentUser);
    _scheduleRepo = ScheduleRepository(currentUser: _currentUser);
    _timetableRepo = TimetableRepository(currentUser: _currentUser);
    _authViewModel = AuthViewModel(_authRepo, _googleAuthService);
    _dashboardViewModel = DashboardViewModel(_teacherRepo);
    _liveSessionViewModel = LiveSessionViewModel(_teacherRepo)
      ..applyRemoteSettings(
        qrCycleSeconds: widget.remoteSettings.qrRefreshSeconds,
        ipCheckDefault: widget.remoteSettings.ipCheckDefault,
      );
    _attendanceHistoryViewModel = AttendanceHistoryViewModel(
      AttendanceHistoryRepository(currentUser: _currentUser),
    );
    _reportViewModel = ReportViewModel(ReportRepository(currentUser: _currentUser));
    _authViewModel.addListener(_syncHistoryAccount);

    _router = createAppRouter(_authViewModel);
    // Firebase Auth giữ phiên trên thiết bị: nạp lại hồ sơ để khỏi đăng nhập lại.
    _authViewModel.restoreSession();
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
    _reportViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: _scheduleRepo),
        Provider.value(value: _timetableRepo),
        ChangeNotifierProvider.value(value: _authViewModel),
        ChangeNotifierProvider.value(value: _dashboardViewModel),
        ChangeNotifierProvider.value(value: _liveSessionViewModel),
        ChangeNotifierProvider.value(value: _attendanceHistoryViewModel),
        ChangeNotifierProvider.value(value: _reportViewModel),
      ],
      child: MaterialApp.router(
        title: 'FAP Check-in',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(
              textScaler: mq.textScaler.clamp(
                minScaleFactor: 0.9,
                maxScaleFactor: 1.2,
              ),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
