import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import './app_router.dart';

import 'package:fapcheckin_core/repositories/account_features_repository.dart';
import 'package:fapcheckin_core/repositories/announcement_repository.dart';
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
import '../viewmodels/preferences_viewmodel.dart';
import '../viewmodels/report_viewmodel.dart';

class FapCheckinApp extends StatefulWidget {
  const FapCheckinApp({
    super.key,
    this.remoteSettings = const RemoteSettings(),
  });

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
  late final AccountFeaturesRepository _accountFeaturesRepo;
  late final PreferencesViewModel _preferencesViewModel;
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
    _authViewModel = AuthViewModel(
      _authRepo,
      _googleAuthService,
      initialRestoring: true,
    );
    _accountFeaturesRepo = AccountFeaturesRepository(
      uid: () => _authViewModel.session?.token ?? '',
    );
    _preferencesViewModel = PreferencesViewModel(_accountFeaturesRepo);
    _dashboardViewModel = DashboardViewModel(_teacherRepo);
    _liveSessionViewModel = LiveSessionViewModel(_teacherRepo)
      ..applyRemoteSettings(
        qrCycleSeconds: widget.remoteSettings.qrRefreshSeconds,
        ipCheckDefault: widget.remoteSettings.ipCheckDefault,
      );
    _attendanceHistoryViewModel = AttendanceHistoryViewModel(
      AttendanceHistoryRepository(currentUser: _currentUser),
    );
    _reportViewModel = ReportViewModel(
      ReportRepository(currentUser: _currentUser),
    );
    _authViewModel.addListener(_syncHistoryAccount);
    _liveSessionViewModel.addListener(_syncLiveSession);

    _router = createAppRouter(_authViewModel);
    // Firebase Auth giữ phiên trên thiết bị: nạp lại hồ sơ để khỏi đăng nhập lại.
    _authViewModel.restoreSession();

    // Nạp RemoteSettings ở background không làm nghẽn khởi động giao diện đầu tiên
    RemoteSettings.load()
        .then((settings) {
          if (mounted) {
            _liveSessionViewModel.applyRemoteSettings(
              qrCycleSeconds: settings.qrRefreshSeconds,
              ipCheckDefault: settings.ipCheckDefault,
            );
          }
        })
        .catchError((e) {
          debugPrint('RemoteSettings load error: $e');
        });
  }

  String? _accountId;
  String? _liveSessionKey;
  void _syncLiveSession() {
    final vm = _liveSessionViewModel;
    _dashboardViewModel.updateActiveSession(
      course: vm.courseName,
      group: vm.courseCode,
      room: vm.room,
      scanned: vm.checkedInCount,
      total: vm.totalStudents,
      present: vm.checkedInCount,
    );
    final key = '${vm.sessionId}:${vm.session?.sessionStatus}';
    if (_liveSessionKey != key) {
      _liveSessionKey = key;
      if (_accountId != null) _dashboardViewModel.loadClasses();
    }
  }

  void _syncHistoryAccount() {
    final session = _authViewModel.session;
    if (_accountId != session?.token) {
      _accountId = session?.token;
      _dashboardViewModel.clearTeacherInfo();
      _liveSessionViewModel.resetSession();
      _reportViewModel.reset();
    }
    if (session != null) {
      _dashboardViewModel.setTeacherInfo(
        name: session.user.fullName,
        email: session.user.email,
        memberCode: session.user.memberCode,
      );
    }
    _attendanceHistoryViewModel.bindAccount(_authViewModel.session?.token);
    _preferencesViewModel.bindAccount(_authViewModel.session?.token);
  }

  @override
  void dispose() {
    _authViewModel.removeListener(_syncHistoryAccount);
    _liveSessionViewModel.removeListener(_syncLiveSession);
    _router.dispose();
    _authViewModel.dispose();
    _dashboardViewModel.dispose();
    _liveSessionViewModel.dispose();
    _attendanceHistoryViewModel.dispose();
    _preferencesViewModel.dispose();
    _reportViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(
          create: (_) => AnnouncementRepository(currentUser: _currentUser),
        ),
        Provider.value(value: _accountFeaturesRepo),
        Provider.value(value: _scheduleRepo),
        Provider.value(value: _timetableRepo),
        ChangeNotifierProvider.value(value: _authViewModel),
        ChangeNotifierProvider.value(value: _dashboardViewModel),
        ChangeNotifierProvider.value(value: _liveSessionViewModel),
        ChangeNotifierProvider.value(value: _attendanceHistoryViewModel),
        ChangeNotifierProvider.value(value: _preferencesViewModel),
        ChangeNotifierProvider.value(value: _reportViewModel),
      ],
      child: Consumer<PreferencesViewModel>(
        builder: (context, prefsVm, _) => MaterialApp.router(
          title: 'FAP Check-in',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          themeMode: prefsVm.themeMode,
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
      ),
    );
  }
}
