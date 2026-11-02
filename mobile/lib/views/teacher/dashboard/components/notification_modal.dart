import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin_core/repositories/account_features_repository.dart';
import 'package:fapcheckin_core/repositories/announcement_repository.dart';

import '../../../../viewmodels/dashboard_viewmodel.dart';

/// Hiển thị Popup Thông báo dạng Bottom Sheet trượt từ dưới lên từ nút chuông ở Header
Future<void> showNotificationModal(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xFF0F172A).withValues(alpha: 0.55),
    builder: (ctx) => const NotificationModal(),
  );
}

enum _NotifFilter { all, unread, schedule, attendance }

class NotificationModal extends StatefulWidget {
  const NotificationModal({super.key, this.announcements});

  final Stream<List<Map<String, dynamic>>>? announcements;

  @override
  State<NotificationModal> createState() => _NotificationModalState();
}

class _NotificationModalState extends State<NotificationModal> {
  _NotifFilter _selectedFilter = _NotifFilter.all;
  final Set<String> _locallyReadIds = <String>{};
  Stream<List<Map<String, dynamic>>>? _stream;

  @override
  void initState() {
    super.initState();
    _stream = widget.announcements;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_stream == null && widget.announcements == null) {
      final accountRepo = context.read<AccountFeaturesRepository?>();
      final announcementRepo = context.read<AnnouncementRepository?>();
      if (accountRepo != null && announcementRepo != null) {
        _stream = _combineStreams(
          accountRepo.notifications(),
          announcementRepo.watch(),
        );
      } else if (accountRepo != null) {
        _stream = accountRepo.notifications();
      } else if (announcementRepo != null) {
        _stream = announcementRepo.watch();
      }
    }
  }

  Stream<List<Map<String, dynamic>>> _combineStreams(
    Stream<List<Map<String, dynamic>>> userNotifs,
    Stream<List<Map<String, dynamic>>> generalAnnouncements,
  ) {
    late StreamController<List<Map<String, dynamic>>> controller;
    List<Map<String, dynamic>> latestUser = const [];
    List<Map<String, dynamic>> latestGeneral = const [];
    bool hasUser = false;
    bool hasGeneral = false;
    StreamSubscription<List<Map<String, dynamic>>>? sub1;
    StreamSubscription<List<Map<String, dynamic>>>? sub2;

    void emitIfReady() {
      if (!controller.isClosed && (hasUser || hasGeneral)) {
        controller.add([...latestUser, ...latestGeneral]);
      }
    }

    controller = StreamController<List<Map<String, dynamic>>>(
      onListen: () {
        sub1 = userNotifs.listen(
          (data) {
            latestUser = data
                .map((d) => {...d, '_source': 'user_notifications'})
                .toList();
            hasUser = true;
            emitIfReady();
          },
          onError: (Object e, StackTrace st) {
            if (!hasGeneral && !controller.isClosed) {
              controller.addError(e, st);
            } else {
              hasUser = true;
              emitIfReady();
            }
          },
        );
        sub2 = generalAnnouncements.listen(
          (data) {
            latestGeneral = data
                .map((d) => {...d, '_source': 'announcements'})
                .toList();
            hasGeneral = true;
            emitIfReady();
          },
          onError: (Object e, StackTrace st) {
            if (!hasUser && !controller.isClosed) {
              controller.addError(e, st);
            } else {
              hasGeneral = true;
              emitIfReady();
            }
          },
        );
      },
      onCancel: () async {
        await sub1?.cancel();
        await sub2?.cancel();
      },
    );
    return controller.stream;
  }

  bool _isRead(Map<String, dynamic> row, int index) {
    final id = (row['id'] ?? 'idx_$index').toString();
    if (_locallyReadIds.contains(id)) return true;
    return row['read'] == true;
  }

  Future<void> _markAllAsRead(List<Map<String, dynamic>> rows) async {
    final accountRepo = context.read<AccountFeaturesRepository?>();
    setState(() {
      for (var i = 0; i < rows.length; i++) {
        final id = (rows[i]['id'] ?? 'idx_$i').toString();
        _locallyReadIds.add(id);
      }
    });
    if (accountRepo != null) {
      for (final row in rows) {
        final id = row['id']?.toString() ?? '';
        if (id.isNotEmpty &&
            row['read'] != true &&
            row['_source'] != 'announcements') {
          await accountRepo.markRead(id);
        }
      }
    }
  }

  Future<void> _markOneAsRead(Map<String, dynamic> row, int index) async {
    final id = (row['id'] ?? 'idx_$index').toString();
    setState(() {
      _locallyReadIds.add(id);
    });
    final accountRepo = context.read<AccountFeaturesRepository?>();
    if (accountRepo != null &&
        row['id'] != null &&
        row['_source'] != 'announcements') {
      await accountRepo.markRead(row['id'].toString());
    }
  }

  String _categoryOf(Map<String, dynamic> row) {
    final type = (row['type'] ?? row['category'] ?? '').toString().toLowerCase();
    if (type.contains('reminder') || type.contains('schedule')) {
      return 'schedule';
    }
    if (type.contains('attendance') || type.contains('absent')) {
      return 'attendance';
    }
    return 'other';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxHeight = (screenHeight * 0.88).clamp(360.0, 780.0);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
          maxWidth: 520,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Color(0x280F172A),
              blurRadius: 32,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: SafeArea(
            top: false,
            child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _stream,
          builder: (context, snapshot) {
            final rows = snapshot.data ?? const <Map<String, dynamic>>[];
            final unreadCount = rows
                .asMap()
                .entries
                .where((e) => !_isRead(e.value, e.key))
                .length;
            final scheduleCount =
                rows.where((r) => _categoryOf(r) == 'schedule').length;
            final attendanceCount =
                rows.where((r) => _categoryOf(r) == 'attendance').length;

            final filteredEntries = rows.asMap().entries.where((entry) {
              switch (_selectedFilter) {
                case _NotifFilter.all:
                  return true;
                case _NotifFilter.unread:
                  return !_isRead(entry.value, entry.key);
                case _NotifFilter.schedule:
                  return _categoryOf(entry.value) == 'schedule';
                case _NotifFilter.attendance:
                  return _categoryOf(entry.value) == 'attendance';
              }
            }).toList();

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Thanh kéo (Drag handle)
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 4),
                    width: 42,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // 2. Header: Icon chuông cam + Tiêu đề + Badge "mới" + Nút X
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFEDE5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          color: Color(0xFFD84315),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Flexible(
                                  child: Text(
                                    'Thông báo',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                                if (unreadCount > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD84315),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$unreadCount mới',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Cập nhật trực tuyến',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

                // 3. Nút "Đánh dấu đã đọc tất cả"
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: rows.isEmpty ? null : () => _markAllAsRead(rows),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.done_all_rounded,
                              size: 15,
                              color: rows.isEmpty
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFFC2410C),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Đánh dấu đã đọc tất cả',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: rows.isEmpty
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFFC2410C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 4. Thanh Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(18, 2, 18, 12),
                  child: Row(
                    children: [
                      _buildFilterTab(
                        label: 'Tất cả',
                        badgeCount: rows.length,
                        isSelected: _selectedFilter == _NotifFilter.all,
                        onTap: () =>
                            setState(() => _selectedFilter = _NotifFilter.all),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterTab(
                        label: 'Chưa đọc',
                        badgeCount: unreadCount,
                        isSelected: _selectedFilter == _NotifFilter.unread,
                        onTap: () => setState(
                          () => _selectedFilter = _NotifFilter.unread,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterTab(
                        label: 'Lịch dạy ($scheduleCount)',
                        isSelected: _selectedFilter == _NotifFilter.schedule,
                        onTap: () => setState(
                          () => _selectedFilter = _NotifFilter.schedule,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterTab(
                        label: 'Chuyên cần ($attendanceCount)',
                        isSelected: _selectedFilter == _NotifFilter.attendance,
                        onTap: () => setState(
                          () => _selectedFilter = _NotifFilter.attendance,
                        ),
                      ),
                    ],
                  ),
                ),

                // 5. Danh sách thẻ thông báo
                Flexible(
                  child: Builder(
                    builder: (context) {
                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              'Không thể tải thông báo: ${snapshot.error}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      if (_stream != null &&
                          snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (filteredEntries.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: Text('Chưa có thông báo.')),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 2, 18, 14),
                        shrinkWrap: true,
                        itemCount: filteredEntries.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, idx) {
                          final entry = filteredEntries[idx];
                          return _buildNotificationCard(
                            entry.value,
                            entry.key,
                            isUnread: !_isRead(entry.value, entry.key),
                          );
                        },
                      );
                    },
                  ),
                ),

                // 6. Footer: Cài đặt nhận thông báo + Nút Đóng thông báo
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: InkWell(
                              onTap: () {
                                final dashVm =
                                    context.read<DashboardViewModel?>();
                                Navigator.of(context).pop();
                                dashVm?.navigate('cai-dat-tro-giup');
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.settings_outlined,
                                      size: 16,
                                      color: Color(0xFF475569),
                                    ),
                                    SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        'Cài đặt nhận thông báo',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'FAP v3.4.1',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 44,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFE2E8F0)
                                .withValues(alpha: 0.7),
                            foregroundColor: const Color(0xFF0F172A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Đóng thông báo',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  ),
);
}

  Widget _buildFilterTab({
    required String label,
    int? badgeCount,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final bgColor =
        isSelected ? const Color(0xFFC2410C) : const Color(0xFFF1F5F9);
    final textColor = isSelected ? Colors.white : const Color(0xFF475569);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: textColor,
              ),
            ),
            if (badgeCount != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : const Color(0xFFFFEDD5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : const Color(0xFFC2410C),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    Map<String, dynamic> row,
    int index, {
    required bool isUnread,
  }) {
    final title = (row['title'] ?? 'Thông báo').toString();
    final body = (row['body'] ?? row['content'] ?? '').toString();
    final category = _categoryOf(row);
    final isSchedule = category == 'schedule';
    final isAttendance = category == 'attendance';

    final badgeLabel = isSchedule
        ? 'Sắp bắt đầu'
        : (isAttendance ? 'Cảnh báo chuyên cần' : 'Thông báo hệ thống');
    final badgeBg = isSchedule
        ? const Color(0xFFFFE4D6)
        : (isAttendance ? const Color(0xFFFFEDD5) : const Color(0xFFEEF2FF));
    final badgeFg = isSchedule
        ? const Color(0xFFB91C1C)
        : (isAttendance ? const Color(0xFFC2410C) : const Color(0xFF4338CA));
    final icon = isSchedule
        ? Icons.alarm_rounded
        : (isAttendance
            ? Icons.warning_rounded
            : Icons.notifications_outlined);

    return InkWell(
      onTap: () => _markOneAsRead(row, index),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnread ? const Color(0xFFFFFBF5) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isUnread
                ? const Color(0xFFFED7AA)
                : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: badgeFg, size: 22),
                    ),
                    if (isUnread)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: const Color(0xFFC2410C),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: badgeFg,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (body.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF475569),
                  height: 1.45,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
