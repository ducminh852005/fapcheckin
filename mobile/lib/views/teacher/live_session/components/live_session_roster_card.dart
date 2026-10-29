import 'package:flutter/material.dart';

import '../live_session_colors.dart';

class StudentAttendanceItem {
  final String rollNumber;
  final String fullName;
  final String initials;
  final String methodText; // vd: "QR hợp lệ" hoặc "Chưa điểm danh"
  final String? checkinTime; // vd: "09:40"
  final bool isPresent;

  const StudentAttendanceItem({
    required this.rollNumber,
    required this.fullName,
    required this.initials,
    this.methodText = 'QR hợp lệ',
    this.checkinTime,
    this.isPresent = true,
  });
}

/// Thẻ danh sách sinh viên điểm danh:
/// - Header: "Sinh viên điểm danh" + Badge số lượng "28/32"
/// - 2 Tab: "Đã điểm danh (28)" & "Chưa điểm danh (4)"
/// - Ô tìm kiếm sinh viên theo tên hoặc mã số
/// - Danh sách sinh viên kèm avatar, mã số, phương thức quét & thời gian
class LiveSessionRosterCard extends StatefulWidget {
  final int presentCount;
  final int totalCount;
  final List<StudentAttendanceItem> presentStudents;
  final List<StudentAttendanceItem> absentStudents;

  const LiveSessionRosterCard({
    super.key,
    this.presentCount = 0,
    this.totalCount = 0,
    this.presentStudents = const [],
    this.absentStudents = const [],
  });

  @override
  State<LiveSessionRosterCard> createState() => _LiveSessionRosterCardState();
}

class _LiveSessionRosterCardState extends State<LiveSessionRosterCard> {
  int _selectedTab = 0; // 0: Đã điểm danh, 1: Chưa điểm danh
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final absentCount = widget.totalCount - widget.presentCount;
    final activeList = _selectedTab == 0
        ? widget.presentStudents
        : widget.absentStudents;

    final filteredList = activeList.where((s) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return s.fullName.toLowerCase().contains(query) ||
          s.rollNumber.toLowerCase().contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Text(
                  'Sinh viên điểm danh',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: LiveSessionColors.textDark,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: LiveSessionColors.orangeLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${widget.presentCount}/${widget.totalCount}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: LiveSessionColors.orangePrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Tabs (bảo vệ chống tràn cho màn hình hẹp)
        Row(
          children: [
            Expanded(
              child: _buildTab(
                index: 0,
                label: 'Đã điểm danh (${widget.presentCount})',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildTab(
                index: 1,
                label: 'Chưa điểm danh ($absentCount)',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Thanh tìm kiếm
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: LiveSessionColors.borderSubtle),
            boxShadow: LiveSessionColors.cardShadow,
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
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  child: const Icon(
                    Icons.clear_rounded,
                    size: 18,
                    color: LiveSessionColors.textSubtle,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Danh sách sinh viên
        if (filteredList.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            alignment: Alignment.center,
            child: const Text(
              'Không tìm thấy sinh viên phù hợp',
              style: TextStyle(
                fontSize: 12.5,
                color: LiveSessionColors.textMuted,
              ),
            ),
          )
        else
          Column(
            children: [
              for (int i = 0; i < filteredList.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                _StudentItemTile(student: filteredList[i]),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildTab({required int index, required String label}) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? LiveSessionColors.orangePrimary
                    : LiveSessionColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2.5,
            width: isSelected ? 48 : 0,
            decoration: BoxDecoration(
              color: isSelected
                  ? LiveSessionColors.orangePrimary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentItemTile extends StatelessWidget {
  final StudentAttendanceItem student;

  const _StudentItemTile({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LiveSessionColors.cardBorder),
        boxShadow: LiveSessionColors.cardShadow,
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFE2E8F0),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              student.initials,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Tên & MSSV
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${student.rollNumber} · ${student.methodText}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: LiveSessionColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Giờ điểm danh & Checkmark
          if (student.isPresent && student.checkinTime != null) ...[
            Text(
              student.checkinTime!,
              style: const TextStyle(
                fontSize: 11.5,
                color: LiveSessionColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.check_circle_outline_rounded,
              size: 18,
              color: LiveSessionColors.statusGreen,
            ),
          ] else
            const Text(
              'Vắng mặt',
              style: TextStyle(
                fontSize: 11.5,
                color: LiveSessionColors.textSubtle,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}
