import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fapcheckin_core/repositories/account_features_repository.dart';
import 'package:fapcheckin_core/result/api_result.dart';
import '../../../viewmodels/preferences_viewmodel.dart';
import '../../../viewmodels/dashboard_viewmodel.dart';
import '../profile/account_dialogs.dart';

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
          SwitchListTile(title: Text(tr('Nhắc lịch dạy', 'Teaching reminders')), subtitle: Text(tr('Thông báo 15 phút trước giờ dạy', 'Notify 15 minutes before class')), value: vm.reminders, onChanged: vm.saving ? null : (v) => vm.save(newReminders: v)),
          ListTile(title: Text(tr('Giao diện', 'Appearance')), trailing: DropdownButton<String>(value: vm.theme, items: [
            DropdownMenuItem(value: 'light', child: Text(tr('Sáng', 'Light'))), DropdownMenuItem(value: 'dark', child: Text(tr('Tối', 'Dark'))), DropdownMenuItem(value: 'system', child: Text(tr('Theo thiết bị', 'System')))], onChanged: vm.saving ? null : (v) => vm.save(newTheme: v))),
          ListTile(title: Text(tr('Ngôn ngữ', 'Language')), trailing: DropdownButton<String>(value: vm.language, items: const [DropdownMenuItem(value: 'vi', child: Text('Tiếng Việt')), DropdownMenuItem(value: 'en', child: Text('English'))], onChanged: vm.saving ? null : (v) => vm.save(newLanguage: v))),
          ListTile(leading: const Icon(Icons.security), title: Text(tr('Tài khoản & Bảo mật', 'Account security')), onTap: () => showAccountSecurity(context)),
        ])),
        Card(child: Column(children: [
          ListTile(leading: const Icon(Icons.feedback_outlined), title: Text(tr('Báo lỗi / Gửi góp ý', 'Report an issue / Feedback')), onTap: () => showDialog(context: context, builder: (_) => const FeedbackDialog())),
          ListTile(leading: const Icon(Icons.history), title: Text(tr('Góp ý đã gửi', 'My feedback')), onTap: () => showDialog(context: context, builder: (_) => const FeedbackHistoryDialog())),
          ListTile(leading: const Icon(Icons.support_agent), title: Text(tr('Liên hệ hỗ trợ', 'Contact support')), onTap: () => showSupport(context)),
          ExpansionTile(title: Text(tr('Hướng dẫn điểm danh QR', 'QR attendance guide')), children: [Padding(padding: const EdgeInsets.all(16), child: Text(tr('Chọn lớp → mở điểm danh → sinh viên quét QR → đóng phiên. Nếu không quét được, dùng điểm danh tay. Khi bật kiểm tra IP, sinh viên cần cùng mạng công khai với giảng viên.', 'Select a class → open attendance → students scan QR → close session. Use manual attendance if scanning fails. When IP checking is enabled, students must share your public network.')))]),
        ])),
      ]));
  }
}

class FeedbackDialog extends StatefulWidget {
  const FeedbackDialog({super.key});
  @override State<FeedbackDialog> createState() => _FeedbackDialogState();
}
class _FeedbackDialogState extends State<FeedbackDialog> {
  final _text = TextEditingController();
  final _id = DateTime.now().microsecondsSinceEpoch.toString();
  String _category = 'bug';
  String? _error;
  bool _saving = false, _submitted = false;
  @override void dispose() { _text.dispose(); super.dispose(); }
  Future<void> _send() async {
    if (_saving) return;
    setState(() { _saving = true; _error = null; _submitted = true; });
    final result = await context.read<AccountFeaturesRepository>().sendFeedback(_category, _text.text, requestId: _id);
    if (!mounted) return;
    if (result is ApiSuccess<String>) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã gửi / Sent: ${result.data}'))); return; }
    setState(() { _saving = false; _error = (result as ApiFailure<String>).error.message; if (result.error.code == 'VALIDATION_ERROR') _submitted = false; });
  }
  @override Widget build(BuildContext context) => AlertDialog(title: const Text('Góp ý / Feedback'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
    DropdownButtonFormField<String>(initialValue: _category, items: const [DropdownMenuItem(value: 'bug', child: Text('Báo lỗi / Bug')), DropdownMenuItem(value: 'suggestion', child: Text('Đề xuất / Suggestion')), DropdownMenuItem(value: 'other', child: Text('Khác / Other'))], onChanged: _submitted ? null : (v) => setState(() => _category = v!)),
    TextField(controller: _text, enabled: !_submitted, maxLength: 2000, maxLines: 5, decoration: const InputDecoration(labelText: 'Nội dung / Message')),
    if (_error != null) Text(_error!), if (_saving) const LinearProgressIndicator(),
  ])), actions: [TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Đóng / Close')), FilledButton(onPressed: _saving ? null : _send, child: Text(_submitted ? 'Thử lại / Retry' : 'Gửi / Send'))]);
}
class FeedbackHistoryDialog extends StatefulWidget {
  const FeedbackHistoryDialog({super.key});
  @override State<FeedbackHistoryDialog> createState() => _FeedbackHistoryDialogState();
}
class _FeedbackHistoryDialogState extends State<FeedbackHistoryDialog> {
  late final _stream = context.read<AccountFeaturesRepository>().feedback();
  @override Widget build(BuildContext context) => AlertDialog(title: const Text('Góp ý đã gửi / My feedback'), content: SizedBox(width: 600, height: 400, child: StreamBuilder<List<Map<String, dynamic>>>(stream: _stream, builder: (_, s) {
    if (s.hasError) return Text('Không tải được / Failed: ${s.error}');
    if (!s.hasData) return const Center(child: CircularProgressIndicator());
    if (s.data!.isEmpty) return const Text('Chưa có góp ý / No feedback yet');
    return ListView(children: [for (final row in s.data!) ListTile(title: Text(row['message'].toString()), subtitle: Text('${row['status']}\n${row['reply'] ?? ''}'))]);
  })), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng / Close'))]);
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
