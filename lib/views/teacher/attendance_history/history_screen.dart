import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/history_download.dart';
import '../../../data/models/history_models.dart';
import '../../../data/repositories/history_repository.dart';
import '../../../viewmodels/history_viewmodel.dart';

class TeacherColors {
  static const primary = AppColors.primary;
  static const border = AppColors.border;
  static const cardBackground = AppColors.surface;
  static const textPrimary = AppColors.textPrimary;
  static const textSecondary = AppColors.textSecondary;
  static const absent = AppColors.statusAbsent;
  static const absentBg = AppColors.statusAbsentBg;
  static const present = AppColors.statusPresent;
  static const info = AppColors.statusManual;
  static const infoBg = AppColors.statusManualBg;
}

/// Nội dung tab "Lịch sử điểm danh" — bố cục master-detail kiểu web: danh
/// sách lớp cố định bên trái (~300px), chi tiết buổi học được chọn chiếm
/// phần còn lại bên phải. Đây là kiểu layout rất phổ biến cho desktop app
/// (email, quản lý đơn hàng...) vì tận dụng được chiều ngang màn hình lớn —
/// khác hẳn mobile phải tách thành 2 màn hình push/pop riêng.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.historyRepository});

  final HistoryRepository historyRepository;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HistoryViewModel>(
      create: (_) => HistoryViewModel(historyRepository)..loadClasses(),
      child: const _HistoryBody(),
    );
  }
}

class _HistoryBody extends StatelessWidget {
  const _HistoryBody();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 300, child: _ClassListPanel()),
        const VerticalDivider(width: 1, color: TeacherColors.border),
        const Expanded(child: _ClassDetailPanel()),
      ],
    );
  }
}

class _ClassListPanel extends StatelessWidget {
  const _ClassListPanel();

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryViewModel>(
      builder: (context, viewModel, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                'Lịch sử điểm danh',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            if (viewModel.state == HistoryViewState.loading &&
                viewModel.classes.isEmpty)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (viewModel.classes.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'Chưa có lớp nào.',
                    style: TextStyle(color: TeacherColors.textSecondary),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: viewModel.classes.length,
                  itemBuilder: (context, index) {
                    final classInfo = viewModel.classes[index];
                    final selected =
                        classInfo.classCode == viewModel.selectedClassCode;
                    return _ClassListTile(
                      classInfo: classInfo,
                      selected: selected,
                      onTap: () => viewModel.selectClass(classInfo.classCode),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ClassListTile extends StatelessWidget {
  const _ClassListTile({
    required this.classInfo,
    required this.selected,
    required this.onTap,
  });

  final ClassSummaryModel classInfo;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final attendancePercent = (classInfo.attendanceRate * 100).toStringAsFixed(
      0,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? TeacherColors.primary.withValues(alpha: 0.08)
            : TeacherColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? TeacherColors.primary : TeacherColors.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${classInfo.subjectCode} — ${classInfo.subjectName}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${classInfo.completedSessions}/${classInfo.totalSessions} buổi · Phòng ${classInfo.room}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: TeacherColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _MiniStat(
                      label: '$attendancePercent%',
                      color: classInfo.attendanceRate < 0.8
                          ? TeacherColors.absent
                          : TeacherColors.present,
                    ),
                    const SizedBox(width: 8),
                    if (classInfo.atRiskCount > 0)
                      _MiniStat(
                        label: '${classInfo.atRiskCount} SV nguy cơ',
                        color: TeacherColors.absent,
                        filled: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.color,
    this.filled = false,
  });

  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.12) : Colors.transparent,
        border: filled ? null : Border.all(color: color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _ClassDetailPanel extends StatelessWidget {
  const _ClassDetailPanel();

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.selectedClassCode == null) {
          return const Center(
            child: Text(
              'Chọn 1 lớp bên trái để xem lịch sử điểm danh.',
              style: TextStyle(color: TeacherColors.textSecondary),
            ),
          );
        }
        if (viewModel.state == HistoryViewState.loading &&
            viewModel.detail == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final detail = viewModel.detail;
        if (detail == null) {
          return Center(
            child: Text(viewModel.errorMessage ?? 'Không có dữ liệu.'),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailHeader(detail: detail, viewModel: viewModel),
              if (viewModel.errorMessage != null) ...[
                const SizedBox(height: 12),
                _ErrorBanner(message: viewModel.errorMessage!),
              ],
              const SizedBox(height: 16),
              Expanded(
                child: viewModel.showMatrix
                    ? _MatrixView(viewModel: viewModel)
                    : _StudentTable(detail: detail, viewModel: viewModel),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TeacherColors.absentBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            size: 18,
            color: TeacherColors.absent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: TeacherColors.absent, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.detail, required this.viewModel});

  final ClassHistoryDetailModel detail;
  final HistoryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '${detail.classInfo.subjectCode} — ${detail.classInfo.subjectName}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.grid_on_outlined, size: 16),
                  label: Text(
                    viewModel.showMatrix
                        ? 'Xem theo buổi'
                        : 'Ma trận điểm danh',
                  ),
                  onPressed: () => viewModel.toggleMatrix(),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.file_download_outlined, size: 16),
                  label: const Text('Xuất Excel'),
                  onPressed: viewModel.hasPendingChanges
                      ? null
                      : () => _handleExport(context, viewModel),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: const Text('Mở buổi mới'),
                  onPressed: viewModel.hasPendingChanges
                      ? null
                      : () => _showStartSessionDialog(
                          context,
                          viewModel,
                          detail.slots,
                        ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'GVGD: ${detail.teacherName} · ${detail.classInfo.room}',
          style: const TextStyle(color: TeacherColors.textSecondary),
        ),
        const SizedBox(height: 16),
        if (!viewModel.showMatrix)
          Row(
            children: [
              const Text(
                'Buổi học: ',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              DropdownButton<String>(
                value: detail.selectedSession?.sessionId,
                items: detail.sessions
                    .map(
                      (s) => DropdownMenuItem(
                        value: s.sessionId,
                        child: Text(
                          '${s.sessionDate} · ${s.slotCode} · ${s.isClosed ? "Đã kết thúc" : "Đang mở"}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (sessionId) {
                  if (sessionId != null) viewModel.selectSession(sessionId);
                },
              ),
              const Spacer(),
              if (viewModel.hasPendingChanges) ...[
                TextButton(
                  onPressed: viewModel.isSavingChanges
                      ? null
                      : () => viewModel.discardPendingChanges(),
                  child: const Text('Huỷ thay đổi'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: TeacherColors.primary,
                  ),
                  icon: viewModel.isSavingChanges
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined, size: 16),
                  label: const Text('Lưu thay đổi'),
                  onPressed: viewModel.isSavingChanges
                      ? null
                      : () => viewModel.savePendingChanges(),
                ),
              ],
            ],
          ),
      ],
    );
  }

  Future<void> _handleExport(
    BuildContext context,
    HistoryViewModel viewModel,
  ) async {
    final file = await viewModel.exportCurrentSession();
    if (file == null || file.base64.isEmpty) return;
    final message = await downloadHistory(
      file.filename,
      file.base64,
      file.mimeType,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _showStartSessionDialog(
    BuildContext context,
    HistoryViewModel viewModel,
    List<SlotModel> slots,
  ) async {
    String? selectedSlot = slots.isNotEmpty ? slots.first.slotCode : null;
    String teacherIp = '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Mở buổi học mới'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedSlot,
                decoration: const InputDecoration(labelText: 'Chọn ca học'),
                items: slots
                    .map(
                      (s) => DropdownMenuItem(
                        value: s.slotCode,
                        child: Text(
                          '${s.slotCode} (${s.startTime} - ${s.endTime})',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setDialogState(() => selectedSlot = value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'IP mạng giảng viên',
                  hintText: 'Ví dụ: 192.168.1.10',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => teacherIp = value.trim(),
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
              child: const Text('Mở buổi học'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && selectedSlot != null && teacherIp.isNotEmpty) {
      await viewModel.startNewSession(selectedSlot!, teacherIp);
    }
  }
}

class _StudentTable extends StatelessWidget {
  const _StudentTable({required this.detail, required this.viewModel});

  final ClassHistoryDetailModel detail;
  final HistoryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final students = viewModel.displayedStudents;

    return Container(
      decoration: BoxDecoration(
        color: TeacherColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TeacherColors.border),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text('MSSV', style: _headerStyle)),
                Expanded(flex: 3, child: Text('HỌ TÊN', style: _headerStyle)),
                Expanded(
                  flex: 2,
                  child: Text('TRẠNG THÁI', style: _headerStyle),
                ),
                Expanded(
                  flex: 2,
                  child: Text('GIỜ ĐIỂM DANH', style: _headerStyle),
                ),
                Expanded(flex: 3, child: Text('GHI CHÚ', style: _headerStyle)),
                Expanded(
                  flex: 2,
                  child: Text('SỐ BUỔI VẮNG', style: _headerStyle),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: TeacherColors.border),
          Expanded(
            child: ListView.separated(
              itemCount: students.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: TeacherColors.border),
              itemBuilder: (context, index) {
                final student = students[index];
                final edited =
                    viewModel.hasPendingChanges &&
                    student.status !=
                        detail.students
                            .firstWhere(
                              (s) => s.rollNumber == student.rollNumber,
                            )
                            .status;
                return _StudentRow(
                  student: student,
                  highlighted: edited,
                  viewModel: viewModel,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

const _headerStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w700,
  color: TeacherColors.textSecondary,
  letterSpacing: 0.4,
);

class _StudentRow extends StatelessWidget {
  const _StudentRow({
    required this.student,
    required this.highlighted,
    required this.viewModel,
  });

  final StudentHistoryModel student;
  final bool highlighted;
  final HistoryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: highlighted ? TeacherColors.infoBg.withValues(alpha: 0.4) : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              student.rollNumber,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(student.fullName, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 2,
            child: DropdownButton<String>(
              value: student.status,
              isDense: true,
              underline: const SizedBox.shrink(),
              items: kAllowedAttendanceStatuses
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(
                        attendanceStatusLabel(s),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: viewModel.detail?.selectedSession == null
                  ? null
                  : (value) {
                      if (value != null) {
                        viewModel.editStatus(student.rollNumber, value);
                      }
                    },
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              student.checkinTime.isEmpty ? '--:--' : student.checkinTime,
              style: const TextStyle(color: TeacherColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: student.note,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Ghi chú...',
              ),
              enabled: viewModel.detail?.selectedSession != null,
              onChanged: (value) =>
                  viewModel.editNote(student.rollNumber, value),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${student.absenceCount}/${student.totalSessions}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color:
                    student.totalSessions > 0 &&
                        student.absenceCount / student.totalSessions > 0.2
                    ? TeacherColors.absent
                    : TeacherColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ma trận điểm danh: mỗi hàng là 1 SV, mỗi cột là 1 buổi học — giống sổ
/// điểm danh giấy truyền thống, giúp GV nhìn ra nhanh SV nào vắng liên tục.
class _MatrixView extends StatelessWidget {
  const _MatrixView({required this.viewModel});

  final HistoryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoadingMatrix) {
      return const Center(child: CircularProgressIndicator());
    }
    final matrix = viewModel.matrix;
    if (matrix == null) {
      return const Center(child: Text('Không có dữ liệu ma trận.'));
    }

    return Container(
      decoration: BoxDecoration(
        color: TeacherColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TeacherColors.border),
      ),
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            const DataColumn(label: Text('MSSV')),
            const DataColumn(label: Text('Họ tên')),
            for (final session in matrix.sessions)
              DataColumn(label: Text(session.sessionDate)),
          ],
          rows: [
            for (final student in matrix.students)
              DataRow(
                cells: [
                  DataCell(Text(student.rollNumber)),
                  DataCell(Text(student.fullName)),
                  for (final status in student.statuses)
                    DataCell(_MatrixStatusDot(status: status)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _MatrixStatusDot extends StatelessWidget {
  const _MatrixStatusDot({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Present' || 'ManualByGV' => TeacherColors.present,
      'Late' => TeacherColors.info,
      'Absent' => TeacherColors.absent,
      _ => TeacherColors.textSecondary,
    };
    return Tooltip(
      message: attendanceStatusLabel(status),
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
