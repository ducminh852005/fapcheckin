import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin_core/responsive/breakpoints.dart';

import '../../../viewmodels/auth_viewmodel.dart';
import 'components/profile_sub_header.dart';
import 'components/work_summary_card.dart';
import 'components/work_details_card.dart';
import 'components/work_info_note_card.dart';

/// Màn hình Thông tin công tác của Giảng viên:
/// 1. Header có nhãn "HỒ SƠ" và tiêu đề "Thông tin công tác"
/// 2. Thẻ tóm tắt: Tên giảng viên, Chức vụ, Badge "Đang công tác"
/// 3. Thẻ bảng chi tiết: Mã giảng viên, Khoa, Bộ môn, Chức vụ, Ngày vào làm, Hợp đồng
/// 4. Thẻ ghi chú thông tin do quản trị viên quản lý
class WorkInfoBody extends StatelessWidget {
  const WorkInfoBody({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final horizontalPadding = context.isMobile ? 18.0 : context.pagePadding;

    final user = authVm.session?.user;
    final fullName = (user?.fullName.isNotEmpty ?? false)
        ? user!.fullName
        : 'Giảng viên';
    final memberCode = (user?.memberCode.isNotEmpty ?? false)
        ? user!.memberCode
        : '—';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          context.isMobile ? 16.0 : 24.0,
          horizontalPadding,
          context.isMobile ? 108.0 : 40.0,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header
                const ProfileSubHeader(title: 'Thông tin công tác'),
                const SizedBox(height: 16),

                // 2. Thẻ tóm tắt
                WorkSummaryCard(
                  fullName: fullName,
                  roleTitle: user?.jobTitle.isNotEmpty == true
                      ? user!.jobTitle
                      : 'Giảng viên',
                  statusBadge: 'Đang công tác',
                ),
                const SizedBox(height: 16),

                // 3. Thẻ chi tiết công tác
                WorkDetailsCard(
                  entries: [
                    WorkDetailEntry(label: 'Mã giảng viên', value: memberCode),
                    WorkDetailEntry(
                      label: 'Khoa',
                      value: user?.department.isNotEmpty == true ? user!.department : 'Chưa cập nhật',
                    ),
                    WorkDetailEntry(
                      label: 'Bộ môn',
                      value: user?.division.isNotEmpty == true ? user!.division : 'Chưa cập nhật',
                    ),
                    WorkDetailEntry(
                      label: 'Chức vụ',
                      value: user?.jobTitle.isNotEmpty == true ? user!.jobTitle : 'Giảng viên',
                    ),
                    WorkDetailEntry(
                      label: 'Ngày vào làm',
                      value: user?.employmentDate.isNotEmpty == true ? user!.employmentDate : 'Chưa cập nhật',
                    ),
                    WorkDetailEntry(
                      label: 'Loại hợp đồng',
                      value: user?.contractType.isNotEmpty == true ? user!.contractType : 'Chưa cập nhật',
                    ),
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
