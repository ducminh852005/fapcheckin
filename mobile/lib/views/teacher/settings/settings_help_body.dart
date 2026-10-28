import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin_core/responsive/breakpoints.dart';
import '../../../viewmodels/dashboard_viewmodel.dart';
import '../profile/profile_colors.dart';

/// Màn hình "Cài đặt & Trợ giúp" (Settings & Help) dành cho Giảng viên:
/// 1. Header: Nút back (<), Tiêu đề "Cài đặt & Trợ giúp", Icon bánh răng cưa màu cam
/// 2. Cài đặt ứng dụng:
///    - Nhắc lịch dạy (Switch bật/tắt)
///    - Giao diện (Sáng)
///    - Ngôn ngữ (Tiếng Việt)
///    - Bảo mật & quyền riêng tư
/// 3. Trợ giúp điểm danh:
///    - Hướng dẫn điểm danh QR
///    - Sinh viên không quét được mã QR? (Expandable FAQ)
///    - Báo lỗi / Gửi góp ý
/// 4. Thẻ "Bạn cần thêm trợ giúp?" kèm nút cam "Liên hệ hỗ trợ"
/// 5. Footer: "Điểm danh giảng viên · Phiên bản 1.0.0"
class SettingsHelpBody extends StatefulWidget {
  const SettingsHelpBody({super.key});

  @override
  State<SettingsHelpBody> createState() => _SettingsHelpBodyState();
}

class _SettingsHelpBodyState extends State<SettingsHelpBody> {
  // Trạng thái nhắc lịch dạy
  bool _reminderEnabled = true;

  // Lựa chọn giao diện và ngôn ngữ
  String _selectedTheme = 'Sáng';
  String _selectedLanguage = 'Tiếng Việt';

  // Trạng thái mở rộng FAQ
  bool _isFaqExpanded = true;

  @override
  Widget build(BuildContext context) {
    final dashboardVm = context.watch<DashboardViewModel>();
    final horizontalPadding = context.isMobile ? 18.0 : context.pagePadding;

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
                // 1. Header
                _buildHeader(context, dashboardVm),
                const SizedBox(height: 20),

                // 2. Nhóm "Cài đặt ứng dụng"
                _buildSectionTitle('Cài đặt ứng dụng'),
                const SizedBox(height: 10),
                _buildAppSettingsCard(context),
                const SizedBox(height: 24),

                // 3. Nhóm "Trợ giúp điểm danh"
                _buildSectionTitle('Trợ giúp điểm danh'),
                const SizedBox(height: 10),
                _buildAttendanceHelpCard(context),
                const SizedBox(height: 20),

                // 4. Thẻ "Bạn cần thêm trợ giúp?"
                _buildSupportBannerCard(context),
                const SizedBox(height: 24),

                // 5. Phiên bản
                const Center(
                  child: Text(
                    'Điểm danh giảng viên · Phiên bản 1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: ProfileColors.textSubtle,
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

  /// 1. Header: Back button + Title + Orange Gear icon
  Widget _buildHeader(BuildContext context, DashboardViewModel dashboardVm) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Nút quay lại & Tiêu đề
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => dashboardVm.navigate('cai-dat'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ProfileColors.borderSubtle),
                  boxShadow: ProfileColors.cardShadow,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Color(0xFF334155),
                ),
              ),
            ),
            const SizedBox(width: 14),
            const Text(
              'Cài đặt & Trợ giúp',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: ProfileColors.textDark,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),

        // Icon bánh răng cưa màu cam đặc trưng
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: ProfileColors.orangeLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.settings_rounded,
            size: 22,
            color: ProfileColors.orangePrimary,
          ),
        ),
      ],
    );
  }

  /// Tiêu đề phân nhóm
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: ProfileColors.textMuted,
        letterSpacing: 0.2,
      ),
    );
  }

  /// 2. Thẻ Cài đặt ứng dụng
  Widget _buildAppSettingsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ProfileColors.cardBorder),
        boxShadow: ProfileColors.cardShadow,
      ),
      child: Column(
        children: [
          // Nhắc lịch dạy (Switch)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildTileIcon(Icons.notifications_none_rounded),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nhắc lịch dạy',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: ProfileColors.textDark,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Thông báo trước giờ dạy 15 phút',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: ProfileColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _reminderEnabled,
                  activeColor: ProfileColors.orangePrimary,
                  activeTrackColor: ProfileColors.orangeLight,
                  onChanged: (val) {
                    setState(() => _reminderEnabled = val);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          val
                              ? 'Đã bật nhắc lịch dạy trước 15 phút'
                              : 'Đã tắt nhắc lịch dạy',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          _buildDivider(),

          // Giao diện (Sáng / Tối)
          _buildActionRow(
            icon: Icons.wb_sunny_outlined,
            title: 'Giao diện',
            subtitle: 'Chế độ hiển thị ứng dụng',
            trailingText: _selectedTheme,
            onTap: () => _showThemePicker(context),
          ),
          _buildDivider(),

          // Ngôn ngữ (Tiếng Việt)
          _buildActionRow(
            icon: Icons.language_rounded,
            title: 'Ngôn ngữ',
            subtitle: 'Ngôn ngữ sử dụng',
            trailingText: _selectedLanguage,
            onTap: () => _showLanguagePicker(context),
          ),
          _buildDivider(),

          // Bảo mật & quyền riêng tư
          _buildActionRow(
            icon: Icons.shield_outlined,
            title: 'Bảo mật & quyền riêng tư',
            subtitle: 'Mật khẩu, quyền truy cập',
            onTap: () => _showSecurityDialog(context),
          ),
        ],
      ),
    );
  }

  /// 3. Thẻ Trợ giúp điểm danh
  Widget _buildAttendanceHelpCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ProfileColors.cardBorder),
        boxShadow: ProfileColors.cardShadow,
      ),
      child: Column(
        children: [
          // Hướng dẫn điểm danh QR
          _buildActionRow(
            icon: Icons.qr_code_2_rounded,
            title: 'Hướng dẫn điểm danh QR',
            subtitle: 'Tạo mã, kết thúc phiên, điểm danh tay',
            onTap: () => _showQrGuideSheet(context),
          ),
          _buildDivider(),

          // Sinh viên không quét được mã QR? (Expandable item)
          InkWell(
            onTap: () {
              setState(() {
                _isFaqExpanded = !_isFaqExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Sinh viên không quét được mã QR?',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: ProfileColors.textDark,
                          ),
                        ),
                      ),
                      Icon(
                        _isFaqExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: ProfileColors.orangePrimary,
                        size: 22,
                      ),
                    ],
                  ),
                  if (_isFaqExpanded) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Kiểm tra kết nối mạng và mã QR còn hiệu lực. Nếu vẫn lỗi, dùng “Điểm danh tay” trong phiên đang mở.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          _buildDivider(),

          // Báo lỗi / Gửi góp ý
          _buildActionRow(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Báo lỗi / Gửi góp ý',
            subtitle: 'Đính kèm mã lớp và ảnh lỗi để hỗ trợ',
            onTap: () => _showFeedbackDialog(context),
          ),
        ],
      ),
    );
  }

  /// 4. Thẻ Bạn cần thêm trợ giúp? (Banner cam nhạt)
  Widget _buildSupportBannerCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFEDD5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: ProfileColors.orangeLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.headset_mic_outlined,
                  size: 22,
                  color: ProfileColors.orangePrimary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bạn cần thêm trợ giúp?',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: ProfileColors.textDark,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Bộ phận hỗ trợ · Thứ 2–6, 08:00–17:00',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: ProfileColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Nút Liên hệ hỗ trợ
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () => _showContactSupportSheet(context),
              icon: const Icon(Icons.send_rounded, size: 17, color: Colors.white),
              label: const Text(
                'Liên hệ hỗ trợ',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ProfileColors.orangePrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Khung icon bo góc màu cam nhạt
  Widget _buildTileIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: ProfileColors.orangeLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 20,
        color: ProfileColors.orangePrimary,
      ),
    );
  }

  /// Dòng action item trong card
  Widget _buildActionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _buildTileIcon(icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: ProfileColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: ProfileColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: ProfileColors.textMuted,
                ),
              ),
              const SizedBox(width: 4),
            ],
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: ProfileColors.textSubtle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 70,
      color: ProfileColors.cardBorder,
    );
  }

  // ── Các Dialogs / Bottom Sheets tương tác ─────────────────────────────────────

  void _showThemePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chọn giao diện',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: ProfileColors.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                _buildRadioTile(
                  title: 'Giao diện Sáng (Mặc định)',
                  selected: _selectedTheme == 'Sáng',
                  onTap: () {
                    setState(() => _selectedTheme = 'Sáng');
                    Navigator.pop(ctx);
                  },
                ),
                _buildRadioTile(
                  title: 'Giao diện Tối (Đang phát triển)',
                  selected: _selectedTheme == 'Tối',
                  onTap: () {
                    setState(() => _selectedTheme = 'Tối');
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chọn ngôn ngữ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: ProfileColors.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                _buildRadioTile(
                  title: 'Tiếng Việt',
                  selected: _selectedLanguage == 'Tiếng Việt',
                  onTap: () {
                    setState(() => _selectedLanguage = 'Tiếng Việt');
                    Navigator.pop(ctx);
                  },
                ),
                _buildRadioTile(
                  title: 'English (US)',
                  selected: _selectedLanguage == 'English',
                  onTap: () {
                    setState(() => _selectedLanguage = 'English');
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRadioTile({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? ProfileColors.orangePrimary : ProfileColors.textDark,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded, color: ProfileColors.orangePrimary)
          : null,
      onTap: onTap,
    );
  }

  void _showSecurityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Bảo mật & Quyền riêng tư',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• Tài khoản được quản lý và bảo mật qua Google Workspace FPT (@fpt.edu.vn / @fe.edu.vn).',
              style: TextStyle(fontSize: 13.5, height: 1.4),
            ),
            SizedBox(height: 8),
            Text(
              '• Dữ liệu điểm danh được mã hóa và lưu trữ trực tiếp trên máy chủ Firebase.',
              style: TextStyle(fontSize: 13.5, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đã hiểu', style: TextStyle(color: ProfileColors.orangePrimary)),
          ),
        ],
      ),
    );
  }

  void _showQrGuideSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Hướng dẫn điểm danh QR',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: ProfileColors.textDark,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildStepItem('1', 'Bắt đầu phiên', 'Chọn lớp từ lịch dạy và nhấn "Bắt đầu điểm danh".'),
              _buildStepItem('2', 'Chiếu mã QR', 'Mã QR tự động làm mới mỗi 15 giây để chống gian lận.'),
              _buildStepItem('3', 'Điểm danh tay', 'Với SV gặp trục trặc mạng hoặc camera, bấm "Điểm danh tay" để đánh dấu có mặt.'),
              _buildStepItem('4', 'Kết thúc phiên', 'Nhấn "Đóng phiên" và đồng bộ kết quả lên hệ thống FAP.'),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem(String number, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: ProfileColors.orangeLight,
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: ProfileColors.orangePrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 12.5, color: ProfileColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Báo lỗi / Gửi góp ý',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Mô tả vấn đề bạn gặp phải để đội ngũ kỹ thuật hỗ trợ kịp thời:',
              style: TextStyle(fontSize: 13, color: ProfileColors.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Nhập nội dung góp ý hoặc mô tả lỗi...',
                hintStyle: const TextStyle(fontSize: 13, color: ProfileColors.textSubtle),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ProfileColors.borderSubtle),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: ProfileColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cảm ơn thầy cô đã gửi góp ý! Chúng tôi sẽ kiểm tra sớm.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ProfileColors.orangePrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Gửi góp ý', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showContactSupportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Liên hệ hỗ trợ kỹ thuật',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ProfileColors.textDark,
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: _buildTileIcon(Icons.phone_in_talk_rounded),
                title: const Text('Hotline Hỗ trợ FAP Check-in', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: const Text('024 7300 1866 (Nhánh 2)'),
                contentPadding: EdgeInsets.zero,
              ),
              ListTile(
                leading: _buildTileIcon(Icons.email_outlined),
                title: const Text('Email hỗ trợ kỹ thuật', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: const Text('fap-support@fpt.edu.vn'),
                contentPadding: EdgeInsets.zero,
              ),
              ListTile(
                leading: _buildTileIcon(Icons.business_outlined),
                title: const Text('Phòng Đào tạo / Khảo thí', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: const Text('Tòa nhà Alpha, Đại học FPT'),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
