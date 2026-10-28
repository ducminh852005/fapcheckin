import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin_core/responsive/breakpoints.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/dashboard_viewmodel.dart';
import 'profile_colors.dart';
import 'components/profile_sub_header.dart';
import 'components/work_summary_card.dart';
import 'components/work_details_card.dart';
import 'components/work_info_note_card.dart';

/// Màn hình Thông tin công tác của Giảng viên:
/// 1. Header có nút quay lại (Back), nhãn "HỒ SƠ" và tiêu đề "Thông tin công tác"
/// 2. Thẻ tóm tắt: Tên giảng viên, Chức vụ, Badge "Đang công tác"
/// 3. Thẻ bảng chi tiết: Mã giảng viên, Khoa, Bộ môn, Chức vụ, Ngày vào làm, Hợp đồng
/// 4. Thẻ ghi chú thông tin do quản trị viên quản lý
class WorkInfoBody extends StatelessWidget {
  const WorkInfoBody({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final dashboardVm = context.watch<DashboardViewModel>();
    final horizontalPadding = context.isMobile ? 18.0 : context.pagePadding;

    final user = authVm.session?.user;
    final fullName = (user?.fullName.isNotEmpty ?? false)
        ? user!.fullName
        : 'Nguyễn Thị Mai';
    final memberCode = (user?.memberCode.isNotEmpty ?? false)
        ? user!.memberCode
        : 'GV01234';

    return Scaffold(
      backgroundColor: ProfileColors.pageBg,
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          context.isMobile ? 16.0 : 24.0,
          horizontalPadding,
          context.isMobile ? 32.0 : 40.0,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header có nút quay lại
                ProfileSubHeader(
                  title: 'Thông tin công tác',
                  onBack: () => dashboardVm.navigate('cai-dat'),
                ),
                const SizedBox(height: 16),

                // 2. Thẻ tóm tắt
                WorkSummaryCard(
                  fullName: fullName,
                  roleTitle: 'Giảng viên',
                  statusBadge: 'Đang công tác',
                ),
                const SizedBox(height: 16),

                // 3. Thẻ chi tiết công tác
                WorkDetailsCard(
                  entries: [
                    WorkDetailEntry(label: 'Mã giảng viên', value: memberCode),
                    const WorkDetailEntry(label: 'Khoa', value: 'Công nghệ thông tin'),
                    const WorkDetailEntry(label: 'Bộ môn', value: 'Phát triển phần mềm'),
                    const WorkDetailEntry(label: 'Chức vụ', value: 'Giảng viên'),
                    const WorkDetailEntry(label: 'Ngày vào làm', value: '01/09/2020'),
                    const WorkDetailEntry(label: 'Loại hợp đồng', value: 'Chính thức'),
                  ],
                ),
                const SizedBox(height: 16),

                // 4. Thẻ ghi chú
                const WorkInfoNoteCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

