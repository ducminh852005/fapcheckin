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
        if (!vm.showToast) return const SizedBox.shrink();
        return Positioned(
          bottom: 20,
          right: 20,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                border: const Border(
                  left: BorderSide(color: AppColors.statusPresent, width: 4),
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
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.statusPresentBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 20, color: AppColors.statusPresent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            children: [
                              const TextSpan(text: 'Nguyễn Văn Bình ('),
                              TextSpan(
                                text: 'SE160342',
                                style: AppTextStyles.codeSm.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const TextSpan(text: ')'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        RichText(
                          text: TextSpan(
                            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                            children: [
                              const TextSpan(text: 'Vừa điểm danh thành công lúc '),
                              TextSpan(
                                text: '07:55:01',
                                style: AppTextStyles.codeSm.copyWith(
                                  color: AppColors.statusPresent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
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
