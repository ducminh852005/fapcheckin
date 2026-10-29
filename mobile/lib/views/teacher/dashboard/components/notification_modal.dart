import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../viewmodels/dashboard_viewmodel.dart';

void showNotificationModal(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (ctx) => const NotificationModal(),
  );
}

class NotificationModal extends StatefulWidget {
  const NotificationModal({super.key});

  @override
  State<NotificationModal> createState() => _NotificationModalState();
}

class _NotificationModalState extends State<NotificationModal> {
  int _selectedTabIndex = 0;
  bool _card1Read = false;
  bool _card2Read = false;
  bool _card3Read = true;

  int get _unreadCount {
    int count = 0;
    if (!_card1Read) count++;
    if (!_card2Read) count++;
    return count;
  }

  void _markAllAsRead() {
    setState(() {
      _card1Read = true;
      _card2Read = true;
      _card3Read = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.90;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Thanh kéo nhỏ trên cùng ─────────────────────────────────────────
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Header thông báo ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Icon chuông tròn màu cam
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDE3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.notifications_rounded,
                      color: Color(0xFFEA580C),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Tiêu đề + Badge "2 mới" + Thời gian cập nhật
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Thông báo',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                            if (_unreadCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEA580C),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$_unreadCount mới',
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
                        const SizedBox(height: 3),
                        const Text(
                          'Cập nhật lúc 08:32 hôm nay',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Nút đóng (X)
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF64748B),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Action: Đánh dấu đã đọc tất cả ───────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: _unreadCount > 0 ? _markAllAsRead : null,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.done_all_rounded,
                          size: 16,
                          color: _unreadCount > 0
                              ? const Color(0xFFC2410C)
                              : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Đánh dấu đã đọc tất cả',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _unreadCount > 0
                                ? const Color(0xFFC2410C)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Bộ lọc Tabs ──────────────────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                children: [
                  _buildTabItem(0, 'Tất cả', count: 5),
                  const SizedBox(width: 8),
                  _buildTabItem(1, 'Chưa đọc', count: _unreadCount),
                  const SizedBox(width: 8),
                  _buildTabItem(2, 'Lịch dạy (2)'),
                  const SizedBox(width: 8),
                  _buildTabItem(3, 'Chuyên cần (1)'),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // ── Danh sách thông báo ──────────────────────────────────────────
            Flexible(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: _buildFilteredCards(context),
              ),
            ),

            // ── Footer: Cài đặt & Nút Đóng thông báo ────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            context.read<DashboardViewModel>().navigate(
                              'cai-dat-tro-giup',
                            );
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.settings_outlined,
                                  size: 16,
                                  color: Color(0xFF64748B),
                                ),
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Cài đặt nhận thông báo',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
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
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE2E8F0).withValues(
                          alpha: 0.7,
                        ),
                        foregroundColor: const Color(0xFF334155),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Đóng thông báo',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String label, {int? count}) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFEA580C)
              : const Color(0xFFF1F5F9),
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
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : (index == 1 && count > 0)
                          ? const Color(0xFFFFEDE3)
                          : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : (index == 1 && count > 0)
                            ? const Color(0xFFEA580C)
                            : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFilteredCards(BuildContext context) {
    final list = <Widget>[];

    final showCard1 = _selectedTabIndex == 0 ||
        (_selectedTabIndex == 1 && !_card1Read) ||
        _selectedTabIndex == 3;
    final showCard2 = _selectedTabIndex == 0 ||
        (_selectedTabIndex == 1 && !_card2Read) ||
        _selectedTabIndex == 2;
    final showCard3 = _selectedTabIndex == 0 ||
        (_selectedTabIndex == 1 && !_card3Read) ||
        _selectedTabIndex == 2;

    if (showCard1) {
      list.add(_buildCard1(context));
    }
    if (showCard2) {
      if (list.isNotEmpty) list.add(const SizedBox(height: 14));
      list.add(_buildCard2(context));
    }
    if (showCard3) {
      if (list.isNotEmpty) list.add(const SizedBox(height: 14));
      list.add(_buildCard3(context));
    }

    if (list.isEmpty) {
      list.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Text(
              'Không có thông báo nào trong mục này',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    return list;
  }

  // ── Card 1: Cảnh báo vắng sinh viên • PRN231 ───────────────────────────────
  Widget _buildCard1(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFED7AA),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF97316).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Tam giác cảnh báo màu vàng
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.warning_rounded,
                      color: Color(0xFFD97706),
                      size: 22,
                    ),
                  ),
                  if (!_card1Read)
                    Positioned(
                      top: -1,
                      right: -1,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Badge Cảnh báo chuyên cần + Thời gian
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Cảnh báo chuyên cần',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFFB45309),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: Color(0xFF94A3B8),
                            ),
                            SizedBox(width: 3),
                            Text(
                              '5 phút trước',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Cảnh báo vắng sinh viên • PRN231',
                      style: TextStyle(
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
          const SizedBox(height: 10),

          // Nội dung chi tiết
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF475569),
                height: 1.45,
              ),
              children: [
                TextSpan(text: 'Sinh viên '),
                TextSpan(
                  text: 'Bùi Ngọc Linh (HE180112)',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                TextSpan(text: ' đã vắng '),
                TextSpan(
                  text: '3/15 buổi (20%)',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFDC2626),
                  ),
                ),
                TextSpan(
                  text: ', chạm ngưỡng cấm thi theo quy chế FAP.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Footer: Lớp học + Nút Xem danh sách >
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'Lớp SE1801 • Ca 2 AL-204',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  setState(() => _card1Read = true);
                  Navigator.of(context).pop();
                  context.read<DashboardViewModel>().navigate(
                    'lich-su-diem-danh',
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEA580C),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Xem danh sách',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Card 2: Sắp tới giờ giảng dạy • Ca 2 (08:45) ──────────────────────────
  Widget _buildCard2(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFFEDD5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon đồng hồ báo thức màu cam
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDD5),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.alarm_rounded,
                      color: Color(0xFFC2410C),
                      size: 22,
                    ),
                  ),
                  if (!_card2Read)
                    Positioned(
                      top: -1,
                      right: -1,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Badge Sắp bắt đầu + Thời gian
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEDD5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Sắp bắt đầu',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFFC2410C),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: Color(0xFF94A3B8),
                            ),
                            SizedBox(width: 3),
                            Text(
                              '15 phút trước',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Sắp tới giờ giảng dạy • Ca 2 (08:45)',
                      style: TextStyle(
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
          const SizedBox(height: 10),

          // Nội dung chi tiết
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF475569),
                height: 1.45,
              ),
              children: [
                TextSpan(text: 'Lớp '),
                TextSpan(
                  text: 'PRN231 (SE1801)',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                TextSpan(text: ' tại phòng '),
                TextSpan(
                  text: 'AL-204',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                TextSpan(
                  text:
                      ' chuẩn bị bắt đầu trong 15 phút nữa. Hãy chuẩn bị mã Live QR điểm danh.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Footer: Live QR sẵn sàng + Nút Vào lớp ngay →
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.qr_code_2_rounded,
                      size: 16,
                      color: Color(0xFFC2410C),
                    ),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Live QR sẵn sàng',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFC2410C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  setState(() => _card2Read = true);
                  Navigator.of(context).pop();
                  context.read<DashboardViewModel>().navigate('diem-danh-qr');
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC2410C),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Vào lớp ngay',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Card 3: Đơn xin phép được duyệt • SWT301 ───────────────────────────────
  Widget _buildCard3(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon tài liệu màu xanh tím
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Color(0xFF4338CA),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Badge Đơn xin phép nghỉ + Thời gian
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.all(Radius.circular(6)),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              child: Text(
                                'Đơn xin phép nghỉ',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Color(0xFF4338CA),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Hôm nay, 07:15',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Đơn xin phép được duyệt • SWT301',
                      style: TextStyle(
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
          const SizedBox(height: 10),

          // Nội dung chi tiết
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF475569),
                height: 1.45,
              ),
              children: [
                TextSpan(text: 'Sinh viên '),
                TextSpan(
                  text: 'Lê Hoàng Nam (HE180124)',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                TextSpan(
                  text:
                      ' đã nộp đơn nghỉ học có xác nhận y tế cho buổi học ngày mai.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Footer: Đã ghi nhận lý do vắng có phép
          const Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 16,
                color: Color(0xFF0D9488),
              ),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Đã ghi nhận lý do vắng có phép',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0D9488),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
