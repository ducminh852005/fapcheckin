import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/network/api_service.dart';
import '../data/repositories/teacher_repository.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../viewmodels/live_session_viewmodel.dart';
import '../viewmodels/attendance_history_viewmodel.dart';
import '../views/auth/login_screen.dart';

class FapCheckinApp extends StatelessWidget {
  const FapCheckinApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Shared singletons
    final apiService = ApiService();
    final teacherRepo = TeacherRepository(apiService);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => DashboardViewModel(teacherRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => LiveSessionViewModel(teacherRepo),
        ),
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
