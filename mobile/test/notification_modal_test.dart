import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fapcheckin/views/teacher/dashboard/components/notification_modal.dart';

void main() {
  testWidgets(
    'announcements show server data, empty state and errors without fake rows',
    (tester) async {
      final stream = StreamController<List<Map<String, dynamic>>>();
      addTearDown(stream.close);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: NotificationModal(announcements: stream.stream)),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      stream.add([]);
      await tester.pump();
      expect(find.text('Chưa có thông báo.'), findsOneWidget);
      stream.add([
        {'title': 'Lịch học cập nhật', 'body': 'Nội dung từ nhà trường'},
      ]);
      await tester.pump();
      expect(find.text('Lịch học cập nhật'), findsOneWidget);
      expect(find.text('Nội dung từ nhà trường'), findsOneWidget);
      expect(find.textContaining('PRN231'), findsNothing);
      stream.addError(Exception('permission-denied'));
      await tester.pump();
      expect(find.textContaining('Không thể tải thông báo'), findsOneWidget);
      expect(find.text('Nội dung từ nhà trường'), findsNothing);
    },
  );
}
