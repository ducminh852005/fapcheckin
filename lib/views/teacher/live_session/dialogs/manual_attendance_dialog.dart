import 'package:flutter/material.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';

import 'package:provider/provider.dart';
import 'package:fapcheckin/viewmodels/live_session_viewmodel.dart';
import 'package:fapcheckin/data/models/roster_entry_model.dart';

class ManualAttendanceDialog extends StatefulWidget {
  const ManualAttendanceDialog({super.key});

  @override
  State<ManualAttendanceDialog> createState() => _ManualAttendanceDialogState();
}

class _ManualAttendanceDialogState extends State<ManualAttendanceDialog> {
  int _selectedFilterIndex = 1; // "Chưa điểm danh" active by default like image
  
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final vm = context.read<LiveSessionViewModel>();
    final List<Map<String, dynamic>> list = [];
    int i = 1;
    for (var r in vm.roster) {
      list.add({
        'no': i.toString().padLeft(2, '0'),
        'name': r.displayName,
        'id': r.rollNumber,
        'initials': r.initials,
        'avatarBg': Colors.indigo.shade50,
        'avatarFg': Colors.indigo.shade600,
        'email': r.email,
        'sysStatus': r.status.isEmpty ? 'Chưa điểm danh' : r.status,
        'sysColor': _mapApiStatusToColor(r.status),
        'sysBgColor': _mapApiStatusToBgColor(r.status),
        'selectedAction': _mapApiStatusToUI(r.status),
        'reason': r.note ?? '',
        '_originalAction': _mapApiStatusToUI(r.status),
        '_originalReason': r.note ?? '',
      });
      i++;
    }
    setState(() {
      _students = list;
    });
  }

  Color _mapApiStatusToColor(String status) {
    if (status == 'Present' || status == 'ManualByGV') return AppColors.statusPresent;
    if (status == 'Late') return AppColors.statusLate;
    if (status == 'Absent') return AppColors.statusAbsent;
    return AppColors.textSecondary;
  }

  Color _mapApiStatusToBgColor(String status) {
    if (status == 'Present' || status == 'ManualByGV') return AppColors.statusPresentBg;
    if (status == 'Late') return AppColors.statusLateBg;
    if (status == 'Absent') return AppColors.statusAbsentBg;
    return Colors.grey.shade100;
  }

  String _mapApiStatusToUI(String status) {
    switch (status) {
      case 'Present':
      case 'ManualByGV': return 'Có mặt';
      case 'Late': return 'Trễ';
      case 'Absent': return 'Vắng';
      default: return 'Có mặt'; // default for un-checked
    }
  }

  String _mapUIToApiStatus(String action) {
    switch (action) {
      case 'Có mặt': return 'Present'; // or ManualByGV
      case 'Trễ': return 'Late';
      case 'Vắng': return 'Absent';
      case 'Phép': return 'Absent'; // Or custom status for Phép if supported
      default: return 'Present';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 1050,
        height: 750,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            _buildFilterAndActions(),
            _buildTableHeader(),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: _students.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF0F0F0)),
                itemBuilder: (context, index) => _buildStudentRow(index, _students[index]),
              ),
            ),
            _buildReasonInputFooter(),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final vm = context.read<LiveSessionViewModel>();
    final session = vm.session;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.assignment_ind_outlined, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Điểm danh thủ công & Điều chỉnh trạng thái',
                      style: AppTextStyles.headlineMd.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Giảng viên Roll-call',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    children: [
                      const TextSpan(text: 'Lớp '),
                      TextSpan(text: session?.classCode ?? '...', style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: '  •  Buổi (Ca ${session?.slotCode ?? ''})  •  '),
                      TextSpan(text: session?.sessionDate ?? '...'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () => Navigator.of(context).pop(),
            splashRadius: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        children: [
          Row(
            children: [
              // Search
              Expanded(
                flex: 4,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 18, color: Colors.grey.shade400),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Tìm theo MSSV hoặc họ tên sinh viên...',
                            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Filters
              Row(
                children: [
                  _buildFilterTab(0, 'Tất cả', '35'),
                  const SizedBox(width: 8),
                  _buildFilterTab(1, 'Chưa điểm danh', '5'),
                  const SizedBox(width: 8),
                  _buildFilterTab(2, 'Đi trễ', '2', highlightColor: AppColors.statusLate),
                  const SizedBox(width: 8),
                  _buildFilterTab(3, 'Đã có mặt', '28', highlightColor: AppColors.statusPresent),
                  const SizedBox(width: 8),
                  _buildFilterTab(4, 'Có đơn phép', '1', highlightColor: Colors.blue),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(int index, String title, String count, {Color? highlightColor}) {
    final isSelected = _selectedFilterIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedFilterIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count,
                style: TextStyle(
                  color: isSelected ? Colors.white : (highlightColor ?? Colors.grey.shade500),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(String title, IconData icon, Color color) {
    return TextButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 16, color: color),
      label: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
      ),
      style: TextButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          SizedBox(width: 50, child: Text('STT', style: _headerStyle)),
          Expanded(flex: 3, child: Text('Sinh viên', style: _headerStyle)),
          Expanded(flex: 3, child: Text('Tình trạng hệ thống', style: _headerStyle)),
          Expanded(flex: 3, child: Text('Điều chỉnh', style: _headerStyle)),
          Expanded(flex: 3, child: Text('Ghi chú / Lý do', style: _headerStyle)),
        ],
      ),
    );
  }

  TextStyle get _headerStyle => TextStyle(
    color: Colors.grey.shade600,
    fontSize: 12,
    fontWeight: FontWeight.bold,
  );

  Widget _buildStudentRow(int index, Map<String, dynamic> student) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // STT
          SizedBox(
            width: 50,
            child: Text(
              student['no'],
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          // Sinh viên
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: student['avatarBg'], shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(
                    student['initials'],
                    style: TextStyle(color: student['avatarFg'], fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              student['name'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              student['id'],
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.w600, fontFamily: 'JetBrains Mono'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        student['email'],
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Tình trạng hệ thống
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: student['sysBgColor'],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: student['sysColor'], shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        student['sysStatus'],
                        style: TextStyle(color: student['sysColor'], fontSize: 11, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Điều chỉnh
          Expanded(
            flex: 3,
            child: Container(
              height: 44, // Make the container a bit taller to contain the buttons properly
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildSegmentedBtn(index, 'Có mặt', student['selectedAction'], AppColors.statusPresent)),
                  Expanded(child: _buildSegmentedBtn(index, 'Trễ', student['selectedAction'], AppColors.statusLate)),
                  Expanded(child: _buildSegmentedBtn(index, 'Phép', student['selectedAction'], Colors.blue.shade600)),
                  Expanded(child: _buildSegmentedBtn(index, 'Vắng', student['selectedAction'], AppColors.statusAbsent)),
                ],
              ),
            ),
          ),
          // Ghi chú
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.centerLeft,
                child: TextFormField(
                  initialValue: student['reason'],
                  onChanged: (val) {
                    _students[index]['reason'] = val;
                  },
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedBtn(int index, String title, String activeAction, Color activeColor) {
    final isActive = title == activeAction;
    return GestureDetector(
      onTap: () {
        setState(() {
          _students[index]['selectedAction'] = title;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey.shade600,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildReasonInputFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                'Lý do điều chỉnh điểm danh thủ công (Lưu log Khảo thí & Đào tạo):',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Xác nhận sinh viên có mặt tại phòng học P.302 nhưng gặp sự cố thiết bị/camera và kẹt xe có báo trước.',
                    style: TextStyle(color: Colors.black87, fontSize: 13),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'REQ-AUDIT',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final vm = context.watch<LiveSessionViewModel>();
    final isLoading = vm.status == ViewStatus.loading;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user_outlined, size: 16, color: AppColors.statusPresent),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              children: const [
                TextSpan(text: 'Dữ liệu chỉnh sửa thủ công sẽ được ghi nhận vào '),
                TextSpan(text: 'Nhật ký kiểm toán FAP Edu.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: isLoading ? null : () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: const Text('Hủy bỏ', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: isLoading ? null : () async {
              // Gather changes
              final changes = <Map<String, dynamic>>[];
              for (var s in _students) {
                final originalAction = s['_originalAction'] as String;
                final originalReason = s['_originalReason'] as String;
                if (s['selectedAction'] != originalAction || s['reason'] != originalReason) {
                  changes.add({
                    'rollNumber': s['id'],
                    'status': _mapUIToApiStatus(s['selectedAction']),
                    'reason': s['reason'],
                  });
                }
              }

              if (changes.isEmpty) {
                Navigator.pop(context);
                return;
              }

              await vm.manualCheckinBulk(changes);
              if (context.mounted) {
                if (vm.status == ViewStatus.success) {
                  Navigator.pop(context);
                } else if (vm.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(vm.errorMessage!)),
                  );
                }
              }
            },
            icon: isLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.check, size: 18),
            label: Text(isLoading ? 'Đang cập nhật...' : 'Lưu & Cập nhật điểm danh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
