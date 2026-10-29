import 'package:fapcheckin_core/session/current_user.dart';
import 'package:fapcheckin_core/repositories/schedule_repository.dart';
import 'package:fapcheckin_core/responsive/breakpoints.dart';
import 'package:fapcheckin_core/responsive/responsive_dialog.dart';
import 'package:fapcheckin/core/services/google_auth_service.dart';
import 'package:fapcheckin_core/models/class_session.dart';
import 'package:fapcheckin_core/repositories/auth_repository.dart';
import 'package:fapcheckin_core/repositories/attendance_history_repository.dart';
import 'package:fapcheckin_core/repositories/report_repository.dart';
import 'package:fapcheckin_core/repositories/teacher_repository.dart';
import 'package:fapcheckin/viewmodels/attendance_history_viewmodel.dart';
import 'package:fapcheckin/viewmodels/auth_viewmodel.dart';
import 'package:fapcheckin/viewmodels/dashboard_viewmodel.dart';
import 'package:fapcheckin/viewmodels/live_session_viewmodel.dart';
import 'package:fapcheckin/viewmodels/report_viewmodel.dart';
import 'package:fapcheckin/views/main_screen.dart';
import 'package:fapcheckin/views/teacher/dashboard/components/class_card.dart';
import 'package:fapcheckin/views/teacher/dashboard/components/sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Fails with the full layout error text (e.g. RenderFlex overflow).
void _expectNoErrors(WidgetTester tester) {
  final errors = <Object>[];
  Object? e;
  while ((e = tester.takeException()) != null) {
    errors.add(e!);
  }
  expect(errors.map((e) => e.toString()).join('\n----\n'), isEmpty);
}

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpMainScreen(WidgetTester tester, Size size) async {
  _setSize(tester, size);
  // Chưa khởi tạo Firebase: mọi lời gọi repository trả ApiFailure (như khi mất mạng).
  final user = CurrentUser();
  final teacherRepo = TeacherRepository(currentUser: user);
  final auth = AuthViewModel(
    AuthRepository(currentUser: user),
    GoogleAuthService(),
  );
  final dashboard = DashboardViewModel(teacherRepo);
  final live = LiveSessionViewModel(teacherRepo);
  final history = AttendanceHistoryViewModel(
    AttendanceHistoryRepository(currentUser: user),
  );
  final report = ReportViewModel(ReportRepository(currentUser: user));

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider(create: (_) => ScheduleRepository(currentUser: user)),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: dashboard),
        ChangeNotifierProvider.value(value: live),
        ChangeNotifierProvider.value(value: history),
        ChangeNotifierProvider.value(value: report),
      ],
      child: const MaterialApp(home: MainScreen()),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _pumpWidth(WidgetTester tester, Size size, Widget child) async {
  _setSize(tester, size);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  group('breakpoints', () {
    test('screenSizeForWidth', () {
      expect(screenSizeForWidth(320), ScreenSize.mobile);
      expect(screenSizeForWidth(599), ScreenSize.mobile);
      expect(screenSizeForWidth(600), ScreenSize.tablet);
      expect(screenSizeForWidth(1023), ScreenSize.tablet);
      expect(screenSizeForWidth(1024), ScreenSize.desktop);
    });
  });

  group('MainScreen shell', () {
    testWidgets('phone: bottom NavigationBar, no sidebar', (tester) async {
      await _pumpMainScreen(tester, const Size(360, 800));
      expect(find.text('Trang chủ'), findsOneWidget);
      expect(find.byType(Sidebar), findsNothing);
      _expectNoErrors(tester);
    });

    testWidgets('desktop: sidebar, no NavigationBar', (tester) async {
      await _pumpMainScreen(tester, const Size(1280, 800));
      expect(find.byType(Sidebar), findsOneWidget);
      _expectNoErrors(tester);
    });

    for (final width in [320.0, 360.0, 412.0]) {
      for (final route in [
        'tong-quan',
        'lich-hoc',
        'lop-hoc',
        'bao-cao',
        'cai-dat',
        'thong-tin-ca-nhan',
        'thong-tin-cong-tac',
        'lich-su-diem-danh',
        'diem-danh-qr',
      ]) {
        testWidgets('${width}dp, $route: no layout errors', (tester) async {
          await _pumpMainScreen(tester, Size(width, 800));
          final ctx = tester.element(find.byType(MainScreen));
          ctx.read<DashboardViewModel>().navigate(route);
          await tester.pump(const Duration(milliseconds: 100));
          // Let the (offline) API calls fail and their zero-length timers fire.
          await tester.pump(const Duration(seconds: 1));
          _expectNoErrors(tester);
        });
      }
    }

    testWidgets('phone: switching tab updates route', (tester) async {
      await _pumpMainScreen(tester, const Size(360, 800));
      await tester.tap(find.text('Quản lý lớp'));
      await tester.pump(const Duration(milliseconds: 100));
      final ctx = tester.element(find.byType(MainScreen));
      expect(ctx.read<DashboardViewModel>().currentRoute, 'lop-hoc');
      _expectNoErrors(tester);
    });
  });

  group('ResponsiveDialogFrame', () {
    Future<void> open(WidgetTester tester, Size size) async {
      _setSize(tester, size);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const ResponsiveDialogFrame(
                    maxWidth: 800,
                    maxHeight: 600,
                    child: SizedBox.expand(key: Key('dialog-body')),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('phone: dialog fills the screen', (tester) async {
      await open(tester, const Size(360, 800));
      final size = tester.getSize(find.byKey(const Key('dialog-body')));
      expect(size.width, 360);
      expect(size.height, 800);
    });

    testWidgets('desktop: dialog capped to max size', (tester) async {
      await open(tester, const Size(1400, 1000));
      final size = tester.getSize(find.byKey(const Key('dialog-body')));
      expect(size.width, 800);
      expect(size.height, 600);
    });
  });

  group('ClassCard on small screens', () {
    for (final status in [
      SessionStatus.active,
      SessionStatus.ready,
      SessionStatus.notStarted,
      SessionStatus.completed,
    ]) {
      testWidgets('320dp wide, $status: no overflow', (tester) async {
        await _pumpWidth(
          tester,
          const Size(320, 640),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ClassCard(
              session: ClassSession(
                courseCode: 'PRN232_SE1917',
                courseName: 'Building Cross-Platform Back-End Application',
                slot: '1',
                timeRange: '07:30 - 09:50',
                room: 'Phòng 602 - Tòa Beta',
                studentCount: 35,
                status: status,
                scannedCount: 12,
                isMakeup: true,
              ),
              onStart: () {},
            ),
          ),
        );
        _expectNoErrors(tester);
      });
    }
  });
}
