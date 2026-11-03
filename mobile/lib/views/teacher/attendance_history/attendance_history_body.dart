import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin_core/models/history_detail.dart';
import 'package:fapcheckin_core/models/session_model.dart';
import 'package:fapcheckin_core/result/api_result.dart';

import '../../../viewmodels/attendance_history_viewmodel.dart';
import '../../../viewmodels/dashboard_viewmodel.dart';
import 'attendance_history_colors.dart';
import 'components/attendance_history_header.dart';
import 'components/attendance_summary_card.dart';
import 'components/attendance_search_filter_bar.dart';
import 'components/attendance_session_selector.dart';
import 'components/attendance_student_card.dart';
import 'components/attendance_save_action_button.dart';
import 'history_actions.dart';

class _PendingEdit {
  final String status;
  final String note;
  final String checkinTime;

  const _PendingEdit({
    required this.status,
    required this.note,
    required this.checkinTime,
  });
}

class AttendanceHistoryBody extends StatefulWidget {
  const AttendanceHistoryBody({super.key});

  @override
  State<AttendanceHistoryBody> createState() => _AttendanceHistoryBodyState();
}

class _AttendanceHistoryBodyState extends State<AttendanceHistoryBody> {
  final TextEditingController _searchController = TextEditingController();
  AttendanceFilterType _activeFilter = AttendanceFilterType.all;
  String _searchQuery = '';

  String? _loadedClassCode;
  String? _selectedSessionId;
  String? _loadedSessionStatus;
  HistoryDetail? _detail;
  bool _loadingDetail = false;
  bool _savingSession = false;

  // Lưu các chỉnh sửa cục bộ trước hoặc trong khi đồng bộ lên Firestore
  final Map<String, _PendingEdit> _pendingEdits = {};

  static const List<(Color, Color)> _avatarPalettes = [
    (Color(0xFFE0F2FE), Color(0xFF0284C7)),
    (Color(0xFFEDE9FE), Color(0xFF7C3AED)),
    (Color(0xFFFFE4E6), Color(0xFFE11D48)),
    (Color(0xFFF3E8FF), Color(0xFF9333EA)),
    (Color(0xFFFEF3C7), Color(0xFFD97706)),
    (Color(0xFFD1FAE5), Color(0xFF059669)),
    (Color(0xFFCCFBF1), Color(0xFF0D9488)),
    (Color(0xFFFCE7F3), Color(0xFFDB2777)),
    (Color(0xFFE0E7FF), Color(0xFF4F46E5)),
    (Color(0xFFFFEDD5), Color(0xFFEA580C)),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final historyVm = context.read<AttendanceHistoryViewModel>();
        final dashVm = context.read<DashboardViewModel?>();

        // Nếu chưa có lớp nào được chọn, ưu tiên lớp đang học/diễn ra từ Dashboard
        if (historyVm.selectedClassCode == null &&
            dashVm != null &&
            dashVm.classes.isNotEmpty) {
          final activeClass =
              dashVm.classes.where((c) => c.isActive).firstOrNull ??
              dashVm.classes.first;
          historyVm.selectClass(activeClass.classCode);
        } else if (historyVm.classes.isEmpty) {
          historyVm.loadClasses();
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _syncWithViewModel(AttendanceHistoryViewModel vm) {
    final classCode = vm.selectedClassCode;
    final summary = vm.summary;
    if (classCode == null || summary == null) {
      if (_loadedClassCode != null || _detail != null) {
        _loadedClassCode = null;
        _selectedSessionId = null;
        _detail = null;
        _pendingEdits.clear();
      }
      return;
    }

    final sessions = summary.sessions;
    if (sessions.isEmpty) {
      _loadedClassCode = classCode;
      _selectedSessionId = null;
      _detail = null;
      _pendingEdits.clear();
      return;
    }

    final dashVm = context.read<DashboardViewModel?>();
    final dashClass = dashVm?.classes
        .where((c) => c.classCode == classCode)
        .firstOrNull;
    final activeSessionId = dashClass?.activeSessionId;

    final targetSessionId =
        (activeSessionId != null &&
            sessions.any((s) => s.sessionId == activeSessionId))
        ? activeSessionId
        : ((_selectedSessionId != null &&
                  sessions.any((s) => s.sessionId == _selectedSessionId))
              ? _selectedSessionId!
              : sessions.first.sessionId);

    final targetStatus = sessions
        .firstWhere((s) => s.sessionId == targetSessionId)
        .sessionStatus;
    if (_loadedClassCode != classCode ||
        _selectedSessionId != targetSessionId ||
        _loadedSessionStatus != targetStatus) {
      _loadedClassCode = classCode;
      _selectedSessionId = targetSessionId;
      _loadedSessionStatus = targetStatus;
      _pendingEdits.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadSessionDetail(classCode, targetSessionId);
        }
      });
    }
  }

  Future<void> _loadSessionDetail(String classCode, String sessionId) async {
    if (!mounted) return;
    final vm = context.read<AttendanceHistoryViewModel>();
    setState(() {
      _loadingDetail = true;
    });

    final result = await vm.repository.getDetail(
      classCode,
      sessionId: sessionId,
    );

    if (!mounted ||
        _loadedClassCode != classCode ||
        _selectedSessionId != sessionId) {
      return;
    }

    setState(() {
      _loadingDetail = false;
      if (result is ApiSuccess<HistoryDetail>) {
        _detail = result.data;
      }
    });
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

  String _formatCheckinTime(String raw) {
    if (raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt != null) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return raw;
  }

  String _nowTimeStr() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  String _todayInVietnam() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  SessionModel? _currentSelectedSession() {
    final summarySessions =
        context.read<AttendanceHistoryViewModel>().summary?.sessions ??
        const [];
    final sessions = _detail?.sessions ?? summarySessions;
    return _detail?.selectedSession ??
        sessions.where((s) => s.sessionId == _selectedSessionId).firstOrNull;
  }

  bool _canEditManualAttendance([SessionModel? session]) {
    final selected = session ?? _currentSelectedSession();
    return selected == null || selected.sessionDate == _todayInVietnam();
  }

  void _showExpiredManualAttendanceGuidance() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Đã qua ngày học. Hãy vào Cài đặt & Trợ giúp → Yêu cầu điểm danh / nghỉ phép để gửi admin duyệt.',
        ),
        backgroundColor: AttendanceHistoryColors.statusRed,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'MỞ CÀI ĐẶT',
          textColor: Colors.white,
          onPressed: () =>
              context.read<DashboardViewModel>().navigate('cai-dat-tro-giup'),
        ),
      ),
    );
  }

  bool _guardManualAttendanceDay() {
    if (_canEditManualAttendance()) return true;
    _showExpiredManualAttendanceGuidance();
    return false;
  }

  List<StudentAttendanceModel> _buildStudentModels(
    AttendanceHistoryViewModel vm,
  ) {
    final detail = _detail;
    if (detail != null && detail.classInfo.classCode == vm.selectedClassCode) {
      return detail.students.asMap().entries.map((entry) {
        final idx = entry.key;
        final s = entry.value;
        final edit = _pendingEdits[s.rollNumber];
        final effectiveStatus = edit?.status ?? s.status;
        final effectiveNote = edit?.note ?? s.note;
        final effectiveTime = edit != null && edit.checkinTime.isNotEmpty
            ? edit.checkinTime
            : _formatCheckinTime(s.checkinTime);

        final palette = _avatarPalettes[idx % _avatarPalettes.length];

        final state = _mapStatusToState(
          status: effectiveStatus,
          note: effectiveNote,
          method: s.method,
        );

        final seatOrNote = effectiveNote.isNotEmpty
            ? effectiveNote
            : (effectiveStatus == 'Late' ? 'Đi muộn' : null);

        final warningText = s.absenceRate > 0.2
            ? 'Cảnh báo ${(s.absenceRate * 100).round()}%'
            : null;

        return StudentAttendanceModel(
          rollNumber: s.rollNumber,
          fullName: s.fullName,
          initials: _extractInitials(s.fullName),
          avatarBgColor: palette.$1,
          avatarTextColor: palette.$2,
          seatOrNote: seatOrNote,
          state: state,
          checkinTime: effectiveTime.isNotEmpty ? effectiveTime : null,
          warningText: warningText,
        );
      }).toList();
    }

    // Khi đang tải chi tiết buổi hoặc lớp chưa có buổi điểm danh nào: lấy từ summary.students (dữ liệu thật từ Firestore)
    final summaryStudents = vm.summary?.students ?? const [];
    final hasSessions = (vm.summary?.sessions.isNotEmpty ?? false);

    return summaryStudents.asMap().entries.map((entry) {
      final idx = entry.key;
      final s = entry.value;
      final edit = _pendingEdits[s.rollNumber];
      final palette = _avatarPalettes[idx % _avatarPalettes.length];

      StudentAttendanceState state;
      String? seatOrNote;
      String? checkinTime;

      if (edit != null) {
        state = _mapStatusToState(
          status: edit.status,
          note: edit.note,
          method: 'Manual',
        );
        seatOrNote = edit.note.isNotEmpty ? edit.note : null;
        checkinTime = edit.checkinTime.isNotEmpty ? edit.checkinTime : null;
      } else if (!hasSessions) {
        state = StudentAttendanceState.absentUnscanned;
        seatOrNote = null;
      } else if (s.presentCount + s.lateCount > 0) {
        state = StudentAttendanceState.presentQr;
        seatOrNote =
            'Có mặt ${s.presentCount + s.lateCount}/${s.closedSessions} buổi';
      } else {
        state = StudentAttendanceState.absentUnscanned;
        seatOrNote = null;
      }

      final warningText = s.absenceRate > 0.2
          ? 'Cảnh báo ${(s.absenceRate * 100).round()}%'
          : null;

      return StudentAttendanceModel(
        rollNumber: s.rollNumber,
        fullName: s.fullName,
        initials: _extractInitials(s.fullName),
        avatarBgColor: palette.$1,
        avatarTextColor: palette.$2,
        seatOrNote: seatOrNote,
        state: state,
        checkinTime: checkinTime,
        warningText: warningText,
      );
    }).toList();
  }

  StudentAttendanceState _mapStatusToState({
    required String status,
    required String note,
    required String method,
  }) {
    if (status == 'ManualByGV') {
      return StudentAttendanceState.presentManual;
    }
    if (status == 'Present' || status == 'Late') {
      if (method.toLowerCase() == 'manual') {
        return StudentAttendanceState.presentManual;
      }
      return StudentAttendanceState.presentQr;
    }
    if (status == 'Absent' &&
        (note.toLowerCase().contains('phép') ||
            note.toLowerCase().contains('fap'))) {
      return StudentAttendanceState.absentExcused;
    }
    return StudentAttendanceState.absentUnscanned;
  }

  String _findRevision(String rollNumber) {
    final detail = _detail;
    if (detail == null) return '';
    final found = detail.students
        .where((s) => s.rollNumber == rollNumber)
        .firstOrNull;
    return found?.revision ?? '';
  }

  Future<String?> _ensureSession(String classCode) async {
    if (_selectedSessionId != null) return _selectedSessionId;
    final vm = context.read<AttendanceHistoryViewModel>();
    final dashVm = context.read<DashboardViewModel?>();
    final dashClass = dashVm?.classes
        .where((c) => c.classCode == classCode)
        .firstOrNull;
    final slotCode = (dashClass?.slotCode.isNotEmpty == true)
        ? dashClass!.slotCode
        : (vm.summary?.slotCodes.firstOrNull ?? '1');

    final result = await vm.repository.startSession(
      classCode,
      slotCode,
      '',
      ipCheck: false,
    );
    if (result is ApiSuccess<SessionModel>) {
      final session = result.data;
      setState(() {
        _selectedSessionId = session.sessionId;
      });
      await vm.refreshSummary();
      await _loadSessionDetail(classCode, session.sessionId);
      return session.sessionId;
    }
    return null;
  }

  // Điểm danh thủ công cho 1 sinh viên và lưu thẳng lên Firebase
  Future<void> _handleManualCheckin(StudentAttendanceModel student) async {
    if (!_guardManualAttendanceDay()) return;
    final vm = context.read<AttendanceHistoryViewModel>();
    final classCode = vm.selectedClassCode;
    if (classCode == null) return;

    var sessionId = _selectedSessionId;
    sessionId ??= await _ensureSession(classCode);

    if (sessionId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể xác định phiên điểm danh để lưu dữ liệu.'),
          backgroundColor: AttendanceHistoryColors.statusRed,
        ),
      );
      return;
    }

    setState(() {
      _pendingEdits[student.rollNumber] = _PendingEdit(
        status: 'ManualByGV',
        note: 'Xác nhận tay',
        checkinTime: _nowTimeStr(),
      );
    });

    final saved = await _commitChangesToFirestore([
      {
        'rollNumber': student.rollNumber,
        'status': 'ManualByGV',
        'note': 'Xác nhận tay',
        'revision': _findRevision(student.rollNumber),
      },
    ]);

    if (!saved) {
      if (mounted) {
        setState(() => _pendingEdits.remove(student.rollNumber));
      }
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Đã điểm danh thủ công cho ${student.fullName}'),
        backgroundColor: AttendanceHistoryColors.statusGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<bool> _commitChangesToFirestore(
    List<Map<String, dynamic>> changes, {
    bool silentSuccess = false,
  }) async {
    final vm = context.read<AttendanceHistoryViewModel>();
    final classCode = vm.selectedClassCode;
    final sessionId = _selectedSessionId;
    if (classCode == null || sessionId == null || changes.isEmpty) {
      return false;
    }

    setState(() => _savingSession = true);
    final result = await vm.repository.save(classCode, sessionId, changes);
    if (!mounted) return false;
    setState(() => _savingSession = false);

    switch (result) {
      case ApiSuccess<HistoryDetail>(:final data):
        setState(() {
          _detail = data;
          for (final c in changes) {
            _pendingEdits.remove(c['rollNumber']);
          }
        });
        await vm.refreshSummary();
        return true;
      case ApiFailure<HistoryDetail>(:final error):
        if (!silentSuccess && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.message),
              backgroundColor: AttendanceHistoryColors.statusRed,
            ),
          );
        }
        return false;
    }
    return false;
  }

  // Đổi trạng thái sinh viên qua Modal Bottom Sheet
  void _showChangeStatusSheet(StudentAttendanceModel student) {
    if (!_guardManualAttendanceDay()) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  student.fullName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AttendanceHistoryColors.textDark,
                  ),
                ),
                Text(
                  'MSSV: ${student.rollNumber}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Color(0xFF10B981),
                  ),
                  title: const Text('Có mặt (Present)'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _applySingleStatusChange(
                      student,
                      status: 'Present',
                      note: '',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.how_to_reg_rounded,
                    color: Color(0xFF10B981),
                  ),
                  title: const Text('Có mặt (Thủ công / GV xác nhận)'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _applySingleStatusChange(
                      student,
                      status: 'ManualByGV',
                      note: 'Xác nhận tay',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.assignment_turned_in_outlined,
                    color: Color(0xFFF59E0B),
                  ),
                  title: const Text('Vắng có phép (Đơn phép FAP)'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _applySingleStatusChange(
                      student,
                      status: 'Absent',
                      note: 'Đơn phép FAP',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.person_off_outlined,
                    color: Color(0xFFEF4444),
                  ),
                  title: const Text('Vắng mặt (Không phép)'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _applySingleStatusChange(
                      student,
                      status: 'Absent',
                      note: '',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _applySingleStatusChange(
    StudentAttendanceModel student, {
    required String status,
    required String note,
  }) async {
    if (!_guardManualAttendanceDay()) return;
    setState(() {
      _pendingEdits[student.rollNumber] = _PendingEdit(
        status: status,
        note: note,
        checkinTime: _nowTimeStr(),
      );
    });

    await _commitChangesToFirestore([
      {
        'rollNumber': student.rollNumber,
        'status': status,
        'note': note,
        'revision': _findRevision(student.rollNumber),
      },
    ]);
  }

  // Nút Chọn nhanh
  void _handleQuickSelect(List<StudentAttendanceModel> allStudents) {
    if (!_guardManualAttendanceDay()) return;
    final absentUnscanned = allStudents
        .where((s) => s.state == StudentAttendanceState.absentUnscanned)
        .toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Thao tác nhanh điểm danh',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AttendanceHistoryColors.textDark,
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: Icon(
                    Icons.done_all_rounded,
                    color: AttendanceHistoryColors.orangePrimary,
                  ),
                  title: Text(
                    'Điểm danh tất cả ${absentUnscanned.length} sinh viên chưa quét',
                  ),
                  subtitle: const Text(
                    'Đánh dấu có mặt xác nhận bởi giảng viên',
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    if (absentUnscanned.isEmpty) return;
                    final nowStr = _nowTimeStr();
                    setState(() {
                      for (final s in absentUnscanned) {
                        _pendingEdits[s.rollNumber] = _PendingEdit(
                          status: 'ManualByGV',
                          note: 'Xác nhận tay',
                          checkinTime: nowStr,
                        );
                      }
                    });
                    final changes = [
                      for (final s in absentUnscanned)
                        {
                          'rollNumber': s.rollNumber,
                          'status': 'ManualByGV',
                          'note': 'Xác nhận tay',
                          'revision': _findRevision(s.rollNumber),
                        },
                    ];
                    final ok = await _commitChangesToFirestore(changes);
                    if (mounted && ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '✓ Đã điểm danh và lưu ${absentUnscanned.length} sinh viên lên Firebase!',
                          ),
                          backgroundColor: AttendanceHistoryColors.statusGreen,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.refresh_rounded,
                    color: Color(0xFF64748B),
                  ),
                  title: const Text('Tải lại dữ liệu từ Firebase'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final vm = context.read<AttendanceHistoryViewModel>();
                    _pendingEdits.clear();
                    await vm.refreshSummary();
                    if (_loadedClassCode != null &&
                        _selectedSessionId != null) {
                      await _loadSessionDetail(
                        _loadedClassCode!,
                        _selectedSessionId!,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Lưu bảng điểm danh lên Firestore và đồng bộ FAP
  Future<void> _handleSave(int sessionNumber) async {
    if (!_guardManualAttendanceDay()) return;
    final vm = context.read<AttendanceHistoryViewModel>();
    final classCode = vm.selectedClassCode;

    if (classCode == null) return;

    var sessionId = _selectedSessionId;
    if (sessionId == null) {
      sessionId = await _ensureSession(classCode);
      if (sessionId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể khởi tạo buổi học để lưu điểm danh.'),
            ),
          );
        }
        return;
      }
    }

    if (_pendingEdits.isNotEmpty) {
      final changes = [
        for (final entry in _pendingEdits.entries)
          {
            'rollNumber': entry.key,
            'status': entry.value.status,
            'note': entry.value.note,
            'revision': _findRevision(entry.key),
          },
      ];
      final ok = await _commitChangesToFirestore(changes);
      if (!ok) return;
    } else if (_detail != null && _detail!.students.isNotEmpty) {
      // Nếu có sinh viên đang ở trạng thái Unchecked khi đóng/lưu buổi, lưu xác nhận bảng điểm danh hiện tại
      final unchecked = _detail!.students
          .where((s) => s.status == 'Unchecked')
          .toList();
      if (unchecked.isNotEmpty) {
        final changes = [
          for (final s in unchecked)
            {
              'rollNumber': s.rollNumber,
              'status': 'Absent',
              'note': s.note,
              'revision': s.revision,
            },
        ];
        await _commitChangesToFirestore(changes);
      } else {
        await vm.refreshSummary();
      }
    }

    if (!mounted) return;
    await syncClassToFap(context);
  }

  // Tùy chọn thêm trên header (Đổi lớp, mở phiên mới, xem ma trận, xuất Excel, đồng bộ FAP)
  void _showMoreOptions(AttendanceHistoryViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (vm.classes.length > 1) ...[
                  const Text(
                    'Chuyển lớp học',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final cls in vm.classes)
                        ChoiceChip(
                          label: Text(
                            '${cls.subjectCode} · ${cls.classCode}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: cls.classCode == vm.selectedClassCode
                                  ? Colors.white
                                  : AttendanceHistoryColors.textDark,
                            ),
                          ),
                          selected: cls.classCode == vm.selectedClassCode,
                          selectedColor: AttendanceHistoryColors.orangePrimary,
                          onSelected: (_) {
                            Navigator.pop(ctx);
                            vm.selectClass(cls.classCode);
                          },
                        ),
                    ],
                  ),
                  const Divider(height: 24),
                ],
                ListTile(
                  leading: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: Color(0xFF10B981),
                  ),
                  title: const Text('Mở phiên điểm danh mới'),
                  onTap: () {
                    Navigator.pop(ctx);
                    openHistorySession(context);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.grid_on_rounded,
                    color: Color(0xFF0F172A),
                  ),
                  title: const Text('Ma trận điểm danh các buổi học'),
                  onTap: () {
                    Navigator.pop(ctx);
                    showHistoryMatrix(context);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.download_rounded,
                    color: Color(0xFF0F172A),
                  ),
                  title: const Text('Xuất bảng điểm danh Excel'),
                  onTap: () {
                    Navigator.pop(ctx);
                    exportHistory(context);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.sync_rounded,
                    color: AttendanceHistoryColors.orangePrimary,
                  ),
                  title: const Text('Đồng bộ dữ liệu FAP'),
                  onTap: () {
                    Navigator.pop(ctx);
                    syncClassToFap(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _buildHeaderSubtitle(
    AttendanceHistoryViewModel vm,
    List<SessionModel> sessions,
    int sessionNumber,
  ) {
    final info = _detail?.classInfo ?? vm.summary?.classInfo;
    if (info == null) {
      return vm.selectedClassCode ?? 'Đang tải thông tin lớp...';
    }
    final selectedSession =
        _detail?.selectedSession ??
        sessions.where((s) => s.sessionId == _selectedSessionId).firstOrNull;

    final dashVm = context.read<DashboardViewModel?>();
    final dashClass = dashVm?.classes
        .where((c) => c.classCode == info.classCode)
        .firstOrNull;

    final subject = info.subjectCode.isNotEmpty
        ? info.subjectCode
        : (dashClass?.subjectCode ?? info.classCode);
    final classCode = info.classCode;
    final fallbackSlot =
        dashClass?.slotCode ??
        info.latestSession?.slotCode ??
        (_detail?.slotCodes.firstOrNull ?? vm.summary?.slotCodes.firstOrNull) ??
        '';
    final slot =
        (selectedSession != null && selectedSession.slotCode.isNotEmpty)
        ? selectedSession.slotCode
        : (fallbackSlot.isNotEmpty ? fallbackSlot : '1');
    final roomName = info.room.isNotEmpty ? info.room : (dashClass?.room ?? '');
    final room = roomName.isNotEmpty ? 'Phòng $roomName' : '';

    final parts = <String>[
      subject,
      if (classCode != subject) classCode,
      if (sessions.isNotEmpty && sessionNumber > 0) 'Buổi $sessionNumber',
      'Ca $slot${room.isNotEmpty ? ' ($room)' : ''}',
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AttendanceHistoryViewModel>();
    _syncWithViewModel(vm);

    final sessions = _detail?.sessions ?? vm.summary?.sessions ?? const [];
    final selectedIdx = sessions.indexWhere(
      (s) => s.sessionId == _selectedSessionId,
    );
    final sessionNumber = sessions.isEmpty
        ? 0
        : (selectedIdx >= 0 ? sessions.length - selectedIdx : sessions.length);

    final selectedSession =
        _detail?.selectedSession ??
        (selectedIdx >= 0 ? sessions[selectedIdx] : null);
    final canEditManualAttendance = _canEditManualAttendance(selectedSession);

    final allStudents = _buildStudentModels(vm);
    final totalStudents = allStudents.length;
    final presentCount = allStudents.where((s) => s.isPresent).length;
    final absentCount = allStudents.where((s) => s.isAbsent).length;
    final excusedCount = allStudents
        .where((s) => s.state == StudentAttendanceState.absentExcused)
        .length;
    final rate = totalStudents == 0
        ? 0.0
        : (presentCount / totalStudents) * 100;

    final filteredList = allStudents.where((s) {
      final matchesFilter = switch (_activeFilter) {
        AttendanceFilterType.all => true,
        AttendanceFilterType.present => s.isPresent,
        AttendanceFilterType.absent => s.isAbsent,
      };
      final q = _searchQuery.trim().toLowerCase();
      final matchesSearch =
          q.isEmpty ||
          s.fullName.toLowerCase().contains(q) ||
          s.rollNumber.toLowerCase().contains(q);
      return matchesFilter && matchesSearch;
    }).toList();

    final subtitle = _buildHeaderSubtitle(vm, sessions, sessionNumber);
    final isShortScreen = MediaQuery.sizeOf(context).height < 500;

    if (isShortScreen) {
      // Khi xoay ngang màn hình (chiều cao hẹp < 500dp), cuộn chung toàn bộ trang
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AttendanceHistoryColors.orangePrimary,
            onRefresh: () async {
              _pendingEdits.clear();
              await vm.loadClasses(force: true);
              if (_loadedClassCode != null && _selectedSessionId != null) {
                await _loadSessionDetail(
                  _loadedClassCode!,
                  _selectedSessionId!,
                );
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                MediaQuery.sizeOf(context).width < 768 ? 108 : 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AttendanceHistoryHeader(
                    title: 'Điểm danh sinh viên',
                    subtitle: subtitle,
                    showBackButton: false,
                    onExport: vm.busy || vm.summary == null
                        ? null
                        : () => exportHistory(context),
                    onOptions: () => _showMoreOptions(vm),
                  ),
                  const SizedBox(height: 8),
                  _buildTopControls(
                    vm: vm,
                    sessions: sessions,
                    canEditManualAttendance: canEditManualAttendance,
                    totalStudents: totalStudents,
                    presentCount: presentCount,
                    absentCount: absentCount,
                    excusedCount: excusedCount,
                    rate: rate,
                    selectedSession: selectedSession,
                    allStudents: allStudents,
                  ),
                  const SizedBox(height: 12),
                  ..._buildStudentItems(
                    vm: vm,
                    filteredList: filteredList,
                    allStudents: allStudents,
                    sessionNumber: sessionNumber,
                    canEditManualAttendance: canEditManualAttendance,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (vm.loadingClasses ||
                vm.loadingSummary ||
                _loadingDetail ||
                _savingSession)
              const LinearProgressIndicator(minHeight: 2),

            // ── 1. Header trên cùng ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: AttendanceHistoryHeader(
                title: 'Điểm danh sinh viên',
                subtitle: subtitle,
                showBackButton: false,
                onExport: vm.busy || vm.summary == null
                    ? null
                    : () => exportHistory(context),
                onOptions: () => _showMoreOptions(vm),
              ),
            ),

            if (vm.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Text(
                  vm.errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            // ── 2. Khung cố định: Sĩ số lớp %, Search và các nút Tất cả / Có mặt / Vắng ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _buildTopControls(
                vm: vm,
                sessions: sessions,
                canEditManualAttendance: canEditManualAttendance,
                totalStudents: totalStudents,
                presentCount: presentCount,
                absentCount: absentCount,
                excusedCount: excusedCount,
                rate: rate,
                selectedSession: selectedSession,
                allStudents: allStudents,
              ),
            ),

            // ── 3. Danh sách sinh viên cuộn lên xuống ──────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: AttendanceHistoryColors.orangePrimary,
                onRefresh: () async {
                  _pendingEdits.clear();
                  await vm.loadClasses(force: true);
                  if (_loadedClassCode != null && _selectedSessionId != null) {
                    await _loadSessionDetail(
                      _loadedClassCode!,
                      _selectedSessionId!,
                    );
                  }
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    4,
                    16,
                    MediaQuery.sizeOf(context).width < 768 ? 108 : 32,
                  ),
                  children: _buildStudentItems(
                    vm: vm,
                    filteredList: filteredList,
                    allStudents: allStudents,
                    sessionNumber: sessionNumber,
                    canEditManualAttendance: canEditManualAttendance,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopControls({
    required AttendanceHistoryViewModel vm,
    required List<SessionModel> sessions,
    required bool canEditManualAttendance,
    required int totalStudents,
    required int presentCount,
    required int absentCount,
    required int excusedCount,
    required double rate,
    required SessionModel? selectedSession,
    required List<StudentAttendanceModel> allStudents,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Thanh trượt chọn buổi học thực tế (khi lớp có nhiều buổi)
        if (sessions.isNotEmpty) ...[
          AttendanceSessionSelector(
            sessions: sessions,
            selectedSessionId: _selectedSessionId,
            onSelectSession: (sessionId) {
              if (_selectedSessionId == sessionId) return;
              setState(() {
                _selectedSessionId = sessionId;
                _pendingEdits.clear();
              });
              if (vm.selectedClassCode != null) {
                _loadSessionDetail(
                  vm.selectedClassCode!,
                  sessionId,
                );
              }
            },
          ),
          const SizedBox(height: 10),
        ],

        if (!canEditManualAttendance) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Đã hết hạn điểm danh tay',
                  style: TextStyle(
                    color: AttendanceHistoryColors.statusRed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Chỉ được điểm danh trực tiếp đến 23:59 của ngày học. Sau thời hạn này, hãy gửi yêu cầu để admin duyệt.',
                  style: TextStyle(
                    color: Color(0xFF991B1B),
                    fontSize: 12.5,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context
                      .read<DashboardViewModel>()
                      .navigate('cai-dat-tro-giup'),
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Đi tới Cài đặt & Trợ giúp'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Thẻ thống kê tóm tắt (Sĩ số & phần trăm)
        AttendanceSummaryCard(
          totalStudents: totalStudents,
          presentCount: presentCount,
          absentCount: absentCount,
          excusedAbsentCount: excusedCount,
          attendanceRate: rate,
          isOngoing: selectedSession?.isOpen ?? sessions.isNotEmpty,
        ),

        const SizedBox(height: 12),

        // Thanh tìm kiếm và bộ lọc chip (Tất cả, Có mặt, Vắng...)
        AttendanceSearchFilterBar(
          searchController: _searchController,
          onSearchChanged: (val) {
            setState(() {
              _searchQuery = val;
            });
          },
          activeFilter: _activeFilter,
          onFilterChanged: (filter) {
            setState(() {
              _activeFilter = filter;
            });
          },
          totalCount: totalStudents,
          presentCount: presentCount,
          absentCount: absentCount,
          onQuickSelect: canEditManualAttendance
              ? () => _handleQuickSelect(allStudents)
              : _showExpiredManualAttendanceGuidance,
        ),
      ],
    );
  }

  List<Widget> _buildStudentItems({
    required AttendanceHistoryViewModel vm,
    required List<StudentAttendanceModel> filteredList,
    required List<StudentAttendanceModel> allStudents,
    required int sessionNumber,
    required bool canEditManualAttendance,
  }) {
    if (!vm.loadingClasses && !vm.loadingSummary && vm.classes.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 40),
          alignment: Alignment.center,
          child: const Text(
            'Chưa có lớp học được phân công.',
            style: TextStyle(
              fontSize: 13.5,
              color: Color(0xFF64748B),
            ),
          ),
        ),
      ];
    }

    if (filteredList.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 40),
          alignment: Alignment.center,
          child: Column(
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 40,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              Text(
                'Không tìm thấy sinh viên phù hợp',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ];
    }

    return [
      ...filteredList.map(
        (student) => AttendanceStudentCard(
          student: student,
          onManualCheckin: canEditManualAttendance
              ? () => _handleManualCheckin(student)
              : _showExpiredManualAttendanceGuidance,
          onChangeStatus: canEditManualAttendance
              ? () => _showChangeStatusSheet(student)
              : _showExpiredManualAttendanceGuidance,
          onOptions: canEditManualAttendance
              ? () => _showChangeStatusSheet(student)
              : _showExpiredManualAttendanceGuidance,
        ),
      ),
      const SizedBox(height: 14),
      if (allStudents.isNotEmpty)
        AttendanceSaveActionButton(
          sessionNumber: sessionNumber > 0 ? sessionNumber : 1,
          onSave: canEditManualAttendance
              ? () => _handleSave(
                  sessionNumber > 0 ? sessionNumber : 1,
                )
              : _showExpiredManualAttendanceGuidance,
        ),
      const SizedBox(height: 20),
    ];
  }
}
