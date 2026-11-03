import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fapcheckin/views/teacher/report/components/report_scope_bottom_sheet.dart';

void main() {
  testWidgets('ReportScopeBottomSheet renders all options and applies filter', (
    tester,
  ) async {
    Map<String, DateTime?>? appliedRange;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                appliedRange = await showReportScopeBottomSheet(
                  context: context,
                  totalClosedSessions: 18,
                );
              },
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      ),
    );

    // Open bottom sheet
    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    // Verify Title and Subtitle
    expect(find.text('Phạm vi báo cáo'), findsOneWidget);
    expect(
      find.text('Chọn khoảng thời gian thống kê điểm danh chuyên cần'),
      findsOneWidget,
    );

    // Verify 4 options exist
    expect(find.text('Toàn bộ lịch sử'), findsOneWidget);
    expect(find.text('Hiện tại'), findsOneWidget);
    expect(find.text('Tuần này'), findsOneWidget);
    expect(find.text('Hôm nay'), findsOneWidget);
    expect(find.text('Tùy chọn khoảng ngày'), findsOneWidget);

    // Verify action buttons
    expect(find.text('Thiết lập lại'), findsOneWidget);
    expect(find.text('Áp dụng bộ lọc'), findsOneWidget);

    // Tap on "Tuần này" option
    await tester.tap(find.text('Tuần này'));
    await tester.pumpAndSettle();

    // Tap "Áp dụng bộ lọc"
    await tester.tap(find.text('Áp dụng bộ lọc'));
    await tester.pumpAndSettle();

    // Verify result is received with week range
    expect(appliedRange, isNotNull);
    expect(appliedRange!['start'], isNotNull);
    expect(appliedRange!['end'], isNotNull);
  });

  testWidgets('ReportScopeBottomSheet resets selection to all', (
    tester,
  ) async {
    Map<String, DateTime?>? appliedRange;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                appliedRange = await showReportScopeBottomSheet(
                  context: context,
                  currentFrom: DateTime(2026, 10, 1),
                  currentTo: DateTime(2026, 10, 8),
                  totalClosedSessions: 18,
                );
              },
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    // Tap "Thiết lập lại"
    await tester.tap(find.text('Thiết lập lại'));
    await tester.pumpAndSettle();

    // Tap "Áp dụng bộ lọc"
    await tester.tap(find.text('Áp dụng bộ lọc'));
    await tester.pumpAndSettle();

    // Should reset to all (null range)
    expect(appliedRange, isNotNull);
    expect(appliedRange!['start'], isNull);
    expect(appliedRange!['end'], isNull);
  });
}

