import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'core/services/telemetry.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    unawaited(initTelemetry());
  } catch (e) {
    debugPrint('Firebase init error: $e');
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Không thể khởi tạo kết nối Firebase. Kiểm tra cấu hình ứng dụng và mở lại.',
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }
  runApp(const FapCheckinApp());
}
