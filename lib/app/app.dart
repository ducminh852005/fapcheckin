import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../viewmodels/live_session_viewmodel.dart';
import '../viewmodels/attendance_history_viewmodel.dart';
import '../views/auth/login_screen.dart';

class FapCheckinApp extends StatelessWidget {
  const FapCheckinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DashboardViewModel()),
        ChangeNotifierProvider(create: (_) => LiveSessionViewModel()),
        ChangeNotifierProvider(create: (_) => AttendanceHistoryViewModel()),
      ],
      child: MaterialApp(
        title: 'FAP Check-in',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const LoginScreen(),
      ),
    );
  }
}
