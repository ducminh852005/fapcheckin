import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/api_service.dart';
import '../../../../data/models/history_class.dart';
import '../../../../data/models/history_detail.dart';
import '../../../../data/models/history_student.dart';
import '../../../../data/repositories/attendance_history_repository.dart';
import '../../../../viewmodels/auth_viewmodel.dart';

typedef _WarningRows = List<({String classCode, HistoryStudent student})>;

class WarningTable extends StatefulWidget {
  const WarningTable({super.key});

  @override
  State<WarningTable> createState() => _WarningTableState();
}

class _WarningTableState extends State<WarningTable> {
  String? _account;
  Future<ApiResult<_WarningRows>>? _request;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final account = context.watch<AuthViewModel>().session?.token;
    if (_account != account) {
      _account = account;
      _request = account == null ? null : _load();
    }
  }

  Future<ApiResult<_WarningRows>> _load() async {
    final repository = AttendanceHistoryRepository(context.read<ApiService>());
    final classes = await repository.getClasses();
    if (classes is ApiFailure<List<HistoryClass>>) {
      return ApiFailure(classes.error);
    }
    final warnings = <({String classCode, HistoryStudent student})>[];
    for (final cls in (classes as ApiSuccess<List<HistoryClass>>).data) {
      final detail = await repository.getDetail(cls.classCode);
      if (detail is ApiFailure<HistoryDetail>) {
        return ApiFailure(detail.error);
      }
      for (final student
          in (detail as ApiSuccess<HistoryDetail>).data.students) {
        if (student.totalSessions > 0 && student.absenceRate > 0.15) {
          warnings.add((classCode: cls.classCode, student: student));
        }
      }
    }
    warnings.sort(
      (a, b) => b.student.absenceRate.compareTo(a.student.absenceRate),
    );
    return ApiSuccess(warnings);
  }

  void _refresh() {
    setState(() {
      _request = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Cảnh báo vắng học',
                  style: AppTextStyles.headlineSm,
                ),
              ),
              IconButton(
                tooltip: 'Tải lại từ Google Sheet',
                onPressed: _account == null ? null : _refresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          Text(
            'Sinh viên vắng >15% số buổi đã đóng. Cảnh báo không phải quyết định cấm thi.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.md),
          if (_account == null)
            const Text('Vui lòng đăng nhập để tải dữ liệu sinh viên.')
          else
            FutureBuilder<ApiResult<_WarningRows>>(
              // Drop the previous account/request snapshot immediately.
              key: ObjectKey(_request),
              future: _request,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final result = snapshot.data;
                if (snapshot.hasError || result is ApiFailure<_WarningRows>) {
                  final message = result is ApiFailure<_WarningRows>
                      ? result.error.message
                      : snapshot.error.toString();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Không tải được danh sách sinh viên: $message'),
                      TextButton(
                        onPressed: _refresh,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  );
                }
                final rows = result is ApiSuccess<_WarningRows>
                    ? result.data
                    : <({String classCode, HistoryStudent student})>[];
                if (rows.isEmpty) {
                  return const Text(
                    'Chưa có sinh viên vượt ngưỡng cảnh báo trong dữ liệu hiện có.',
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${rows.map((r) => r.student.rollNumber).toSet().length} sinh viên • ${rows.length} lượt theo lớp',
                      style: AppTextStyles.caption,
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Sinh viên')),
                          DataColumn(label: Text('Lớp')),
                          DataColumn(label: Text('Vắng')),
                          DataColumn(label: Text('Cảnh báo')),
                        ],
                        rows: rows.map((row) {
                          final student = row.student;
                          return DataRow(
                            cells: [
                              DataCell(
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student.fullName.isEmpty
                                          ? student.rollNumber
                                          : student.fullName,
                                    ),
                                    Text(
                                      student.rollNumber,
                                      style: AppTextStyles.caption,
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(Text(row.classCode)),
                              DataCell(
                                Text(
                                  '${student.absenceCount}/${student.totalSessions} (${(student.absenceRate * 100).toStringAsFixed(1)}%)',
                                ),
                              ),
                              DataCell(
                                Text(
                                  student.absenceRate > 0.20
                                      ? 'Vượt 20%'
                                      : 'Vượt 15%',
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
