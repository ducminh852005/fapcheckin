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
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    unawaited(initTelemetry());
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }
  runApp(const FapCheckinApp());
}
