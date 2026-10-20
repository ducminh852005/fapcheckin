import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/responsive/responsive_dialog.dart';
import '../../../../data/models/timetable_scan_model.dart';
import '../../../../data/repositories/timetable_repository.dart';

class ImportTimetableDialog extends StatefulWidget {
  const ImportTimetableDialog({super.key, this.repository});

  final TimetableRepository? repository;

  @override
  State<ImportTimetableDialog> createState() => _ImportTimetableDialogState();
}

enum _Step { pick, scanning, review, importing }

class _ImportTimetableDialogState extends State<ImportTimetableDialog> {
  static const int _maxFileSizeBytes = 10 * 1024 * 1024;

  late final TimetableRepository _repository;

  TimetableScanResult? _scan;
  final Set<String> _selectedClassCodes = {};
  String? _fileName;
  Uint8List? _previewBytes;
  String? _error;
  _Step _step = _Step.pick;

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ?? TimetableRepository(context.read<ApiService>());
  }

  String? _mimeTypeFor(String name) {
    final extension = name.split('.').last.toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'bmp' => 'image/bmp',
      _ => null,
    };
  }

  Future<void> _pickAndScan() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'bmp'],
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
            'Ảnh vượt quá 10 MB. Hãy cắt gọn hoặc nén ảnh rồi thử lại.',
      );
      return;
    }
    await _scanBytes(bytes, file.name, mimeType);
  }

  Future<void> _scanBytes(Uint8List bytes, String name, String mimeType) async {
    setState(() {
      _step = _Step.scanning;
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
          _step = _Step.review;
          _selectedClassCodes.addAll(
            data.entries
                .where((entry) => entry.canImport)
                .map((entry) => entry.matchedClassCode!),
          );
        case ApiFailure<TimetableScanResult>(:final error):
          _error = error.message;
          _step = _Step.pick;
      }
    });
  }

  Future<void> _import() async {
    final scan = _scan;
    if (scan == null ||
        _selectedClassCodes.isEmpty ||
        _step == _Step.importing) {
      return;
    }
    setState(() {
      _step = _Step.importing;
      _error = null;
    });

    final result = await _repository.importAssignments(
      scanToken: scan.scanToken,
      classCodes: _selectedClassCodes.toList(),
    );

    if (!mounted) return;

    switch (result) {
      case ApiSuccess<TimetableImportResult>(:final data):
        Navigator.of(context).pop(data);
      case ApiFailure<TimetableImportResult>(:final error):
        setState(() {
          _step = _Step.review;
          _error = error.message;
        });
    }
  }

  bool get _isBusy => _step == _Step.scanning || _step == _Step.importing;

  Color _statusColor(TimetableScanEntry entry) {
    return switch (entry.status) {
      'available' => AppColors.statusPresent,
      'alreadyAssigned' => AppColors.primary,
      _ => AppColors.error,
    };
  }

  IconData _statusIcon(TimetableScanEntry entry) {
    return switch (entry.status) {
      'available' => Icons.add_circle_outline_rounded,
      'alreadyAssigned' => Icons.check_circle_outline_rounded,
      'conflict' => Icons.block_rounded,
      _ => Icons.warning_amber_rounded,
    };
  }

  String _statusLabel(TimetableScanEntry entry) {
    return switch (entry.status) {
      'available' => 'Sẵn sàng',
      'alreadyAssigned' => 'Đã phân công',
      'conflict' => 'Xung đột',
      'ambiguous' => 'Mơ hồ',
      _ => 'Không tìm thấy',
    };
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveDialogFrame(
      maxWidth: 860,
      maxHeight: 780,
      radius: 20,
      backgroundColor:
          Theme.of(context).dialogTheme.backgroundColor ??
          Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          _DialogHeader(
            isBusy: _isBusy,
            step: _step,
            onClose: () => Navigator.pop(context),
          ),

          Divider(height: 1),

          // ── Body ──────────────────────────────────────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 250),
              child: switch (_step) {
                _Step.pick => _PickStep(
                  key: ValueKey('pick'),
                  fileName: _fileName,
                  error: _error,
                  onPickPressed: _pickAndScan,
                ),
                _Step.scanning => _ScanningStep(
                  key: ValueKey('scanning'),
                  previewBytes: _previewBytes,
                  fileName: _fileName,
                ),
                _Step.review => _ReviewStep(
                  key: ValueKey('review'),
                  scan: _scan!,
                  selectedClassCodes: _selectedClassCodes,
                  previewBytes: _previewBytes,
                  error: _error,
                  onToggle: (code, selected) {
                    setState(() {
                      if (selected) {
                        _selectedClassCodes.add(code);
                      } else {
                        _selectedClassCodes.remove(code);
                      }
                    });
                  },
                  statusColor: _statusColor,
                  statusIcon: _statusIcon,
                  statusLabel: _statusLabel,
                ),
                _Step.importing => _ImportingStep(
                  key: ValueKey('importing'),
                  count: _selectedClassCodes.length,
                ),
              },
            ),
          ),

          Divider(height: 1),

          // ── Footer ────────────────────────────────────────────────────────
          _DialogFooter(
            step: _step,
            selectedCount: _selectedClassCodes.length,
            isBusy: _isBusy,
            onCancel: _isBusy ? null : () => Navigator.pop(context),
            onPick: _isBusy ? null : _pickAndScan,
            onImport: (_selectedClassCodes.isEmpty || _isBusy) ? null : _import,
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ────────────────────────────────────────────────────────────

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({
    required this.isBusy,
    required this.step,
    required this.onClose,
  });

  final bool isBusy;
  final _Step step;
  final VoidCallback onClose;

  String get _subtitle {
    return switch (step) {
      _Step.pick =>
        'Chụp ảnh thời khóa biểu → hệ thống tự tìm lớp và thêm giáo viên.',
      _Step.scanning => 'Đang gửi ảnh lên Google OCR để nhận diện mã lớp...',
      _Step.review => 'Chọn lớp muốn thêm rồi nhấn Xác nhận thêm.',
      _Step.importing => 'Đang cập nhật phân công lớp...',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.isMobile ? 16 : 24,
        context.isMobile ? 12 : 20,
        8,
        context.isMobile ? 12 : 20,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.document_scanner_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quét thời khóa biểu',
                  style: AppTextStyles.headlineMd.copyWith(fontSize: 18),
                ),
                SizedBox(height: 2),
                Text(
                  _subtitle,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            onPressed: isBusy ? null : onClose,
            icon: Icon(Icons.close),
            tooltip: 'Đóng',
          ),
        ],
      ),
    );
  }
}

class _DialogFooter extends StatelessWidget {
  const _DialogFooter({
    required this.step,
    required this.selectedCount,
    required this.isBusy,
    required this.onCancel,
    required this.onPick,
    required this.onImport,
  });

  final _Step step;
  final int selectedCount;
  final bool isBusy;
  final VoidCallback? onCancel;
  final VoidCallback? onPick;
  final VoidCallback? onImport;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.isMobile ? 16 : 24,
        14,
        context.isMobile ? 16 : 24,
        16,
      ),
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          TextButton(onPressed: onCancel, child: Text('Hủy')),
          if (step == _Step.pick) ...[
            FilledButton.icon(
              onPressed: onPick,
              icon: Icon(Icons.upload_file, size: 18),
              label: Text('Chọn ảnh để quét'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
          if (step == _Step.review) ...[
            OutlinedButton.icon(
              onPressed: onPick,
              icon: Icon(Icons.refresh, size: 18),
              label: Text('Quét ảnh khác'),
            ),
            FilledButton.icon(
              onPressed: onImport,
              icon: Icon(Icons.person_add_alt_1, size: 18),
              label: Text(
                selectedCount == 0
                    ? 'Chưa chọn lớp nào'
                    : 'Xác nhận thêm $selectedCount lớp',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Step: Pick ───────────────────────────────────────────────────────────────

class _PickStep extends StatelessWidget {
  const _PickStep({
    super.key,
    required this.fileName,
    required this.error,
    required this.onPickPressed,
  });

  final String? fileName;
  final String? error;
  final VoidCallback onPickPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.isMobile ? 16 : 24),
      child: Column(
        children: [
          // Drop zone / upload area
          Expanded(
            child: GestureDetector(
              onTap: onPickPressed,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.border,
                      width: 2,
                      // Use dashed border style via custom paint or approximate with solid
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.photo_camera_back_outlined,
                          size: 36,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Nhấp để chọn ảnh thời khóa biểu',
                        style: AppTextStyles.headlineSm.copyWith(fontSize: 15),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Hỗ trợ JPG, PNG, GIF, BMP · Tối đa 10 MB',
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 24),
                      // Tips
                      _TipRow(
                        icon: Icons.check_circle_outline,
                        color: AppColors.statusPresent,
                        text: 'Chụp thẳng màn hình, đủ sáng, không bị lóa',
                      ),
                      SizedBox(height: 6),
                      _TipRow(
                        icon: Icons.check_circle_outline,
                        color: AppColors.statusPresent,
                        text: 'Mã lớp phải rõ, ví dụ: SE1917-PRN232',
                      ),
                      SizedBox(height: 6),
                      _TipRow(
                        icon: Icons.check_circle_outline,
                        color: AppColors.statusPresent,
                        text: 'Có thể quét nhiều ảnh, mỗi lần một ảnh',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (error != null) ...[
            SizedBox(height: 16),
            _ErrorBanner(message: error!),
          ],
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step: Scanning ────────────────────────────────────────────────────────────

class _ScanningStep extends StatelessWidget {
  const _ScanningStep({
    super.key,
    required this.previewBytes,
    required this.fileName,
  });

  final Uint8List? previewBytes;
  final String? fileName;

  @override
  Widget build(BuildContext context) {
    final mobile = context.isMobile;
    final preview = previewBytes == null
        ? null
        : ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              previewBytes!,
              width: mobile ? double.infinity : 300,
              height: mobile ? 160 : null,
              fit: BoxFit.cover,
            ),
          );
    final status = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        SizedBox(height: 20),
        Text(
          'Đang nhận diện thời khóa biểu…',
          style: AppTextStyles.headlineSm.copyWith(fontSize: 16),
        ),
        SizedBox(height: 8),
        Text(
          'Hệ thống đang dùng Google OCR để đọc mã lớp và mã môn học từ ảnh của bạn. '
          'Quá trình này thường mất 10–20 giây.',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
        ),
        if (fileName != null) ...[
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.image_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    fileName!,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: 16),
        LinearProgressIndicator(),
      ],
    );

    if (mobile) {
      return SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [?preview, SizedBox(height: 20), status],
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ?preview,
          SizedBox(width: 24),
          Expanded(child: status),
        ],
      ),
    );
  }
}

// ── Step: Review ─────────────────────────────────────────────────────────────

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    super.key,
    required this.scan,
    required this.selectedClassCodes,
    required this.previewBytes,
    required this.error,
    required this.onToggle,
    required this.statusColor,
    required this.statusIcon,
    required this.statusLabel,
  });

  final TimetableScanResult scan;
  final Set<String> selectedClassCodes;
  final Uint8List? previewBytes;
  final String? error;
  final void Function(String code, bool selected) onToggle;
  final Color Function(TimetableScanEntry) statusColor;
  final IconData Function(TimetableScanEntry) statusIcon;
  final String Function(TimetableScanEntry) statusLabel;

  int get _availableCount => scan.entries.where((e) => e.canImport).length;

  int get _selectedCount => selectedClassCodes.length;

  @override
  Widget build(BuildContext context) {
    final entries = scan.entries;
    final availableEntries = entries.where((e) => e.canImport).toList();
    final otherEntries = entries.where((e) => !e.canImport).toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Left panel: image preview ──────────────────────────────────────
          if (previewBytes != null && !context.isMobile)
            Container(
              width: 240,
              decoration: BoxDecoration(
                color: Color(0xFF111827),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                ),
              ),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Ảnh đã quét',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(previewBytes!, fit: BoxFit.contain),
                    ),
                  ),
                  SizedBox(height: 12),
                  // Detected dates
                  if (scan.detectedDates.isNotEmpty) ...[
                    Text(
                      'Ngày nhận diện',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                    SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: scan.detectedDates
                          .map(
                            (d) => Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                d,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white70,
                                  fontFamily: 'JetBrains Mono',
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ] else
                    Text(
                      'Không đọc được ngày học.\nViệc ghép lớp vẫn dựa vào mã.',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),

          // ── Right panel: entries list ──────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Summary bar
                Container(
                  color: AppColors.surfaceContainerLow,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _SummaryChip(
                        label: 'Tìm thấy ${entries.length} mục',
                        icon: Icons.search,
                        color: AppColors.primary,
                      ),
                      _SummaryChip(
                        label: '$_availableCount sẵn sàng',
                        icon: Icons.add_circle_outline_rounded,
                        color: AppColors.statusPresent,
                      ),
                      _SummaryChip(
                        label: '$_selectedCount đã chọn',
                        icon: Icons.check_box_outlined,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),

                if (error != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _ErrorBanner(message: error!),
                  ),

                // Entry list
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    children: [
                      if (availableEntries.isNotEmpty) ...[
                        _SectionLabel(
                          label: 'Lớp có thể thêm (${availableEntries.length})',
                        ),
                        ...availableEntries.map(
                          (entry) => _EntryTile(
                            entry: entry,
                            isSelected: selectedClassCodes.contains(
                              entry.matchedClassCode,
                            ),
                            statusColor: statusColor(entry),
                            statusIcon: statusIcon(entry),
                            statusLabel: statusLabel(entry),
                            onToggle: (val) =>
                                onToggle(entry.matchedClassCode!, val ?? false),
                          ),
                        ),
                      ],
                      if (otherEntries.isNotEmpty) ...[
                        SizedBox(height: 8),
                        _SectionLabel(
                          label: 'Không thể thêm (${otherEntries.length})',
                        ),
                        ...otherEntries.map(
                          (entry) => _EntryTile(
                            entry: entry,
                            isSelected: false,
                            statusColor: statusColor(entry),
                            statusIcon: statusIcon(entry),
                            statusLabel: statusLabel(entry),
                            onToggle: null,
                          ),
                        ),
                      ],
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
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.textTertiary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.entry,
    required this.isSelected,
    required this.statusColor,
    required this.statusIcon,
    required this.statusLabel,
    required this.onToggle,
  });

  final TimetableScanEntry entry;
  final bool isSelected;
  final Color statusColor;
  final IconData statusIcon;
  final String statusLabel;
  final void Function(bool?)? onToggle;

  @override
  Widget build(BuildContext context) {
    final canSelect = entry.canImport && onToggle != null;

    return Material(
      color: isSelected
          ? AppColors.statusPresent.withValues(alpha: 0.04)
          : Colors.transparent,
      child: InkWell(
        onTap: canSelect ? () => onToggle?.call(!isSelected) : null,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Checkbox (only for selectable)
              SizedBox(
                width: 40,
                child: canSelect
                    ? Checkbox(
                        value: isSelected,
                        onChanged: onToggle,
                        activeColor: AppColors.statusPresent,
                        visualDensity: VisualDensity.compact,
                      )
                    : SizedBox(),
              ),

              // Status icon
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(statusIcon, size: 18, color: statusColor),
              ),
              SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${entry.classCode} – ${entry.subjectCode}',
                          style: AppTextStyles.headlineSm.copyWith(
                            fontSize: 13,
                          ),
                        ),
                        if (entry.room.isNotEmpty) ...[
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Phòng ${entry.room}',
                              style: TextStyle(
                                fontSize: 10,
                                fontFamily: 'JetBrains Mono',
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      entry.message,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Status badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step: Importing ──────────────────────────────────────────────────────────

class _ImportingStep extends StatelessWidget {
  const _ImportingStep({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(strokeWidth: 4),
          ),
          SizedBox(height: 24),
          Text(
            'Đang thêm giáo viên vào $count lớp…',
            style: AppTextStyles.headlineSm.copyWith(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Vui lòng không đóng cửa sổ này.',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared ───────────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
