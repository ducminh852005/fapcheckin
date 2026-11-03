import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin_core/repositories/account_features_repository.dart';

import 'feedback_modal_sheet.dart';

/// Hiển thị Modal Sheet "Lịch sử góp ý đã gửi" chuẩn phong cách FAP Check-in
Future<T?> showFeedbackHistoryBottomSheet<T>(BuildContext context) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const FeedbackHistoryModalSheet(),
  );
}

class FeedbackHistoryModalSheet extends StatefulWidget {
  const FeedbackHistoryModalSheet({super.key});

  @override
  State<FeedbackHistoryModalSheet> createState() =>
      _FeedbackHistoryModalSheetState();
}

class _FeedbackHistoryModalSheetState extends State<FeedbackHistoryModalSheet> {
  // Filter state: 'all' (Tất cả), 'processing' (Đang xử lý), 'replied' (Đã phản hồi)
  String _activeFilter = 'all';

  Stream<List<Map<String, dynamic>>>? _stream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repo = context.read<AccountFeaturesRepository?>();
    if (repo != null && _stream == null) {
      _stream = repo.feedback();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x2E000000),
            blurRadius: 40,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Handle Bar
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Header Modal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDD5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 18,
                        color: Color(0xFFEA580C),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'Góp ý đã gửi',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              TextSpan(
                                text: ' / My feedback',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Hệ thống ghi nhận và phản hồi từ FPT Edu IT Support',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Dải phân cách viền
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

            // Content & List
            Expanded(
              child: _stream == null
                  ? const Center(
                      child: Text(
                        'Chưa kết nối dịch vụ phản hồi.',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                    )
                  : StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _stream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                'Không tải được lịch sử: ${snapshot.error}',
                                style: const TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }

                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFEA580C),
                            ),
                          );
                        }

                        final allList = snapshot.data!;
                        final totalCount = allList.length;
                        final processingCount = allList.where((item) {
                          final status = (item['status']?.toString() ?? 'pending').toLowerCase();
                          return status == 'pending' || status == 'processing';
                        }).length;
                        final repliedCount = allList.where((item) {
                          final status = (item['status']?.toString() ?? '').toLowerCase();
                          final reply = item['reply']?.toString() ?? '';
                          return status == 'replied' || status == 'resolved' || reply.isNotEmpty;
                        }).length;

                        // Filter list
                        final filteredList = allList.where((item) {
                          final status = (item['status']?.toString() ?? 'pending').toLowerCase();
                          final reply = item['reply']?.toString() ?? '';
                          if (_activeFilter == 'processing') {
                            return status == 'pending' || status == 'processing';
                          }
                          if (_activeFilter == 'replied') {
                            return status == 'replied' || status == 'resolved' || reply.isNotEmpty;
                          }
                          return true;
                        }).toList();

                        return Column(
                          children: [
                            // Filter Tabs Ribbon
                            _buildFilterRibbon(
                              total: totalCount,
                              processing: processingCount,
                              replied: repliedCount,
                            ),

                            // Items List
                            Expanded(
                              child: filteredList.isEmpty
                                  ? _buildEmptyState()
                                  : ListView.separated(
                                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                                      itemCount: filteredList.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                                      itemBuilder: (ctx, idx) => _buildFeedbackCard(
                                        ctx,
                                        filteredList[idx],
                                      ),
                                    ),
                            ),
                          ],
                        );
                      },
                    ),
            ),

            // Action Buttons Footer
            _buildFooter(context),

            // Home Indicator Bar
            Center(
              child: Container(
                width: 128,
                height: 4,
                margin: const EdgeInsets.only(top: 2, bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Filter Ribbon
  Widget _buildFilterRibbon({
    required int total,
    required int processing,
    required int replied,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterPill(
              key: 'all',
              label: 'Tất cả',
              count: total,
              badgeBg: _activeFilter == 'all'
                  ? Colors.white.withOpacity(0.2)
                  : const Color(0xFFF1F5F9),
              badgeText: _activeFilter == 'all'
                  ? Colors.white
                  : const Color(0xFF475569),
            ),
            const SizedBox(width: 8),
            _buildFilterPill(
              key: 'processing',
              label: 'Đang xử lý',
              count: processing,
              badgeBg: const Color(0xFFFEF3C7),
              badgeText: const Color(0xFF92400E),
            ),
            const SizedBox(width: 8),
            _buildFilterPill(
              key: 'replied',
              label: 'Đã phản hồi',
              count: replied,
              badgeBg: const Color(0xFFD1FAE5),
              badgeText: const Color(0xFF065F46),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill({
    required String key,
    required String label,
    required int count,
    required Color badgeBg,
    required Color badgeText,
  }) {
    final isSelected = _activeFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEA580C) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFEA580C)
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x26EA580C),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: badgeText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Card Feedback Item
  Widget _buildFeedbackCard(BuildContext context, Map<String, dynamic> item) {
    final category = item['category']?.toString() ?? 'other';
    final fullMessage = item['message']?.toString() ?? '';
    final status = (item['status']?.toString() ?? 'pending').toLowerCase();
    final reply = item['reply']?.toString() ?? '';
    final adminName = item['adminName']?.toString() ?? 'Quản trị viên FAP (IT Support)';
    final createdAt = item['createdAt'] as Timestamp?;
    final replyAt = item['resolvedAt'] as Timestamp? ?? item['replyAt'] as Timestamp? ?? item['updatedAt'] as Timestamp?;
    final ticketCode = _formatTicketCode(item['id']?.toString() ?? '', createdAt);

    final titleAndBody = _parseTitleAndBody(category, fullMessage);
    final title = titleAndBody['title']!;
    final body = titleAndBody['body']!;

    // Category styling
    final catInfo = _getCategoryStyle(category);

    // Status styling
    final bool isReplied = status == 'replied' || status == 'resolved' || reply.isNotEmpty;
    final bool isClosed = status == 'closed';

    String statusText = 'Đang xử lý';
    Color statusBg = const Color(0xFFFFF7ED);
    Color statusBorder = const Color(0xFFFED7AA);
    Color statusTextCol = const Color(0xFFEA580C);
    Color dotCol = const Color(0xFFEA580C);

    if (isClosed) {
      statusText = 'Đã đóng';
      statusBg = const Color(0xFFF1F5F9);
      statusBorder = const Color(0xFFE2E8F0);
      statusTextCol = const Color(0xFF475569);
      dotCol = const Color(0xFF64748B);
    } else if (isReplied) {
      statusText = 'Đã phản hồi';
      statusBg = const Color(0xFFECFDF5);
      statusBorder = const Color(0xFFA7F3D0);
      statusTextCol = const Color(0xFF047857);
      dotCol = const Color(0xFF10B981);
    }

    final sentTimeStr = createdAt != null
        ? '${createdAt.toDate().hour.toString().padLeft(2, '0')}:${createdAt.toDate().minute.toString().padLeft(2, '0')}, ${createdAt.toDate().day.toString().padLeft(2, '0')}/${createdAt.toDate().month.toString().padLeft(2, '0')}/${createdAt.toDate().year}'
        : 'Gần đây';

    final replyTimeStr = replyAt != null
        ? '${replyAt.toDate().hour.toString().padLeft(2, '0')}:${replyAt.toDate().minute.toString().padLeft(2, '0')} • ${replyAt.toDate().day.toString().padLeft(2, '0')}/${replyAt.toDate().month.toString().padLeft(2, '0')}'
        : 'Hôm nay';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Category tag + Ticket Code + Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: catInfo['bg'] as Color,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: catInfo['border'] as Color),
                    ),
                    child: Text(
                      catInfo['label'] as String,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: catInfo['text'] as Color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    ticketCode,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: dotCol,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusTextCol,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 4),

          // Body Message
          Text(
            body,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF475569),
              height: 1.45,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Response Box from Admin (if reply exists)
          if (reply.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(
                    color: isReplied ? const Color(0xFF10B981) : const Color(0xFFEA580C),
                    width: 4,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isReplied
                                ? Icons.verified_rounded
                                : Icons.support_agent_rounded,
                            size: 14,
                            color: isReplied
                                ? const Color(0xFF059669)
                                : const Color(0xFFEA580C),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            adminName,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        replyTimeStr,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reply,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF475569),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Card Footer
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gửi lúc: $sentTimeStr',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                GestureDetector(
                  onTap: () => _showDetailDialog(
                    context,
                    item,
                    ticketCode,
                    title,
                    body,
                    statusText,
                    statusBg,
                    statusTextCol,
                    catInfo,
                    sentTimeStr,
                  ),
                  child: const Text(
                    'Chi tiết ›',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFEA580C),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Footer Action Bar
  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Column(
        children: [
          // Button Primary: Gửi góp ý mới
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                showFeedbackBottomSheet(context);
              },
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Gửi góp ý mới / New Feedback',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                foregroundColor: Colors.white,
                elevation: 3,
                shadowColor: const Color(0x40EA580C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Button Secondary: Đóng / Close
          SizedBox(
            width: double.infinity,
            height: 36,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Đóng / Close',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String msg = 'Chưa có góp ý nào được ghi nhận.';
    if (_activeFilter == 'processing') {
      msg = 'Không có góp ý nào đang xử lý.';
    } else if (_activeFilter == 'replied') {
      msg = 'Chưa có góp ý nào được phản hồi.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 26,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              msg,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                showFeedbackBottomSheet(context);
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Gửi góp ý ngay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Detail Modal Dialog
  void _showDetailDialog(
    BuildContext context,
    Map<String, dynamic> item,
    String ticketCode,
    String title,
    String body,
    String statusText,
    Color statusBg,
    Color statusTextCol,
    Map<String, dynamic> catInfo,
    String sentTimeStr,
  ) {
    final reply = item['reply']?.toString() ?? '';
    final adminName = item['adminName']?.toString() ?? 'Quản trị viên FAP (IT Support)';
    final attachments = item['attachments'] as List? ?? [];

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: catInfo['bg'] as Color,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: catInfo['border'] as Color),
                        ),
                        child: Text(
                          catInfo['label'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: catInfo['text'] as Color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ticketCode,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusTextCol,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 12),

              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),

              const SizedBox(height: 6),

              // Message Body
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  body,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF334155),
                    height: 1.45,
                  ),
                ),
              ),

              // Image Attachments if present
              if (attachments.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text(
                  'Hình ảnh minh chứng:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (int i = 0; i < attachments.length; i++)
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: const Icon(
                          Icons.image_outlined,
                          size: 24,
                          color: Color(0xFFEA580C),
                        ),
                      ),
                  ],
                ),
              ],

              // Response from Admin
              if (reply.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            size: 15,
                            color: Color(0xFF059669),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            adminName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF065F46),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reply,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF047857),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),
              Text(
                'Thời gian gửi: $sentTimeStr',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                ),
              ),

              const SizedBox(height: 16),

              // Close button
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA580C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Đóng',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helpers
  String _formatTicketCode(String id, Timestamp? createdAt) {
    if (id.startsWith('#FB-')) return id;
    if (createdAt != null) {
      final dt = createdAt.toDate();
      final dateCode =
          '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';
      final suffix = id.length >= 2 ? id.substring(id.length - 2).toUpperCase() : '01';
      return '#FB-$dateCode-$suffix';
    }
    return '#FB-20261008-01';
  }

  Map<String, String> _parseTitleAndBody(String category, String raw) {
    String title = '';
    String body = raw;

    // Check bracket tag [Lỗi quét mã QR điểm danh]
    if (raw.startsWith('[') && raw.contains(']')) {
      final endTag = raw.indexOf(']');
      title = raw.substring(1, endTag).trim();
      body = raw.substring(endTag + 1).trim();
    } else {
      // First line as title
      final lines = raw.split('\n');
      if (lines.length > 1 && lines[0].length < 70) {
        title = lines[0].trim();
        body = lines.sublist(1).join('\n').trim();
      } else if (raw.length > 50) {
        title = '${raw.substring(0, 48)}...';
      } else {
        title = raw;
      }
    }

    if (title.isEmpty) {
      if (category == 'qr_error') {
        title = 'Lỗi quét mã QR điểm danh';
      } else if (category == 'bug') {
        title = 'Báo lỗi ứng dụng / Bug';
      } else if (category == 'suggestion') {
        title = 'Đề xuất tính năng mới';
      } else if (category == 'schedule_error') {
        title = 'Sai lệch dữ liệu ca học / Lịch dạy';
      } else {
        title = 'Góp ý hệ thống';
      }
    }

    return {'title': title, 'body': body};
  }

  Map<String, dynamic> _getCategoryStyle(String category) {
    switch (category) {
      case 'qr_error':
        return {
          'label': 'Báo lỗi QR',
          'bg': const Color(0xFFFEF2F2),
          'border': const Color(0xFFFEE2E2),
          'text': const Color(0xFFDC2626),
        };
      case 'bug':
        return {
          'label': 'Báo lỗi ứng dụng',
          'bg': const Color(0xFFFEF2F2),
          'border': const Color(0xFFFEE2E2),
          'text': const Color(0xFFDC2626),
        };
      case 'suggestion':
        return {
          'label': 'Đề xuất',
          'bg': const Color(0xFFFFFBEB),
          'border': const Color(0xFFFEF3C7),
          'text': const Color(0xFFB45309),
        };
      case 'schedule_error':
        return {
          'label': 'Dữ liệu ca học',
          'bg': const Color(0xFFEFF6FF),
          'border': const Color(0xFFDBEAFE),
          'text': const Color(0xFF1D4ED8),
        };
      default:
        return {
          'label': 'Góp ý khác',
          'bg': const Color(0xFFFAF5FF),
          'border': const Color(0xFFF3E8FF),
          'text': const Color(0xFF7E22CE),
        };
    }
  }
}

