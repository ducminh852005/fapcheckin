import 'package:fapcheckin/core/services/push_notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('routeForPushMessage', () {
    test('mở trang yêu cầu khi báo cáo vắng được admin xử lý', () {
      final message = RemoteMessage(
        data: {'type': 'absence_escalation_resolved'},
      );
      expect(routeForPushMessage(message), 'yeu-cau');
    });

    test('opens the teaching schedule for lesson reminders', () {
      final message = RemoteMessage(data: const {'type': 'teaching_reminder'});

      expect(routeForPushMessage(message), 'lich-hoc');
    });

    test('opens help for feedback updates', () {
      final message = RemoteMessage(data: const {'type': 'feedback_resolved'});

      expect(routeForPushMessage(message), 'cai-dat-tro-giup');
    });

    test('opens attendance history for attendance alerts', () {
      final message = RemoteMessage(data: const {'type': 'attendance_warning'});

      expect(routeForPushMessage(message), 'lich-su-diem-danh');
    });

    test('falls back to the dashboard for unknown messages', () {
      final message = RemoteMessage(data: const {'type': 'other'});

      expect(routeForPushMessage(message), 'tong-quan');
    });
  });
}
