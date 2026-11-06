import 'feedback_history_modal_sheet.dart';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fapcheckin_core/repositories/account_features_repository.dart';
import 'package:fapcheckin_core/result/api_result.dart';
import '../../../core/widgets/app_toast.dart';

Future<T?> showFeedbackBottomSheet<T>(BuildContext context) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const FeedbackModalSheet(),
  );
}

class _AttachmentItem {
  final Uint8List bytes;
  final String name;
  final String mime;
  _AttachmentItem({required this.bytes, required this.name, required this.mime});
}

class _CategoryOption {
  final String id;
  final String title;
  final String? badge;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _CategoryOption({
    required this.id,
    required this.title,
    this.badge,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });
}

const List<_CategoryOption> _kCategoryOptions = [
  _CategoryOption(
    id: 'bug',
    title: 'Báo lỗi ứng dụng / Bug',
    badge: 'Mặc định',
    subtitle: 'Ứng dụng bị văng, hiển thị sai giao diện',
    icon: Icons.pest_control_outlined,
    iconColor: Color(0xFFEF4444),
    iconBg: Color(0xFFFEE2E2),
  ),
  _CategoryOption(
    id: 'qr_error',
    title: 'Lỗi quét mã QR điểm danh',
    subtitle: 'Camera không nhận QR, lỗi mạng khi check-in',
    icon: Icons.qr_code_scanner_rounded,
    iconColor: Color(0xFFD97706),
    iconBg: Color(0xFFFEF3C7),
  ),
  _CategoryOption(
    id: 'schedule_error',
    title: 'Sai lệch dữ liệu ca học / Lịch dạy',
    subtitle: 'Sai thời gian, thiếu danh sách sinh viên',
    icon: Icons.access_time_rounded,
    iconColor: Color(0xFF0284C7),
    iconBg: Color(0xFFE0F2FE),
  ),
  _CategoryOption(
    id: 'suggestion',
    title: 'Đề xuất tính năng mới',
    subtitle: 'Góp ý cải tiến quy trình điểm danh',
    icon: Icons.lightbulb_outline_rounded,
    iconColor: Color(0xFFEA580C),
    iconBg: Color(0xFFFFEDD5),
  ),
  _CategoryOption(
    id: 'other',
    title: 'Vấn đề khác / Trợ giúp',
    subtitle: 'Góp ý khác hoặc cần kỹ thuật viên hỗ trợ',
    icon: Icons.help_outline_rounded,
    iconColor: Color(0xFF9333EA),
    iconBg: Color(0xFFF3E8FF),
  ),
];

class FeedbackModalSheet extends StatefulWidget {
  const FeedbackModalSheet({super.key});

  @override
  State<FeedbackModalSheet> createState() => _FeedbackModalSheetState();
}

class _FeedbackModalSheetState extends State<FeedbackModalSheet> {
  final TextEditingController _textController = TextEditingController();
  final String _requestId = DateTime.now().microsecondsSinceEpoch.toString();
  final GlobalKey _categoryBoxKey = GlobalKey();
  final GlobalKey _sheetKey = GlobalKey();

  String _category = 'bug';
  bool _isMenuOpen = false;
  String? _error;
  bool _saving = false;
  final List<_AttachmentItem> _attachments = [];

  _CategoryOption get _selectedCategory => _kCategoryOptions.firstWhere(
        (o) => o.id == _category,
        orElse: () => _kCategoryOptions.first,
      );

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  double _getMenuTop() {
    try {
      final boxRender =
          _categoryBoxKey.currentContext?.findRenderObject() as RenderBox?;
      final sheetRender =
          _sheetKey.currentContext?.findRenderObject() as RenderBox?;
      if (boxRender != null && sheetRender != null) {
        final pos =
            boxRender.localToGlobal(Offset.zero, ancestor: sheetRender);
        return pos.dy + boxRender.size.height + 6.0;
      }
    } catch (_) {}
    return 185.0;
  }

  Future<void> _pickImages() async {
    if (_attachments.length >= 3) {
      showAppToast(
        context,
        message: 'Chỉ đính kèm tối đa 3 ảnh minh chứng.',
        type: AppToastType.warning,
      );
      return;
    }
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg'],
        allowMultiple: true,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      for (final file in result.files) {
        if (_attachments.length >= 3) break;
        Uint8List? bytes = file.bytes;
        if (bytes == null && !kIsWeb && file.path != null) {
          bytes = await io.File(file.path!).readAsBytes();
        }
        if (bytes != null) {
          final ext = (file.extension ?? 'jpg').toLowerCase();
          final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
          _attachments.add(
            _AttachmentItem(bytes: bytes, name: file.name, mime: mime),
          );
        }
      }
      setState(() {});
    } catch (e) {
      if (mounted) {
        showAppToast(
          context,
          message: 'Lỗi chọn ảnh: $e',
          type: AppToastType.error,
        );
      }
    }
  }

  Future<void> _send() async {
    if (_saving) return;
    final body = _textController.text.trim();
    if (body.isEmpty) {
      setState(() => _error = 'Vui lòng nhập nội dung góp ý.');
      return;
    }
    if (body.length > 2000) {
      setState(() => _error = 'Nội dung không được vượt quá 2000 ký tự.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final repo = context.read<AccountFeaturesRepository>();

    // 1. Upload attachments
    final List<String> uploadedUrls = [];
    for (final entry in _attachments.asMap().entries) {
      final att = entry.value;
      final uploadRes = await repo.uploadFeedbackAttachment(
        att.bytes,
        att.mime,
        requestId: _requestId,
        index: entry.key,
      );
      if (uploadRes is ApiSuccess<String>) {
        uploadedUrls.add(uploadRes.data);
      } else {
        if (mounted) {
          final message = (uploadRes as ApiFailure<String>).error.message;
          setState(() {
            _saving = false;
            _error = message;
          });
          showAppToast(
            context,
            message: message,
            type: AppToastType.error,
          );
        }
        return;
      }
    }

    // 2. Map category and prefix tag to ensure full backend/Firestore compatibility
    String categoryCode;
    String prefixTag = '';
    if (_category == 'bug') {
      categoryCode = 'bug';
    } else if (_category == 'qr_error') {
      categoryCode = 'bug';
      prefixTag = '[Lỗi quét mã QR điểm danh]\n';
    } else if (_category == 'schedule_error') {
      categoryCode = 'bug';
      prefixTag = '[Sai lệch dữ liệu ca học / Lịch dạy]\n';
    } else if (_category == 'suggestion') {
      categoryCode = 'suggestion';
    } else {
      categoryCode = 'other';
    }

    final fullMessage = '$prefixTag$body';

    // 3. Submit feedback
    final result = await repo.sendFeedback(
      categoryCode,
      fullMessage,
      requestId: _requestId,
      attachments: uploadedUrls,
    );

    if (!mounted) return;
    if (result is ApiSuccess<String>) {
      final toastContext = Navigator.of(context).context;
      Navigator.pop(context);
      showAppToast(
        toastContext,
        message: 'Cảm ơn bạn! Góp ý đã được gửi thành công.',
        type: AppToastType.success,
        actionLabel: 'Xem lịch sử',
        onAction: () => showFeedbackHistoryBottomSheet(toastContext),
      );
      return;
    }

    final message = (result as ApiFailure<String>).error.message;
    setState(() {
      _saving = false;
      _error = message;
    });
    showAppToast(context, message: message, type: AppToastType.error);
  }

  Widget _buildPopupMenuCard() {
    return Material(
      elevation: 10,
      shadowColor: const Color(0x33000000),
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top header inside popup card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'CHỌN LOẠI SỰ CỐ / YÊU CẦU',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.4,
                    ),
                  ),
                  Text(
                    '5 danh mục',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // 5 Category Items
            ..._kCategoryOptions.map((opt) {
              final isSelected = opt.id == _category;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _saving
                      ? null
                      : () {
                          setState(() {
                            _category = opt.id;
                            _isMenuOpen = false;
                          });
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFFF7ED)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: const Color(0xFFFDBA74), width: 1.2)
                          : null,
                    ),
                    child: Row(
                      children: [
                        // Colored icon box
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: opt.iconBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Icon(
                              opt.icon,
                              color: opt.iconColor,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Title + Badge + Subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    opt.title,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? const Color(0xFFFA5A1E)
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  if (opt.badge != null) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFA5A1E),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        opt.badge!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                opt.subtitle,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF64748B),
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Check circle icon if selected
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFFFA5A1E),
                            size: 22,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _sheetKey,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 1. Main Modal Content Form
            Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 8,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle pill
                    Center(
                      child: Container(
                        width: 42,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header Row: Orange dot, Title, Close icon
                    Row(
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFA5A1E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Góp ý / Feedback',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          splashRadius: 20,
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 22,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Subtitle
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'FAP Check-in luôn lắng nghe để cải thiện trải nghiệm điểm danh.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                              height: 1.35,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            showFeedbackHistoryBottomSheet(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFFEDD5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  'Lịch sử',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFEA580C),
                                  ),
                                ),
                                SizedBox(width: 2),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 14,
                                  color: Color(0xFFEA580C),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Category Section
                    const Text(
                      'Loại phản hồi / Category',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Category Trigger Box
                    InkWell(
                      key: _categoryBoxKey,
                      borderRadius: BorderRadius.circular(14),
                      onTap: _saving
                          ? null
                          : () => setState(() => _isMenuOpen = !_isMenuOpen),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _isMenuOpen
                                ? const Color(0xFFFA5A1E)
                                : const Color(0xFFE2E8F0),
                            width: _isMenuOpen ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Soft rounded icon box
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: _selectedCategory.iconBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Icon(
                                  _selectedCategory.icon,
                                  color: _selectedCategory.iconColor,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _selectedCategory.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            Icon(
                              _isMenuOpen
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: const Color(0xFF64748B),
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Message Textarea Section
                    Row(
                      children: [
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                            children: [
                              TextSpan(text: 'Nội dung / Message '),
                              TextSpan(
                                text: '*',
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _textController,
                          builder: (context, value, _) => Text(
                            '${value.text.length}/2000',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _textController,
                      enabled: !_saving,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      autocorrect: true,
                      enableSuggestions: true,
                      textInputAction: TextInputAction.newline,
                      maxLines: 4,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'Mô tả cụ thể sự cố (Mã môn, ca học, lỗi hiển thị...) để kỹ thuật viên hỗ trợ ngay...',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                          height: 1.45,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFFA5A1E),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Attachments Section
                    Row(
                      children: [
                        const Text(
                          'Ảnh minh chứng đính kèm (Tối đa 3 ảnh)',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _saving ? null : _pickImages,
                          child: const Text(
                            '+ Thêm ảnh',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFA5A1E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Camera button box
                        GestureDetector(
                          onTap: _saving ? null : _pickImages,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                                width: 1.2,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.camera_alt_outlined,
                                size: 22,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Placeholder or list of images
                        if (_attachments.isEmpty)
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                'Chưa có\nảnh',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF64748B),
                                  height: 1.2,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                        else
                          ..._attachments.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(11),
                                      child: Image.memory(
                                        item.bytes,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: -4,
                                    right: -4,
                                    child: GestureDetector(
                                      onTap: _saving
                                          ? null
                                          : () => setState(
                                                () => _attachments
                                                    .removeAt(index),
                                              ),
                                      child: Container(
                                        padding: const EdgeInsets.all(2.5),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF0F172A),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 11,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Bottom Actions: Đóng / Close & Gửi / Send
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _saving ? null : () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF475569),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: const Text('Đóng / Close'),
                        ),
                        ElevatedButton(
                          onPressed: _saving ? null : _send,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFA5A1E),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: const Color(0x66FA5A1E),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 26,
                              vertical: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.2,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Text(
                                      'Gửi / Send',
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Device Home bar indicator
                    Center(
                      child: Container(
                        width: 120,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),

            // 2. Floating Popup Menu Card when _isMenuOpen
            if (_isMenuOpen) ...[
              // Dismiss barrier when tapping outside
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => setState(() => _isMenuOpen = false),
                  child: const ColoredBox(color: Colors.transparent),
                ),
              ),

              // The Floating Popup Menu Card positioned directly below Category Box
              Positioned(
                left: 20,
                right: 20,
                top: _getMenuTop(),
                child: _buildPopupMenuCard(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
