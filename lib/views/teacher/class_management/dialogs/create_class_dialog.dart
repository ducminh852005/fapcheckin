import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/api_result.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/json_values.dart';
import '../../../../data/repositories/schedule_repository.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/responsive/responsive_dialog.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_spacing.dart';

class CreateClassDialog extends StatefulWidget {
  const CreateClassDialog({super.key, this.repository});
  final ScheduleRepository? repository;

  @override
  State<CreateClassDialog> createState() => _CreateClassDialogState();
}

class _CreateClassDialogState extends State<CreateClassDialog> {
  late ScheduleRepository _repository;
  final _note = TextEditingController();
  Map<String, dynamic>? _options;
  String? _error, _classCode, _slotCode, _room, _day;
  String _type = 'makeup';
  bool _loading = true, _saving = false;
  Map<String, dynamic>? _pending;

  List<Map<String, dynamic>> _rows(String key) =>
      ((_options?[key] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ?? ScheduleRepository(context.read<ApiService>());
    _load();
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
        _day = _options!['today'] as String;
      } else if (result is ApiFailure<Map<String, dynamic>>) {
        _error = result.error.message;
      }
    });
  }

  Future<void> _pickDate() async {
    final first = DateTime.parse(_options!['today'] as String);
    final value = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_day!),
      firstDate: first,
      lastDate: DateTime(first.year + 5, 12, 31),
    );
    if (value != null && mounted) {
      setState(
        () => _day =
            '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}',
      );
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_classCode == null || _slotCode == null || _room == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng chọn lớp, ca học và phòng học.'),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() => _error = 'Vui lòng chọn lớp, ca học và phòng học.');
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
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Widget _buildLabel(String text, {bool required = true, Widget? suffix}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(
            text: TextSpan(
              text: text,
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              children: [
                if (required)
                  TextSpan(
                    text: ' *',
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.error,
                    ),
                  ),
              ],
            ),
          ),
          ?suffix,
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String? value,
    List<DropdownMenuItem<String>> items,
    ValueChanged<String?> changed, {
    String hint = '',
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
          items: items,
          onChanged: changed,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, {String? rightText}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          SizedBox(width: 8),
          Text(
            title,
            style: AppTextStyles.headlineSm.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          Spacer(),
          if (rightText != null)
            Text(
              rightText,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
        ],
      ),
    );
  }

  Map<String, String> _getSlotTimeRange(
    String slotCode,
    String rawStart,
    String rawEnd,
  ) {
    final startClean = formatTimeLabel(rawStart);
    final endClean = formatTimeLabel(rawEnd);

    if (startClean.isNotEmpty &&
        endClean.isNotEmpty &&
        startClean != 'Chưa rõ' &&
        endClean != 'Chưa rõ') {
      return {'start': startClean, 'end': endClean};
    }

    final cleanSlot = slotCode.trim().toUpperCase();
    switch (cleanSlot) {
      case 'A1':
      case '1':
      case 'SLOT 1':
        return {'start': '07:30', 'end': '09:50'};
      case 'A2':
      case '2':
      case 'SLOT 2':
        return {'start': '10:00', 'end': '12:20'};
      case 'P3':
      case '3':
      case 'SLOT 3':
        return {'start': '12:50', 'end': '15:10'};
      case 'P4':
      case '4':
      case 'SLOT 4':
        return {'start': '15:20', 'end': '17:40'};
      case 'E5':
      case '5':
      case 'SLOT 5':
        return {'start': '17:50', 'end': '20:10'};
      case 'E6':
      case '6':
      case 'SLOT 6':
        return {'start': '20:20', 'end': '22:40'};
      default:
        return {
          'start': startClean.isNotEmpty ? startClean : '07:30',
          'end': endClean.isNotEmpty ? endClean : '09:50',
        };
    }
  }

  Widget _buildSlotCard(Map<String, dynamic> slot) {
    final slotCode = slot['slotCode'] as String;
    final isSelected = _slotCode == slotCode;
    final isEnabled = slot['available'] == true || true;
    final timeMap = _getSlotTimeRange(
      slotCode,
      slot['startTime'] as String? ?? '',
      slot['endTime'] as String? ?? '',
    );
    final cleanSlotTitle = slotCode.replaceAll('Slot', '').trim();

    return Expanded(
      child: InkWell(
        onTap: isEnabled ? () => setState(() => _slotCode = slotCode) : null,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          margin: EdgeInsets.only(right: 8),
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryLight.withValues(alpha: 0.3)
                : AppColors.surface,
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryContainer
                  : AppColors.surfaceContainerHigh,
              width: isSelected ? 1.5 : 1.0,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Ca $cleanSlotTitle',
                    style: AppTextStyles.labelMd.copyWith(
                      color: isSelected
                          ? AppColors.primaryContainer
                          : (isEnabled
                                ? AppColors.textPrimary
                                : AppColors.textTertiary),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                    ),
                  ),
                  if (isSelected) ...[
                    SizedBox(width: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 4),
              Text(
                '${timeMap['start']} - ${timeMap['end']}',
                style: AppTextStyles.caption.copyWith(
                  color: isSelected
                      ? AppColors.primaryContainer
                      : (isEnabled
                            ? AppColors.textSecondary
                            : AppColors.textTertiary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final classes = _rows('classes');
    final selectedClass = classes
        .where((c) => c['classCode'] == _classCode)
        .firstOrNull;

    return PopScope(
      canPop: !_saving,
      child: ResponsiveDialogFrame(
        backgroundColor: AppColors.surface,
        maxWidth: 800,
        maxHeight: 900,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.isMobile ? 16 : 24,
                context.isMobile ? 16 : 24,
                context.isMobile ? 8 : 24,
                16,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.edit_calendar,
                      color: AppColors.primaryContainer,
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Tạo lịch học mới & Đăng ký dạy bù',
                              style: AppTextStyles.headlineSm.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 8,
                                    color: AppColors.primaryContainer,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Học kỳ Fall 2026',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.primaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Khởi tạo buổi học phát sinh, bù lịch nghỉ lễ hoặc tăng cường ôn tập môn học',
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: AppColors.textTertiary),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),

            if (_loading)
              Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_options == null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error ?? 'Không tải được dữ liệu.'),
                      SizedBox(height: 16),
                      FilledButton(onPressed: _load, child: Text('Thử lại')),
                    ],
                  ),
                ),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(context.isMobile ? 12 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section 1: Info
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.surfaceContainerHigh,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                              Icons.tune,
                              'THÔNG TIN MÔN HỌC & THỜI ĐIỂM HỌC',
                              rightText: '* Bắt buộc nhập đầy đủ',
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('Loại buổi học'),
                                      _buildDropdown(_type, [
                                        DropdownMenuItem(
                                          value: 'makeup',
                                          child: Text(
                                            'Học bù kế hoạch (Make-up Class)',
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'workshop',
                                          child: Text(
                                            'Lịch tăng cường (Workshop)',
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'review',
                                          child: Text('Review đồ án'),
                                        ),
                                      ], (v) => setState(() => _type = v!)),
                                      SizedBox(height: 20),
                                      _buildLabel(
                                        'Ngày học bù',
                                        suffix: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryLight,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.public,
                                                size: 12,
                                                color:
                                                    AppColors.primaryContainer,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Giờ Việt Nam (GMT+7)',
                                                style: AppTextStyles.caption
                                                    .copyWith(
                                                      color: AppColors
                                                          .primaryContainer,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 10,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: _pickDate,
                                        borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusMd,
                                        ),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: AppColors.border,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              AppSpacing.radiusMd,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_month,
                                                color: AppColors.textSecondary,
                                                size: 20,
                                              ),
                                              SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  '${_day!.split('-')[2]}/${_day!.split('-')[1]}/${_day!.split('-')[0]}',
                                                  style: AppTextStyles.bodyMd
                                                      .copyWith(
                                                        color: AppColors
                                                            .textPrimary,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(
                                          top: 8,
                                          left: 4,
                                        ),
                                        child: Text(
                                          'Đã chọn ngày: $_day',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.textTertiary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel(
                                        'Tiết học & Mã môn phụ trách',
                                      ),
                                      _buildDropdown(
                                        _classCode,
                                        classes
                                            .map(
                                              (c) => DropdownMenuItem(
                                                value: c['classCode'] as String,
                                                child: Text(
                                                  '${c['subjectName']} (${c['classCode']}) • ${c['studentCount']} sinh viên',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        (v) => setState(() => _classCode = v),
                                        hint: 'Chọn tiết học',
                                      ),
                                      SizedBox(height: 20),
                                      _buildLabel(
                                        'Phòng học (Classroom)',
                                        suffix: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.statusPresentBg,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            'Trống lịch',
                                            style: AppTextStyles.caption
                                                .copyWith(
                                                  color:
                                                      AppColors.statusPresent,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                          ),
                                        ),
                                      ),
                                      _buildDropdown(
                                        _room,
                                        (_options!['rooms'] as List)
                                            .map(
                                              (r) => DropdownMenuItem(
                                                value: r as String,
                                                child: Text(r),
                                              ),
                                            )
                                            .toList(),
                                        (v) => setState(() => _room = v),
                                        hint: 'Chọn phòng học',
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(
                                          top: 8,
                                          left: 4,
                                        ),
                                        child: Text(
                                          'Phòng được lấy tự động từ hệ thống tài nguyên cơ sở vật chất Campus.',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.textTertiary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 24),
                            _buildLabel('Ca học / Slot yêu cầu'),
                            Row(
                              children: _rows('slots')
                                  .map((slot) => _buildSlotCard(slot))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Section 2: Teaching Format
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.surfaceContainerHigh,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                              Icons.computer,
                              'HÌNH THỨC & NỘI DUNG GIẢNG DẠY',
                            ),
                            _buildLabel('Hình thức đào tạo', required: false),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      border: Border.all(
                                        color: AppColors.primaryContainer,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusMd,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.domain,
                                          color: AppColors.primaryContainer,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Trực tiếp tại phòng học (On-Campus)',
                                          style: AppTextStyles.labelMd.copyWith(
                                            color: AppColors.primaryContainer,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      border: Border.all(
                                        color: AppColors.surfaceContainerHigh,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusMd,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.devices,
                                          color: AppColors.textTertiary,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Trực tuyến từ xa (Hybrid / MS Teams)',
                                          style: AppTextStyles.labelMd.copyWith(
                                            color: AppColors.textTertiary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 24),
                            _buildLabel(
                              'Nội dung bài học & Ghi chú cho sinh viên',
                              required: false,
                              suffix: Text(
                                '0 / 2000 ký tự',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ),
                            TextField(
                              controller: _note,
                              maxLength: 2000,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Nhập tóm tắt nội dung học bù, lý do tổ chức dạy bù (nghỉ lễ, công tác...), dặn dò chuẩn bị laptop, bài tập trước buổi học...',
                                hintStyle: AppTextStyles.bodyMd.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd,
                                  ),
                                  borderSide: BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd,
                                  ),
                                  borderSide: BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                                counterText: '',
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_error != null)
                        Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Text(
                            _error!,
                            style: AppTextStyles.bodyMd.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // Footer
            Divider(height: 1),
            Padding(
              padding: EdgeInsets.all(context.isMobile ? 12 : 24),
              child: Row(
                children: [
                  if (!context.isMobile)
                    Icon(
                      Icons.info_outline,
                      color: AppColors.textTertiary,
                      size: 18,
                    ),
                  if (!context.isMobile) SizedBox(width: 8),
                  Expanded(
                    child: context.isMobile
                        ? SizedBox.shrink()
                        : Text(
                            'Yêu cầu sẽ được tự động đồng bộ sau khi bấm xác nhận',
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                  ),
                  SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(color: AppColors.border),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                      ),
                    ),
                    child: Text('Hủy bỏ'),
                  ),

                  SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _saving || _options == null || classes.isEmpty
                        ? null
                        : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: AppColors.onPrimary,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                      ),
                    ),
                    icon: _saving
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(Icons.check),
                    label: Text(
                      _saving ? 'Đang xử lý...' : 'Xác nhận',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
}
