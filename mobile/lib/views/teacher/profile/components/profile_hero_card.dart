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
  final int classCount;
  final int studentCount;
  final String attendanceRate;

  const ProfileHeroCard({
    super.key,
    this.fullName = 'Nguyễn Thị Mai',
    this.roleTitle = 'Giảng viên • FPT University',
    this.department = 'Khoa Công nghệ thông tin',
    this.initials = 'NM',
    this.classCount = 6,
    this.studentCount = 120,
    this.attendanceRate = '94,1%',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ProfileColors.heroBannerBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phần thông tin Giảng viên (Avatar + Tên)
          Row(
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
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      roleTitle,
                      style: const TextStyle(
                        color: ProfileColors.textSubtle,
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
                        color: ProfileColors.textSubtle,
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
          const SizedBox(height: 20),

          // Đường kẻ ngang mỏng phân cách
          Container(
            height: 1,
            color: ProfileColors.heroDivider,
          ),
          const SizedBox(height: 16),

          // 3 cột chỉ số
          Row(
            children: [
              Expanded(
                child: _HeroStatItem(
                  value: '$classCount',
                  label: 'Lớp giảng dạy',
                ),
              ),
              Container(
                width: 1,
                height: 34,
                color: ProfileColors.heroDivider,
              ),
              Expanded(
                child: _HeroStatItem(
                  value: '$studentCount',
                  label: 'Sinh viên',
                ),
              ),
              Container(
                width: 1,
                height: 34,
                color: ProfileColors.heroDivider,
              ),
              Expanded(
                child: _HeroStatItem(
                  value: attendanceRate,
                  label: 'Chuyên cần\ntuần này',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStatItem extends StatelessWidget {
  final String value;
  final String label;

  const _HeroStatItem({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ProfileColors.textSubtle,
              fontSize: 11,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

