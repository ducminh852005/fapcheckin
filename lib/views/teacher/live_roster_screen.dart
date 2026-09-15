import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/attendance_model.dart';
import '../../viewmodels/teacher_session_viewmodel.dart';

/// Danh sách "đã điểm danh" cập nhật dần khi sinh viên quét QR.
///
/// Màn hình này KHÔNG tự gọi API và không có nút "làm mới" — vì
/// [TeacherSessionViewModel] đã tự polling ở dưới nền (xem
/// `_startRosterPolling` trong ViewModel). Ở đây chỉ cần "lắng nghe"
/// (watch) `viewModel.roster`; mỗi lần danh sách đổi, Consumer tự build lại.
class LiveRosterScreen extends StatelessWidget {
  const LiveRosterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách điểm danh')),
      body: Consumer<TeacherSessionViewModel>(
        builder: (context, viewModel, _) {
          final roster = viewModel.roster;

          if (roster.isEmpty) {
            return const Center(child: Text('Chưa có sinh viên nào điểm danh.'));
          }

          return ListView.builder(
            itemCount: roster.length,
            itemBuilder: (context, index) {
              final entry = roster[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: entry.method == CheckinMethod.manual
                      ? Colors.orange.shade100
                      : Colors.green.shade100,
                  child: Icon(
                    entry.method == CheckinMethod.manual ? Icons.edit_note : Icons.qr_code_2,
                    size: 18,
                  ),
                ),
                title: Text(entry.studentName ?? entry.studentId),
                subtitle: Text(
                  '${entry.status.label}'
                  '${entry.studentIp != null && !entry.ipMatch ? " · ⚠️ IP không khớp mạng trường" : ""}',
                ),
                trailing: entry.checkinTime != null ? Text(_formatTime(entry.checkinTime!)) : null,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.edit_note),
        label: const Text('Điểm danh tay'),
        onPressed: () => _showManualCheckInDialog(context),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  /// Điểm danh tay dự phòng (ưu tiên "PHẢI CÓ" theo tài liệu kiến trúc) —
  /// dùng khi trang web check-in của SV bị lỗi hoặc SV không mang điện thoại.
  Future<void> _showManualCheckInDialog(BuildContext context) async {
    // Lấy viewModel bằng context.read() (không phải context.watch()) vì ta
    // chỉ cần GỌI method một lần khi bấm nút, không cần màn hình này rebuild
    // mỗi khi ViewModel đổi trạng thái.
    final viewModel = context.read<TeacherSessionViewModel>();
    final studentIdController = TextEditingController();
    final studentNameController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Điểm danh tay'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: studentIdController,
              decoration: const InputDecoration(labelText: 'Mã số sinh viên'),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: studentNameController,
              decoration: const InputDecoration(labelText: 'Họ tên'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed == true && studentIdController.text.trim().isNotEmpty) {
      await viewModel.manualCheckIn(
        studentId: studentIdController.text.trim(),
        studentName: studentNameController.text.trim(),
      );
    }

    studentIdController.dispose();
    studentNameController.dispose();
  }
}
