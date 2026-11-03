import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:fapcheckin_core/repositories/account_features_repository.dart';

import 'package:fapcheckin_core/result/api_result.dart';

import 'package:fapcheckin_core/responsive/breakpoints.dart';



import '../../../viewmodels/dashboard_viewmodel.dart';

import '../../../viewmodels/preferences_viewmodel.dart';

import '../profile/account_dialogs.dart';

import '../profile/profile_colors.dart';

import 'account_features_body.dart';

import 'feedback_modal_sheet.dart';
import 'feedback_history_modal_sheet.dart';

import '../requests/request_modal_sheet.dart';



/// Màn hình "Cài đặt & Trợ giúp" (Settings & Help) dành cho Giảng viên:

/// 1. Header: Nút back (<), Tiêu đề "Cài đặt & Trợ giúp", Icon bánh răng cưa màu cam

/// 2. Cài đặt ứng dụng:

///    - Nhắc lịch dạy (Switch bật/tắt kết nối user_preferences + FCM)

///    - Giao diện (Sáng / Tối / Theo thiết bị)

///    - Ngôn ngữ (Tiếng Việt / English)

///    - Bảo mật & quyền riêng tư (Tài khoản Google & 2FA)

/// 3. Trợ giúp điểm danh:

///    - Hướng dẫn điểm danh QR

///    - Sinh viên không quét được mã QR? (Expandable FAQ)

///    - Báo lỗi / Gửi góp ý (Gửi và xem lịch sử phản hồi từ Admin)

/// 4. Thẻ "Bạn cần thêm trợ giúp?" kèm nút cam "Liên hệ hỗ trợ" (support_config/public)

/// 5. Footer: "Điểm danh giảng viên · Phiên bản 1.0.0"

class SettingsHelpBody extends StatefulWidget {

  const SettingsHelpBody({super.key});



  @override

  State<SettingsHelpBody> createState() => _SettingsHelpBodyState();

}



class _SettingsHelpBodyState extends State<SettingsHelpBody> {

  // Trạng thái dự phòng khi chạy widget test độc lập không có PreferencesViewModel

  bool _localReminderEnabled = false;

  String _localTheme = 'light';

  String _localLanguage = 'vi';



  // Trạng thái mở rộng FAQ

  bool _isFaqExpanded = true;



  // Cấu hình liên hệ hỗ trợ từ support_config/public

  Map<String, dynamic> _supportData = const {};



  @override

  void initState() {

    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSupportConfig());

  }



  Future<void> _loadSupportConfig() async {

    final repo = context.read<AccountFeaturesRepository?>();

    if (repo == null) return;

    final res = await repo.support();

    if (!mounted) return;

    if (res is ApiSuccess<Map<String, dynamic>>) {

      setState(() {

        _supportData = res.data;

      });

    }

  }



  String _themeLabel(String code) {

    switch (code) {

      case 'dark':

        return 'Tối';

      case 'system':

        return 'Theo thiết bị';

      default:

        return 'Sáng';

    }

  }



  String _languageLabel(String code) {

    return code == 'en' ? 'English' : 'Tiếng Việt';

  }



  @override

  Widget build(BuildContext context) {

    final dashboardVm = context.watch<DashboardViewModel>();

    final prefsVm = context.watch<PreferencesViewModel?>();

    final horizontalPadding = context.isMobile ? 18.0 : context.pagePadding;



    return Scaffold(

      backgroundColor: ProfileColors.pageBg,

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

                _buildHeader(context, dashboardVm),

                if (prefsVm?.saving == true) ...[

                  const SizedBox(height: 12),

                  const LinearProgressIndicator(),

                ],

                if (prefsVm?.error != null) ...[

                  const SizedBox(height: 10),

                  Text(

                    prefsVm!.error!,

                    style: const TextStyle(

                      color: Colors.redAccent,

                      fontSize: 12.5,

                      fontWeight: FontWeight.w600,

                    ),

                  ),

                ],

                const SizedBox(height: 20),



                // 2. Nhóm "Cài đặt ứng dụng"

                _buildSectionTitle('Cài đặt ứng dụng'),

                const SizedBox(height: 10),

                _buildAppSettingsCard(context, prefsVm),

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



  /// 1. Header: Back button + Title

  Widget _buildHeader(BuildContext context, DashboardViewModel dashboardVm) {

    return Row(

      crossAxisAlignment: CrossAxisAlignment.center,

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

        const Expanded(

          child: Text(

            'Cài đặt & Trợ giúp',

            maxLines: 1,

            overflow: TextOverflow.ellipsis,

            style: TextStyle(

              fontSize: 20,

              fontWeight: FontWeight.w800,

              color: ProfileColors.textDark,

              letterSpacing: -0.4,

            ),

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

  Widget _buildAppSettingsCard(

    BuildContext context,

    PreferencesViewModel? prefsVm,

  ) {

    final reminderOn = prefsVm?.reminders ?? _localReminderEnabled;

    final currentTheme = prefsVm?.theme ?? _localTheme;

    final currentLang = prefsVm?.language ?? _localLanguage;

    final isSaving = prefsVm?.saving ?? false;



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

                        'Thông báo tự động 15 phút trước giờ dạy',

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

                  value: reminderOn,

                  activeThumbColor: ProfileColors.orangePrimary,

                  activeTrackColor: ProfileColors.orangeLight,

                  onChanged: isSaving

                      ? null

                      : (val) async {

                          if (prefsVm == null) {

                            setState(() => _localReminderEnabled = val);

                            return;

                          }

                          final ok = await prefsVm.save(newReminders: val);

                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(

                            SnackBar(

                              content: Text(

                                ok

                                    ? (val

                                        ? 'Đã bật nhắc lịch trước giờ dạy 15 phút.'

                                        : 'Đã tắt nhắc lịch dạy.')

                                    : (prefsVm.error ??

                                        'Không thể lưu cài đặt nhắc lịch.'),

                              ),

                            ),

                          );

                        },

                ),

              ],

            ),

          ),

          _buildDivider(),



          // Giao diện (Sáng / Tối / Theo thiết bị)

          _buildActionRow(

            icon: Icons.wb_sunny_outlined,

            title: 'Giao diện',

            subtitle: 'Chế độ hiển thị ứng dụng',

            trailingText: _themeLabel(currentTheme),

            onTap: () => _showThemePicker(context, prefsVm, currentTheme),

          ),

          _buildDivider(),



          // Ngôn ngữ (Tiếng Việt / English)

          _buildActionRow(

            icon: Icons.language_rounded,

            title: 'Ngôn ngữ',

            subtitle: 'Ngôn ngữ sử dụng',

            trailingText: _languageLabel(currentLang),

            onTap: () => _showLanguagePicker(context, prefsVm, currentLang),

          ),

          _buildDivider(),



          // Bảo mật & quyền riêng tư

          _buildActionRow(

            icon: Icons.shield_outlined,

            title: 'Bảo mật & quyền riêng tư',

            subtitle: 'Mật khẩu, xác thực hai lớp (Google)',

            onTap: () {

              final repo = context.read<AccountFeaturesRepository?>();

              if (repo != null) {

                showAccountSecurity(context);

              } else {

                _showSecurityDialog(context);

              }

            },

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



          _buildActionRow(

            icon: Icons.edit_note,

            title: 'Yêu cầu điểm danh / nghỉ phép',

            subtitle: 'Gửi yêu cầu và theo dõi phản hồi từ quản trị viên',

            onTap: () => showRequestBottomSheet(context),

          ),

          _buildDivider(),



          // Báo lỗi / Gửi góp ý

          _buildActionRow(

            icon: Icons.chat_bubble_outline_rounded,

            title: 'Báo lỗi / Gửi góp ý',

            subtitle: 'Gửi báo lỗi hoặc đề xuất tới quản trị viên',

            onTap: () => _showFeedbackDialog(context),

          ),

          _buildDivider(),



          // Lịch sử góp ý đã gửi

          _buildActionRow(

            icon: Icons.history_rounded,

            title: 'Lịch sử góp ý đã gửi',

            subtitle: 'Xem trạng thái xử lý và phản hồi từ nhà trường',

            onTap: () => _showFeedbackHistoryDialog(context),

          ),

        ],

      ),

    );

  }



  /// 4. Thẻ Bạn cần thêm trợ giúp? (Banner cam nhạt)

  Widget _buildSupportBannerCard(BuildContext context) {

    final hours = (_supportData['hours']?.toString().isNotEmpty ?? false)

        ? _supportData['hours'].toString()

        : 'Thứ 2–6, 08:00–17:00';

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

              Expanded(

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    const Text(

                      'Bạn cần thêm trợ giúp?',

                      style: TextStyle(

                        fontSize: 15,

                        fontWeight: FontWeight.w700,

                        color: ProfileColors.textDark,

                      ),

                    ),

                    const SizedBox(height: 3),

                    Text(

                      'Bộ phận hỗ trợ · $hours',

                      style: const TextStyle(

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

              icon: const Icon(

                Icons.send_rounded,

                size: 17,

                color: Colors.white,

              ),

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

      child: Icon(icon, size: 20, color: ProfileColors.orangePrimary),

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



  Future<void> _showThemePicker(

    BuildContext context,

    PreferencesViewModel? prefsVm,

    String currentTheme,

  ) async {

    final chosen = await showDialog<String>(

      context: context,

      builder: (ctx) => SimpleDialog(

        title: const Text('Chọn giao diện'),

        children: [

          SimpleDialogOption(

            onPressed: () => Navigator.pop(ctx, 'light'),

            child: Row(

              children: [

                Icon(

                  currentTheme == 'light'

                      ? Icons.radio_button_checked

                      : Icons.radio_button_off,

                  color: ProfileColors.orangePrimary,

                  size: 20,

                ),

                const SizedBox(width: 10),

                const Text('Sáng (Light)'),

              ],

            ),

          ),

          SimpleDialogOption(

            onPressed: () => Navigator.pop(ctx, 'dark'),

            child: Row(

              children: [

                Icon(

                  currentTheme == 'dark'

                      ? Icons.radio_button_checked

                      : Icons.radio_button_off,

                  color: ProfileColors.orangePrimary,

                  size: 20,

                ),

                const SizedBox(width: 10),

                const Text('Tối (Dark)'),

              ],

            ),

          ),

          SimpleDialogOption(

            onPressed: () => Navigator.pop(ctx, 'system'),

            child: Row(

              children: [

                Icon(

                  currentTheme == 'system'

                      ? Icons.radio_button_checked

                      : Icons.radio_button_off,

                  color: ProfileColors.orangePrimary,

                  size: 20,

                ),

                const SizedBox(width: 10),

                const Text('Theo thiết bị (System)'),

              ],

            ),

          ),

        ],

      ),

    );

    if (chosen == null || !mounted) return;

    if (prefsVm == null) {

      setState(() => _localTheme = chosen);

      return;

    }

    await prefsVm.save(newTheme: chosen);

  }



  Future<void> _showLanguagePicker(

    BuildContext context,

    PreferencesViewModel? prefsVm,

    String currentLang,

  ) async {

    final chosen = await showDialog<String>(

      context: context,

      builder: (ctx) => SimpleDialog(

        title: const Text('Chọn ngôn ngữ'),

        children: [

          SimpleDialogOption(

            onPressed: () => Navigator.pop(ctx, 'vi'),

            child: Row(

              children: [

                Icon(

                  currentLang == 'vi'

                      ? Icons.radio_button_checked

                      : Icons.radio_button_off,

                  color: ProfileColors.orangePrimary,

                  size: 20,

                ),

                const SizedBox(width: 10),

                const Text('Tiếng Việt'),

              ],

            ),

          ),

          SimpleDialogOption(

            onPressed: () => Navigator.pop(ctx, 'en'),

            child: Row(

              children: [

                Icon(

                  currentLang == 'en'

                      ? Icons.radio_button_checked

                      : Icons.radio_button_off,

                  color: ProfileColors.orangePrimary,

                  size: 20,

                ),

                const SizedBox(width: 10),

                const Text('English'),

              ],

            ),

          ),

        ],

      ),

    );

    if (chosen == null || !mounted) return;

    if (prefsVm == null) {

      setState(() => _localLanguage = chosen);

      return;

    }

    await prefsVm.save(newLanguage: chosen);

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

            child: const Text(

              'Đã hiểu',

              style: TextStyle(color: ProfileColors.orangePrimary),

            ),

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

              _buildStepItem(

                '1',

                'Bắt đầu phiên',

                'Chọn lớp từ lịch dạy và nhấn "Bắt đầu điểm danh".',

              ),

              _buildStepItem(

                '2',

                'Chiếu mã QR',

                'Mã QR tự động làm mới mỗi 15 giây để chống gian lận.',

              ),

              _buildStepItem(

                '3',

                'Điểm danh tay',

                'Với SV gặp trục trặc mạng hoặc camera, bấm "Điểm danh tay" để đánh dấu có mặt.',

              ),

              _buildStepItem(

                '4',

                'Kết thúc phiên',

                'Nhấn "Đóng phiên" và đồng bộ kết quả lên hệ thống FAP.',

              ),

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

                  style: const TextStyle(

                    fontSize: 14.5,

                    fontWeight: FontWeight.w700,

                  ),

                ),

                const SizedBox(height: 2),

                Text(

                  desc,

                  style: const TextStyle(

                    fontSize: 12.5,

                    color: ProfileColors.textMuted,

                  ),

                ),

              ],

            ),

          ),

        ],

      ),

    );

  }



  void _showFeedbackDialog(BuildContext context) {

    final repo = context.read<AccountFeaturesRepository?>();

    if (repo == null) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(

          content: Text('Chưa khởi tạo dịch vụ gửi góp ý.'),

        ),

      );

      return;

    }

    showFeedbackBottomSheet(context);

  }



  void _showFeedbackHistoryDialog(BuildContext context) {

    final repo = context.read<AccountFeaturesRepository?>();

    if (repo == null) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(

          content: Text('Chưa khởi tạo dịch vụ lịch sử góp ý.'),

        ),

      );

      return;

    }

    showFeedbackHistoryBottomSheet(context);

  }



  Future<void> _showContactSupportSheet(BuildContext context) async {

    final repo = context.read<AccountFeaturesRepository?>();

    if (repo != null) {

      final result = await repo.support();

      if (!context.mounted) return;

      if (result is ApiSuccess<Map<String, dynamic>>) {

        setState(() => _supportData = result.data);

      }

    }



    final phone = _supportData['phone']?.toString() ?? '';

    final email = _supportData['email']?.toString() ?? '';

    final address = _supportData['address']?.toString() ?? '';

    final hours = _supportData['hours']?.toString() ?? '';



    await showModalBottomSheet(

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

              if (hours.isNotEmpty) ...[

                const SizedBox(height: 4),

                Text(

                  'Giờ làm việc: $hours',

                  style: const TextStyle(

                    fontSize: 12.5,

                    color: ProfileColors.textMuted,

                  ),

                ),

              ],

              const SizedBox(height: 14),

              ListTile(

                leading: _buildTileIcon(Icons.phone_in_talk_rounded),

                title: const Text(

                  'Hotline Hỗ trợ FAP Check-in',

                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),

                ),

                subtitle: Text(

                  phone.isNotEmpty ? phone : 'Chưa được nhà trường cấu hình',

                ),

                contentPadding: EdgeInsets.zero,

                onTap: phone.isNotEmpty

                    ? () async {

                        final ok = await launchUrl(

                          Uri(scheme: 'tel', path: phone),

                        );

                        if (!ok && ctx.mounted) {

                          ScaffoldMessenger.of(ctx).showSnackBar(

                            const SnackBar(

                              content: Text('Không mở được ứng dụng gọi điện.'),

                            ),

                          );

                        }

                      }

                    : null,

              ),

              ListTile(

                leading: _buildTileIcon(Icons.email_outlined),

                title: const Text(

                  'Email hỗ trợ kỹ thuật',

                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),

                ),

                subtitle: Text(

                  email.isNotEmpty ? email : 'Chưa được nhà trường cấu hình',

                ),

                contentPadding: EdgeInsets.zero,

                onTap: email.isNotEmpty

                    ? () async {

                        final ok = await launchUrl(

                          Uri(scheme: 'mailto', path: email),

                        );

                        if (!ok && ctx.mounted) {

                          ScaffoldMessenger.of(ctx).showSnackBar(

                            const SnackBar(

                              content: Text('Không mở được ứng dụng email.'),

                            ),

                          );

                        }

                      }

                    : null,

              ),

              ListTile(

                leading: _buildTileIcon(Icons.business_outlined),

                title: const Text(

                  'Phòng Đào tạo / Khảo thí',

                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),

                ),

                subtitle: Text(

                  address.isNotEmpty

                      ? address

                      : 'Liên hệ đơn vị phụ trách tại cơ sở của bạn',

                ),

                contentPadding: EdgeInsets.zero,

              ),

            ],

          ),

        ),

      ),

    );

  }

}

