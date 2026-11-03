import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../viewmodels/live_session_viewmodel.dart';
import '../live_session_colors.dart';

class ManualAttendanceStudent {
  final String rollNumber;
  final String fullName;
  final String statusText;
  final bool isAlreadyPresent;

  const ManualAttendanceStudent({
    required this.rollNumber,
    required this.fullName,
    this.statusText = 'Chưa điểm danh',
    this.isAlreadyPresent = false,
  });
}

/// Bottom Sheet "Điểm danh tay" lướt từ dưới lên:
/// - Thanh gạt đỉnh modal (drag handle)
/// - Tiêu đề "Điểm danh tay", mã lớp, số lượng hiện tại, nút X đóng
/// - Mô tả: "Xác nhận sinh viên có mặt tại lớp nhưng chưa thể quét mã QR."
/// - Ô tìm kiếm tên hoặc MSSV
/// - 2 Tab lọc: "Chưa điểm danh (4)" & "Tất cả (32)"
/// - Dòng trạng thái "Đã chọn N sinh viên" & nút "Chọn tất cả"
/// - Danh sách sinh viên với ô tick cam bo góc khi chọn
/// - Dòng tính toán "Sau xác nhận: 30/32 có mặt · Ghi nhận điểm danh tay"
/// - Nút cam "Xác nhận N sinh viên có mặt" & Nút "Hủy"
class ManualAttendanceBottomSheet extends StatefulWidget {
  const ManualAttendanceBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ManualAttendanceBottomSheet(),
    );
  }

  @override
  State<ManualAttendanceBottomSheet> createState() =>
      _ManualAttendanceBottomSheetState();
}

class _ManualAttendanceBottomSheetState
    extends State<ManualAttendanceBottomSheet> {
  int _selectedFilterIndex = 0; // 0: Chưa điểm danh, 1: Tất cả
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Khởi tạo 2 sinh viên được chọn mặc định như ảnh mockup
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = {};
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liveVm = context.watch<LiveSessionViewModel>();
    final classTitle = liveVm.courseCode.isNotEmpty ? liveVm.courseCode : '';
    final currentPresent = liveVm.checkedInCount;
    final totalCount = liveVm.totalStudents;

    // Dữ liệu sinh viên (lấy từ roster ViewModel hoặc fallback chuẩn mockup)
    final allStudents = _buildStudentsList(liveVm);
    final absentStudents = allStudents
        .where((s) => !s.isAlreadyPresent)
        .toList();
    final currentList = _selectedFilterIndex == 0
        ? absentStudents
        : allStudents;

    // Lọc theo tìm kiếm
    final filteredList = currentList.where((s) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return s.fullName.toLowerCase().contains(q) ||
          s.rollNumber.toLowerCase().contains(q);
    }).toList();

    final afterConfirmCount = currentPresent + _selectedIds.length;
    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.90;
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            12,
            18,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thanh kéo drag handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Header: Tiêu đề + Nút đóng X
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Điểm danh tay',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: LiveSessionColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$classTitle · $currentPresent/$totalCount đã có mặt',
                          style: const TextStyle(
                            fontSize: 12,
                            color: LiveSessionColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tooltip(
                    message: 'Đóng',
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (!isKeyboardOpen) ...[
                const SizedBox(height: 10),
                // Mô tả
                const Text(
                  'Xác nhận sinh viên có mặt tại lớp nhưng chưa thể quét mã QR.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: LiveSessionColors.textMuted,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // Ô tìm kiếm
              Container(
                height: 44,
                padding: const EdgeInsets.only(left: 12, right: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: LiveSessionColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: LiveSessionColors.textSubtle,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim();
                          });
                        },
                        style: const TextStyle(
                          fontSize: 13,
                          color: LiveSessionColors.textDark,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Tìm tên sinh viên hoặc mã số...',
                          hintStyle: TextStyle(
                            fontSize: 12.5,
                            color: LiveSessionColors.textSubtle,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      Tooltip(
                        message: 'Xóa tìm kiếm',
                        child: InkWell(
                          onTap: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: const SizedBox(
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.clear_rounded,
                              size: 18,
                              color: LiveSessionColors.textSubtle,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // 2 Tab lọc: Chưa điểm danh / Tất cả
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildFilterTab(
                        index: 0,
                        title: 'Chưa điểm danh (${absentStudents.length})',
                      ),
                    ),
                    Expanded(
                      child: _buildFilterTab(
                        index: 1,
                        title: 'Tất cả ($totalCount)',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Trạng thái chọn & Nút Chọn tất cả
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Đã chọn ${_selectedIds.length} sinh viên',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: LiveSessionColors.textDark,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (_selectedIds.length == filteredList.length) {
                          _selectedIds.clear();
                        } else {
                          _selectedIds.addAll(
                            filteredList.map((s) => s.rollNumber),
                          );
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Text(
                        _selectedIds.length == filteredList.length &&
                                filteredList.isNotEmpty
                            ? 'Bỏ chọn'
                            : 'Chọn tất cả',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: LiveSessionColors.orangePrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Danh sách sinh viên (cuộn được)
              Flexible(
                child: filteredList.isEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        alignment: Alignment.center,
                        child: const Text(
                          'Không có sinh viên phù hợp',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: LiveSessionColors.textMuted,
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: filteredList.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final student = filteredList[index];
                          final isSelected = _selectedIds.contains(
                            student.rollNumber,
                          );
                          return _StudentSelectionTile(
                            student: student,
                            isSelected: isSelected,
                            onToggle: () {
                              if (student.isAlreadyPresent || _saving) return;
                              setState(() {
                                if (isSelected) {
                                  _selectedIds.remove(student.rollNumber);
                                } else {
                                  _selectedIds.add(student.rollNumber);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
              const SizedBox(height: 10),

              if (!isKeyboardOpen) ...[
                // Dòng ghi chú dự kiến sau xác nhận
                FittedBox(
                  alignment: Alignment.center,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Sau xác nhận: $afterConfirmCount/$totalCount có mặt · Ghi nhận điểm danh tay',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: LiveSessionColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Nút xác nhận chính & Hủy (Row ngang nhất quán với các Modal khác trong ứng dụng)
              Row(
                children: [
                  SizedBox(
                    width: 90,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: LiveSessionColors.textDark,
                        side: const BorderSide(
                          color: Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: LiveSessionColors.textDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _selectedIds.isEmpty || _saving
                            ? null
                            : () => _handleConfirmAttendance(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LiveSessionColors.orangePrimary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFCBD5E1),
                          disabledForegroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_saving) ...[
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Đang lưu...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ] else ...[
                                const Icon(
                                  Icons.check_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _selectedIds.isEmpty
                                      ? 'Chọn sinh viên để xác nhận'
                                      : 'Xác nhận ${_selectedIds.length} sinh viên có mặt',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTab({required int index, required String title}) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilterIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? LiveSessionColors.textDark
                    : LiveSessionColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<ManualAttendanceStudent> _buildStudentsList(LiveSessionViewModel vm) {
    if (vm.roster.isNotEmpty) {
      return vm.roster.map((r) {
        return ManualAttendanceStudent(
          rollNumber: r.rollNumber,
          fullName: r.fullName,
          statusText: r.hasCheckedIn ? 'Đã điểm danh' : 'Chưa điểm danh',
          isAlreadyPresent: r.hasCheckedIn,
        );
      }).toList();
    }

    return const [];
  }

  bool _saving = false;
  Future<void> _handleConfirmAttendance(BuildContext context) async {
    if (_saving || _selectedIds.isEmpty) return;
    setState(() => _saving = true);
    final vm = context.read<LiveSessionViewModel>();
    final changes = vm.roster
        .where((r) => _selectedIds.contains(r.rollNumber) && !r.hasCheckedIn)
        .map(
          (r) => <String, dynamic>{
            'rollNumber': r.rollNumber,
            'status': 'ManualByGV',
          },
        )
        .toList();
    final success = await vm.manualCheckinBulk(changes);
    if (!context.mounted) return;
    setState(() => _saving = false);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage ?? 'Không thể điểm danh tay. Vui lòng thử lại.'),
        ),
      );
      return;
    }
    final count = changes.length;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã xác nhận điểm danh tay cho $count sinh viên có mặt'),
        duration: const Duration(seconds: 2),
        backgroundColor: LiveSessionColors.statusGreen,
      ),
    );
  }
}

class _StudentSelectionTile extends StatelessWidget {
  final ManualAttendanceStudent student;
  final bool isSelected;
  final VoidCallback onToggle;

  const _StudentSelectionTile({
    required this.student,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF9F5) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFED7AA)
                : LiveSessionColors.borderSubtle,
            width: isSelected ? 1.3 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: LiveSessionColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${student.rollNumber} · ${student.statusText}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: LiveSessionColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Checkbox cam tùy biến
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected
                    ? LiveSessionColors.orangePrimary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected
                      ? LiveSessionColors.orangePrimary
                      : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
