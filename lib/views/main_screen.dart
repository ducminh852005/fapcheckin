import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/viewmodels/dashboard_viewmodel.dart';
import 'package:fapcheckin/viewmodels/live_session_viewmodel.dart';
import 'package:fapcheckin/views/teacher/dashboard/dashboard_body.dart';
import 'package:fapcheckin/views/teacher/live_session/live_session_body.dart';
import 'package:fapcheckin/views/teacher/class_management/class_management_body.dart';
import 'package:fapcheckin/views/teacher/attendance_history/attendance_history_body.dart';
import 'package:fapcheckin/views/teacher/report/report_body.dart';
import 'package:fapcheckin/views/teacher/settings/settings_body.dart';
import 'package:fapcheckin/views/teacher/dashboard/components/sidebar.dart';
import 'package:fapcheckin/views/teacher/dashboard/components/top_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          context.read<LiveSessionViewModel>().tickTimers();
          context.read<DashboardViewModel>().tickCountdown();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = context.watch<DashboardViewModel>().currentRoute;

    Widget body;
    switch (currentRoute) {
      case 'diem-danh-qr':
        body = const LiveSessionBody();
        break;
      case 'lop-hoc':
        body = const ClassManagementBody();
        break;
      case 'lich-su-diem-danh':
        body = const AttendanceHistoryBody();
        break;
      case 'bao-cao':
        body = const ReportBody();
        break;
      case 'cai-dat':
        body = const SettingsBody();
        break;
      case 'tong-quan':
      default:
        body = const DashboardBody();
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Row(
            children: [
              const Sidebar(),
              Expanded(
                child: Column(
                  children: [
                    const TopBar(),
                    Expanded(child: body),
                  ],
                ),
              ),
            ],
          ),
          if (currentRoute == 'diem-danh-qr') const ToastNotification(),
        ],
      ),
    );
  }
}
