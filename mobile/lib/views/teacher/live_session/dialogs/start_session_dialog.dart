import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fapcheckin_core/constants/app_colors.dart';
import 'package:fapcheckin_core/constants/app_text_styles.dart';
import 'package:fapcheckin_core/models/class_section_model.dart';

import '../../../../viewmodels/live_session_viewmodel.dart';

/// Asks how the attendance session should be opened.
///
/// Returns `null` when the teacher cancels, otherwise whether the (optional)
/// IP check is on. It starts as [initialIpCheck] (Remote Config `ip_check_default`,
/// off unless configured) and the teacher can change it.
Future<bool?> showStartSessionDialog(
  BuildContext context,
  ClassSectionModel classSection, {
  bool initialIpCheck = false,
}) {
  var ipCheck = initialIpCheck;
  return showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        scrollable: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Mở phiên điểm danh',
          style: AppTextStyles.headlineSm.copyWith(fontWeight: FontWeight.w800),
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${classSection.classCode} · ${classSection.subjectName}',
                style: AppTextStyles.labelMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 12),
              Semantics(
                label: 'Kiểm tra IP mạng',
                hint: 'Yêu cầu sinh viên dùng cùng mạng Wi-Fi với giảng viên',
                toggled: ipCheck,
                child: CheckboxListTile(
                  key: Key('ip-check-toggle'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: ipCheck,
                  onChanged: (value) =>
                      setState(() => ipCheck = value ?? false),
                  title: Text('Kiểm tra IP mạng (tùy chọn)'),
                  subtitle: Text(
                    'Bật: sinh viên phải dùng cùng mạng Wi-Fi (cùng IP công khai) '
                    'với giảng viên mới điểm danh được. '
                    'Tắt: sinh viên quét QR ở bất kỳ mạng nào.',
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ipCheck),
            child: Text('Mở phiên'),
          ),
        ],
      ),
    ),
  );
}

/// Opens (or resumes) an attendance session for [classSection].
///
/// A class that already has an open session is resumed as it is (its IP-check
/// setting is kept). Otherwise the teacher is asked first. Returns `false`
/// when the teacher cancelled the dialog.
Future<bool> startSessionWithOptions(
  BuildContext context, {
  required ClassSectionModel classSection,
  required String slotCode,
}) async {
  final liveVm = context.read<LiveSessionViewModel>();
  if (liveVm.session?.isOpen == true &&
      liveVm.session!.classCode != classSection.classCode) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hãy đóng phiên đang mở trước khi chuyển sang lớp khác.'),
      ),
    );
    return false;
  }
  final resuming =
      classSection.isActive &&
      (classSection.activeSessionId?.isNotEmpty ?? false);

  var ipCheck = false;
  if (!resuming) {
    final choice = await showStartSessionDialog(
      context,
      classSection,
      initialIpCheck: liveVm.ipCheckDefault,
    );
    if (choice == null) return false;
    ipCheck = choice;
  }

  if (!context.mounted) return false;

  // Hiển thị modal loading để người dùng biết hệ thống đang kết nối và mở phiên
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              SizedBox(width: 16),
              Text(
                'Đang mở phiên điểm danh...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  try {
    await liveVm.startSession(
      classSection: classSection,
      slotCode: slotCode,
      ipCheck: ipCheck,
    );
  } finally {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  final ok = liveVm.session?.isOpen == true && liveVm.errorMessage == null;
  if (!ok && context.mounted) {
    final msg = liveVm.errorMessage ??
        'Không thể mở phiên điểm danh. Vui lòng kiểm tra lại kết nối mạng hoặc thử lại.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  return ok;
}
