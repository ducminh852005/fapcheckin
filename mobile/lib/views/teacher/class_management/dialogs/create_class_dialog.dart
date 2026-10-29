import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fapcheckin_core/result/api_result.dart';
import 'package:fapcheckin_core/repositories/schedule_repository.dart';
import 'package:fapcheckin_core/responsive/responsive_dialog.dart';
import 'package:fapcheckin_core/constants/app_colors.dart';

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
    _repository = widget.repository ?? context.read<ScheduleRepository>();
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: ResponsiveDialogFrame(
        maxWidth: 680,
        maxHeight: 850,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tạo lịch học bổ sung',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            if (_loading) const LinearProgressIndicator(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_options != null) ...[
                      Text('Giảng viên: ${_options!['teacherName'] ?? ''}'),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _type,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Loại buổi học',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'makeup',
                            child: Text('Học bù'),
                          ),
                          DropdownMenuItem(
                            value: 'workshop',
                            child: Text('Workshop'),
                          ),
                          DropdownMenuItem(
                            value: 'review',
                            child: Text('Ôn tập'),
                          ),
                        ],
                        onChanged: _saving || _pending != null
                            ? null
                            : (v) => setState(() => _type = v!),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _classCode,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Lớp học'),
                        items: _rows('classes')
                            .map(
                              (c) => DropdownMenuItem(
                                value: c['classCode'] as String,
                                child: Text(
                                  '${c['classCode']} — ${c['subjectName']}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: _saving || _pending != null
                            ? null
                            : (v) => setState(() => _classCode = v),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _slotCode,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Ca học'),
                        items: _rows('slots')
                            .map(
                              (s) => DropdownMenuItem(
                                value: s['slotCode'] as String,
                                enabled: s['available'] == true,
                                child: Text(
                                  '${s['slotCode']} • ${s['startTime']} – ${s['endTime']}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: _saving || _pending != null
                            ? null
                            : (v) => setState(() => _slotCode = v),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _room,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Phòng học',
                        ),
                        items: (_options!['rooms'] as List)
                            .map(
                              (r) => DropdownMenuItem(
                                value: r.toString(),
                                child: Text(r.toString()),
                              ),
                            )
                            .toList(),
                        onChanged: _saving || _pending != null
                            ? null
                            : (v) => setState(() => _room = v),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _saving || _pending != null
                            ? null
                            : _pickDate,
                        icon: const Icon(Icons.calendar_month),
                        label: Text('Ngày học: $_day'),
                      ),
                      const SizedBox(height: 16),
                      const Text('Hình thức: Trực tiếp tại phòng học'),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _note,
                        enabled: !_saving && _pending == null,
                        maxLength: 2000,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Ghi chú'),
                      ),
                    ],
                    if (_error != null)
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    if (!_loading && _options == null)
                      TextButton(
                        onPressed: _load,
                        child: const Text('Thử lại'),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 12,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                  FilledButton(
                    onPressed: _saving || _options == null ? null : _save,
                    child: Text(
                      _saving
                          ? 'Đang lưu…'
                          : _pending == null
                          ? 'Xác nhận tạo lịch'
                          : 'Thử lại cùng yêu cầu',
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
