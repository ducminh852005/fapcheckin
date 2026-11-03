

import 'dart:io' as io;

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:file_picker/file_picker.dart';

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:fapcheckin_core/repositories/request_repository.dart';

import 'package:fapcheckin_core/result/api_result.dart';



import '../../../viewmodels/auth_viewmodel.dart';





Future<T?> showRequestBottomSheet<T>(BuildContext context, {RequestRepository? repository}) {

  return showModalBottomSheet<T>(

    context: context,

    isScrollControlled: true,

    backgroundColor: Colors.transparent,

    builder: (_) => RequestModalSheet(repository: repository),

  );

}



class _AttachmentFile {

  final String name;

  final int size;

  final String mime;

  final Uint8List bytes;

  _AttachmentFile({

    required this.name,

    required this.size,

    required this.mime,

    required this.bytes,

  });

}



class RequestModalSheet extends StatefulWidget {

  const RequestModalSheet({super.key, this.repository});
  final RequestRepository? repository;



  @override

  State<RequestModalSheet> createState() => _RequestModalSheetState();

}



class _RequestModalSheetState extends State<RequestModalSheet> {

  int _activeTab = 0; // 0: Tạo yêu cầu mới, 1: Lịch sử yêu cầu
  String _historyFilter = 'all'; // 'all', 'pending', 'approved', 'rejected'



  // Form state

  String _requestType = 'leave'; // 'leave', 'attendance_fix', 'reschedule'

  String _selectedClass = '';

  String _selectedSlot = '';

  String _slotTime = '';

  String _slotDateRoom = '';
  final _sessionController = TextEditingController();
  final _dateController = TextEditingController();
  String _requestId = DateTime.now().microsecondsSinceEpoch.toString();
  List<Map<String, dynamic>> _classRows = [];
  bool _loadingClasses = true;

  String _mainReason = 'business_trip'; // 'business_trip', 'health', 'technical_issue', 'other'

  final TextEditingController _reasonController = TextEditingController();



  final List<_AttachmentFile> _attachments = [];

  bool _saving = false;

  String? _error;



  late RequestRepository _repo;

  Stream<List<Map<String, dynamic>>>? _requestsStream;

  String? _uid;



  final List<String> _defaultClasses = [];



  final Map<String, String> _mainReasonLabels = {

    'business_trip': 'Công tác đột xuất theo quyết định',

    'health': 'Lý do sức khỏe / Y tế',

    'technical_issue': 'Sự cố mạng / lỗi thiết bị',

    'other': 'Khác (Ghi rõ bên dưới)',

  };



  @override

  void didChangeDependencies() {

    super.didChangeDependencies();

    final authVm = context.watch<AuthViewModel>();

    final session = authVm.session;

    if (session != null && _uid != session.token) {

      _uid = session.token;

      _repo = widget.repository ?? RequestRepository(

        uid: session.token,

        memberCode: session.user.memberCode,

      );

      _requestsStream = _repo.watchMine();
      _loadClasses();

    }



  }
  Future<void> _loadClasses() async {
    final result = await _repo.classOptions();
    if (!mounted) return;
    setState(() {
      _loadingClasses = false;
      if (result is ApiSuccess<List<Map<String, dynamic>>>) {
        _classRows = result.data;
        _defaultClasses..clear()..addAll(_classRows.map((c) => c['classCode'].toString()));
        if (_defaultClasses.isNotEmpty) _selectClass(_defaultClasses.first);
      } else {
        _error = (result as ApiFailure<List<Map<String, dynamic>>>).error.message;
      }
    });
  }
  void _selectClass(String code) {
    _selectedClass = code;
    final row = _classRows.firstWhere((c) => c['classCode'] == code);
    _selectedSlot = (row['slotCode'] ?? '').toString();
    _slotTime = (row['timeLabel'] ?? '').toString();
    _slotDateRoom = (row['room'] ?? '').toString();
    _sessionController.clear();
  }

  @override

  void dispose() {

    _reasonController.dispose();
    _sessionController.dispose();
    _dateController.dispose();

    super.dispose();

  }



  Future<void> _pickFile() async {

    try {

      final result = await FilePicker.platform.pickFiles(

        type: FileType.custom,

        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'docx'],

        withData: true,

      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;



      Uint8List? bytes = file.bytes;

      if (bytes == null && !kIsWeb && file.path != null) {

        bytes = await io.File(file.path!).readAsBytes();

      }

      if (bytes != null) {

        if (bytes.length > 15 * 1024 * 1024) {

          if (mounted) {

            ScaffoldMessenger.of(context).showSnackBar(

              const SnackBar(content: Text('Tệp đính kèm tối đa 15 MB.')),

            );

          }

          return;

        }

        final ext = (file.extension ?? 'pdf').toLowerCase();

        final mime = ext == 'pdf'

            ? 'application/pdf'

            : (ext == 'docx' ? 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' : ext == 'png' ? 'image/png' : 'image/jpeg');



        setState(() {

          _attachments.add(_AttachmentFile(

            name: file.name,

            size: file.size,

            mime: mime,

            bytes: bytes!,

          ));

        });

      }

    } catch (e) {

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(content: Text('Lỗi tải tệp: $e')),

        );

      }

    }

  }



  Future<void> _submitRequest() async {

    if (_saving || _loadingClasses) return;
    if (_selectedClass.isEmpty) { setState(() => _error = 'Chưa có lớp để gửi yêu cầu.'); return; }
    if (_requestType == 'attendance_fix' && _sessionController.text.trim().isEmpty) { setState(() => _error = 'Nhập mã phiên cần sửa điểm danh.'); return; }

    final detail = _reasonController.text.trim();

    if (detail.isEmpty) {

      setState(() => _error = 'Vui lòng nhập mô tả chi tiết & kế hoạch.');

      return;

    }



    setState(() {

      _saving = true;

      _error = null;

    });



    try {

      final List<String> uploadedUrls = [];

      for (final att in _attachments) {

        final upRes = await _repo.uploadAttachment(att.bytes, att.mime, att.name);

        if (upRes is ApiSuccess<String>) {

          uploadedUrls.add(upRes.data);

        } else {

          throw Exception((upRes as ApiFailure<String>).error.message);

        }

      }



      final mainReasonText = _mainReasonLabels[_mainReason] ?? _mainReason;

      final fullReason = '[Lý do chính]: $mainReasonText\n'

          '[Ca học]: $_selectedSlot ($_slotTime) · $_slotDateRoom\n'

          '[Chi tiết & Kế hoạch]: $detail'

          '';



      final classCodeOnly = _selectedClass;

      final id = _requestId;



      final res = await _repo.submit(

        id: id,

        type: _requestType,

        reason: fullReason,

        classCode: classCodeOnly,

        sessionId: _sessionController.text.trim(),

        mainReason: mainReasonText,

        slot: _selectedSlot,

        date: _dateController.text.trim(),
        room: _slotDateRoom,

        attachments: uploadedUrls,

      );



      if (!mounted) return;

      if (res is ApiSuccess<void>) {

        setState(() {

          _saving = false;

          _activeTab = 1; // Switch to history tab

          _reasonController.clear();
          _requestId = DateTime.now().microsecondsSinceEpoch.toString();

          _attachments.clear();

        });

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(

            content: Text('Đã gửi yêu cầu thành công tới phòng Quản lý Đào tạo (HAC).'),

            backgroundColor: Color(0xFF10B981),

          ),

        );

      } else {

        setState(() {

          _saving = false;

          _error = (res as ApiFailure<void>).error.message;

        });

      }

    } catch (e) {

      setState(() {

        _saving = false;

        _error = 'Lỗi gửi yêu cầu: $e';

      });

    }

  }



  @override

  Widget build(BuildContext context) {

    return Container(

      constraints: BoxConstraints(

        maxHeight: MediaQuery.of(context).size.height * 0.90,

      ),

      decoration: const BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),

        boxShadow: [

          BoxShadow(

            color: Color(0x26000000),

            blurRadius: 28,

            offset: Offset(0, -6),

          ),

        ],

      ),

      child: SafeArea(

        top: false,

        child: Column(

          mainAxisSize: MainAxisSize.min,

          children: [

            // Drag Handle

            const SizedBox(height: 12),

            Center(

              child: Container(

                width: 48,

                height: 5,

                decoration: BoxDecoration(

                  color: const Color(0xFFE2E8F0),

                  borderRadius: BorderRadius.circular(2.5),

                ),

              ),

            ),

            const SizedBox(height: 12),



            // Header Row: Dot + Title + Close Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: const Color(0xFFCC4900),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFFFDBCE),
                                  width: 2.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Yêu cầu điểm danh / Nghỉ phép',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF191C1E),
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Phòng Quản lý Đào tạo (HAC) xử lý trực tuyến',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF565E74),
                          ),
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
                        color: Color(0xFFF2F4F6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Color(0xFF565E74),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),



            // 2. SEGMENTED PILL TAB SWITCHER
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F6),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    // Tab 1: Tạo yêu cầu mới
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _activeTab == 0
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: _activeTab == 0
                                ? const [
                                    BoxShadow(
                                      color: Color(0x140F172A),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                : null,
                            border: _activeTab == 0
                                ? Border.all(
                                    color: const Color(0xFFE2BFB2)
                                        .withOpacity(0.35),
                                  )
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              'Tạo yêu cầu mới',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: _activeTab == 0
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: _activeTab == 0
                                    ? const Color(0xFFA33900)
                                    : const Color(0xFF565E74),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Tab 2: Lịch sử yêu cầu
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _activeTab == 1
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: _activeTab == 1
                                ? const [
                                    BoxShadow(
                                      color: Color(0x140F172A),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                : null,
                            border: _activeTab == 1
                                ? Border.all(
                                    color: const Color(0xFFE2BFB2)
                                        .withOpacity(0.35),
                                  )
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Lịch sử yêu cầu',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: _activeTab == 1
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: _activeTab == 1
                                      ? const Color(0xFFA33900)
                                      : const Color(0xFF565E74),
                                ),
                              ),
                              const SizedBox(width: 6),
                              StreamBuilder<List<Map<String, dynamic>>>(
                                stream: _requestsStream,
                                builder: (context, snapshot) {
                                  final count = snapshot.data?.length ?? 0;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _activeTab == 1
                                          ? const Color(0xFFCC4900)
                                          : const Color(0xFFE0E3E5),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$count',
                                      style: TextStyle(
                                        color: _activeTab == 1
                                            ? Colors.white
                                            : const Color(0xFF565E74),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tab Content
            Expanded(
              child: _activeTab == 0
                  ? _buildCreateFormTab(context)
                  : _buildHistoryTab(context),
            ),

            // 5. BOTTOM ACTION BAR & SAFE AREA PADDING
            _buildFooter(context),

            // Mobile Home Indicator Bar
            _buildHomeIndicator(),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------- TAB 1: FORM
  Widget _buildCreateFormTab(BuildContext context) {
    return SingleChildScrollView(

            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                // 1. Loại yêu cầu

                Row(

                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: const [

                    Text.rich(

                      TextSpan(

                        text: 'Loại yêu cầu ',

                        style: TextStyle(

                          fontSize: 13,

                          fontWeight: FontWeight.w700,

                          color: Color(0xFF0F172A),

                        ),

                        children: [

                          TextSpan(

                            text: '*',

                            style: TextStyle(color: Color(0xFFEF4444)),

                          ),

                        ],

                      ),

                    ),

                    Text(

                      'Chọn 1 hình thức',

                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),

                    ),

                  ],

                ),

                const SizedBox(height: 8),



                // Radio Cards

                _buildRadioCard(

                  type: 'leave',

                  title: 'Xin nghỉ phép / Báo vắng',

                  badge: 'Khuyên dùng',

                  subtitle: 'Giảng viên bận việc đột xuất / công tác',

                  icon: Icons.event_busy_rounded,

                  iconColor: const Color(0xFFFA5A1E),

                  iconBg: const Color(0xFFFFEDD5),

                ),

                const SizedBox(height: 8),



                _buildRadioCard(

                  type: 'attendance_fix',

                  title: 'Bổ sung điểm danh',

                  subtitle: 'Sinh viên lỗi QR / duyệt bù có minh chứng',

                  icon: Icons.how_to_reg_rounded,

                  iconColor: const Color(0xFF0284C7),

                  iconBg: const Color(0xFFE0F2FE),

                ),

                const SizedBox(height: 8),



                _buildRadioCard(

                  type: 'reschedule',

                  title: 'Đổi ca dạy / Dạy bù',

                  subtitle: 'Chuyển đổi lịch trình hoặc giảng viên dạy thay',

                  icon: Icons.published_with_changes_rounded,

                  iconColor: const Color(0xFFD97706),

                  iconBg: const Color(0xFFFEF3C7),

                ),

                const SizedBox(height: 14),



                // 2. Class & Slot Picker Container

                Container(

                  padding: const EdgeInsets.all(12),

                  decoration: BoxDecoration(

                    color: const Color(0xFFF8FAFC),

                    borderRadius: BorderRadius.circular(14),

                    border: Border.all(color: const Color(0xFFE2E8F0)),

                  ),

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      // Class Picker

                      const Text(

                        'Chọn lớp học *',

                        style: TextStyle(

                          fontSize: 12.5,

                          fontWeight: FontWeight.w600,

                          color: Color(0xFF475569),

                        ),

                      ),

                      const SizedBox(height: 6),

                      DropdownButtonFormField<String>(

                        value: _defaultClasses.contains(_selectedClass)

                            ? _selectedClass

                            : (_defaultClasses.isEmpty ? null : _defaultClasses.first),

                        isExpanded: true,

                        decoration: InputDecoration(

                          filled: true,

                          fillColor: Colors.white,

                          contentPadding: const EdgeInsets.symmetric(

                            horizontal: 12,

                            vertical: 10,

                          ),

                          enabledBorder: OutlineInputBorder(

                            borderRadius: BorderRadius.circular(12),

                            borderSide:

                                const BorderSide(color: Color(0xFFE2E8F0)),

                          ),

                          focusedBorder: OutlineInputBorder(

                            borderRadius: BorderRadius.circular(12),

                            borderSide: const BorderSide(

                              color: Color(0xFFFA5A1E),

                              width: 1.5,

                            ),

                          ),

                        ),

                        items: _defaultClasses

                            .map((c) => DropdownMenuItem(

                                  value: c,

                                  child: Text(

                                    c,

                                    style: const TextStyle(

                                      fontSize: 13,

                                      fontWeight: FontWeight.w500,

                                      color: Color(0xFF0F172A),

                                    ),

                                    overflow: TextOverflow.ellipsis,

                                  ),

                                ))

                            .toList(),

                        onChanged: (val) {

                          if (val != null) setState(() => _selectClass(val));

                        },

                      ),

                      const SizedBox(height: 10),



                      if (_loadingClasses) const LinearProgressIndicator(),
                      if (_defaultClasses.isEmpty && !_loadingClasses) TextButton(onPressed: _loadClasses, child: const Text('Tải lại danh sách lớp')),
                      TextField(controller: _sessionController, decoration: const InputDecoration(labelText: 'Mã phiên (bắt buộc khi sửa điểm danh)')),
                      TextField(controller: _dateController, decoration: const InputDecoration(labelText: 'Ngày học (YYYY-MM-DD)')),
                      // Slot Picker

                      const Text(

                        'Ca học (Slot) *',

                        style: TextStyle(

                          fontSize: 12.5,

                          fontWeight: FontWeight.w600,

                          color: Color(0xFF475569),

                        ),

                      ),

                      const SizedBox(height: 6),

                      Container(

                        padding: const EdgeInsets.all(10),

                        decoration: BoxDecoration(

                          color: Colors.white,

                          borderRadius: BorderRadius.circular(12),

                          border: Border.all(color: const Color(0xFFE2E8F0)),

                        ),

                        child: Row(

                          children: [

                            Container(

                              padding: const EdgeInsets.symmetric(

                                horizontal: 8,

                                vertical: 4,

                              ),

                              decoration: BoxDecoration(

                                color: const Color(0xFFFFEDD5),

                                borderRadius: BorderRadius.circular(6),

                              ),

                              child: Text(

                                _selectedSlot,

                                style: const TextStyle(

                                  color: Color(0xFFFA5A1E),

                                  fontWeight: FontWeight.w700,

                                  fontSize: 12,

                                ),

                              ),

                            ),

                            const SizedBox(width: 10),

                            Expanded(

                              child: Column(

                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [

                                  Text(

                                    _slotTime,

                                    style: const TextStyle(

                                      fontSize: 12.5,

                                      fontWeight: FontWeight.w700,

                                      color: Color(0xFF0F172A),

                                    ),

                                  ),

                                  const SizedBox(height: 2),

                                  Row(

                                    children: [

                                      const Icon(

                                        Icons.calendar_month_outlined,

                                        size: 12,

                                        color: Color(0xFF64748B),

                                      ),

                                      const SizedBox(width: 4),

                                      Text(

                                        _slotDateRoom,

                                        style: const TextStyle(

                                          fontSize: 11,

                                          color: Color(0xFF64748B),

                                        ),

                                      ),

                                    ],

                                  ),

                                ],

                              ),

                            ),

                            const Icon(

                              Icons.calendar_month_outlined,

                              size: 18,

                              color: Color(0xFF64748B),

                            ),

                          ],

                        ),

                      ),

                    ],

                  ),

                ),

                const SizedBox(height: 14),



                // 3. Reason & Plan Section

                const Text(

                  'Lý do chính *',

                  style: TextStyle(

                    fontSize: 12.5,

                    fontWeight: FontWeight.w600,

                    color: Color(0xFF475569),

                  ),

                ),

                const SizedBox(height: 6),

                DropdownButtonFormField<String>(

                  value: _mainReason,

                  isExpanded: true,

                  decoration: InputDecoration(

                    filled: true,

                    fillColor: const Color(0xFFF8FAFC),

                    contentPadding: const EdgeInsets.symmetric(

                      horizontal: 12,

                      vertical: 10,

                    ),

                    enabledBorder: OutlineInputBorder(

                      borderRadius: BorderRadius.circular(12),

                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),

                    ),

                    focusedBorder: OutlineInputBorder(

                      borderRadius: BorderRadius.circular(12),

                      borderSide: const BorderSide(

                        color: Color(0xFFFA5A1E),

                        width: 1.5,

                      ),

                    ),

                  ),

                  items: _mainReasonLabels.entries

                      .map((e) => DropdownMenuItem(

                            value: e.key,

                            child: Text(

                              e.value,

                              style: const TextStyle(

                                fontSize: 13,

                                fontWeight: FontWeight.w500,

                                color: Color(0xFF0F172A),

                              ),

                            ),

                          ))

                      .toList(),

                  onChanged: (val) {

                    if (val != null) setState(() => _mainReason = val);

                  },

                ),

                const SizedBox(height: 12),



                // Detailed message textarea

                Row(

                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [

                    const Text.rich(

                      TextSpan(

                        text: 'Mô tả chi tiết & Kế hoạch bù ',

                        style: TextStyle(

                          fontSize: 12.5,

                          fontWeight: FontWeight.w600,

                          color: Color(0xFF475569),

                        ),

                        children: [

                          TextSpan(

                            text: '*',

                            style: TextStyle(color: Color(0xFFEF4444)),

                          ),

                        ],

                      ),

                    ),

                    Text(

                      '${_reasonController.text.length}/500',

                      style: const TextStyle(

                        fontSize: 11,

                        color: Color(0xFF64748B),

                      ),

                    ),

                  ],

                ),

                const SizedBox(height: 6),

                TextField(

                  controller: _reasonController,

                  maxLength: 500,

                  maxLines: 3,

                  buildCounter: (_,

                          {required currentLength,

                          required isFocused,

                          maxLength}) =>

                      null,

                  onChanged: (_) => setState(() {}),

                  style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),

                  decoration: InputDecoration(

                    hintText:

                        'Mô tả chi tiết lý do vắng mặt, người dự kiến dạy thay hoặc kế hoạch học bù...',

                    hintStyle: const TextStyle(

                      fontSize: 12.5,

                      color: Color(0xFF94A3B8),

                      height: 1.35,

                    ),

                    filled: true,

                    fillColor: const Color(0xFFF8FAFC),

                    contentPadding: const EdgeInsets.all(12),

                    enabledBorder: OutlineInputBorder(

                      borderRadius: BorderRadius.circular(12),

                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),

                    ),

                    focusedBorder: OutlineInputBorder(

                      borderRadius: BorderRadius.circular(12),

                      borderSide: const BorderSide(

                        color: Color(0xFFFA5A1E),

                        width: 1.5,

                      ),

                    ),

                  ),

                ),

                const SizedBox(height: 14),



                // 4. Attachments Section

                Row(

                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [

                    Row(

                      children: const [

                        Icon(

                          Icons.attach_file_rounded,

                          size: 14,

                          color: Color(0xFFFA5A1E),

                        ),

                        SizedBox(width: 4),

                        Text(

                          'Minh chứng đính kèm (Tối đa 15MB)',

                          style: TextStyle(

                            fontSize: 11,

                            fontWeight: FontWeight.w600,

                            color: Color(0xFF475569),

                          ),

                        ),

                      ],

                    ),

                    GestureDetector(

                      onTap: _pickFile,

                      child: const Text(

                        '+ Thêm tệp',

                        style: TextStyle(

                          fontSize: 11,

                          fontWeight: FontWeight.w700,

                          color: Color(0xFFFA5A1E),

                        ),

                      ),

                    ),

                  ],

                ),

                const SizedBox(height: 8),



                if (_attachments.isEmpty)

                  Container(

                    padding: const EdgeInsets.symmetric(

                      horizontal: 12,

                      vertical: 10,

                    ),

                    decoration: BoxDecoration(

                      color: const Color(0xFFF8FAFC),

                      borderRadius: BorderRadius.circular(12),

                      border: Border.all(

                        color: const Color(0xFFE2E8F0),

                        style: BorderStyle.solid,

                      ),

                    ),

                    child: Row(

                      children: const [

                        Icon(

                          Icons.picture_as_pdf_outlined,

                          size: 18,

                          color: Color(0xFF94A3B8),

                        ),

                        SizedBox(width: 8),

                        Expanded(

                          child: Text(

                            'Chưa có tệp minh chứng đính kèm (PDF, JPG, PNG...)',

                            style: TextStyle(

                              fontSize: 11.5,

                              color: Color(0xFF94A3B8),

                            ),

                          ),

                        ),

                      ],

                    ),

                  )

                else

                  Column(

                    children: _attachments.asMap().entries.map((entry) {

                      final idx = entry.key;

                      final f = entry.value;

                      final sizeMb = (f.size / (1024 * 1024)).toStringAsFixed(1);

                      return Padding(

                        padding: const EdgeInsets.only(bottom: 6),

                        child: Container(

                          padding: const EdgeInsets.symmetric(

                            horizontal: 10,

                            vertical: 8,

                          ),

                          decoration: BoxDecoration(

                            color: const Color(0xFFF8FAFC),

                            borderRadius: BorderRadius.circular(12),

                            border: Border.all(color: const Color(0xFFE2E8F0)),

                          ),

                          child: Row(

                            children: [

                              Icon(

                                f.name.endsWith('.pdf')

                                    ? Icons.picture_as_pdf_rounded

                                    : Icons.image_rounded,

                                size: 18,

                                color: const Color(0xFFFA5A1E),

                              ),

                              const SizedBox(width: 8),

                              Expanded(

                                child: Column(

                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [

                                    Text(

                                      f.name,

                                      style: const TextStyle(

                                        fontSize: 11.5,

                                        fontWeight: FontWeight.w600,

                                        color: Color(0xFF0F172A),

                                      ),

                                      maxLines: 1,

                                      overflow: TextOverflow.ellipsis,

                                    ),

                                    Text(

                                      '$sizeMb MB · Đã tải lên',

                                      style: const TextStyle(

                                        fontSize: 10,

                                        color: Color(0xFF64748B),

                                      ),

                                    ),

                                  ],

                                ),

                              ),

                              IconButton(

                                padding: EdgeInsets.zero,

                                constraints: const BoxConstraints(),

                                icon: const Icon(

                                  Icons.close_rounded,

                                  size: 16,

                                  color: Color(0xFF64748B),

                                ),

                                onPressed: () => setState(

                                  () => _attachments.removeAt(idx),

                                ),

                              ),

                            ],

                          ),

                        ),

                      );

                    }).toList(),

                  ),

                const SizedBox(height: 12),



                // 5. Academic Policy Note

                Container(

                  padding: const EdgeInsets.all(10),

                  decoration: BoxDecoration(

                    color: const Color(0xFFF8FAFC),

                    borderRadius: BorderRadius.circular(12),

                    border: Border.all(color: const Color(0xFFE2E8F0)),

                  ),

                  child: Row(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      const Icon(

                        Icons.info_outline_rounded,

                        size: 18,

                        color: Color(0xFFFA5A1E),

                      ),

                      const SizedBox(width: 8),

                      Expanded(

                        child: Text.rich(

                          TextSpan(

                            text: 'Lưu ý: ',

                            style: const TextStyle(

                              fontSize: 11,

                              fontWeight: FontWeight.w700,

                              color: Color(0xFF0F172A),

                            ),

                            children: [

                              const TextSpan(

                                text:

                                    'Đơn xin nghỉ phép cần gửi trước ít nhất ',

                                style: TextStyle(

                                  fontWeight: FontWeight.normal,

                                  color: Color(0xFF64748B),

                                ),

                              ),

                              const TextSpan(

                                text: '02 tiếng',

                                style: TextStyle(

                                  fontWeight: FontWeight.w700,

                                  color: Color(0xFFFA5A1E),

                                ),

                              ),

                              const TextSpan(

                                text:

                                    ' trước giờ bắt đầu slot học để HAC kịp thời phê duyệt.',

                                style: TextStyle(

                                  fontWeight: FontWeight.normal,

                                  color: Color(0xFF64748B),

                                ),

                              ),

                            ],

                          ),

                          style: const TextStyle(height: 1.3),

                        ),

                      ),

                    ],

                  ),

                ),



                if (_error != null) ...[

                  const SizedBox(height: 10),

                  Text(

                    _error!,

                    style: const TextStyle(

                      color: Color(0xFFEF4444),

                      fontSize: 12,

                      fontWeight: FontWeight.w500,

                    ),

                  ),

                ],

                    const SizedBox(height: 16),
            ],
          ),
    );
  }

  Widget _buildRadioCard({

    required String type,

    required String title,

    String? badge,

    required String subtitle,

    required IconData icon,

    required Color iconColor,

    required Color iconBg,

  }) {

    final isSelected = _requestType == type;

    return InkWell(

      borderRadius: BorderRadius.circular(12),

      onTap: () => setState(() => _requestType = type),

      child: AnimatedContainer(

        duration: const Duration(milliseconds: 150),

        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

        decoration: BoxDecoration(

          color: isSelected ? const Color(0xFFFFF7ED) : Colors.white,

          borderRadius: BorderRadius.circular(12),

          border: Border.all(

            color: isSelected ? const Color(0xFFFA5A1E) : const Color(0xFFE2E8F0),

            width: isSelected ? 1.8 : 1,

          ),

        ),

        child: Row(

          children: [

            Container(

              width: 32,

              height: 32,

              decoration: BoxDecoration(

                color: iconBg,

                borderRadius: BorderRadius.circular(8),

              ),

              child: Center(

                child: Icon(icon, color: iconColor, size: 18),

              ),

            ),

            const SizedBox(width: 10),

            Expanded(

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Row(

                    children: [

                      Text(

                        title,

                        style: const TextStyle(

                          fontSize: 13,

                          fontWeight: FontWeight.w700,

                          color: Color(0xFF0F172A),

                        ),

                      ),

                      if (badge != null) ...[

                        const SizedBox(width: 6),

                        Container(

                          padding: const EdgeInsets.symmetric(

                            horizontal: 5,

                            vertical: 1.5,

                          ),

                          decoration: BoxDecoration(

                            color: const Color(0xFFFFEDD5),

                            borderRadius: BorderRadius.circular(6),

                          ),

                          child: Text(

                            badge,

                            style: const TextStyle(

                              color: Color(0xFFFA5A1E),

                              fontSize: 9.5,

                              fontWeight: FontWeight.w700,

                            ),

                          ),

                        ),

                      ],

                    ],

                  ),

                  const SizedBox(height: 2),

                  Text(

                    subtitle,

                    style: const TextStyle(

                      fontSize: 11,

                      color: Color(0xFF64748B),

                    ),

                  ),

                ],

              ),

            ),

            Container(

              width: 16,

              height: 16,

              decoration: BoxDecoration(

                shape: BoxShape.circle,

                border: Border.all(

                  color: isSelected

                      ? const Color(0xFFFA5A1E)

                      : const Color(0xFFCBD5E1),

                  width: isSelected ? 4.5 : 1.5,

                ),

              ),

            ),

          ],

        ),

      ),

    );

  }



  // ------------------------------------------------------------- TAB 2: HISTORY
  Widget _buildHistoryTab(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _repo.watchMine(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: Color(0xFFBA1A1A),
                ),
                const SizedBox(height: 10),
                Text(
                  'Không tải được lịch sử: ${snapshot.error}',
                  style: const TextStyle(
                    color: Color(0xFFBA1A1A),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () =>
                      setState(() => _requestsStream = _repo.watchMine()),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFCC4900),
            ),
          );
        }

        final allItems = snapshot.data!;
        final totalCount = allItems.length;
        final pendingCount = allItems
            .where((e) => (e['status']?.toString() ?? 'pending') == 'pending')
            .length;
        final approvedCount =
            allItems.where((e) => e['status'] == 'approved').length;
        final rejectedCount =
            allItems.where((e) => e['status'] == 'rejected').length;

        final filteredList = allItems.where((r) {
          final s = r['status']?.toString() ?? 'pending';
          if (_historyFilter == 'pending') return s == 'pending';
          if (_historyFilter == 'approved') return s == 'approved';
          if (_historyFilter == 'rejected') return s == 'rejected';
          return true;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 3. FILTER CHIPS & STATUS SUMMARY
            Container(
              height: 38,
              margin: const EdgeInsets.only(top: 4, bottom: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildFilterChip(
                    key: 'all',
                    label: 'Tất cả ($totalCount)',
                    dotColor: null,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    key: 'pending',
                    label: 'Chờ duyệt ($pendingCount)',
                    dotColor: const Color(0xFFCC4900),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    key: 'approved',
                    label: 'Đã duyệt ($approvedCount)',
                    dotColor: const Color(0xFF00855B),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    key: 'rejected',
                    label: 'Từ chối ($rejectedCount)',
                    dotColor: const Color(0xFFBA1A1A),
                  ),
                ],
              ),
            ),

            // 4. LIST OF REQUEST HISTORY ITEMS (SCROLLABLE CANVAS)
            Expanded(
              child: filteredList.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      itemCount: filteredList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final row = filteredList[index];
                        final status = row['status']?.toString() ?? 'pending';
                        if (status == 'approved') {
                          return _buildApprovedCard(context, row);
                        } else if (status == 'rejected') {
                          return _buildRejectedCard(context, row);
                        }
                        return _buildPendingCard(context, row);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String key,
    required String label,
    Color? dotColor,
  }) {
    final isSelected = _historyFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _historyFilter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2D3133) : const Color(0xFFECEEF0),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFFEFF1F3)
                    : const Color(0xFF191C1E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // CARD 1: PENDING (Chờ duyệt)
  Widget _buildPendingCard(BuildContext context, Map<String, dynamic> row) {
    final type = row['type']?.toString() ?? 'leave';
    final typeTitle = _getTypeTitle(type);
    final typeIcon = _getTypeIcon(type);
    final classInfo = _parseClassInfo(row['classCode']?.toString() ?? '');
    final schedule = _parseSchedule(row);
    final reasonDetail = _parseDetailReason(row);
    final attachmentName = _parseAttachmentName(row);
    final createdAt = row['createdAt'] as Timestamp?;
    final ticketCode = _formatTicketCode(row['id']?.toString() ?? '', createdAt);
    final timeStr = createdAt != null
        ? 'Gửi lúc ${createdAt.toDate().hour.toString().padLeft(2, '0')}:${createdAt.toDate().minute.toString().padLeft(2, '0')} hôm nay'
        : 'Gửi gần đây';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFCC4900).withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14EA580C),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar: Type + Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDBCE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      typeIcon,
                      size: 16,
                      color: const Color(0xFFCC4900),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    typeTitle,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF191C1E),
                    ),
                  ),
                ],
              ),
              // Status Badge Pending
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDBCE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFCC4900),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Đang chờ duyệt',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFA33900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Academic & Slot Details
          Row(
            children: [
              Text(
                classInfo['code']!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFCC4900),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                classInfo['class']!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF565E74),
                ),
              ),
              if (classInfo['name']!.isNotEmpty) ...[
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '• ${classInfo['name']}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF565E74),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 16,
                color: Color(0xFF565E74),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  schedule,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF191C1E),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Reason block
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE2BFB2).withOpacity(0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: Color(0xFF565E74),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reasonDetail,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF5A4138),
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (attachmentName != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.attach_file_rounded,
                              size: 14,
                              color: Color(0xFFCC4900),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Kèm minh chứng ($attachmentName)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFCC4900),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Card Footer
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFECEEF0))),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 8,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ticketCode,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF565E74),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('•', style: TextStyle(color: Color(0xFF565E74))),
                    const SizedBox(width: 6),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF565E74),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => _showRequestDetailDialog(context, row, ticketCode),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Chi tiết yêu cầu',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFA33900),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xFFA33900),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // CARD 2: APPROVED (Đã duyệt)
  Widget _buildApprovedCard(BuildContext context, Map<String, dynamic> row) {
    final type = row['type']?.toString() ?? 'attendance_fix';
    final typeTitle = _getTypeTitle(type);
    final typeIcon = _getTypeIcon(type);
    final classInfo = _parseClassInfo(row['classCode']?.toString() ?? '');
    final schedule = _parseSchedule(row);
    final adminNote = row['adminNote']?.toString() ?? '';
    final createdAt = row['createdAt'] as Timestamp?;
    final ticketCode = _formatTicketCode(row['id']?.toString() ?? '', createdAt);
    final approvalStr = createdAt != null
        ? 'HAC_Admin duyệt ${createdAt.toDate().hour.toString().padLeft(2, '0')}:${createdAt.toDate().minute.toString().padLeft(2, '0')}, ${createdAt.toDate().day.toString().padLeft(2, '0')}/${createdAt.toDate().month.toString().padLeft(2, '0')}'
        : 'HAC_Admin duyệt';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE2BFB2).withOpacity(0.3),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar: Type + Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      typeIcon,
                      size: 16,
                      color: const Color(0xFF006947),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    typeTitle,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF191C1E),
                    ),
                  ),
                ],
              ),
              // Status Badge Approved
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: Color(0xFF006947),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Đã phê duyệt',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF006947),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Academic & Slot Details
          Row(
            children: [
              Text(
                classInfo['code']!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF191C1E),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                classInfo['class']!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF565E74),
                ),
              ),
              if (classInfo['name']!.isNotEmpty) ...[
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '• ${classInfo['name']}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF565E74),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 16,
                color: Color(0xFF565E74),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  schedule,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF191C1E),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Note from HAC
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7).withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF6FFBBE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.verified_rounded,
                  size: 16,
                  color: Color(0xFF006947),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Phản hồi từ HAC:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF006947),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        adminNote.isNotEmpty
                            ? adminNote
                            : 'Đã cập nhật có mặt cho sinh viên theo yêu cầu.',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF002113),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Card Footer
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFECEEF0))),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 8,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ticketCode,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF565E74),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('•', style: TextStyle(color: Color(0xFF565E74))),
                    const SizedBox(width: 6),
                    Text(
                      approvalStr,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF565E74),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => _showRequestDetailDialog(context, row, ticketCode),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Xem phiếu duyệt',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF006947),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xFF006947),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // CARD 3: REJECTED (Từ chối)
  Widget _buildRejectedCard(BuildContext context, Map<String, dynamic> row) {
    final type = row['type']?.toString() ?? 'reschedule';
    final typeTitle = _getTypeTitle(type);
    final typeIcon = _getTypeIcon(type);
    final classInfo = _parseClassInfo(row['classCode']?.toString() ?? '');
    final schedule = _parseSchedule(row);
    final adminNote = row['adminNote']?.toString() ?? '';
    final createdAt = row['createdAt'] as Timestamp?;
    final ticketCode = _formatTicketCode(row['id']?.toString() ?? '', createdAt);
    final dateStr = createdAt != null
        ? '${createdAt.toDate().day.toString().padLeft(2, '0')}/${createdAt.toDate().month.toString().padLeft(2, '0')}/${createdAt.toDate().year}'
        : 'Gần đây';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFFDAD6),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar: Type + Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDAD6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      typeIcon,
                      size: 16,
                      color: const Color(0xFFBA1A1A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    typeTitle,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF191C1E),
                    ),
                  ),
                ],
              ),
              // Status Badge Rejected
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDAD6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.cancel_rounded,
                      size: 14,
                      color: Color(0xFFBA1A1A),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Bị từ chối',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFBA1A1A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Academic & Slot Details
          Row(
            children: [
              Text(
                classInfo['code']!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF191C1E),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                classInfo['class']!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF565E74),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              const Icon(
                Icons.event_repeat_rounded,
                size: 16,
                color: Color(0xFF565E74),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Đề xuất chuyển sang $schedule',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF191C1E),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Reason Rejected
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFDAD6).withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFDAD6)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 16,
                  color: Color(0xFFBA1A1A),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lý do từ chối:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFBA1A1A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        adminNote.isNotEmpty
                            ? adminNote
                            : 'Phòng học AL-306 đã có lịch thi cuối kỳ vào slot yêu cầu. Vui lòng chọn slot khác.',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF93000A),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Card Footer
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFECEEF0))),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 8,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ticketCode,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF565E74),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('•', style: TextStyle(color: Color(0xFF565E74))),
                    const SizedBox(width: 6),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF565E74),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => _reapplyRequest(row),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6E8EA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.refresh_rounded,
                          size: 14,
                          color: Color(0xFF191C1E),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Tạo lại yêu cầu',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF191C1E),
                          ),
                        ),
                      ],
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

  Widget _buildEmptyState() {
    String message = 'Bạn chưa gửi yêu cầu nào.';
    if (_historyFilter == 'pending') {
      message = 'Không có yêu cầu nào đang chờ duyệt.';
    } else if (_historyFilter == 'approved') {
      message = 'Chưa có yêu cầu nào được phê duyệt.';
    } else if (_historyFilter == 'rejected') {
      message = 'Không có yêu cầu nào bị từ chối.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFF2F4F6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inbox_outlined,
                size: 28,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF565E74),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => setState(() => _activeTab = 0),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('+ Tạo yêu cầu mới'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCC4900),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 5. BOTTOM ACTION BAR & SAFE AREA PADDING
  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: const Color(0xFFE6E8EA).withOpacity(0.6),
          ),
        ),
      ),
      child: Row(
        children: [
          // Button Secondary: Close
          Expanded(
            flex: 10,
            child: SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFF2F4F6),
                  foregroundColor: const Color(0xFF191C1E),
                  side: BorderSide(
                    color: const Color(0xFFE2BFB2).withOpacity(0.4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  'Đóng / Close',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Button Primary Brand: Create New Request or Submit
          Expanded(
            flex: 16,
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _activeTab == 1
                    ? () => setState(() => _activeTab = 0)
                    : (_saving ? null : _submitRequest),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCC4900),
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shadowColor: const Color(0x66CC4900),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: _activeTab == 1
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_circle_outline_rounded, size: 20),
                          SizedBox(width: 6),
                          Text(
                            '+ Tạo yêu cầu mới',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      )
                    : (_saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.send_rounded, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Gửi yêu cầu',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          )),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Mobile Home Indicator Bar
  Widget _buildHomeIndicator() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Center(
        child: Container(
          width: 128,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFE0E3E5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  void _reapplyRequest(Map<String, dynamic> row) {
    setState(() {
      _requestType = row['type']?.toString() ?? 'leave';
      final reasonDetail = _parseDetailReason(row);
      _reasonController.text = reasonDetail;
      _activeTab = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã nạp thông tin để tạo lại yêu cầu.'),
        backgroundColor: Color(0xFFCC4900),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showRequestDetailDialog(
    BuildContext context,
    Map<String, dynamic> row,
    String ticketCode,
  ) {
    final status = row['status']?.toString() ?? 'pending';
    final type = row['type']?.toString() ?? 'leave';
    final typeTitle = _getTypeTitle(type);
    final typeIcon = _getTypeIcon(type);
    final classInfo = _parseClassInfo(row['classCode']?.toString() ?? '');
    final schedule = _parseSchedule(row);
    final reasonDetail = _parseDetailReason(row);
    final adminNote = row['adminNote']?.toString() ?? '';
    final attachmentName = _parseAttachmentName(row);
    final createdAt = row['createdAt'] as Timestamp?;
    final dateStr = createdAt != null
        ? '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year} lúc ${createdAt.toDate().hour.toString().padLeft(2, '0')}:${createdAt.toDate().minute.toString().padLeft(2, '0')}'
        : 'Hôm nay';

    Color statusColor = const Color(0xFFA33900);
    Color statusBg = const Color(0xFFFFDBCE);
    String statusText = 'Đang chờ duyệt';
    IconData statusIcon = Icons.hourglass_top_rounded;

    if (status == 'approved') {
      statusColor = const Color(0xFF006947);
      statusBg = const Color(0xFFDCFCE7);
      statusText = 'Đã phê duyệt';
      statusIcon = Icons.check_circle_rounded;
    } else if (status == 'rejected') {
      statusColor = const Color(0xFFBA1A1A);
      statusBg = const Color(0xFFFFDAD6);
      statusText = 'Bị từ chối';
      statusIcon = Icons.cancel_rounded;
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Ticket ID + Close
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          ticketCode,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF191C1E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 12, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF565E74)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFECEEF0)),
              const SizedBox(height: 14),

              // Title with Type Icon
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDBCE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(typeIcon, size: 18, color: const Color(0xFFCC4900)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      typeTitle,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF191C1E),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Subject & Class details
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFECEEF0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${classInfo['code']} • ${classInfo['class']}${classInfo['name']!.isNotEmpty ? " (${classInfo['name']})" : ""}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF191C1E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF565E74)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            schedule,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF565E74)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Thời gian gửi: $dateStr',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF8E7166)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Content detail
              const Text(
                'Nội dung / Lý do:',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF191C1E),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2BFB2).withOpacity(0.3)),
                ),
                child: Text(
                  reasonDetail,
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF5A4138), height: 1.4),
                ),
              ),

              if (attachmentName != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.attach_file_rounded, size: 15, color: Color(0xFFCC4900)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Minh chứng đính kèm: $attachmentName',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFCC4900),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              // HAC Response (if any)
              if (adminNote.isNotEmpty || status == 'approved' || status == 'rejected') ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: status == 'rejected'
                        ? const Color(0xFFFFDAD6).withOpacity(0.5)
                        : const Color(0xFFDCFCE7).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: status == 'rejected' ? const Color(0xFFFFDAD6) : const Color(0xFF6FFBBE),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        status == 'rejected' ? Icons.error_outline_rounded : Icons.verified_rounded,
                        size: 16,
                        color: status == 'rejected' ? const Color(0xFFBA1A1A) : const Color(0xFF006947),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              status == 'rejected' ? 'Lý do từ chối từ HAC:' : 'Phản hồi từ HAC:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: status == 'rejected' ? const Color(0xFFBA1A1A) : const Color(0xFF006947),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              adminNote.isNotEmpty
                                  ? adminNote
                                  : (status == 'rejected'
                                      ? 'Không đủ điều kiện theo quy chế đào tạo.'
                                      : 'Yêu cầu đã được phê duyệt.'),
                              style: TextStyle(
                                fontSize: 12,
                                color: status == 'rejected' ? const Color(0xFF93000A) : const Color(0xFF002113),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Button Close
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCC4900),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
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

  String _getTypeTitle(String type) {
    switch (type) {
      case 'leave':
        return 'Xin nghỉ phép / Báo vắng';
      case 'attendance_fix':
        return 'Bổ sung điểm danh';
      case 'reschedule':
        return 'Đổi ca dạy / Dạy bù';
      default:
        return 'Yêu cầu đào tạo';
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'leave':
        return Icons.calendar_today_rounded;
      case 'attendance_fix':
        return Icons.how_to_reg_rounded;
      case 'reschedule':
        return Icons.swap_horiz_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  String _formatTicketCode(String id, Timestamp? createdAt) {
    if (id.startsWith('#YCHV-')) return id;
    if (createdAt != null) {
      final dt = createdAt.toDate();
      final dateCode =
          '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';
      final suffix = id.length >= 2 ? id.substring(id.length - 2).toUpperCase() : '01';
      return '#YCHV-$dateCode-$suffix';
    }
    return id.isEmpty ? 'Đang gửi' : id;
  }

  Map<String, String> _parseClassInfo(String raw) {
    if (raw.isEmpty) {
      return {'code': 'Chưa cung cấp', 'class': '', 'name': ''};
    }
    String code = raw;
    String cls = '';
    String name = '';
    if (raw.contains(' - ')) {
      final parts = raw.split(' - ');
      code = parts[0].trim();
      final rest = parts.sublist(1).join(' - ').trim();
      if (rest.contains('(')) {
        cls = rest.split('(')[0].trim();
        name = rest.split('(')[1].replaceAll(')', '').trim();
      } else {
        cls = rest;
      }
    }
    return {'code': code, 'class': cls, 'name': name};
  }

  String _parseSchedule(Map<String, dynamic> row) {
    final slot = row['slot']?.toString();
    final date = row['date']?.toString();
    if (slot != null && slot.isNotEmpty && date != null && date.isNotEmpty) {
      return '$slot • $date';
    }
    if (date != null && date.isNotEmpty) return date;
    final reason = row['reason']?.toString() ?? '';
    for (final line in reason.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('[Ca học]:')) {
        return trimmed.substring('[Ca học]:'.length).trim();
      }
    }
    return 'Chưa cung cấp lịch học';
  }

  String _parseDetailReason(Map<String, dynamic> row) {
    final reason = row['reason']?.toString() ?? '';
    for (final line in reason.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('[Chi tiết & Kế hoạch]:')) {
        return trimmed.substring('[Chi tiết & Kế hoạch]:'.length).trim();
      }
    }
    for (final line in reason.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('[Lý do chính]:')) {
        return trimmed.substring('[Lý do chính]:'.length).trim();
      }
    }
    return reason;
  }

  String? _parseAttachmentName(Map<String, dynamic> row) {
    final atts = row['attachments'] as List?;
    if (atts != null && atts.isNotEmpty) {
      final first = atts.first;
      if (first is Map && first['name'] != null) return first['name'].toString();
      if (first is String) {
        if (first.contains('(')) return first.split('(')[0].trim();
        final uri = Uri.tryParse(first);
        if (uri != null && uri.pathSegments.isNotEmpty) {
          return uri.pathSegments.last.split('?').first;
        }
      }
      return 'Minh_chứng.pdf';
    }
    final reason = row['reason']?.toString() ?? '';
    if (reason.contains('[Tệp minh chứng]:')) {
      bool foundMarker = false;
      for (final line in reason.split('\n')) {
        final trimmed = line.trim();
        if (foundMarker && trimmed.isNotEmpty) {
          if (trimmed.contains('(')) return trimmed.split('(')[0].trim();
          return 'Minh_chứng.pdf';
        }
        if (trimmed.startsWith('[Tệp minh chứng]:')) {
          foundMarker = true;
        }
      }
    }
    return null;
  }
}
