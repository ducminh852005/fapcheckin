import 'package:flutter/material.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';

class HeaderBar extends StatelessWidget {
  const HeaderBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isLarge = constraints.maxWidth > 800;
          return Flex(
            direction: isLarge ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: isLarge ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Context
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'FAP Academic Attendance',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'SYS_VER: 2023.3-WIN',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Lịch sử điểm danh các lớp giảng dạy',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Tra cứu, theo dõi chuyên cần và điều chỉnh trạng thái điểm danh theo từng buổi học',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (!isLarge) const SizedBox(height: 16),
              // Filters & Actions
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Semester Select
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: 'fall23',
                        icon: const Icon(Icons.expand_more, color: AppColors.textSecondary, size: 18),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        onChanged: (_) {},
                        items: const [
                          DropdownMenuItem(value: 'fall23', child: Text('Fall 2023 (Kỳ hiện tại)')),
                          DropdownMenuItem(value: 'summer23', child: Text('Summer 2023')),
                          DropdownMenuItem(value: 'spring23', child: Text('Spring 2023')),
                        ],
                      ),
                    ),
                  ),
                  // Search
                  Container(
                    width: isLarge ? 200 : null,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: 'Tìm MSSV, tên, mã lớp...',
                        hintStyle: TextStyle(fontSize: 14, color: AppColors.textTertiary),
                        prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 18),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  // Filter Button
                  ElevatedButton.icon(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceMuted,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.filter_list, size: 18),
                    label: const Text('Bộ lọc', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                  // Export Button
                  ElevatedButton.icon(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: AppColors.onPrimary,
                      elevation: 0,
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.file_download, size: 18),
                    label: const Text('Xuất Excel FAP (.xlsx)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
