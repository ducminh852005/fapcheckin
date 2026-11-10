import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

typedef PushMessageHandler = void Function(RemoteMessage message);

/// Connects Firebase Messaging to the Flutter UI.
///
/// Notification messages are displayed by Android/iOS while the app is in the
/// background. In the foreground, this service shows an in-app SnackBar and
/// forwards notification taps to the app router.
class PushNotificationService {
  PushNotificationService({
    required this.messengerKey,
    required this.onOpenMessage,
    FirebaseMessaging? messaging,
  }) : _messaging = messaging ?? FirebaseMessaging.instance;

  final GlobalKey<ScaffoldMessengerState> messengerKey;
  final PushMessageHandler onOpenMessage;
  final FirebaseMessaging _messaging;

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;

  Future<void> start() async {
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: false,
    );

    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _showForegroundMessage,
    );
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      onOpenMessage,
    );

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) onOpenMessage(initialMessage);
  }

  void _showForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString();
    final body = notification?.body ?? message.data['body']?.toString();
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    final messenger = messengerKey.currentState;
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 6),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null && title.isNotEmpty)
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              if (body != null && body.isNotEmpty) Text(body),
            ],
          ),
          action: SnackBarAction(
            label: 'Xem',
            onPressed: () => onOpenMessage(message),
          ),
        ),
      );
  }

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
  }
}

String routeForPushMessage(RemoteMessage message) {
  final type = message.data['type']?.toString().toLowerCase() ?? '';
  if (type.startsWith('absence_escalation_')) {
    return 'yeu-cau';
  }
  if (type == 'teaching_reminder' || type.contains('schedule')) {
    return 'lich-hoc';
  }
  if (type.startsWith('feedback_')) {
    return 'cai-dat-tro-giup';
  }
  if (type.contains('attendance') || type.contains('absent')) {
    return 'lich-su-diem-danh';
  }
  return 'tong-quan';
}
