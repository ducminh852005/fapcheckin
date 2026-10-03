import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';
import 'package:fapcheckin/core/responsive/breakpoints.dart';
import 'package:fapcheckin/viewmodels/live_session_viewmodel.dart';
import 'package:fapcheckin/viewmodels/dashboard_viewmodel.dart';

import 'components/qr_panel.dart';
import 'components/checkin_panel.dart';

class LiveSessionBody extends StatelessWidget {
  const LiveSessionBody({super.key});

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 1220;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(context.isMobile ? 12 : AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  context.read<DashboardViewModel>().navigate('lop-hoc');
                },
                icon: Icon(Icons.arrow_back, size: 20),
                label: Text(
                  'Quay lại Quản lý Tiết học',
                  style: AppTextStyles.labelMd.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  backgroundColor: AppColors.surface,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    side: BorderSide(color: AppColors.surfaceContainerHigh),
                  ),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            if (isNarrow)
              Column(
                children: [QrPanel(), SizedBox(height: 16), CheckinPanel()],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: QrPanel(minHeight: 820)),
                  SizedBox(width: 16),
                  Expanded(flex: 8, child: CheckinPanel()),
                ],
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
        if (!vm.showToast || vm.toastData == null) {
          return SizedBox.shrink();
        }
        final toast = vm.toastData!;

        final isMobile = context.isMobile;
        return Positioned(
          top: isMobile ? 8 : 20,
          right: isMobile ? 12 : 20,
          left: isMobile ? 12 : null,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(maxWidth: 440),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: toast.accentColor == AppColors.statusPresent
                    ? AppColors.statusPresentBg
                    : (toast.accentColor == AppColors.error ||
                              toast.accentColor == AppColors.statusAbsent
                          ? AppColors.statusAbsentBg
                          : AppColors.surface),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                border: Border(
                  left: BorderSide(color: toast.accentColor, width: 4),
                ),
                boxShadow: [
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
                  SizedBox(width: 12),
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
                        SizedBox(height: 2),
                        Text(
                          toast.message,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => vm.dismissToast(),
                    child: Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.textTertiary,
                      ),
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
