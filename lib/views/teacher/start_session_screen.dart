import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../data/models/class_model.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../viewmodels/teacher_session_viewmodel.dart';
import 'class_stats_screen.dart';
import 'live_roster_screen.dart';

/// Màn hình "Bắt đầu điểm danh": hiện mã QR xoay vòng mỗi 20 giây.
///
/// Toàn bộ logic (mở phiên, xoay QR) nằm ở [TeacherSessionViewModel] — màn
/// hình này chỉ lắng nghe và "vẽ lại" mỗi khi ViewModel gọi
/// `notifyListeners()`. Đây là điểm cốt lõi của MVVM: nếu sau này bạn muốn
/// đổi giao diện QR, chỉ sửa file này; nếu muốn đổi logic xoay QR, chỉ sửa
/// ViewModel — hai việc không đụng chạm nhau.
class StartSessionScreen extends StatelessWidget {
  const StartSessionScreen({
    super.key,
    required this.classModel,
    this.attendanceRepository,
  });

  final ClassModel classModel;

  /// TODO(Nền tảng): trong main.dart thật của app, Repository nên được cấp
  /// dùng chung cho toàn app qua MultiProvider ở gốc cây widget, thay vì tạo
  /// mới ở từng màn hình. Cho phép truyền vào đây để bạn test/demo màn hình
  /// này độc lập trong lúc chưa ráp xong toàn bộ app.
  final AttendanceRepository? attendanceRepository;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TeacherSessionViewModel>(
      // Gọi startSession() ngay khi ViewModel được tạo — nhờ vậy khi màn
      // hình build lần đầu, phiên điểm danh đã bắt đầu được mở.
      create: (_) => TeacherSessionViewModel(
        attendanceRepository: attendanceRepository ?? MockAttendanceRepository(),
      )..startSession(classModel),
      child: _StartSessionView(classModel: classModel),
    );
  }
}

class _StartSessionView extends StatelessWidget {
  const _StartSessionView({required this.classModel});

  final ClassModel classModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Điểm danh · ${classModel.className}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Thống kê chuyên cần',
            onPressed: () {
              final viewModel = context.read<TeacherSessionViewModel>();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: viewModel,
                    child: ClassStatsScreen(
                      classId: classModel.classId,
                      className: classModel.className,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<TeacherSessionViewModel>(
        builder: (context, viewModel, _) {
          switch (viewModel.state) {
            case ViewState.loading:
            case ViewState.idle:
              return const Center(child: CircularProgressIndicator());
            case ViewState.error:
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    viewModel.errorMessage ?? 'Đã có lỗi xảy ra.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            case ViewState.ready:
              return _buildReadyContent(context, viewModel);
          }
        },
      ),
    );
  }

  Widget _buildReadyContent(BuildContext context, TeacherSessionViewModel viewModel) {
    final qrPayload = viewModel.qrPayload;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Sinh viên quét mã bằng camera điện thoại',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (qrPayload != null)
            // QrImageView nằm trong Consumer nên tự build lại mỗi khi
            // viewModel.qrPayload đổi (sau mỗi 20s) — không cần code thêm
            // gì để "làm mới" hình QR, Flutter tự lo phần vẽ lại.
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: qrPayload,
                size: 240,
                backgroundColor: Colors.white,
              ),
            ),
          const SizedBox(height: 12),
          Text('Mã mới sau: ${viewModel.secondsUntilNextRotation}s'),
          const SizedBox(height: 32),
          FilledButton.icon(
            icon: const Icon(Icons.groups),
            label: Text('Xem danh sách điểm danh (${viewModel.roster.length})'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                // Dùng ChangeNotifierProvider.value (KHÔNG phải .create) để
                // truyền CÙNG MỘT instance ViewModel sang màn hình sau. Nếu
                // dùng .create ở đây, Flutter sẽ tạo 1 ViewModel MỚI — mất
                // hết phiên đang mở, timer QR/roster hiện tại cũng dừng lại.
                builder: (_) => ChangeNotifierProvider.value(
                  value: viewModel,
                  child: const LiveRosterScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('Kết thúc buổi học'),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Kết thúc buổi học?'),
                  content: const Text(
                    'Sinh viên chưa điểm danh sẽ được ghi nhận là Vắng.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: const Text('Huỷ'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: const Text('Kết thúc'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await viewModel.closeSession();
                if (context.mounted) Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }
}
