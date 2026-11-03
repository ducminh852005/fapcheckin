import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin_core/responsive/breakpoints.dart';

import '../../../viewmodels/live_session_viewmodel.dart';
import '../../../viewmodels/dashboard_viewmodel.dart';
import './components/manual_attendance_bottom_sheet.dart';
import 'live_session_colors.dart';
import 'dialogs/start_session_dialog.dart';
import 'components/live_session_custom_header.dart';
import 'components/live_session_qr_card.dart';
import 'components/live_session_network_card.dart';
import 'components/live_session_roster_card.dart';
import 'components/live_session_manual_button.dart';

/// Màn hình Điểm danh trực tiếp (Live QR):
/// 1. Header (CA 2 · THỨ NĂM, 08/10/2026, Điểm danh trực tiếp, nút ...)
/// 2. Thông tin môn & lớp: PRN231 · SE1801, 08:45-10:15 · Phòng AL-204, chấm xanh
/// 3. Thẻ QR: ĐANG MỞ ĐIỂM DANH, mã QR, đếm ngược 42s
/// 4. Thẻ Kiểm tra IP mạng (Nút gạt Tắt / Bật)
/// 5. Danh sách Sinh viên điểm danh (28/32, 2 tabs, ô tìm kiếm)
/// 6. Nút "Điểm danh tay"
/// 7. Chân trang: QR minh họa
class LiveSessionBody extends StatelessWidget {
  const LiveSessionBody({super.key});

  @override
  Widget build(BuildContext context) {
    final liveVm = context.watch<LiveSessionViewModel>();
    final dashboardVm = context.watch<DashboardViewModel>();
    final horizontalPadding = context.isMobile ? 18.0 : context.pagePadding;

    if (liveVm.session == null || liveVm.isClosed) {
      return Scaffold(
        backgroundColor: LiveSessionColors.pageBg,
        body: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            context.isMobile ? 16.0 : 24.0,
            horizontalPadding,
            context.isMobile ? 108.0 : 40.0,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => dashboardVm.navigate('lich-hoc'),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: LiveSessionColors.borderSubtle,
                            ),
                            boxShadow: LiveSessionColors.cardShadow,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 17,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Chọn lớp để mở điểm danh',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: LiveSessionColors.textDark,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (liveVm.isLoading) const LinearProgressIndicator(),
                  if (liveVm.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      liveVm.errorMessage!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],
                  if (dashboardVm.classes.isEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 28,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: LiveSessionColors.borderSubtle,
                        ),
                        boxShadow: LiveSessionColors.cardShadow,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: LiveSessionColors.orangeLight,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner_rounded,
                              color: LiveSessionColors.orangePrimary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Chưa có lớp được phân công.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: LiveSessionColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Hãy quét thời khóa biểu FAP trong mục Lịch dạy để chọn lớp mở phiên QR.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: LiveSessionColors.textMuted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    for (final c in dashboardVm.classes)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: LiveSessionColors.borderSubtle,
                          ),
                          boxShadow: LiveSessionColors.cardShadow,
                        ),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Text(
                            '${c.subjectCode} · ${c.classCode}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: LiveSessionColors.textDark,
                            ),
                          ),
                          subtitle: Text(
                            '${c.timeLabel} · ${c.room}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: LiveSessionColors.textMuted,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.qr_code_rounded,
                            color: LiveSessionColors.orangePrimary,
                          ),
                          onTap: liveVm.isLoading
                              ? null
                              : () async {
                                  await startSessionWithOptions(
                                    context,
                                    classSection: c,
                                    slotCode: c.slotCode,
                                  );
                                },
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    final classTitle =
        '${liveVm.classInfo?.subjectCode ?? ''} · ${liveVm.courseCode}';
    final timeAndRoom = '${liveVm.classInfo?.timeLabel ?? ''} · ${liveVm.room}';
    final qrData = liveVm.checkinUrl;
    final refreshSeconds = liveVm.qrRefreshSeconds;
    final totalCycleSeconds = liveVm.qrCycleSeconds;
    final presentCount = liveVm.checkedInCount;
    final totalCount = liveVm.totalStudents;
    final students = liveVm.roster
        .map(
          (r) => StudentAttendanceItem(
            rollNumber: r.rollNumber,
            fullName: r.displayName,
            initials: _extractInitials(r.displayName),
            checkinTime: r.displayCheckinTime,
            methodText: r.hasCheckedIn
                ? (r.status == 'ManualByGV'
                      ? 'Giảng viên xác nhận'
                      : r.status == 'Late'
                      ? 'Đi muộn'
                      : 'QR')
                : 'Chưa điểm danh',
            isPresent: r.hasCheckedIn,
          ),
        )
        .toList();
    final presentStudents = students.where((s) => s.isPresent).toList();
    return Scaffold(
      backgroundColor: LiveSessionColors.pageBg,
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          context.isMobile ? 16.0 : 24.0,
          horizontalPadding,
          context.isMobile ? 108.0 : 40.0,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (liveVm.isLoading) const LinearProgressIndicator(),
                if (liveVm.errorMessage != null)
                  Text(
                    liveVm.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                // 1 & 2. Header & Banner môn học
                LiveSessionCustomHeader(
                  sessionSubtitle: 'Ca ${liveVm.slot} · ${liveVm.dateLabel}',
                  classTitle: classTitle,
                  timeAndRoom: timeAndRoom,
                  onBackTap: () => dashboardVm.navigate('lich-hoc'),
                  onMoreTap: () => _showMoreOptions(context, dashboardVm),
                ),
                const SizedBox(height: 16),

                // 3. Thẻ QR Code
                LiveSessionQrCard(
                  qrData: qrData,
                  refreshSeconds: refreshSeconds,
                  totalCycleSeconds: totalCycleSeconds,
                  onRefresh: liveVm.refreshQrNow,
                  onFullscreen: () => _showFullscreenQr(context, qrData),
                ),
                const SizedBox(height: 14),

                // 4. Thẻ Kiểm tra IP mạng
                LiveSessionNetworkCard(isEnforced: liveVm.ipCheck),
                const SizedBox(height: 18),

                // 5. Thẻ danh sách sinh viên điểm danh
                LiveSessionRosterCard(
                  presentCount: presentCount,
                  totalCount: totalCount,
                  presentStudents: presentStudents,
                  absentStudents: students.where((s) => !s.isPresent).toList(),
                ),
                const SizedBox(height: 16),

                // 6. Nút "Điểm danh tay"
                LiveSessionManualButton(
                  onPressed: () => ManualAttendanceBottomSheet.show(context),
                ),
                const SizedBox(height: 16),

                // 7. Chân trang ghi chú
                const Center(
                  child: Text(
                    'Sinh viên quét mã QR để điểm danh. Cấu hình IP được chọn khi mở phiên.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: LiveSessionColors.textSubtle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _extractInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'SV';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  void _showMoreOptions(BuildContext context, DashboardViewModel dashboardVm) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.arrow_back_rounded),
                title: const Text('Quay lại Lịch dạy'),
                onTap: () {
                  Navigator.pop(ctx);
                  dashboardVm.navigate('lich-hoc');
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh_rounded),
                title: const Text('Làm mới phiên'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<LiveSessionViewModel>().refreshQrNow();
                },
              ),
              ListTile(
                leading: const Icon(Icons.close_rounded, color: Colors.red),
                title: const Text(
                  'Đóng phiên điểm danh',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      title: const Text(
                        'Đóng phiên điểm danh?',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      content: const Text(
                        'Sau khi đóng phiên, sinh viên sẽ không thể tiếp tục quét mã QR của buổi học này.',
                        style: TextStyle(fontSize: 13.5, height: 1.4),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dCtx, false),
                          child: const Text('Hủy'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(dCtx, true),
                          child: const Text('Đóng phiên'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true || !context.mounted) return;
                  final ok = await context
                      .read<LiveSessionViewModel>()
                      .closeCurrentSession();
                  if (ok) await dashboardVm.loadClasses();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullscreenQr(BuildContext context, String qrData) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mã QR Điểm danh',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: LiveSessionColors.textDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Toàn màn hình QR
              InteractiveViewer(
                child: LiveSessionQrCard(
                  qrData: ctx.watch<LiveSessionViewModel>().checkinUrl,
                  refreshSeconds: ctx
                      .watch<LiveSessionViewModel>()
                      .qrRefreshSeconds,
                  totalCycleSeconds: ctx
                      .watch<LiveSessionViewModel>()
                      .qrCycleSeconds,
                ),
              ),
            ],
          ),
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
          return const SizedBox.shrink();
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
              constraints: const BoxConstraints(maxWidth: 440),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          toast.message,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
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
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: Color(0xFF94A3B8),
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
