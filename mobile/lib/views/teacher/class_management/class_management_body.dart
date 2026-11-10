import 'package:fapcheckin_core/models/class_section_model.dart';
import 'package:fapcheckin_core/responsive/breakpoints.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../viewmodels/attendance_history_viewmodel.dart';
import '../../../viewmodels/dashboard_viewmodel.dart';
import 'class_management_colors.dart';
import 'components/class_item_card.dart';
import 'components/class_management_header.dart';
import 'components/class_search_bar.dart';
import 'components/class_summary_banner.dart';

/// Danh sách toàn bộ môn/lớp mà giảng viên phụ trách. Slot và giờ học thuộc
/// màn Lịch dạy; từ đây giảng viên chọn môn để xem điểm danh từng buổi.
class ClassManagementBody extends StatefulWidget {
  const ClassManagementBody({super.key});

  @override
  State<ClassManagementBody> createState() => _ClassManagementBodyState();
}

class _ClassManagementBodyState extends State<ClassManagementBody> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _sortAscending = true;

  Future<void> _openHistory(String classCode) async {
    final history = context.read<AttendanceHistoryViewModel>();
    final dashboard = context.read<DashboardViewModel>();
    await history.loadClasses();
    if (!mounted) return;
    await history.selectClass(classCode);
    if (mounted) dashboard.navigate('lich-su-diem-danh');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final padding = context.isMobile ? 18.0 : context.pagePadding;
    final subjects = _visibleSubjects(vm.classes);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          if (!isDark)
            Container(
              height: 320,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFEDE3),
                    Color(0xFFFFF8F5),
                    Color(0xFFF8FAFC),
                  ],
                ),
              ),
            ),
          SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(padding, 14, padding, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (vm.isLoading)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: LinearProgressIndicator(),
                            ),
                          if (vm.errorMessage != null)
                            _ErrorBanner(
                              message: vm.errorMessage!,
                              onRetry: vm.loadClasses,
                            ),
                          const ClassManagementHeader(),
                          const SizedBox(height: 16),
                          if (!keyboardOpen) ...[
                            ClassSummaryBanner(
                              classCount: vm.classes.length,
                              studentCount: vm.totalStudents,
                            ),
                            const SizedBox(height: 14),
                          ],
                          ClassSearchBar(
                            controller: _searchController,
                            onChanged: (value) => setState(
                              () => _searchQuery = value.trim().toLowerCase(),
                            ),
                            onClear: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text(
                                  'Tất cả môn học',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: ClassManagementColors.textDark,
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () => setState(
                                  () => _sortAscending = !_sortAscending,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    'Theo tên ${_sortAscending ? "↑" : "↓"}',
                                    style: const TextStyle(
                                      color: ClassManagementColors.textMuted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        color: ClassManagementColors.orangePrimary,
                        onRefresh: vm.loadClasses,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            padding,
                            4,
                            padding,
                            context.isMobile ? 108 : 36,
                          ),
                          children: [
                            if (subjects.isEmpty)
                              _EmptyState(
                                hasSearch: _searchQuery.isNotEmpty,
                                onAction: () {
                                  if (_searchQuery.isNotEmpty) {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  } else {
                                    vm.navigate('lich-hoc');
                                  }
                                },
                              )
                            else ...[
                              const Padding(
                                padding: EdgeInsets.only(bottom: 10),
                                child: Text(
                                  'Chọn một môn để xem điểm danh theo từng buổi học',
                                  style: TextStyle(
                                    color: ClassManagementColors.textMuted,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              for (final subject in subjects)
                                ClassItemCard(
                                  subjectCode: subject.subjectCode,
                                  classCode: subject.classCode,
                                  subjectName: subject.subjectName,
                                  studentCount: subject.studentCount,
                                  completedSessions: subject.completedSessions,
                                  totalSessions: subject.totalSessions,
                                  attendanceRate: subject.averageAttendance,
                                  onTap: () => _openHistory(subject.classCode),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<ClassSectionModel> _visibleSubjects(List<ClassSectionModel> classes) {
    final result = classes.where((item) {
      if (_searchQuery.isEmpty) return true;
      return '${item.subjectCode} ${item.subjectName} ${item.classCode}'
          .toLowerCase()
          .contains(_searchQuery);
    }).toList();
    result.sort((a, b) {
      final comparison = '${a.subjectCode} ${a.classCode}'.compareTo(
        '${b.subjectCode} ${b.classCode}',
      );
      return _sortAscending ? comparison : -comparison;
    });
    return result;
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFFEF2F2),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFFECACA)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: Color(0xFFB91C1C)),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Thử lại')),
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasSearch, required this.onAction});
  final bool hasSearch;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 6),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: ClassManagementColors.cardBorder),
    ),
    child: Column(
      children: [
        Icon(
          hasSearch ? Icons.search_off_rounded : Icons.menu_book_rounded,
          color: ClassManagementColors.orangePrimary,
          size: 32,
        ),
        const SizedBox(height: 12),
        Text(
          hasSearch
              ? 'Không tìm thấy môn học phù hợp'
              : 'Chưa có môn học được phân công.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onAction,
          child: Text(hasSearch ? 'Xóa tìm kiếm' : 'Tới Lịch dạy'),
        ),
      ],
    ),
  );
}
