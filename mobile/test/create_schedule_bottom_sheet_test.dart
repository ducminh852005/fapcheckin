import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fapcheckin_core/repositories/schedule_repository.dart';
import 'package:fapcheckin_core/result/api_result.dart';
import 'package:fapcheckin_core/session/current_user.dart';
import 'package:fapcheckin/views/teacher/schedule/components/create_schedule_bottom_sheet.dart';

class _FakeScheduleRepository extends ScheduleRepository {
  _FakeScheduleRepository({this.hasRegularConflict = false})
    : super(currentUser: CurrentUser());

  final bool hasRegularConflict;

  final requests = <Map<String, dynamic>>[];

  @override
  Future<ApiResult<Map<String, dynamic>>> options() async => ApiSuccess({
    'today': '2026-10-30',
    'teacherName': 'Khoaaaa',
    'classes': [
      {
        'classCode': 'PRN231_SE1801',
        'subjectName': 'Building Cross-Platform Apps',
        'studentCount': 30,
        'room': 'AL-204',
        'slotCode': hasRegularConflict ? 'Slot 2' : 'Slot 1',
      },
    ],
    'slots': [
      {
        'slotCode': 'Slot 1',
        'startTime': '07:00',
        'endTime': '08:30',
        'weekdays': [2],
        'available': true,
      },
      {
        'slotCode': 'Slot 2',
        'startTime': '08:45',
        'endTime': '10:15',
        'weekdays': [6],
        'available': true,
      },
    ],
    'rooms': ['AL-204'],
    'schedules': [],
  });

  @override
  Future<ApiResult<Map<String, dynamic>>> create(
    Map<String, dynamic> input,
  ) async {
    requests.add(Map.of(input));
    return ApiSuccess({
      ...input,
      'scheduleId': 'schedule-12345',
      'status': 'scheduled',
    });
  }
}

void main() {
  testWidgets(
    'CreateScheduleBottomSheet renders all UI components matching mockup',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _FakeScheduleRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    showCreateScheduleBottomSheet(context, repository: repo),
                child: const Text('Open Bottom Sheet'),
              ),
            ),
          ),
        ),
      );

      // Mở Bottom Sheet
      await tester.tap(find.text('Open Bottom Sheet'));
      await tester.pumpAndSettle();

      // 1. Header
      expect(find.text('Tạo lịch học bổ sung'), findsOneWidget);
      expect(find.textContaining('Giảng viên: Khoaaaa · FPTU'), findsOneWidget);
      expect(find.byIcon(Icons.edit_calendar_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // 2. Thẻ lưu ý FAP
      expect(find.textContaining('Lưu ý FAP:'), findsOneWidget);
      expect(
        find.textContaining(
          'Lịch học bổ sung sẽ được đồng bộ tự động lên cổng FAP',
        ),
        findsOneWidget,
      );

      // 3. LOẠI BUỔI HỌC *
      expect(find.text('LOẠI BUỔI HỌC'), findsOneWidget);
      expect(find.text('Bắt buộc'), findsOneWidget);
      expect(find.text('Học bù (Make-up Slot)'), findsOneWidget);

      await tester.tap(find.text('Học bù (Make-up Slot)'));
      await tester.pumpAndSettle();
      expect(find.text('CHỌN LOẠI BUỔI HỌC'), findsOneWidget);
      expect(find.text('3 loại'), findsOneWidget);
      expect(find.text('Workshop (Hội thảo / Chuyên đề)'), findsOneWidget);
      expect(find.text('Ôn tập (Review Slot)'), findsOneWidget);
      await tester.tap(find.text('Học bù (Make-up Slot)').last);
      await tester.pumpAndSettle();

      // 4. LỚP HỌC *
      expect(find.text('LỚP HỌC'), findsOneWidget);

      // 5. CA HỌC (SLOT) * với 6 thẻ slot
      expect(find.text('CA HỌC (SLOT)'), findsOneWidget);
      expect(find.text('Slot 1'), findsOneWidget);
      expect(find.text('Slot 2 ✓'), findsOneWidget);
      expect(find.text('Slot 3'), findsOneWidget);
      expect(find.text('Slot 4'), findsOneWidget);
      expect(find.text('Slot 5'), findsOneWidget);
      expect(find.text('Slot 6'), findsOneWidget);

      // 6. PHÒNG HỌC *
      expect(find.text('PHÒNG HỌC'), findsOneWidget);
      expect(find.text('Phòng trống'), findsOneWidget);

      // 7. NGÀY HỌC BÙ
      expect(find.text('NGÀY HỌC BÙ'), findsOneWidget);
      expect(find.text('NGÀY ĐÃ CHỌN'), findsOneWidget);
      expect(find.text('Thứ Sáu, 30/10/2026'), findsOneWidget);
      expect(find.text('Đổi ngày'), findsOneWidget);

      // 8. HÌNH THỨC HỌC
      expect(find.text('HÌNH THỨC HỌC'), findsOneWidget);
      expect(find.text('Trực tiếp tại phòng học (On-campus)'), findsOneWidget);

      // 9. Nút chân trang
      expect(find.text('Hủy bỏ'), findsOneWidget);
      expect(find.text('Xác nhận tạo lịch'), findsOneWidget);

      // Đóng sheet qua nút Hủy bỏ
      await tester.tap(find.text('Hủy bỏ'));
      await tester.pumpAndSettle();
      expect(find.text('Tạo lịch học bổ sung'), findsNothing);
    },
  );

  testWidgets(
    'CreateScheduleBottomSheet selects options and submits to backend',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _FakeScheduleRepository();
      Map<String, dynamic>? createdResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  createdResult = await showCreateScheduleBottomSheet(
                    context,
                    repository: repo,
                  );
                },
                child: const Text('Open Bottom Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Bottom Sheet'));
      await tester.pumpAndSettle();

      // Chọn lớp học
      await tester.ensureVisible(find.text('Chọn lớp học'));
      await tester.tap(find.text('Chọn lớp học'));
      await tester.pumpAndSettle();
      expect(find.text('CHỌN LỚP HỌC'), findsOneWidget);
      expect(find.text('1 lớp'), findsOneWidget);
      await tester.tap(find.text('PRN231_SE1801').last);
      await tester.pumpAndSettle();

      // Chọn phòng học
      final dropdowns = find.byType(DropdownButtonFormField<String>);
      await tester.ensureVisible(dropdowns.at(1));
      await tester.tap(dropdowns.at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Phòng AL-204').last);
      await tester.pumpAndSettle();

      // Nhấn Xác nhận tạo lịch
      await tester.ensureVisible(find.text('Xác nhận tạo lịch'));
      await tester.tap(find.text('Xác nhận tạo lịch'));
      await tester.pumpAndSettle();

      // Kiểm tra kết quả trả về và request gửi xuống backend
      expect(repo.requests.length, 1);
      expect(repo.requests.first['classCode'], 'PRN231_SE1801');
      expect(repo.requests.first['room'], 'AL-204');
      expect(repo.requests.first['lessonType'], 'makeup');
      expect(repo.requests.first['teachingMethod'], 'onCampus');
      expect(createdResult, isNotNull);
      expect(createdResult!['scheduleId'], 'schedule-12345');
    },
  );

  testWidgets(
    'blocks submit when selected day and time overlap regular class',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _FakeScheduleRepository(hasRegularConflict: true);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    showCreateScheduleBottomSheet(context, repository: repo),
                child: const Text('Open Bottom Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Bottom Sheet'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Giảng viên đã có lịch chính khóa PRN231_SE1801'),
        findsOneWidget,
      );
      final confirm = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Xác nhận tạo lịch'),
      );
      expect(confirm.onPressed, isNull);
      expect(repo.requests, isEmpty);
    },
  );
}
