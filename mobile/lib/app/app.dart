import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import './app_router.dart';

import 'package:fapcheckin_core/repositories/account_features_repository.dart';
import 'package:fapcheckin_core/repositories/announcement_repository.dart';
import 'package:fapcheckin_core/theme/app_theme.dart';

import '../core/services/auto_session_manager.dart';
import '../core/services/google_auth_service.dart';
import '../core/services/push_notification_service.dart';
import '../core/services/remote_settings.dart';
import '../core/services/speech_service.dart';
import '../core/services/tts_service.dart';
import '../core/services/timetable_ocr_service.dart';

import 'package:fapcheckin_core/repositories/auth_repository.dart';
import 'package:fapcheckin_core/repositories/schedule_repository.dart';
import 'package:fapcheckin_core/repositories/timetable_repository.dart';
import 'package:fapcheckin_core/session/current_user.dart';
import 'package:fapcheckin_core/repositories/teacher_repository.dart';
import 'package:fapcheckin_core/repositories/attendance_history_repository.dart';
import 'package:fapcheckin_core/repositories/report_repository.dart';
import 'package:fapcheckin_core/repositories/ai_assistant_repository.dart';
import 'package:fapcheckin_core/ai/ai_tool_executor.dart';

import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../viewmodels/live_session_viewmodel.dart';
import '../viewmodels/attendance_history_viewmodel.dart';
import '../viewmodels/preferences_viewmodel.dart';
import '../viewmodels/report_viewmodel.dart';
import '../viewmodels/ai_chat_viewmodel.dart';

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
  late final AiChatViewModel _aiChatViewModel;
  late final GoRouter _router;
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();
  late final PushNotificationService _pushNotificationService;
  RemoteMessage? _pendingPushMessage;

  @override
  void initState() {
    super.initState();
    _currentUser = CurrentUser();
    _googleAuthService = GoogleAuthService();
    _authRepo = AuthRepository(currentUser: _currentUser);
    _teacherRepo = TeacherRepository(currentUser: _currentUser);
    _scheduleRepo = ScheduleRepository(currentUser: _currentUser);
    _timetableRepo = TimetableRepository(
      currentUser: _currentUser,
      recognizeText: TimetableOcrService().recognize,
    );
    _authViewModel = AuthViewModel(
      _authRepo,
      _googleAuthService,
      initialRestoring: true,
    );
    _accountFeaturesRepo = AccountFeaturesRepository(
      uid: () => _authViewModel.session?.token ?? '',
    );
    _preferencesViewModel = PreferencesViewModel(_accountFeaturesRepo);
    _authViewModel.beforeSignOut = _preferencesViewModel.unregisterDevice;
    _dashboardViewModel = DashboardViewModel(_teacherRepo);
    _liveSessionViewModel = LiveSessionViewModel(_teacherRepo)
      ..applyRemoteSettings(
        qrCycleSeconds: widget.remoteSettings.qrRefreshSeconds,
        ipCheckDefault: widget.remoteSettings.ipCheckDefault,
      );
    final historyRepo = AttendanceHistoryRepository(currentUser: _currentUser);
    final reportRepo = ReportRepository(currentUser: _currentUser);
    _attendanceHistoryViewModel = AttendanceHistoryViewModel(historyRepo);
    _reportViewModel = ReportViewModel(reportRepo);
    _aiChatViewModel = AiChatViewModel(
      repository: AiAssistantRepository(),
      executor: AiToolExecutor(
        teacher: _teacherRepo,
        history: historyRepo,
        report: reportRepo,
        currentUser: _currentUser,
      ),
      speech: DeviceSpeechService(),
      tts: DeviceTtsService(),
    );
    _autoSessionManager = AutoSessionManager(
      liveSessionViewModel: _liveSessionViewModel,
      dashboardViewModel: _dashboardViewModel,
      teacherRepository: _teacherRepo,
    );
    _authViewModel.addListener(_syncHistoryAccount);
    _liveSessionViewModel.addListener(_syncLiveSession);

    _router = createAppRouter(_authViewModel);
    _pushNotificationService = PushNotificationService(
      messengerKey: _messengerKey,
      onOpenMessage: _handlePushMessage,
    );
    unawaited(
      _pushNotificationService.start().catchError((Object error) {
        debugPrint('Push notification init error: $error');
      }),
    );
    // Firebase Auth giữ phiên trên thiết bị: nạp lại hồ sơ để khỏi đăng nhập lại.
    _authViewModel.restoreSession();

    // Nạp RemoteSettings ở background không làm nghẽn khởi động giao diện đầu tiên
    RemoteSettings.load()
        .then((settings) {
          if (mounted) {
            _liveSessionViewModel.applyRemoteSettings(
              qrCycleSeconds: (_systemSettings['qrRefreshRate'] as num?)?.toInt() ?? settings.qrRefreshSeconds,
              ipCheckDefault: _systemSettings['requireCampusIp'] as bool? ?? settings.ipCheckDefault,
            );
          }
        })
        .catchError((e) {
          debugPrint('RemoteSettings load error: $e');
        });
  }

  StreamSubscription<Map<String, dynamic>>? _systemSettingsSubscription;
  Map<String, dynamic> _systemSettings = {};
  AutoSessionManager? _autoSessionManager;
  String? _accountId;
  String? _liveSessionKey;

  void _handlePushMessage(RemoteMessage message) {
    if (!_authViewModel.isAuthenticated) {
      _pendingPushMessage = message;
      return;
    }

    final route = routeForPushMessage(message);
    _pendingPushMessage = null;
    _dashboardViewModel.navigate(route);
    _router.go('${AppRoutes.teacher}/$route');
  }

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
      if (_accountId != null) _attendanceHistoryViewModel.refreshSummary();
      _autoSessionManager?.checkRealtimeSessions();
    }
  }

  void _syncHistoryAccount() {
    final session = _authViewModel.session;
    if (_accountId != session?.token) {
      _accountId = session?.token;
      _systemSettingsSubscription?.cancel();
      _systemSettings = {};
      if (session != null) {
        final uid = session.token;
        _systemSettingsSubscription = _accountFeaturesRepo.systemSettings().listen((data) {
          if (!mounted || _accountId != uid) return;
          _systemSettings = data;
          _liveSessionViewModel.applyRemoteSettings(
            qrCycleSeconds: data['qrRefreshRate'] is num ? (data['qrRefreshRate'] as num).toInt() : null,
            ipCheckDefault: data['requireCampusIp'] is bool ? data['requireCampusIp'] as bool : null,
          );
        }, onError: (Object error) { debugPrint('Không cập nhật được cấu hình hệ thống: $error'); });
      }
      _dashboardViewModel.clearTeacherInfo();
      _liveSessionViewModel.resetSession();
      _reportViewModel.reset();
      _aiChatViewModel.reset();
    }
    if (session != null && session.user.isTeacher) {
      _dashboardViewModel.setTeacherInfo(
        name: session.user.fullName,
        email: session.user.email,
        memberCode: session.user.memberCode,
      );
      _autoSessionManager?.start();
    } else {
      _autoSessionManager?.stop();
    }
    _attendanceHistoryViewModel.bindAccount(
      session?.user.isTeacher == true ? session?.token : null,
    );
    _preferencesViewModel.bindAccount(_authViewModel.session?.token);
    final pendingMessage = _pendingPushMessage;
    if (session != null && pendingMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _handlePushMessage(pendingMessage);
      });
    }
  }

  @override
  void dispose() {
    _autoSessionManager?.stop();
    _systemSettingsSubscription?.cancel();
    _authViewModel.removeListener(_syncHistoryAccount);
    _liveSessionViewModel.removeListener(_syncLiveSession);
    _router.dispose();
    _authViewModel.dispose();
    _dashboardViewModel.dispose();
    _liveSessionViewModel.dispose();
    _attendanceHistoryViewModel.dispose();
    _preferencesViewModel.dispose();
    unawaited(_pushNotificationService.dispose());
    _reportViewModel.dispose();
    _aiChatViewModel.dispose();
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
        ChangeNotifierProvider.value(value: _aiChatViewModel),
      ],
      child: Consumer<PreferencesViewModel>(
        builder: (context, prefsVm, _) => MaterialApp.router(
          title: 'FAP Check-in',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: prefsVm.themeMode,
          scaffoldMessengerKey: _messengerKey,
          routerConfig: _router,
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(
                textScaler: mq.textScaler.clamp(
                  minScaleFactor: 0.9,
                  maxScaleFactor: 1.35,
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
