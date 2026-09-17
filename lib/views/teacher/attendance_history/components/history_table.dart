import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/data/models/history_student.dart';
import 'package:fapcheckin/data/models/student_checkin.dart';
import 'package:fapcheckin/viewmodels/attendance_history_viewmodel.dart';

class HistoryTable extends StatelessWidget {
  const HistoryTable({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AttendanceHistoryViewModel>();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Toolbar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Flex(
              direction: Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('Danh sách sinh viên điểm danh', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    Text('(Buổi 12 - 24/10/2023)', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    // Status Filter
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: vm.statusFilter,
                          icon: const Icon(Icons.expand_more, size: 16),
                          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                          onChanged: (val) => vm.setStatusFilter(val ?? 'all'),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('Tất cả trạng thái (35)')),
                            DropdownMenuItem(value: 'present', child: Text('Có mặt (30)')),
                            DropdownMenuItem(value: 'late', child: Text('Đi trễ (3)')),
                            DropdownMenuItem(value: 'absent', child: Text('Vắng mặt (2)')),
                          ],
                        ),
                      ),
                    ),
                    // Save Button
                    ElevatedButton.icon(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: AppColors.onPrimary,
                        elevation: 0,
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.save, size: 16),
                      label: const Text('Lưu thay đổi thủ công', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Table Data
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 500),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppColors.surfaceMuted),
                dataRowMinHeight: 64,
                dataRowMaxHeight: 64,
                horizontalMargin: 24,
                columnSpacing: 24,
                headingTextStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
                columns: const [
                  DataColumn(label: Text('STT', textAlign: TextAlign.center)),
                  DataColumn(label: Text('MSSV')),
                  DataColumn(label: Text('HỌ VÀ TÊN')),
                  DataColumn(label: Text('THỜI GIAN QUÉT')),
                  DataColumn(label: Text('PHƯƠNG THỨC')),
                  DataColumn(label: Text('TRẠNG THÁI BUỔI')),
                  DataColumn(label: Text('TỶ LỆ VẮNG LŨY KẾ')),
                  DataColumn(label: Text('THAO TÁC')),
                ],
                rows: vm.filteredStudents.map((s) => _buildDataRow(s)).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(HistoryStudent student) {
    Color? rowBg;
    if (student.status == CheckinStatus.absent) {
      rowBg = AppColors.statusAbsentBg.withValues(alpha: 0.3);
    }

    return DataRow(
      color: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return AppColors.surfaceContainerLow;
        }
        return rowBg ?? Colors.transparent;
      }),
      cells: [
        DataCell(
          Center(
            child: Text(
              student.index.toString().padLeft(2, '0'),
              style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, color: AppColors.textTertiary),
            ),
          ),
        ),
        DataCell(
          Text(
            student.studentId,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: student.status == CheckinStatus.absent ? AppColors.statusAbsent : AppColors.primaryDark,
            ),
          ),
        ),
        DataCell(
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _getAvatarBg(student),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  student.initials,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getAvatarText(student),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(student.fullName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  Text(student.email, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                ],
              ),
            ],
          ),
        ),
        DataCell(
          Text(
            student.checkInTime,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 12,
              fontWeight: student.status == CheckinStatus.late ? FontWeight.bold : FontWeight.normal,
              color: student.status == CheckinStatus.late ? AppColors.statusLate : AppColors.textSecondary,
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: student.methodLabel == 'Điểm danh bù bởi GV' ? AppColors.statusManualBg : AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getIconData(student.methodIcon),
                  size: 14,
                  color: student.methodLabel == 'Điểm danh bù bởi GV' ? AppColors.statusManual : AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  student.methodLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: student.methodLabel == 'Điểm danh bù bởi GV' ? AppColors.statusManual : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusBg(student.status, student.methodLabel),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _getStatusText(student.status, student.methodLabel),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  student.lateLabel ?? _getStatusLabel(student.status, student.methodLabel),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusText(student.status, student.methodLabel),
                  ),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          Container(
            padding: student.absenceStatusText == 'Nguy cơ' ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2) : null,
            decoration: student.absenceStatusText == 'Nguy cơ'
                ? BoxDecoration(
                    color: AppColors.statusAbsentBg,
                    borderRadius: BorderRadius.circular(4),
                  )
                : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (student.absenceStatusText == 'Nguy cơ') ...[
                  const Icon(Icons.error, size: 14, color: AppColors.statusAbsent),
                  const SizedBox(width: 4),
                ],
                Text(
                  '${student.absenceCount}/${student.totalSessions} (${(student.absenceRate * 100).toStringAsFixed(0)}%)',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: student.absenceStatusText == 'Nguy cơ'
                        ? AppColors.statusAbsent
                        : student.absenceStatusText == 'Tuyệt đối' ? AppColors.statusPresent : AppColors.textPrimary,
                  ),
                ),
                if (student.absenceStatusText != 'Nguy cơ') ...[
                  const SizedBox(width: 6),
                  Text(
                    student.absenceStatusText,
                    style: TextStyle(
                      fontSize: 12,
                      color: student.absenceStatusText == 'Tuyệt đối' ? AppColors.statusPresent : AppColors.textTertiary,
                    ),
                  ),
                ] else ...[
                  const Text(' - Nguy cơ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.statusAbsent)),
                ]
              ],
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_note, size: 18),
                color: AppColors.textSecondary,
                onPressed: () {},
                tooltip: 'Chỉnh sửa trạng thái',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                icon: const Icon(Icons.comment, size: 18),
                color: AppColors.textSecondary,
                onPressed: () {},
                tooltip: 'Ghi chú sinh viên',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getAvatarBg(HistoryStudent s) {
    if (s.status == CheckinStatus.absent) return AppColors.statusAbsentBg;
    if (s.index % 2 == 0) return AppColors.secondaryContainer;
    return AppColors.primaryLight;
  }

  Color _getAvatarText(HistoryStudent s) {
    if (s.status == CheckinStatus.absent) return AppColors.statusAbsent;
    if (s.index % 2 == 0) return AppColors.onSecondaryContainer;
    return AppColors.primaryDark;
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'qr_code_2': return Icons.qr_code_2;
      case 'how_to_reg': return Icons.how_to_reg;
      case 'block': return Icons.block;
      case 'mail': return Icons.mail;
      default: return Icons.check;
    }
  }

  Color _getStatusBg(CheckinStatus s, String method) {
    if (method == 'Đơn phép qua FAP') return AppColors.statusManualBg;
    switch (s) {
      case CheckinStatus.present: return AppColors.statusPresentBg;
      case CheckinStatus.late: return AppColors.statusLateBg;
      case CheckinStatus.absent: return AppColors.statusAbsentBg;
      case CheckinStatus.unchecked: return AppColors.statusUncheckedBg;
    }
  }

  Color _getStatusText(CheckinStatus s, String method) {
    if (method == 'Đơn phép qua FAP') return AppColors.statusManual;
    switch (s) {
      case CheckinStatus.present: return AppColors.statusPresent;
      case CheckinStatus.late: return AppColors.statusLate;
      case CheckinStatus.absent: return AppColors.statusAbsent;
      case CheckinStatus.unchecked: return AppColors.statusUnchecked;
    }
  }

  String _getStatusLabel(CheckinStatus s, String method) {
    if (method == 'Đơn phép qua FAP') return 'Vắng có phép';
    switch (s) {
      case CheckinStatus.present: return 'Có mặt';
      case CheckinStatus.late: return 'Đi trễ';
      case CheckinStatus.absent: return 'Vắng mặt';
      case CheckinStatus.unchecked: return 'Chưa điểm danh';
    }
  }
}
