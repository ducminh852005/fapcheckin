import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin_core/repositories/teacher_repository.dart';
import 'package:fapcheckin_core/session/current_user.dart';
import 'package:fapcheckin/viewmodels/dashboard_viewmodel.dart';
import 'package:fapcheckin/views/teacher/dashboard/components/notification_modal.dart';

void main() {
  testWidgets('NotificationModal renders header, tabs, and notification cards', (
    tester,
  ) async {
    final teacherRepo = TeacherRepository(currentUser: CurrentUser());
    final dashboardVm = DashboardViewModel(teacherRepo);

    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<DashboardViewModel>.value(
          value: dashboardVm,
          child: const Scaffold(body: NotificationModal()),
        ),
      ),
    );

    // Verify Header
    expect(find.text('Thông báo'), findsOneWidget);
    expect(find.text('Cập nhật lúc 08:32 hôm nay'), findsOneWidget);
    expect(find.text('Đánh dấu đã đọc tất cả'), findsOneWidget);

    // Verify Tabs
    expect(find.text('Tất cả'), findsOneWidget);
    expect(find.text('Chưa đọc'), findsOneWidget);
    expect(find.text('Lịch dạy (2)'), findsOneWidget);
    expect(find.text('Chuyên cần (1)'), findsOneWidget);

    // Verify Notification Cards
    expect(find.text('Cảnh báo vắng sinh viên • PRN231'), findsOneWidget);
    expect(find.text('Sắp tới giờ giảng dạy • Ca 2 (08:45)'), findsOneWidget);
    expect(find.text('Đơn xin phép được duyệt • SWT301'), findsOneWidget);

    // Verify Buttons
    expect(find.text('Xem danh sách'), findsOneWidget);
    expect(find.text('Vào lớp ngay'), findsOneWidget);
    expect(find.text('Đóng thông báo'), findsOneWidget);

    // Test mark all as read
    await tester.tap(find.text('Đánh dấu đã đọc tất cả'));
    await tester.pumpAndSettle();
  });
}
