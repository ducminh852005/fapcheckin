import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fapcheckin_core/models/timetable_scan_model.dart';
import 'package:fapcheckin_core/repositories/timetable_repository.dart';
import 'package:fapcheckin_core/result/api_result.dart';

/// Hiển thị Popup Quét thời khóa biểu dạng Bottom Sheet trượt từ dưới lên
Future<TimetableImportResult?> showImportTimetableBottomSheet(
  BuildContext context, {
  TimetableRepository? repository,
}) {
  return showModalBottomSheet<TimetableImportResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xFF0F172A).withValues(alpha: 0.55),
    builder: (ctx) => ImportTimetableBottomSheet(repository: repository),
  );
}

enum _ScanStep { pick, scanning, review, importing }

class ImportTimetableBottomSheet extends StatefulWidget {
  const ImportTimetableBottomSheet({super.key, this.repository});

  final TimetableRepository? repository;

  @override
  State<ImportTimetableBottomSheet> createState() =>
      _ImportTimetableBottomSheetState();
}

class _ImportTimetableBottomSheetState
    extends State<ImportTimetableBottomSheet> {
  static const int _maxFileSizeBytes = 5 * 1024 * 1024;

  late final TimetableRepository _repository;

  TimetableScanResult? _scan;
  final Set<String> _selectedClassCodes = {};
  String? _fileName;
  Uint8List? _previewBytes;
  String? _error;
  _ScanStep _step = _ScanStep.pick;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? context.read<TimetableRepository>();
  }

  String? _mimeTypeFor(String name) {
    final extension = name.split('.').last.toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      _ => null,
    };
  }

  Future<void> _pickAndScan() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      allowMultiple: false,
      withData: true,
    );
    if (!mounted || picked == null || picked.files.isEmpty) return;
    final file = picked.files.single;
    final bytes = file.bytes;
    final mimeType = _mimeTypeFor(file.name);
    if (bytes == null || mimeType == null) {
      setState(() => _error = 'Không thể đọc tệp ảnh đã chọn.');
      return;
    }
    if (bytes.lengthInBytes > _maxFileSizeBytes) {
      setState(
        () => _error =
            'Ảnh vượt quá 5 MB. Hãy cắt gọn hoặc nén ảnh rồi thử lại.',
      );
      return;
    }
    await _scanBytes(bytes, file.name, mimeType);
  }

  Future<void> _scanBytes(Uint8List bytes, String name, String mimeType) async {
    setState(() {
      _step = _ScanStep.scanning;
      _error = null;
      _scan = null;
      _fileName = name;
      _previewBytes = bytes;
      _selectedClassCodes.clear();
    });
    final result = await _repository.scanImage(
      bytes: bytes,
      fileName: name,
      mimeType: mimeType,
    );

    if (!mounted) return;

    setState(() {
      switch (result) {
        case ApiSuccess<TimetableScanResult>(:final data):
          _scan = data;
          _selectedClassCodes
            ..clear()
            ..addAll(
              data.entries
                  .where((e) => e.canImport && e.matchedClassCode != null)
                  .map((e) => e.matchedClassCode!),
            );
          _step = _ScanStep.review;
        case ApiFailure<TimetableScanResult>(:final error):
          _error = error.message;
          _step = _ScanStep.pick;
      }
    });
  }

  Future<void> _import() async {
    final scan = _scan;
    if (scan == null || _selectedClassCodes.isEmpty) return;

    setState(() {
      _step = _ScanStep.importing;
      _error = null;
    });

    final result = await _repository.importAssignments(
      scanToken: scan.scanToken,
      classCodes: _selectedClassCodes.toList(),
    );

    if (!mounted) return;

    switch (result) {
      case ApiSuccess<TimetableImportResult>(:final data):
        Navigator.pop(context, data);
      case ApiFailure<TimetableImportResult>(:final error):
        setState(() {
          _error = error.message;
          _step = _ScanStep.review;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thanh kéo nhỏ
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
              const SizedBox(height: 16),

              // Header: Icon Huy hiệu cam + Tiêu đề + Huy hiệu AI OCR + Nút đóng
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF8533), Color(0xFFE65100)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEA580C).withValues(alpha: 0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.document_scanner_rounded,
                      color: Colors.white,
                      size: 24,
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
                                'Quét thời khóa biểu',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEDD5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFFED7AA),
                                  width: 0.8,
                                ),
                              ),
                              child: const Text(
                                'AI OCR',
                                style: TextStyle(
                                  color: Color(0xFFEA580C),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'FAP Student Portal • FPT University',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: _step == _ScanStep.scanning || _step == _ScanStep.importing
                        ? null
                        : () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(18),
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
                ],
              ),
              const SizedBox(height: 14),

              // Nội dung hiển thị theo từng bước
              if (_step == _ScanStep.pick) ...[
                // Mô tả giới thiệu
                const Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF475569),
                      height: 1.45,
                    ),
                    children: [
                      TextSpan(text: 'Chụp ảnh hoặc tải lên thời khóa biểu '),
                      TextSpan(
                        text: 'FAP',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      TextSpan(
                        text:
                            '. Hệ thống AI tự động trích xuất danh sách lớp, ca học và giảng đường chính xác.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── Khung Tải lên / Chụp ảnh (Dropzone viền nét đứt cam) ─
                _buildUploadDropzone(),
                const SizedBox(height: 14),

                // ── Thẻ Trạng thái AI OCR ────────────────────────────────
                _buildOcrStatusCard(),
                const SizedBox(height: 14),

                // ── Thẻ Mẹo quét lịch học chuẩn xác ─────────────────────
                _buildTipsCard(),
                const SizedBox(height: 20),

                // ── Nút chân trang: Hủy & Chọn ảnh để quét ─────────────
                Row(
                  children: [
                    SizedBox(
                      width: 90,
                      height: 48,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFF1F5F9),
                          foregroundColor: const Color(0xFF334155),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Hủy',
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
                          onPressed: _pickAndScan,
                          icon: const Icon(
                            Icons.file_upload_outlined,
                            size: 19,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Chọn ảnh để quét',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEA580C),
                            foregroundColor: Colors.white,
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
              ] else if (_step == _ScanStep.scanning) ...[
                _buildScanningView(),
              ] else if (_step == _ScanStep.review) ...[
                _buildReviewView(),
              ] else if (_step == _ScanStep.importing) ...[
                _buildImportingView(),
              ],

              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFDC2626),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFB91C1C),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadDropzone() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CustomPaint(
          painter: const _DashedBorderPainter(
            color: Color(0xFFFDBA74),
            radius: 20,
            strokeWidth: 1.4,
          ),
          child: Material(
            color: const Color(0xFFFFFDFB),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: _pickAndScan,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
                child: Column(
                  children: [
                    // Khối icon hình ảnh cam
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFFEDD5),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEA580C).withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.image_outlined,
                        color: Color(0xFFEA580C),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tiêu đề
                    const Text(
                      'Tải lên hoặc chụp ảnh thời khóa biểu',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Phụ đề
                    const Text(
                      'Hỗ trợ ảnh JPG, PNG • Tối đa 5 MB\nẢnh được nhận dạng ngay trên điện thoại',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Huy hiệu "Nhận diện tự động" ghim ở mép trên
        Positioned(
          top: -11,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
              decoration: BoxDecoration(
                color: const Color(0xFFEA580C),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Nhận diện tự động',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOcrStatusCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nhận dạng trên thiết bị',
                  style: TextStyle(
                    fontSize: 12.8,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Đọc mã lớp–môn • Kiểm tra kết quả trước khi nhập',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Sẵn\nsàng',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF15803D),
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFEA580C),
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'i',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFEA580C),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'MẸO QUÉT LỊCH HỌC CHUẨN XÁC',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '4 lưu ý',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipItem(
            text: 'Chụp thẳng góc màn hình/giấy in, đủ sáng, tránh bóng lóa.',
          ),
          const SizedBox(height: 8),
          _buildTipItemRich(
            prefix: 'Hiển thị rõ ',
            bold1: 'Mã Lớp',
            between: ' & ',
            bold2: 'Môn',
            suffix: ' (VD: ',
            chips: ['SE1917', 'PRN231'],
          ),
          const SizedBox(height: 8),
          _buildTipItemRich(
            prefix: 'Hỗ trợ quét thời khóa biểu theo ',
            bold1: 'Tuần',
            between: ' hoặc ',
            bold2: 'Cả kỳ',
            suffix: '.',
          ),
          const SizedBox(height: 8),
          _buildTipItem(
            text:
                'Hệ thống cho phép xem trước và điều chỉnh trước khi đồng bộ.',
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem({required String text}) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 15,
            color: Color(0xFF10B981),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                color: Color(0xFF475569),
                height: 1.35,
              ),
            ),
          ),
        ],
      );

  Widget _buildTipItemRich({
    required String prefix,
    required String bold1,
    required String between,
    required String bold2,
    required String suffix,
    List<String> chips = const [],
  }) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 15,
            color: Color(0xFF10B981),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  prefix,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF475569),
                  ),
                ),
                Text(
                  bold1,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  between,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF475569),
                  ),
                ),
                Text(
                  bold2,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  suffix,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF475569),
                  ),
                ),
                for (int i = 0; i < chips.length; i++) ...[
                  _codeChip(chips[i]),
                  if (i < chips.length - 1)
                    const Text(
                      ' • ',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                ],
                if (chips.isNotEmpty)
                  const Text(
                    ' ).',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF475569),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );

  Widget _codeChip(String code) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          code,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
            fontFamily: 'monospace',
          ),
        ),
      );

  // ── Step: Scanning View ─────────────────────────────────────────────────────
  Widget _buildScanningView() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          if (_previewBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                _previewBytes!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 24),
          const CircularProgressIndicator(
            color: Color(0xFFEA580C),
            strokeWidth: 3,
          ),
          const SizedBox(height: 18),
          const Text(
            'Đang phân tích thời khóa biểu bằng AI OCR...',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _fileName ?? 'Vui lòng chờ trong giây lát...',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step: Review View ───────────────────────────────────────────────────────
  Widget _buildReviewView() {
    final entries = _scan?.entries ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Đọc được ${entries.length} mã lớp–môn',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _pickAndScan,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Quét lại'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (entries.isNotEmpty && !entries.any((e) => e.canImport))
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Không có lớp mới đủ điều kiện để nhận. OCR chỉ đọc mã từ ảnh, không tạo lớp mới. Lớp cần có trong hệ thống, đúng mã môn và chưa được phân công; lớp bạn đã nhận không cần thêm lại.',
              style: TextStyle(fontSize: 12, color: Color(0xFF9A3412)),
            ),
          ),
        for (final entry in entries) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: entry.matchedClassCode != null &&
                      _selectedClassCodes.contains(entry.matchedClassCode),
                  onChanged: entry.canImport && entry.matchedClassCode != null
                      ? (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedClassCodes.add(entry.matchedClassCode!);
                            } else {
                              _selectedClassCodes.remove(entry.matchedClassCode!);
                            }
                          });
                        }
                      : null,
                  activeColor: const Color(0xFFEA580C),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.classCode} • ${entry.subjectCode}',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Phòng: ${entry.room} • ${entry.message}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
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
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () => setState(() => _step = _ScanStep.pick),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Quay lại'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _selectedClassCodes.isEmpty ? null : _import,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA580C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Đồng bộ ${_selectedClassCodes.length} lớp',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Step: Importing View ────────────────────────────────────────────────────
  Widget _buildImportingView() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          CircularProgressIndicator(
            color: Color(0xFFEA580C),
            strokeWidth: 3,
          ),
          SizedBox(height: 18),
          Text(
            'Đang đồng bộ lớp học vào lịch dạy...',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter vẽ đường viền nét đứt bo tròn (Dashed Rounded Rectangle)
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;

  const _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.2,
    this.radius = 20,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const dashLength = 6.0;
    const gapLength = 4.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final len = (distance + dashLength < metric.length)
            ? dashLength
            : metric.length - distance;
        final extractPath = metric.extractPath(distance, distance + len);
        canvas.drawPath(extractPath, paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.radius != radius;
}
