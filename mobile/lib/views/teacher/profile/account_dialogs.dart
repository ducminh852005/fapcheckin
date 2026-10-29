import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fapcheckin_core/repositories/account_features_repository.dart';
import 'package:fapcheckin_core/result/api_result.dart';
import '../../../cloudary/cloudary.dart';
import '../../../viewmodels/auth_viewmodel.dart';

Future<void> showAccountSecurity(BuildContext context) async {
  final repo = context.read<AccountFeaturesRepository?>();
  if (repo == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chưa khởi tạo dịch vụ tài khoản.')),
    );
    return;
  }
  final result = await repo.security();
  if (!context.mounted) return;
  if (result is ApiFailure<Map<String, dynamic>>) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.error.message)),
    );
    return;
  }
  final data = (result as ApiSuccess<Map<String, dynamic>>).data;
  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Tài khoản & Bảo mật',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${data['email'] ?? '—'}'),
            const SizedBox(height: 4),
            Text(
              'Xác thực email: ${data['emailVerified'] == true ? 'Đã xác thực' : 'Chưa xác thực'}',
            ),
            const SizedBox(height: 4),
            Text(
              'Phương thức đăng nhập: ${((data['providers'] as List?) ?? const []).join(', ')}',
            ),
            const SizedBox(height: 4),
            Text('Đăng nhập gần nhất: ${data['lastSignIn'] ?? '—'}'),
            const SizedBox(height: 12),
            const Text(
              'Ứng dụng đăng nhập thông qua Google Workspace FPT. Việc đổi mật khẩu và bật xác thực hai lớp (2FA) được quản lý trực tiếp tại trang Bảo mật Google Account.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Đóng'),
        ),
        FilledButton(
          onPressed: () async {
            final ok = await launchUrl(
              Uri.parse('https://myaccount.google.com/security'),
              mode: LaunchMode.externalApplication,
            );
            if (!ok && ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Không mở được Google Account.')),
              );
            }
          },
          child: const Text('Quản lý trên Google'),
        ),
      ],
    ),
  );
}

class AccountAvatar extends StatefulWidget {
  const AccountAvatar({
    super.key,
    required this.path,
    required this.initials,
    this.radius = 40,
    this.backgroundColor,
    this.textStyle,
  });
  final String path, initials;
  final double radius;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  @override
  State<AccountAvatar> createState() => _AccountAvatarState();
}

class _AccountAvatarState extends State<AccountAvatar> {
  Future<Uint8List?>? _image;
  void _load() {
    final repo = context.read<AccountFeaturesRepository?>();
    _image = (widget.path.isEmpty || repo == null)
        ? null
        : repo.avatar(widget.path);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(AccountAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) _load();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.path.startsWith('http://') ||
        widget.path.startsWith('https://')) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: widget.backgroundColor,
        backgroundImage: NetworkImage(widget.path),
        onBackgroundImageError: (_, _) {},
        child: widget.path.isEmpty
            ? Text(widget.initials, style: widget.textStyle)
            : null,
      );
    }
    if (widget.path.startsWith('data:image/')) {
      try {
        final commaIdx = widget.path.indexOf(',');
        final base64Part =
            commaIdx >= 0 ? widget.path.substring(commaIdx + 1) : widget.path;
        final decodedBytes = base64Decode(base64Part);
        return CircleAvatar(
          radius: widget.radius,
          backgroundColor: widget.backgroundColor,
          backgroundImage: MemoryImage(decodedBytes),
          child: null,
        );
      } catch (_) {}
    }
    return FutureBuilder<Uint8List?>(
      future: _image,
      builder: (_, s) => CircleAvatar(
        radius: widget.radius,
        backgroundColor: widget.backgroundColor,
        backgroundImage: s.data == null ? null : MemoryImage(s.data!),
        child: s.data == null
            ? Text(widget.initials, style: widget.textStyle)
            : null,
      ),
    );
  }
}

/// Mở hộp thoại cấu hình Cloudinary (Cloud Name, Upload Preset, Folder)
Future<void> showCloudinaryConfigDialog(BuildContext context) async {
  final nameCtrl = TextEditingController(text: CloudinaryConfig.cloudName);
  final presetCtrl = TextEditingController(text: CloudinaryConfig.uploadPreset);
  final folderCtrl = TextEditingController(text: CloudinaryConfig.folder);

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Row(
        children: [
          Icon(Icons.cloud_upload_outlined, color: Color(0xFFC2410C)),
          SizedBox(width: 8),
          Text(
            'Cấu hình Cloudinary',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập thông tin Cloudinary của bạn để tự động lưu ảnh đại diện vào thư mục được chọn trên đám mây:',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Cloud Name',
                hintText: 'vd: my-cloud-name',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: presetCtrl,
              decoration: const InputDecoration(
                labelText: 'Upload Preset (Unsigned)',
                hintText: 'vd: ml_default hoặc fapcheckin_avatars',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: folderCtrl,
              decoration: const InputDecoration(
                labelText: 'Thư mục (Folder)',
                hintText: 'mặc định: cloudary',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Hủy'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFC2410C),
          ),
          onPressed: () {
            CloudinaryConfig.update(
              newCloudName: nameCtrl.text,
              newUploadPreset: presetCtrl.text,
              newFolder: folderCtrl.text,
            );
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã cập nhật cấu hình Cloudinary thành công.'),
              ),
            );
          },
          child: const Text('Lưu cấu hình'),
        ),
      ],
    ),
  );
}

Future<void> chooseAvatar(BuildContext context) async {
  final repo = context.read<AccountFeaturesRepository?>();
  if (repo == null) return;
  final auth = context.read<AuthViewModel>();
  final picked = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['png', 'jpg', 'jpeg'],
    withData: true,
  );
  if (picked == null || !context.mounted) return;
  final file = picked.files.single;
  if (file.bytes == null) return;
  final mime =
      file.extension?.toLowerCase() == 'png' ? 'image/png' : 'image/jpeg';

  // 1. Cố gắng tải ảnh lên Cloudinary vào thư mục cloudary
  String? cloudaryUrl;
  if (CloudinaryConfig.cloudName != 'fapcheckin') {
    try {
      final cloudinary = CloudinaryService();
      final uploadRes = await cloudinary.uploadAvatar(
        bytes: file.bytes!,
        fileName: file.name,
        folder: CloudinaryConfig.folder,
      );
      if (uploadRes.secureUrl.isNotEmpty) {
        cloudaryUrl = uploadRes.secureUrl;
      }
    } catch (_) {
      cloudaryUrl = null;
    }
  }

  // 2. Nếu Cloudinary chưa được cấu hình key riêng hoặc upload thất bại,
  // lưu trực tiếp dạng Base64 Data URI vào hồ sơ (đảm bảo không bị lỗi 404
  // Firebase Storage do bucket chưa tạo).
  final targetAvatarPath = cloudaryUrl ?? 'data:$mime;base64,${base64Encode(file.bytes!)}';

  // 3. Cập nhật đường dẫn avatar vào hồ sơ người dùng
  final result = await repo.uploadAvatar(
    file.bytes!,
    mime,
    customUrl: targetAvatarPath,
  );
  if (!context.mounted) return;
  if (result is ApiFailure<String>) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.error.message)),
    );
    return;
  }
  await auth.restoreSession();
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          cloudaryUrl != null
              ? 'Đã tải ảnh lên Cloudinary (folder ${CloudinaryConfig.folder}) thành công.'
              : 'Đã lưu ảnh đại diện thành công.',
        ),
        backgroundColor: const Color(0xFF10B981),
        action: cloudaryUrl == null
            ? SnackBarAction(
                label: 'Cấu hình Cloudinary',
                textColor: Colors.white,
                onPressed: () => showCloudinaryConfigDialog(context),
              )
            : null,
      ),
    );
  }
}
