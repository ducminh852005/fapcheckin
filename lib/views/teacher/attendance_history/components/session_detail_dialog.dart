import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_result.dart';
import '../../../../data/models/session_model.dart';
import '../../../../data/models/history_detail.dart';
import '../../../../data/models/history_student.dart';
import '../../../../viewmodels/attendance_history_viewmodel.dart';

class SessionDetailDialog extends StatefulWidget {
  final SessionModel session;

  const SessionDetailDialog({super.key, required this.session});

  @override
  State<SessionDetailDialog> createState() => _SessionDetailDialogState();
}

class _SessionDetailDialogState extends State<SessionDetailDialog> {
  bool _loading = true;
  String? _error;
  HistoryDetail? _detail;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final vm = context.read<AttendanceHistoryViewModel>();
      final classCode = vm.selectedClassCode;
      if (classCode == null) {
        setState(() {
          _error = 'Không xác định được mã lớp.';
          _loading = false;
        });
        return;
      }
      final result = await vm.repository.getDetail(
        classCode,
        sessionId: widget.session.sessionId,
      );
      if (!mounted) return;
      switch (result) {
        case ApiSuccess<HistoryDetail>(:final data):
          setState(() {
            _detail = data;
            _loading = false;
          });
        case ApiFailure<HistoryDetail>(:final error):
          setState(() {
            _error = error.message;
            _loading = false;
          });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = _formatDate(widget.session.sessionDate);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 700),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Dialog Header ---
            _buildHeader(dateStr, context),

            const Divider(height: 1, color: AppColors.border),

            // --- Content ---
            if (_loading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              )
            else if (_error != null)
              Expanded(child: _buildError())
            else if (_detail != null)
              Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String dateStr, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.event_note_outlined,
              color: AppColors.primaryDark,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chi tiết buổi học — $dateStr',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Ca ${widget.session.slotCode}  ·  ${_statusLabel()}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 20),
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppColors.statusAbsent),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Đã xảy ra lỗi',
              style: const TextStyle(color: AppColors.statusAbsent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadDetail,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final detail = _detail!;
    final students = detail.students;

    // Filter by search
    final filtered = _search.trim().isEmpty
        ? students
        : students.where((s) {
            final q = _search.trim().toLowerCase();
            return s.rollNumber.toLowerCase().contains(q) ||
                s.fullName.toLowerCase().contains(q) ||
                s.email.toLowerCase().contains(q);
          }).toList();

    // Stats
    final presentCount = students.where((s) => s.status == 'Present' || s.status == 'ManualByGV').length;
    final lateCount = students.where((s) => s.status == 'Late').length;
    final absentCount = students.where((s) => s.status == 'Absent').length;
    final uncheckedCount = students.where((s) => s.status == 'Unchecked').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Stats row
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatChip(
                label: 'Có mặt',
                count: presentCount,
                color: AppColors.statusPresent,
                bg: AppColors.statusPresentBg,
              ),
              _StatChip(
                label: 'Đi trễ',
                count: lateCount,
                color: AppColors.statusLate,
                bg: AppColors.statusLateBg,
              ),
              _StatChip(
                label: 'Vắng',
                count: absentCount,
                color: AppColors.statusAbsent,
                bg: AppColors.statusAbsentBg,
              ),
              _StatChip(
                label: 'Chưa điểm danh',
                count: uncheckedCount,
                color: AppColors.textSecondary,
                bg: AppColors.surfaceContainerLow,
              ),
              const SizedBox(width: 8),
              // Total
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Tổng: ${students.length} sinh viên',
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
          child: SizedBox(
            width: 300,
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, size: 18),
                hintText: 'Tìm MSSV, họ tên...',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        const Divider(height: 1, color: AppColors.border),

        // Table header
        Container(
          color: AppColors.surfaceContainerLow,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: const Row(
            children: [
              SizedBox(width: 36, child: _HeaderCell('STT', center: true)),
              SizedBox(width: 12),
              SizedBox(width: 100, child: _HeaderCell('MSSV')),
              SizedBox(width: 12),
              Expanded(child: _HeaderCell('HỌ VÀ TÊN')),
              SizedBox(width: 12),
              SizedBox(width: 110, child: _HeaderCell('TRẠNG THÁI')),
              SizedBox(width: 12),
              SizedBox(width: 80, child: _HeaderCell('GIỜ CHECKIN')),
              SizedBox(width: 12),
              SizedBox(width: 100, child: _HeaderCell('PHƯƠNG THỨC')),
            ],
          ),
        ),

        // Table rows
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text(
                    'Không tìm thấy sinh viên phù hợp.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: filtered.length,
                  separatorBuilder: (context, idx) =>
                      const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (context, i) {
                    final s = filtered[i];
                    return _StudentRow(student: s, index: i + 1);
                  },
                ),
        ),
      ],
    );
  }

  String _statusLabel() {
    switch (widget.session.sessionStatus) {
      case 'open':
        return 'Đang mở';
      case 'closed':
        return 'Đã kết thúc';
      case 'planned':
        return 'Dự kiến';
      default:
        return widget.session.sessionStatus;
    }
  }

  String _formatDate(String value) {
    if (value.isEmpty) return '—';
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return value;
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(date.day)}/${pad(date.month)}/${date.year}';
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final Color bg;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $count',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final bool center;
  const _HeaderCell(this.text, {this.center = false});

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      );
}

class _StudentRow extends StatelessWidget {
  final HistoryStudent student;
  final int index;

  const _StudentRow({required this.student, required this.index});

  Color get _statusColor {
    switch (student.status) {
      case 'Present':
      case 'ManualByGV':
        return AppColors.statusPresent;
      case 'Late':
        return AppColors.statusLate;
      case 'Absent':
        return AppColors.statusAbsent;
      default:
        return AppColors.textSecondary;
    }
  }

  Color get _statusBg {
    switch (student.status) {
      case 'Present':
      case 'ManualByGV':
        return AppColors.statusPresentBg;
      case 'Late':
        return AppColors.statusLateBg;
      case 'Absent':
        return AppColors.statusAbsentBg;
      default:
        return AppColors.surfaceContainerLow;
    }
  }

  String get _statusLabel => attendanceStatusLabels[student.status] ?? student.status;

  String _shortTime(String value) {
    if (value.isEmpty) return '—';
    final d = DateTime.tryParse(value)?.toLocal();
    if (d == null) return value;
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(d.hour)}:${pad(d.minute)}';
  }

  String _methodLabel(String method) {
    if (method.isEmpty) return '—';
    if (method.toLowerCase().contains('pass')) return 'QR';
    if (method.toLowerCase().contains('fail')) return 'QR (lỗi IP)';
    if (method.toLowerCase() == 'manualbygv') return 'GV xác nhận';
    return method;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: index.isEven
          ? AppColors.surfaceContainerLowest.withValues(alpha: 0.5)
          : Colors.transparent,
      child: Row(
        children: [
          // STT
          SizedBox(
            width: 36,
            child: Text(
              index.toString().padLeft(2, '0'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // MSSV
          SizedBox(
            width: 100,
            child: Text(
              student.rollNumber,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Họ tên + email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.fullName.isEmpty ? student.rollNumber : student.fullName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (student.email.isNotEmpty)
                  Text(
                    student.email,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Status badge
          SizedBox(
            width: 110,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _statusColor.withValues(alpha: 0.25)),
              ),
              child: Text(
                _statusLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Check-in time
          SizedBox(
            width: 80,
            child: Text(
              _shortTime(student.checkinTime),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Method
          SizedBox(
            width: 100,
            child: Text(
              _methodLabel(student.method),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
