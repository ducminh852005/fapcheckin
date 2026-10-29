import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../viewmodels/dashboard_viewmodel.dart';
import '../class_management_colors.dart';

/// Phần Header của trang Quản lý lớp:
/// - Tiêu đề lớn "Quản lý lớp"
/// - Nút "Lịch sử điểm danh" chuyển sang màn hình lịch sử
class ClassManagementHeader extends StatelessWidget {
  const ClassManagementHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardVm = context.watch<DashboardViewModel>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Text(
            'Quản lý lớp',
            style: TextStyle(
              color: ClassManagementColors.textDark,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => dashboardVm.navigate('lich-su-diem-danh'),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ClassManagementColors.cardBorder),
              boxShadow: ClassManagementColors.cardShadow,
            ),
            child: const Text(
              'Lịch sử điểm danh',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: ClassManagementColors.textDark,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
