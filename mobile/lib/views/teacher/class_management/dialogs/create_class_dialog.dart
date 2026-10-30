import 'package:flutter/material.dart';
import 'package:fapcheckin_core/repositories/schedule_repository.dart';
import '../../schedule/components/create_schedule_bottom_sheet.dart';

export '../../schedule/components/create_schedule_bottom_sheet.dart';

/// Hộp thoại Tạo lịch học bổ sung (tương thích ngược với các lệnh gọi CreateClassDialog)
class CreateClassDialog extends StatelessWidget {
  const CreateClassDialog({super.key, this.repository});
  final ScheduleRepository? repository;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: CreateScheduleBottomSheet(repository: repository),
        ),
      ),
    );
  }
}
