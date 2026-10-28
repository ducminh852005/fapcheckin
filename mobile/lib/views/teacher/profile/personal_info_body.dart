import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin_core/responsive/breakpoints.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/dashboard_viewmodel.dart';
import 'profile_colors.dart';
import 'components/profile_sub_header.dart';
import 'components/personal_avatar_card.dart';
import 'components/personal_form_card.dart';

/// Màn hình Thông tin cá nhân của Giảng viên:
/// 1. Header có nút quay lại (Back), nhãn "HỒ SƠ" và tiêu đề "Thông tin cá nhân"
/// 2. Thẻ Avatar kèm nút "Đổi ảnh đại diện"
/// 3. Thẻ form thông tin: Họ và tên, Email (khóa), Số điện thoại, Ngày sinh
/// 4. Nút cam "Lưu thay đổi"
class PersonalInfoBody extends StatefulWidget {
  const PersonalInfoBody({super.key});

  @override
  State<PersonalInfoBody> createState() => _PersonalInfoBodyState();
}

class _PersonalInfoBodyState extends State<PersonalInfoBody> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _birthDateController;

  @override
  void initState() {
    super.initState();
    final authVm = context.read<AuthViewModel>();
    final user = authVm.session?.user;

    final name = (user?.fullName.isNotEmpty ?? false) ? user!.fullName : 'Nguyễn Thị Mai';
    final email = (user?.email.isNotEmpty ?? false) ? user!.email : 'mainguyen@fpt.edu.vn';

    _nameController = TextEditingController(text: name);
    _emailController = TextEditingController(text: email);
    _phoneController = TextEditingController(text: '0912 345 678');
    _birthDateController = TextEditingController(text: '15/08/1995');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  String _extractInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'NM';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardVm = context.watch<DashboardViewModel>();
    final horizontalPadding = context.isMobile ? 18.0 : context.pagePadding;
    final initials = _extractInitials(_nameController.text);

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
                  title: 'Thông tin cá nhân',
                  onBack: () => dashboardVm.navigate('cai-dat'),
                ),
                const SizedBox(height: 16),

                // 2. Thẻ Avatar
                PersonalAvatarCard(
                  initials: initials,
                  onChangeAvatar: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tính năng tải ảnh đại diện đang được cập nhật'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 3. Thẻ Form thông tin cá nhân
                PersonalFormCard(
                  nameController: _nameController,
                  emailController: _emailController,
                  phoneController: _phoneController,
                  birthDateController: _birthDateController,
                  onPickBirthDate: _handlePickBirthDate,
                ),
                const SizedBox(height: 20),

                // 4. Nút "Lưu thay đổi"
                InkWell(
                  onTap: _handleSave,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: ProfileColors.orangePrimary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: ProfileColors.orangePrimary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Lưu thay đổi',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handlePickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995, 8, 15),
      firstDate: DateTime(1950),
      lastDate: now,
    );
    if (picked != null) {
      final day = picked.day.toString().padLeft(2, '0');
      final month = picked.month.toString().padLeft(2, '0');
      setState(() {
        _birthDateController.text = '$day/$month/${picked.year}';
      });
    }
  }

  void _handleSave() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu thay đổi thông tin cá nhân thành công'),
        backgroundColor: ProfileColors.statusGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

