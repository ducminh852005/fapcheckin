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
              CheckboxListTile(
                key: Key('ip-check-toggle'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: ipCheck,
                onChanged: (value) => setState(() => ipCheck = value ?? false),
                title: Text('Kiểm tra IP mạng (tùy chọn)'),
                subtitle: Text(
                  'Bật: sinh viên phải dùng cùng mạng Wi-Fi (cùng IP công khai) '
                  'với giảng viên mới điểm danh được. '
                  'Tắt: sinh viên quét QR ở bất kỳ mạng nào.',
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

  await liveVm.startSession(
    classSection: classSection,
    slotCode: slotCode,
    ipCheck: ipCheck,
  );
  return true;
}
