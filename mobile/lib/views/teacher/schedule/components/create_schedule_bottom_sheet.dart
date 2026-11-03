import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fapcheckin_core/constants/app_colors.dart';
import 'package:fapcheckin_core/repositories/schedule_repository.dart';
import 'package:fapcheckin_core/result/api_result.dart';

import '../../dashboard/components/weekly_timetable.dart';

/// Hiển thị Modal Bottom Sheet Tạo lịch học bổ sung (Học bù / Workshop / Ôn tập)
Future<Map<String, dynamic>?> showCreateScheduleBottomSheet(
  BuildContext context, {
  ScheduleRepository? repository,
}) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xFF0F172A).withValues(alpha: 0.55),
    builder: (ctx) => CreateScheduleBottomSheet(repository: repository),
  );
}

class _SlotDef {
  final int number;
  final String label;
  final String startTime;
  final String endTime;

  const _SlotDef({
    required this.number,
    required this.label,
    required this.startTime,
    required this.endTime,
  });
}

const List<_SlotDef> _kStandardSlots = [
  _SlotDef(number: 1, label: 'Slot 1', startTime: '07:00', endTime: '08:30'),
  _SlotDef(number: 2, label: 'Slot 2', startTime: '08:45', endTime: '10:15'),
  _SlotDef(number: 3, label: 'Slot 3', startTime: '10:30', endTime: '12:00'),
  _SlotDef(number: 4, label: 'Slot 4', startTime: '12:30', endTime: '14:00'),
  _SlotDef(number: 5, label: 'Slot 5', startTime: '14:15', endTime: '15:45'),
  _SlotDef(number: 6, label: 'Slot 6', startTime: '16:00', endTime: '17:30'),
];

class _LessonTypeOption {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  const _LessonTypeOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  });
}

const List<_LessonTypeOption> _kLessonTypeOptions = [
  _LessonTypeOption(
    id: 'makeup',
    title: 'Học bù (Make-up Slot)',
    subtitle: 'Bổ sung buổi học bị hoãn hoặc thiếu tiết',
    icon: Icons.event_repeat_rounded,
    iconColor: Color(0xFFEA580C),
    iconBackground: Color(0xFFFFEDD5),
  ),
  _LessonTypeOption(
    id: 'workshop',
    title: 'Workshop (Hội thảo / Chuyên đề)',
    subtitle: 'Buổi chia sẻ, thực hành hoặc chuyên đề mở rộng',
    icon: Icons.groups_2_outlined,
    iconColor: Color(0xFF2563EB),
    iconBackground: Color(0xFFDBEAFE),
  ),
  _LessonTypeOption(
    id: 'review',
    title: 'Ôn tập (Review Slot)',
    subtitle: 'Ôn luyện kiến thức trước kiểm tra hoặc thi',
    icon: Icons.menu_book_rounded,
    iconColor: Color(0xFF7C3AED),
    iconBackground: Color(0xFFEDE9FE),
  ),
];

/// Bottom Sheet Tạo lịch học bổ sung
class CreateScheduleBottomSheet extends StatefulWidget {
  const CreateScheduleBottomSheet({super.key, this.repository});

  final ScheduleRepository? repository;

  @override
  State<CreateScheduleBottomSheet> createState() =>
      _CreateScheduleBottomSheetState();
}

class _CreateScheduleBottomSheetState extends State<CreateScheduleBottomSheet> {
  late final ScheduleRepository _repository;
  final TextEditingController _note = TextEditingController();
  final LayerLink _classMenuLink = LayerLink();
  final GlobalKey _classFieldKey = GlobalKey();
  OverlayEntry? _classMenuOverlay;
  bool _isClassMenuOpen = false;
  final LayerLink _lessonTypeMenuLink = LayerLink();
  final GlobalKey _lessonTypeFieldKey = GlobalKey();
  OverlayEntry? _lessonTypeMenuOverlay;
  bool _isLessonTypeMenuOpen = false;

  Map<String, dynamic>? _options;
  String? _error;
  String? _classCode;
  String? _slotCode;
  String? _room;
  String? _day;
  String _type = 'makeup';
  bool _loading = true;
  bool _saving = false;
  Map<String, dynamic>? _pending;

  List<Map<String, dynamic>> _rows(String key) =>
      ((_options?[key] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? context.read<ScheduleRepository>();
    _load();
  }

  @override
  void dispose() {
    _classMenuOverlay?.remove();
    _classMenuOverlay = null;
    _lessonTypeMenuOverlay?.remove();
    _lessonTypeMenuOverlay = null;
    _note.dispose();
    super.dispose();
  }

  void _closeClassMenu() {
    _classMenuOverlay?.remove();
    _classMenuOverlay = null;
    if (mounted && _isClassMenuOpen) {
      setState(() => _isClassMenuOpen = false);
    }
  }

  void _toggleClassMenu(List<Map<String, dynamic>> classes) {
    if (_isClassMenuOpen) {
      _closeClassMenu();
      return;
    }
    if (_saving || _pending != null || classes.isEmpty) return;
    _closeLessonTypeMenu();

    final renderBox =
        _classFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    setState(() => _isClassMenuOpen = true);
    _classMenuOverlay = OverlayEntry(
      builder: (overlayContext) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeClassMenu,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _classMenuLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, 8),
            child: SizedBox(
              width: renderBox.size.width,
              child: _buildClassMenuCard(classes),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_classMenuOverlay!);
  }

  void _closeLessonTypeMenu() {
    _lessonTypeMenuOverlay?.remove();
    _lessonTypeMenuOverlay = null;
    if (mounted && _isLessonTypeMenuOpen) {
      setState(() => _isLessonTypeMenuOpen = false);
    }
  }

  void _toggleLessonTypeMenu() {
    if (_isLessonTypeMenuOpen) {
      _closeLessonTypeMenu();
      return;
    }
    if (_saving || _pending != null) return;
    _closeClassMenu();

    final renderBox =
        _lessonTypeFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    setState(() => _isLessonTypeMenuOpen = true);
    _lessonTypeMenuOverlay = OverlayEntry(
      builder: (overlayContext) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeLessonTypeMenu,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _lessonTypeMenuLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, 8),
            child: SizedBox(
              width: renderBox.size.width,
              child: _buildLessonTypeMenuCard(),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_lessonTypeMenuOverlay!);
  }

  void _selectLessonType(String type) {
    setState(() => _type = type);
    _closeLessonTypeMenu();
  }

  Widget _buildLessonTypeMenuCard() {
    return Material(
      elevation: 10,
      shadowColor: const Color(0x33000000),
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CHỌN LOẠI BUỔI HỌC',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.4,
                    ),
                  ),
                  Text(
                    '3 loại',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            ..._kLessonTypeOptions.map((option) {
              final selected = option.id == _type;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _selectLessonType(option.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFFFF7ED)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: selected
                          ? Border.all(
                              color: const Color(0xFFFDBA74),
                              width: 1.2,
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: option.iconBackground,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            option.icon,
                            color: option.iconColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option.title,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? const Color(0xFFFA5A1E)
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                option.subtitle,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF64748B),
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (selected) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFFFA5A1E),
                            size: 22,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _selectClass(
    String classCode,
    List<Map<String, dynamic>> classes,
  ) {
    setState(() {
      _classCode = classCode;
      final match = classes
          .where((item) => item['classCode']?.toString() == classCode)
          .firstOrNull;
      final room = match?['room']?.toString();
      if (room != null && room.isNotEmpty) _room = room;
    });
    _closeClassMenu();
  }

  Widget _buildClassMenuCard(List<Map<String, dynamic>> classes) {
    return Material(
      elevation: 10,
      shadowColor: const Color(0x33000000),
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 380),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'CHỌN LỚP HỌC',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.4,
                    ),
                  ),
                  Text(
                    '${classes.length} lớp',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: classes.map((item) {
                    final classCode = item['classCode']?.toString() ?? '';
                    final subjectName = item['subjectName']?.toString() ?? '';
                    final selected = classCode == _classCode;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _selectClass(classCode, classes),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFFFFF7ED)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: selected
                                ? Border.all(
                                    color: const Color(0xFFFDBA74),
                                    width: 1.2,
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEDD5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.school_outlined,
                                  color: Color(0xFFEA580C),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      classCode,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: selected
                                            ? const Color(0xFFFA5A1E)
                                            : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    if (subjectName.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        subjectName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: Color(0xFF64748B),
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (selected) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFFFA5A1E),
                                  size: 22,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repository.options();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result is ApiSuccess<Map<String, dynamic>>) {
        _options = result.data;
        _day = _options!['today'] as String? ?? _todayFormatted();

        // Tự động khởi tạo slot nếu chưa chọn (ưu tiên Slot 2 như mockup hoặc slot đầu tiên)
        final repoSlots = _rows('slots');
        _slotCode = _resolveSlotCodeFor(2, repoSlots);
      } else if (result is ApiFailure<Map<String, dynamic>>) {
        _error = result.error.message;
      }
    });
  }

  String _todayFormatted() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _resolveSlotCodeFor(
    int slotNumber,
    List<Map<String, dynamic>> repoSlots,
  ) {
    if (repoSlots.isEmpty) return 'Slot $slotNumber';

    // 1. Khớp chính xác 'Slot X' hoặc 'X'
    for (final s in repoSlots) {
      final code = s['slotCode']?.toString() ?? '';
      if (code.toLowerCase() == 'slot $slotNumber' || code == '$slotNumber') {
        return code;
      }
    }

    // 2. Parse theo mã slot FAP (A1..A6, P1..P6)
    for (final s in repoSlots) {
      final code = s['slotCode']?.toString() ?? '';
      final parsed = SlotCodeParser.parse(code);
      if (parsed != null && parsed.slot == slotNumber) {
        return code;
      }
    }

    // 3. Khớp theo giờ bắt đầu chuẩn FPT
    final std = _kStandardSlots.firstWhere(
      (s) => s.number == slotNumber,
      orElse: () => _kStandardSlots[1],
    );
    for (final s in repoSlots) {
      final start = s['startTime']?.toString() ?? '';
      if (start == std.startTime) {
        return s['slotCode']?.toString() ?? 'Slot $slotNumber';
      }
    }

    // 4. Fallback theo index
    if (slotNumber - 1 < repoSlots.length) {
      return repoSlots[slotNumber - 1]['slotCode']?.toString() ??
          'Slot $slotNumber';
    }

    return repoSlots.first['slotCode']?.toString() ?? 'Slot $slotNumber';
  }

  int _selectedSlotNumber(
    String? selectedSlotCode,
    List<Map<String, dynamic>> repoSlots,
  ) {
    if (selectedSlotCode == null || selectedSlotCode.isEmpty) return 2;

    for (final std in _kStandardSlots) {
      if (selectedSlotCode.toLowerCase() == 'slot ${std.number}' ||
          selectedSlotCode == '${std.number}') {
        return std.number;
      }
    }

    final parsed = SlotCodeParser.parse(selectedSlotCode);
    if (parsed != null && parsed.slot >= 1 && parsed.slot <= 6) {
      return parsed.slot;
    }

    final repoSlot = repoSlots
        .where((s) => s['slotCode'] == selectedSlotCode)
        .firstOrNull;
    if (repoSlot != null) {
      final start = repoSlot['startTime']?.toString();
      for (final std in _kStandardSlots) {
        if (std.startTime == start) return std.number;
      }
      final idx = repoSlots.indexOf(repoSlot);
      if (idx >= 0 && idx < 6) return idx + 1;
    }

    return 2;
  }

  int? _minutes(String? value) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value ?? '');
    if (match == null) return null;
    final hour = int.tryParse(match[1]!);
    final minute = int.tryParse(match[2]!);
    if (hour == null || minute == null || hour > 23 || minute > 59) {
      return null;
    }
    return hour * 60 + minute;
  }

  Map<String, dynamic>? _regularClassConflict() {
    final day = DateTime.tryParse(_day ?? '');
    final selectedCode = _slotCode;
    if (day == null || selectedCode == null) return null;

    final slots = _rows('slots');
    Map<String, dynamic>? slotOf(String code) =>
        slots.where((slot) => slot['slotCode'] == code).firstOrNull;
    final selected = slotOf(selectedCode);
    if (selected == null) return null;
    final selectedStart = _minutes(selected['startTime']?.toString());
    final selectedEnd = _minutes(selected['endTime']?.toString());
    if (selectedStart == null || selectedEnd == null) return null;

    // Firestore dùng 2 = Thứ Hai ... 7 = Thứ Bảy, 8 = Chủ Nhật.
    final firestoreWeekday = day.weekday + 1;
    for (final regularClass in _rows('classes')) {
      final regularSlot = slotOf(regularClass['slotCode']?.toString() ?? '');
      if (regularSlot == null) continue;
      final weekdays =
          (regularSlot['weekdays'] as List?)?.whereType<num>().map(
            (value) => value.toInt(),
          ) ??
          const Iterable<int>.empty();
      if (!weekdays.contains(firestoreWeekday)) continue;
      final start = _minutes(regularSlot['startTime']?.toString());
      final end = _minutes(regularSlot['endTime']?.toString());
      if (start != null &&
          end != null &&
          start < selectedEnd &&
          end > selectedStart) {
        return regularClass;
      }
    }
    return null;
  }

  String? get _regularConflictMessage {
    final conflict = _regularClassConflict();
    if (conflict == null) return null;
    final classCode = conflict['classCode']?.toString() ?? '';
    final slotCode = conflict['slotCode']?.toString() ?? '';
    return 'Giảng viên đã có lịch chính khóa $classCode ($slotCode) trong ngày và khung giờ này. Vui lòng chọn ngày hoặc ca khác.';
  }

  String _formatVnDate(DateTime date) {
    const weekdays = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
    final weekday = weekdays[date.weekday - 1];
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$weekday, $d/$m/$y';
  }

  Future<void> _pickDate() async {
    final todayStr = _options?['today'] as String? ?? _todayFormatted();
    final first = DateTime.tryParse(todayStr) ?? DateTime.now();
    final current = DateTime.tryParse(_day ?? '') ?? first;

    final value = await showDatePicker(
      context: context,
      initialDate: current.isBefore(first) ? first : current,
      firstDate: first,
      lastDate: DateTime(first.year + 5, 12, 31),
    );
    if (value != null && mounted) {
      setState(() {
        _day =
            '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final regularConflict = _regularConflictMessage;
    if (regularConflict != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(regularConflict),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_classCode == null || _slotCode == null || _room == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn lớp học, ca học và phòng học.'),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() => _error = 'Vui lòng chọn lớp học, ca học và phòng học.');
      return;
    }

    _pending ??= {
      'requestId':
          '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(999999)}',
      'classCode': _classCode,
      'slotCode': _slotCode,
      'room': _room,
      'scheduleDate': _day,
      'lessonType': _type,
      'teachingMethod': 'onCampus',
      'note': _note.text.trim(),
    };

    setState(() {
      _saving = true;
      _error = null;
    });

    final result = await _repository.create(_pending!);
    if (!mounted) return;

    if (result is ApiSuccess<Map<String, dynamic>>) {
      Navigator.pop(context, result.data);
      return;
    }

    setState(() {
      _saving = false;
      if (result is ApiFailure<Map<String, dynamic>>) {
        _error = result.error.message;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_error!), backgroundColor: AppColors.error),
        );
        if ([
          'VALIDATION_ERROR',
          'FORBIDDEN',
          'NOT_SUPPORTED',
          'SCHEDULE_CONFLICT',
        ].contains(result.error.code)) {
          _pending = null;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final repoSlots = _rows('slots');
    final selectedSlotNum = _selectedSlotNumber(_slotCode, repoSlots);
    final activeSlotDef = _kStandardSlots.firstWhere(
      (s) => s.number == selectedSlotNum,
      orElse: () => _kStandardSlots[1],
    );
    final visibleError = _regularConflictMessage ?? _error;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.94,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Thanh kéo trên cùng ──────────────────────────────────────
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Thân cuộn của modal ──────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header: Icon Huy hiệu cam + Tiêu đề + Giảng viên + Nút đóng
                    _buildHeader(),
                    const SizedBox(height: 14),

                    // Thẻ thông báo FAP
                    _buildFapNoticeCard(),
                    const SizedBox(height: 18),

                    if (_loading) ...[
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: CircularProgressIndicator(
                            color: Color(0xFFEA580C),
                          ),
                        ),
                      ),
                    ] else if (_options != null) ...[
                      // 1. LOẠI BUỔI HỌC *
                      _buildLessonTypeSection(),
                      const SizedBox(height: 16),

                      // 2. LỚP HỌC *
                      _buildClassSection(),
                      const SizedBox(height: 16),

                      // 3. CA HỌC (SLOT) *
                      _buildSlotGridSection(repoSlots, activeSlotDef),
                      const SizedBox(height: 16),

                      // 4. PHÒNG HỌC *
                      _buildRoomSection(),
                      const SizedBox(height: 16),

                      // 5. NGÀY HỌC BÙ
                      _buildDateSection(),
                      const SizedBox(height: 16),

                      // 6. HÌNH THỨC HỌC
                      _buildTeachingMethodSection(),
                      const SizedBox(height: 16),

                      // 7. GHI CHÚ
                      _buildNoteSection(),
                      const SizedBox(height: 12),
                    ],

                    if (visibleError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Color(0xFFDC2626),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                visibleError,
                                style: const TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (!_loading && _options == null)
                      Center(
                        child: TextButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Thử tải lại dữ liệu'),
                        ),
                      ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),

            // ── Chân trang cố định: Hủy bỏ & Xác nhận tạo lịch ─────────────
            _buildFooter(bottomPadding),
          ],
        ),
      ),
    );
  }

  // ── 1. Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final teacherName = _options?['teacherName'] ?? 'Giảng viên';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFED7AA), width: 1.2),
          ),
          child: const Icon(
            Icons.edit_calendar_rounded,
            color: Color(0xFFEA580C),
            size: 23,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tạo lịch học bổ sung',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 6.5,
                    height: 6.5,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Giảng viên: $teacherName · FPTU',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        InkWell(
          onTap: _saving ? null : () => Navigator.pop(context),
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
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── 2. Thẻ lưu ý FAP ───────────────────────────────────────────────────────
  Widget _buildFapNoticeCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFEDD5), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFFEA580C),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 11.8,
                  color: Color(0xFF7C2D12),
                  height: 1.38,
                ),
                children: [
                  TextSpan(
                    text: 'Lưu ý FAP: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFC2410C),
                    ),
                  ),
                  TextSpan(
                    text: 'Lịch học bổ sung sẽ được đồng bộ tự động lên cổng FAP và gửi thông báo push đến toàn bộ sinh viên trong lớp sau khi xác nhận.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. LOẠI BUỔI HỌC ──────────────────────────────────────────────────────
  Widget _buildLessonTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.category_outlined,
              size: 15,
              color: Color(0xFFEA580C),
            ),
            const SizedBox(width: 6),
            const Text(
              'LOẠI BUỔI HỌC',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF334155),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 3),
            const Text(
              '*',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEDD5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Bắt buộc',
                style: TextStyle(
                  color: Color(0xFFEA580C),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        CompositedTransformTarget(
          link: _lessonTypeMenuLink,
          child: InkWell(
            key: _lessonTypeFieldKey,
            borderRadius: BorderRadius.circular(12),
            onTap: _toggleLessonTypeMenu,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isLessonTypeMenuOpen
                      ? const Color(0xFFFA5A1E)
                      : const Color(0xFFE2E8F0),
                  width: _isLessonTypeMenuOpen ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _kLessonTypeOptions
                          .firstWhere((option) => option.id == _type)
                          .iconBackground,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      _kLessonTypeOptions
                          .firstWhere((option) => option.id == _type)
                          .icon,
                      color: _kLessonTypeOptions
                          .firstWhere((option) => option.id == _type)
                          .iconColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _kLessonTypeOptions
                          .firstWhere((option) => option.id == _type)
                          .title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  Icon(
                    _isLessonTypeMenuOpen
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF64748B),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── 4. LỚP HỌC ─────────────────────────────────────────────────────────────
  Widget _buildClassSection() {
    final classes = _rows('classes');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.school_outlined, size: 15, color: Color(0xFFEA580C)),
            SizedBox(width: 6),
            Text(
              'LỚP HỌC',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF334155),
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(width: 3),
            Text(
              '*',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        CompositedTransformTarget(
          link: _classMenuLink,
          child: InkWell(
            key: _classFieldKey,
            borderRadius: BorderRadius.circular(12),
            onTap: () => _toggleClassMenu(classes),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isClassMenuOpen
                      ? const Color(0xFFFA5A1E)
                      : const Color(0xFFE2E8F0),
                  width: _isClassMenuOpen ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDD5),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.school_outlined,
                      color: Color(0xFFEA580C),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _classCode == null
                        ? const Text(
                            'Chọn lớp học',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF94A3B8),
                            ),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _classCode!,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                classes
                                        .where(
                                          (item) =>
                                              item['classCode']?.toString() ==
                                              _classCode,
                                        )
                                        .firstOrNull?['subjectName']
                                        ?.toString() ??
                                    '',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                  ),
                  Icon(
                    _isClassMenuOpen
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF64748B),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── 5. CA HỌC (SLOT) GRID ──────────────────────────────────────────────────
  Widget _buildSlotGridSection(
    List<Map<String, dynamic>> repoSlots,
    _SlotDef activeSlotDef,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.access_time_rounded,
              size: 15,
              color: Color(0xFFEA580C),
            ),
            const SizedBox(width: 6),
            const Text(
              'CA HỌC (SLOT)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF334155),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 3),
            const Text(
              '*',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '${activeSlotDef.label} (${activeSlotDef.startTime} – ${activeSlotDef.endTime})',
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Grid 3 cột x 2 hàng
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 16) / 3;

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _kStandardSlots.map((slotDef) {
                final isSelected = activeSlotDef.number == slotDef.number;

                return SizedBox(
                  width: cardWidth,
                  child: InkWell(
                    onTap: _saving || _pending != null
                        ? null
                        : () {
                            setState(() {
                              _slotCode = _resolveSlotCodeFor(
                                slotDef.number,
                                repoSlots,
                              );
                            });
                          },
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFFF7ED)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFEA580C)
                              : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.6 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isSelected ? '${slotDef.label} ✓' : slotDef.label,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? const Color(0xFFEA580C)
                                  : const Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${slotDef.startTime} – ${slotDef.endTime}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFFC2410C)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // ── 6. PHÒNG HỌC ───────────────────────────────────────────────────────────
  Widget _buildRoomSection() {
    final rooms = (_options?['rooms'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.meeting_room_outlined,
              size: 15,
              color: Color(0xFFEA580C),
            ),
            const SizedBox(width: 6),
            const Text(
              'PHÒNG HỌC',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF334155),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 3),
            const Text(
              '*',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'Phòng trống',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF15803D),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _room,
          isExpanded: true,
          hint: const Text(
            'Chọn phòng học',
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
          decoration: _inputDecoration(),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF64748B),
          ),
          items: rooms
              .map(
                (r) => DropdownMenuItem(
                  value: r.toString(),
                  child: Text(
                    r.toString().startsWith('Phòng')
                        ? r.toString()
                        : 'Phòng ${r.toString()}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: _saving || _pending != null
              ? null
              : (v) => setState(() => _room = v),
        ),
      ],
    );
  }

  // ── 7. NGÀY HỌC BÙ ─────────────────────────────────────────────────────────
  Widget _buildDateSection() {
    final parsedDate = DateTime.tryParse(_day ?? '') ?? DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 15,
              color: Color(0xFFEA580C),
            ),
            SizedBox(width: 6),
            Text(
              'NGÀY HỌC BÙ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF334155),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFEDD5), width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Color(0xFFEA580C),
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NGÀY ĐÃ CHỌN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatVnDate(parsedDate),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 34,
                child: OutlinedButton(
                  onPressed: _saving || _pending != null ? null : _pickDate,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Đổi ngày',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFEA580C),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 8. HÌNH THỨC HỌC ───────────────────────────────────────────────────────
  Widget _buildTeachingMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.cast_for_education_rounded,
              size: 15,
              color: Color(0xFFEA580C),
            ),
            SizedBox(width: 6),
            Text(
              'HÌNH THỨC HỌC',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF334155),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Row(
            children: [
              Icon(Icons.domain_rounded, size: 17, color: Color(0xFFEA580C)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Trực tiếp tại phòng học (On-campus)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: Color(0xFF10B981),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 9. GHI CHÚ ─────────────────────────────────────────────────────────────
  Widget _buildNoteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.edit_note_rounded, size: 16, color: Color(0xFFEA580C)),
            SizedBox(width: 6),
            Text(
              'GHI CHÚ (TÙY CHỌN)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF334155),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _note,
          enabled: !_saving && _pending == null,
          maxLength: 2000,
          maxLines: 2,
          style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
          decoration: _inputDecoration(
            hintText: 'Nhập nội dung lưu ý cho sinh viên (nếu có)...',
          ),
        ),
      ],
    );
  }

  // ── 10. Chân trang cố định ─────────────────────────────────────────────────
  Widget _buildFooter(double bottomPadding) {
    final hasRegularConflict = _regularConflictMessage != null;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 14 + bottomPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 105,
            height: 48,
            child: TextButton(
              onPressed: _saving ? null : () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                foregroundColor: const Color(0xFF334155),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Hủy bỏ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _saving || _options == null || hasRegularConflict
                    ? null
                    : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 19,
                        color: Colors.white,
                      ),
                label: Text(
                  _saving
                      ? 'Đang lưu…'
                      : _pending == null
                      ? 'Xác nhận tạo lịch'
                      : 'Thử lại cùng yêu cầu',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFA5A1E),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFFA5A1E)
                      .withValues(alpha: 0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEA580C), width: 1.4),
      ),
    );
  }
}
