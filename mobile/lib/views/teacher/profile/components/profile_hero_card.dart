import 'package:flutter/material.dart';
import '../profile_colors.dart';

/// Thẻ Dark Navy chứa thông tin tổng quan của Giảng viên:
/// - Avatar viết tắt (vd: "NM"), họ tên, chức vụ, đơn vị công tác
/// - 3 cột chỉ số: Lớp giảng dạy (6), Sinh viên (120), Chuyên cần tuần này (94,1%)
class ProfileHeroCard extends StatelessWidget {
  final String fullName;
  final String roleTitle;
  final String department;
  final String initials;
  final int? classCount;
  final int? studentCount;
  final String? attendanceRate;

  const ProfileHeroCard({
    super.key,
    this.fullName = 'Nguyễn Thị Mai',
    this.roleTitle = 'Giảng viên • FPT University',
    this.department = 'Khoa Công nghệ thông tin',
    this.initials = 'NM',
    this.classCount,
    this.studentCount,
    this.attendanceRate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFE5D9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFA5A1E).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: ProfileColors.orangePrimary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    fullName,
                    style: const TextStyle(
                      color: ProfileColors.textDark,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  roleTitle,
                  style: const TextStyle(
                    color: ProfileColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  department,
                  style: const TextStyle(
                    color: ProfileColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
