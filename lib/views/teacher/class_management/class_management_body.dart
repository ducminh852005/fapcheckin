import 'package:flutter/material.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';

import 'components/today_classes_section.dart';
import 'components/all_classes_grid.dart';

class ClassManagementBody extends StatelessWidget {
  const ClassManagementBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TodayClassesSection(),
          const SizedBox(height: AppSpacing.md),
          const AllClassesGrid(),
          const SizedBox(height: AppSpacing.xl),

        ],
      ),
    );
  }
}
