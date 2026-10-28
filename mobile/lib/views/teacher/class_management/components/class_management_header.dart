import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../viewmodels/dashboard_viewmodel.dart';
import '../class_management_colors.dart';

/// Phần Header của trang Quản lý lớp:
/// - "HỌC KỲ THU 2026"
/// - Tiêu đề lớn "Quản lý lớp"
/// - Nút "Lịch sử điểm danh" chuyển sang màn hình lịch sử
class ClassManagementHeader extends StatelessWidget {
  const ClassManagementHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardVm = context.watch<DashboardViewModel>();
    final semesterText = dashboardVm.semester.isNotEmpty
        ? 'HỌC KỲ ${dashboardVm.semester.toUpperCase()}'
        : 'HỌC KỲ THU 2026';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Tiêu đề & Học kỳ
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                semesterText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ClassManagementColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Quản lý lớp',
                style: TextStyle(
                  color: ClassManagementColors.textDark,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Nút "Lịch sử điểm danh"
        InkWell(
          onTap: () => dashboardVm.navigate('lich-su-diem-danh'),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Lịch sử điểm danh',
                style: TextStyle(
                  color: ClassManagementColors.textDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

