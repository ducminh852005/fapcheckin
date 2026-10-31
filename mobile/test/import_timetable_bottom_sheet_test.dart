import 'package:fapcheckin/views/teacher/schedule/components/import_timetable_bottom_sheet.dart';
import 'package:fapcheckin_core/repositories/timetable_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTimetableRepository extends Fake implements TimetableRepository {}

void main() {
  testWidgets('ImportTimetableBottomSheet renders all initial UI components matching mockup', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeRepo = _FakeTimetableRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showImportTimetableBottomSheet(
                context,
                repository: fakeRepo,
              ),
              child: const Text('Open Scan Sheet'),
            ),
          ),
        ),
      ),
    );

    // Open Bottom Sheet
    await tester.tap(find.text('Open Scan Sheet'));
    await tester.pumpAndSettle();

    // 1. Header elements
    expect(find.text('Quét thời khóa biểu'), findsOneWidget);
    expect(find.text('AI OCR'), findsOneWidget);
    expect(find.text('FAP Student Portal • FPT University'), findsOneWidget);
    expect(find.byIcon(Icons.document_scanner_rounded), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    // 2. Dropzone elements
    expect(find.text('Nhận diện tự động'), findsOneWidget);
    expect(find.text('Tải lên hoặc chụp ảnh thời khóa biểu'), findsOneWidget);
    expect(find.text('Chụp ảnh'), findsNothing);
    expect(find.text('Thư viện ảnh'), findsNothing);

    // 3. AI OCR Status Card
    expect(find.text('Nhận dạng trên thiết bị'), findsOneWidget);
    expect(
      find.text('Đọc mã lớp–môn • Kiểm tra kết quả trước khi nhập'),
      findsOneWidget,
    );
    expect(find.text('Sẵn\nsàng'), findsOneWidget);

    // 4. Tips Card
    expect(find.text('MẸO QUÉT LỊCH HỌC CHUẨN XÁC'), findsOneWidget);
    expect(find.text('4 lưu ý'), findsOneWidget);
    expect(find.text('SE1917'), findsOneWidget);
    expect(find.text('PRN231'), findsOneWidget);

    // 5. Action Buttons
    expect(find.text('Hủy'), findsOneWidget);
    expect(find.text('Chọn ảnh để quét'), findsOneWidget);

    // Dismiss bottom sheet via 'Hủy' button
    await tester.ensureVisible(find.text('Hủy'));
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();

    // Verify it is dismissed
    expect(find.text('Quét thời khóa biểu'), findsNothing);
  });

  testWidgets('ImportTimetableBottomSheet closes when tapping close icon button', (
    tester,
  ) async {
    final fakeRepo = _FakeTimetableRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showImportTimetableBottomSheet(
                context,
                repository: fakeRepo,
              ),
              child: const Text('Open Scan Sheet'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Scan Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Quét thời khóa biểu'), findsOneWidget);

    // Tap top-right '✕' button
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Quét thời khóa biểu'), findsNothing);
  });
}
