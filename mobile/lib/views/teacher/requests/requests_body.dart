import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin_core/constants/app_palette.dart';
import 'package:fapcheckin_core/repositories/request_repository.dart';
import 'package:fapcheckin_core/responsive/breakpoints.dart';

import '../../../viewmodels/auth_viewmodel.dart';
import '../dashboard/components/notification_modal.dart';
import 'request_modal_sheet.dart';

const _statuses = {
  'pending': 'Chờ duyệt',
  'approved': 'Đã duyệt',
  'rejected': 'Đã từ chối',
  'resolved': 'Đã giải quyết',
  'dismissed': 'Không hợp lệ',
};

class RequestsBody extends StatefulWidget {
  const RequestsBody({super.key, this.repository});

  final RequestRepository? repository;

  @override
  State<RequestsBody> createState() => _RequestsBodyState();
}

class _RequestsBodyState extends State<RequestsBody> {
  late RequestRepository _repo;
  late Stream<List<Map<String, dynamic>>> _requests;
  String? _uid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = context.watch<AuthViewModel>().session;
    if (session == null) return;
    if (_uid != session.token) {
      _uid = session.token;
      _repo =
          widget.repository ??
          RequestRepository(
            uid: session.token,
            memberCode: session.user.memberCode,
          );
      _requests = _repo.watchMine();
    }
  }

  (Color bg, Color fg, Color border) _statusStyle(String? status) {
    return switch (status) {
      'approved' || 'resolved' => (
        AppPalette.statusGreenBg,
        AppPalette.statusGreen,
        const Color(0xFFBBF7D0),
      ),
      'rejected' || 'dismissed' => (
        AppPalette.statusRedBg,
        AppPalette.statusRed,
        const Color(0xFFFECACA),
      ),
      _ => (
        AppPalette.orangeLight,
        AppPalette.primary,
        AppPalette.orangeBorder,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = context.isMobile ? 18.0 : context.pagePadding;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppPalette.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () => showRequestBottomSheet(context, repository: _repo),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Gửi yêu cầu',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Stack(
        children: [
          if (!isDark)
            Container(
              height: 240,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppPalette.headerGradient,
              ),
            ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        14,
                        horizontalPadding,
                        12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ĐƠN TỪ & HỖ TRỢ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: AppPalette.primary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Yêu cầu điểm danh / nghỉ phép',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? const Color(0xFFF8FAFC) : AppPalette.textDark,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Thông báo',
                            onPressed: () => showNotificationModal(context),
                            icon: Icon(
                              Icons.notifications_outlined,
                              color: isDark ? const Color(0xFFF8FAFC) : AppPalette.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _requests,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: const Color(0xFFFECACA),
                                    ),
                                    boxShadow: AppPalette.cardShadow,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.error_outline_rounded,
                                        size: 36,
                                        color: AppPalette.statusRed,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Không tải được yêu cầu: ${snapshot.error}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          color: AppPalette.textBody,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextButton.icon(
                                        onPressed: () => setState(
                                          () => _requests = _repo.watchMine(),
                                        ),
                                        icon: const Icon(
                                          Icons.refresh_rounded,
                                          size: 18,
                                        ),
                                        label: const Text('Thử lại'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppPalette.primary,
                              ),
                            );
                          }
                          if (snapshot.data!.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 32,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Theme.of(context).colorScheme.surface
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isDark
                                          ? Theme.of(context).colorScheme.outline
                                          : AppPalette.borderSubtle,
                                    ),
                                    boxShadow: isDark
                                        ? const []
                                        : AppPalette.cardShadow,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF334155)
                                              : AppPalette.orangeLight,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.inbox_outlined,
                                          color: AppPalette.primary,
                                          size: 26,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        'Bạn chưa gửi yêu cầu nào.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? const Color(0xFFF8FAFC)
                                              : AppPalette.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Nhấn nút "Gửi yêu cầu" bên dưới để tạo đơn xin nghỉ phép hoặc xác nhận điểm danh.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: isDark
                                              ? const Color(0xFF94A3B8)
                                              : AppPalette.textMuted,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              8,
                              horizontalPadding,
                              108,
                            ),
                            itemCount: snapshot.data!.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final row = snapshot.data![index];
                              final isLeave = row['type'] == 'leave';
                              final isAbsenceEscalation =
                                  row['type'] == 'absence_escalation';
                              final statusKey =
                                  row['status']?.toString() ?? 'pending';
                              final statusLabel =
                                  _statuses[statusKey] ?? statusKey;
                              final (badgeBg, badgeFg, badgeBorder) =
                                  _statusStyle(statusKey);
                              final adminNote =
                                  row['adminNote']?.toString().trim() ?? '';
                              final sessionId =
                                  row['sessionId']?.toString().trim() ?? '';
                              final classCode =
                                  row['classCode']?.toString().trim() ?? '';

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Theme.of(context).colorScheme.surface
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isDark
                                        ? Theme.of(context).colorScheme.outline
                                        : AppPalette.borderSubtle,
                                  ),
                                  boxShadow: isDark
                                      ? const []
                                      : AppPalette.cardShadow,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${isAbsenceEscalation ? 'Báo cáo vượt ngưỡng vắng' : isLeave ? 'Nghỉ phép' : 'Sửa điểm danh'}${classCode.isNotEmpty ? ' · $classCode' : ''}',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: isDark
                                                  ? const Color(0xFFF8FAFC)
                                                  : AppPalette.textDark,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: badgeBg,
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                            border: Border.all(
                                              color: badgeBorder,
                                            ),
                                          ),
                                          child: Text(
                                            statusLabel,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: badgeFg,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${row['reason'] ?? ''}',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        color: isDark
                                            ? const Color(0xFFCBD5E1)
                                            : AppPalette.textBody,
                                        height: 1.4,
                                      ),
                                    ),
                                    if (sessionId.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        'Mã phiên: $sessionId',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? const Color(0xFF94A3B8)
                                              : AppPalette.textMuted,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                    if (adminNote.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF0F172A)
                                              : const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: isDark
                                                ? const Color(0xFF334155)
                                                : AppPalette.borderSubtle,
                                          ),
                                        ),
                                        child: Text(
                                          'Phản hồi: $adminNote',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: isDark
                                                ? const Color(0xFFF8FAFC)
                                                : AppPalette.textDark,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
