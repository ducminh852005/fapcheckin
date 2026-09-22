import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';
import 'package:fapcheckin/viewmodels/live_session_viewmodel.dart';
import 'package:fapcheckin/viewmodels/dashboard_viewmodel.dart';
import 'components/qr_panel.dart';
import 'components/checkin_panel.dart';

class LiveSessionBody extends StatelessWidget {
  const LiveSessionBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Main 2-column grid (5/12 + 7/12)
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 900) {
                  // Stack vertically on small screens
                  return const Column(
                    children: [
                      QrPanel(),
                      SizedBox(height: 16),
                      CheckinPanel(),
                    ],
                  );
                }
                return const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left column (~40%)
                    Expanded(flex: 5, child: QrPanel()),
                    SizedBox(width: 16),
                    // Right column (~60%)
                    Expanded(flex: 7, child: CheckinPanel()),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            // Back button
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  context.read<DashboardViewModel>().navigate('lop-hoc');
                },
                icon: const Icon(Icons.arrow_back, size: 20),
                label: Text(
                  'Quay lại Quản lý Lớp học',
                  style: AppTextStyles.labelMd.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  backgroundColor: AppColors.surface,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    side: const BorderSide(color: AppColors.surfaceContainerHigh),
                  ),
                ),
              ),
            ),
          ],

        ),
      ),
    );
  }
}



/// Toast notification (bottom-right)
class ToastNotification extends StatelessWidget {
  const ToastNotification({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LiveSessionViewModel>(
      builder: (context, vm, _) {
        if (!vm.showToast || vm.toastData == null) return const SizedBox.shrink();
        final toast = vm.toastData!;

        return Positioned(
          top: 20,
          right: 20,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: toast.accentColor == AppColors.statusPresent
                    ? AppColors.statusPresentBg
                    : (toast.accentColor == AppColors.error || toast.accentColor == AppColors.statusAbsent
                        ? AppColors.statusAbsentBg
                        : AppColors.surface),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                border: Border(
                  left: BorderSide(color: toast.accentColor, width: 4),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A142433),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: toast.accentColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(toast.icon, size: 20, color: toast.accentColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          toast.title,
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          toast.message,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => vm.dismissToast(),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, size: 18, color: AppColors.textTertiary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
