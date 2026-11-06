import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:fapcheckin_core/repositories/account_features_repository.dart';

import 'package:fapcheckin_core/result/api_result.dart';

import '../../../viewmodels/preferences_viewmodel.dart';

import '../../../viewmodels/dashboard_viewmodel.dart';

import '../profile/account_dialogs.dart';

import 'feedback_modal_sheet.dart';
import 'feedback_history_modal_sheet.dart';

import '../requests/request_modal_sheet.dart';



class AccountFeaturesBody extends StatelessWidget {

  const AccountFeaturesBody({super.key});

  @override

  Widget build(BuildContext context) {

    final vm = context.watch<PreferencesViewModel>();

    final tr = vm.tr;

    return Scaffold(appBar: AppBar(title: Text(tr('Cài đặt & Trợ giúp', 'Settings & Help')), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.read<DashboardViewModel>().navigate('cai-dat'))),

      body: ListView(padding: const EdgeInsets.all(16), children: [

        if (vm.saving) const LinearProgressIndicator(),

        if (vm.error != null) Text(vm.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),

        Card(child: Column(children: [

          ListTile(leading: const Icon(Icons.edit_note), title: const Text('Yêu cầu điểm danh / nghỉ phép'), onTap: () => showRequestBottomSheet(context)),

          SwitchListTile(title: Text(tr('Nhắc lịch dạy', 'Teaching reminders')), subtitle: Text(tr('Thông báo 15 phút trước giờ dạy', 'Notify 15 minutes before class')), value: vm.reminders, onChanged: vm.saving ? null : (v) => vm.save(newReminders: v)),

          ListTile(title: Text(tr('Giao diện', 'Appearance')), trailing: DropdownButton<String>(value: vm.theme, items: [

            DropdownMenuItem(value: 'light', child: Text(tr('Sáng', 'Light'))), DropdownMenuItem(value: 'dark', child: Text(tr('Tối', 'Dark'))), DropdownMenuItem(value: 'system', child: Text(tr('Theo thiết bị', 'System')))], onChanged: vm.saving ? null : (v) => vm.save(newTheme: v))),

          ListTile(title: Text(tr('Ngôn ngữ', 'Language')), trailing: DropdownButton<String>(value: vm.language, items: const [DropdownMenuItem(value: 'vi', child: Text('Tiếng Việt')), DropdownMenuItem(value: 'en', child: Text('English'))], onChanged: vm.saving ? null : (v) => vm.save(newLanguage: v))),

          ListTile(leading: const Icon(Icons.security), title: Text(tr('Tài khoản & Bảo mật', 'Account security')), onTap: () => showAccountSecurity(context)),

        ])),

        Card(child: Column(children: [

          ListTile(leading: const Icon(Icons.feedback_outlined), title: Text(tr('Báo lỗi / Gửi góp ý', 'Report an issue / Feedback')), onTap: () => showFeedbackBottomSheet(context)),

          ListTile(leading: const Icon(Icons.history), title: Text(tr('Góp ý đã gửi', 'My feedback')), onTap: () => showFeedbackHistoryBottomSheet(context)),

          ListTile(leading: const Icon(Icons.support_agent), title: Text(tr('Liên hệ hỗ trợ', 'Contact support')), onTap: () => showSupport(context)),

          ExpansionTile(title: Text(tr('Hướng dẫn điểm danh QR', 'QR attendance guide')), children: [Padding(padding: const EdgeInsets.all(16), child: Text(tr('Chọn lớp → mở điểm danh → sinh viên quét QR → đóng phiên. Nếu không quét được, dùng điểm danh tay. Khi bật kiểm tra IP, sinh viên cần cùng mạng công khai với giảng viên.', 'Select a class → open attendance → students scan QR → close session. Use manual attendance if scanning fails. When IP checking is enabled, students must share your public network.')))]),

        ])),

      ]));

  }

}



class FeedbackDialog extends StatefulWidget {

  const FeedbackDialog({super.key});



  @override

  State<FeedbackDialog> createState() => _FeedbackDialogState();

}



class _FeedbackDialogState extends State<FeedbackDialog> {

  @override

  Widget build(BuildContext context) => const Dialog(

        backgroundColor: Colors.transparent,

        insetPadding: EdgeInsets.zero,

        alignment: Alignment.bottomCenter,

        child: FeedbackModalSheet(),

      );

}

class FeedbackHistoryDialog extends StatefulWidget {
  const FeedbackHistoryDialog({super.key});

  @override
  State<FeedbackHistoryDialog> createState() => _FeedbackHistoryDialogState();
}

class _FeedbackHistoryDialogState extends State<FeedbackHistoryDialog> {
  @override
  Widget build(BuildContext context) => const Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        alignment: Alignment.bottomCenter,
        child: FeedbackHistoryModalSheet(),
      );
}

Future<void> showSupport(BuildContext context) async {

  final result = await context.read<AccountFeaturesRepository>().support();

  if (!context.mounted) return;

  if (result is ApiFailure<Map<String, dynamic>>) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error.message))); return; }

  final data = (result as ApiSuccess<Map<String, dynamic>>).data;

  await showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Liên hệ hỗ trợ / Support'), content: Column(mainAxisSize: MainAxisSize.min, children: [

    if (data.isEmpty) const Text('Nhà trường chưa cấu hình thông tin hỗ trợ / Contact details have not been configured.'),

    for (final field in ['phone', 'email', 'address', 'hours'])

      if (data[field]?.toString().isNotEmpty == true) ListTile(title: Text(data[field].toString()), onTap: field == 'phone' || field == 'email' ? () async {

        final uri = Uri(scheme: field == 'phone' ? 'tel' : 'mailto', path: data[field].toString());

        final opened = await launchUrl(uri);

        if (!opened && ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Không mở được ứng dụng liên hệ / Unable to open contact app.')));

      } : null),

  ]), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng / Close'))]));

}

