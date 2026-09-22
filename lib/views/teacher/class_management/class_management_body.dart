import 'package:flutter/material.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';

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
          const AllClassesGrid(),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
