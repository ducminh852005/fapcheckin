import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fapcheckin_core/result/api_result.dart';
import 'package:fapcheckin_core/session/current_user.dart';
import 'package:fapcheckin_core/repositories/schedule_repository.dart';
import 'package:fapcheckin/views/teacher/class_management/dialogs/create_class_dialog.dart';

class FakeScheduleRepository extends ScheduleRepository {
  FakeScheduleRepository() : super(currentUser: CurrentUser());
  final requests = <Map<String, dynamic>>[];
  @override
  Future<ApiResult<Map<String, dynamic>>> options() async => ApiSuccess({
    'today': '2099-09-21',
    'teacherName': 'Real Teacher',
    'classes': [
      {'classCode': 'C1', 'subjectName': 'Real Course', 'studentCount': 17},
    ],
    'slots': [
      {
        'slotCode': 'A1',
        'startTime': '07:00',
        'endTime': '09:15',
        'available': true,
      },
    ],
    'rooms': ['303'],
    'schedules': [],
  });
  @override
  Future<ApiResult<Map<String, dynamic>>> create(
    Map<String, dynamic> input,
  ) async {
    requests.add(Map.of(input));
    if (requests.length == 1) {
      return ApiFailure(ApiError(code: 'NETWORK_ERROR', message: 'Timeout'));
    }
    return ApiSuccess({...input, 'scheduleId': 'saved'});
  }
}

void main() {
  testWidgets('real options, required fields and idempotent timeout retry', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = FakeScheduleRepository();
    Map<String, dynamic>? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                saved = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (_) => CreateClassDialog(repository: repo),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Giảng viên: Real Teacher'), findsOneWidget);
    await tester.tap(find.text('Xác nhận tạo lịch'));
    await tester.pumpAndSettle();
    expect(repo.requests, isEmpty);

    final dropdowns = find.byType(DropdownButtonFormField<String>);

    // Chọn lớp học (dropdown thứ 2: index 1)
    await tester.tap(dropdowns.at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('C1 — Real Course').last);
    await tester.pumpAndSettle();

    // Chọn ca học (Slot 1) từ Grid thẻ slot
    await tester.tap(find.text('Slot 1 ✓'));
    await tester.pumpAndSettle();

    // Chọn phòng học (dropdown thứ 3: index 2)
    await tester.ensureVisible(dropdowns.at(2));
    await tester.tap(dropdowns.at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Phòng 303').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Xác nhận tạo lịch'));
    await tester.tap(find.text('Xác nhận tạo lịch'));
    await tester.pumpAndSettle();
    expect(repo.requests.length, 1);
    await tester.tap(find.text('Thử lại cùng yêu cầu'));
    await tester.pumpAndSettle();
    expect(repo.requests[0], repo.requests[1]);
    expect(saved?['scheduleId'], 'saved');
    expect(tester.takeException(), isNull);
  });
}
