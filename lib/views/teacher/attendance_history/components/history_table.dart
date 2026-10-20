import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../viewmodels/attendance_history_viewmodel.dart';
import '../../../../data/models/history_summary.dart';
import '../../../../core/constants/app_colors.dart';

class HistoryTable extends StatefulWidget {
  const HistoryTable({super.key});

  @override
  State<HistoryTable> createState() => _HistoryTableState();
}

class _HistoryTableState extends State<HistoryTable> {
  int _currentPage = 0;
  static const int _itemsPerPage = 10;
  String _prevClassCode = '';

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AttendanceHistoryViewModel>();
    final filteredStudents = vm.filteredStudents;
    final totalStudents = filteredStudents.length;
    final studentsCount = vm.students.length;

    final currentClass = vm.selectedClassCode ?? '';
    if (currentClass != _prevClassCode) {
      _currentPage = 0;
      _prevClassCode = currentClass;
    }

    final totalPages = (totalStudents / _itemsPerPage).ceil();
    if (_currentPage >= totalPages && totalPages > 0) {
      _currentPage = totalPages - 1;
    }

    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage > totalStudents)
        ? totalStudents
        : startIndex + _itemsPerPage;

    final paginatedStudents = totalStudents > 0
        ? filteredStudents.sublist(startIndex, endIndex)
        : <StudentSummary>[];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Tổng hợp điểm danh khóa học',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                _StudentCount(count: totalStudents),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          Padding(
            padding: EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 280,
                  child: TextFormField(
                    key: ValueKey(vm.selectedClassCode),
                    initialValue: vm.searchQuery,
                    onChanged: (val) {
                      setState(() => _currentPage = 0);
                      vm.setSearch(val);
                    },
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search, size: 20),
                      hintText: 'Tìm MSSV, họ tên, email',
                      isDense: true,
                    ),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: _RiskFilter(
                    value: vm.riskFilter,
                    studentsCount: studentsCount,
                    atRiskCount: vm.atRiskCount,
                    onChanged: (val) {
                      setState(() => _currentPage = 0);
                      vm.setRiskFilter(val);
                    },
                  ),
                ),
              ],
            ),
          ),
          if (filteredStudents.isEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 36),
              child: Center(
                child: Text(
                  'Không có sinh viên phù hợp.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final tableWidth = constraints.maxWidth < 860
                    ? 860.0
                    : constraints.maxWidth;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Table(
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      columnWidths: {
                        0: FixedColumnWidth(60), // STT
                        1: FixedColumnWidth(110), // MSSV
                        2: FlexColumnWidth(2.8), // HỌ VÀ TÊN
                        3: FixedColumnWidth(110), // CÓ MẶT
                        4: FixedColumnWidth(100), // ĐI TRỄ
                        5: FixedColumnWidth(140), // VẮNG
                        6: FixedColumnWidth(140), // TỔNG BUỔI
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                          ),
                          children: [
                            _headerCell('STT', center: true),
                            _headerCell('MSSV'),
                            _headerCell('HỌ VÀ TÊN'),
                            _headerCell('CÓ MẶT', center: true),
                            _headerCell('ĐI TRỄ', center: true),
                            _headerCell('VẮNG', center: true),
                            _headerCell('BUỔI ĐÃ KẾT THÚC', center: true),
                          ],
                        ),
                        ...paginatedStudents.asMap().entries.map((entry) {
                          final s = entry.value;
                          final idx = startIndex + entry.key + 1;
                          final isEven = entry.key.isEven;
                          return TableRow(
                            decoration: BoxDecoration(
                              color: isEven
                                  ? Colors.transparent
                                  : AppColors.surfaceContainerLowest.withValues(
                                      alpha: 0.5,
                                    ),
                              border: Border(
                                bottom: BorderSide(
                                  color: AppColors.border.withValues(
                                    alpha: 0.6,
                                  ),
                                  width: 0.6,
                                ),
                              ),
                            ),
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 14,
                                ),
                                child: Text(
                                  '$idx'.padLeft(2, '0'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 14,
                                ),
                                child: Text(
                                  s.rollNumber,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        _getInitials(
                                          s.fullName.isEmpty
                                              ? s.rollNumber
                                              : s.fullName,
                                        ),
                                        style: TextStyle(
                                          color: AppColors.primaryDark,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            s.fullName.isEmpty
                                                ? s.rollNumber
                                                : s.fullName,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            s.email,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 14,
                                ),
                                child: Text(
                                  '${s.presentCount}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppColors.statusPresent,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 14,
                                ),
                                child: Text(
                                  '${s.lateCount}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppColors.statusLate,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 14,
                                ),
                                child: Text(
                                  '${s.absentCount}/${s.closedSessions} (${(s.absenceRate * 100).toStringAsFixed(0)}%)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: s.absenceRate > .2
                                        ? AppColors.statusAbsent
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 14,
                                ),
                                child: Text(
                                  '${s.closedSessions}/${s.totalSessions}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
          if (totalPages > 1) ...[
            Divider(height: 1, color: AppColors.border),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _currentPage > 0
                        ? () => setState(() => _currentPage--)
                        : null,
                    icon: Icon(Icons.chevron_left),
                    tooltip: 'Trang trước',
                    color: AppColors.primaryContainer,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Trang ${_currentPage + 1} / $totalPages',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    onPressed: _currentPage < totalPages - 1
                        ? () => setState(() => _currentPage++)
                        : null,
                    icon: Icon(Icons.chevron_right),
                    tooltip: 'Trang tiếp',
                    color: AppColors.primaryContainer,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _headerCell(String label, {bool center = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      child: Text(
        label,
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  static String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length.clamp(0, 2)).toUpperCase();
    }
    return (parts[parts.length - 2][0] + parts[parts.length - 1][0])
        .toUpperCase();
  }
}

class _StudentCount extends StatelessWidget {
  const _StudentCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count sinh viên',
        style: TextStyle(
          color: AppColors.primaryDark,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RiskFilter extends StatelessWidget {
  const _RiskFilter({
    required this.value,
    required this.studentsCount,
    required this.atRiskCount,
    required this.onChanged,
  });

  final String value;
  final int studentsCount;
  final int atRiskCount;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      onChanged: (risk) {
        if (risk != null) onChanged(risk);
      },
      decoration: InputDecoration(
        labelText: 'Lọc',
        prefixIcon: Icon(Icons.filter_list),
        isDense: true,
      ),
      items: [
        DropdownMenuItem(
          value: 'all',
          child: Text(
            'Tất cả ($studentsCount)',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DropdownMenuItem(
          value: 'atRisk',
          child: Text(
            'Vắng >20% ($atRiskCount)',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
