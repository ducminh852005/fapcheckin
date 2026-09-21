import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/api_result.dart';
import '../../../../core/network/api_service.dart';
import '../../../../data/repositories/schedule_repository.dart';

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
      setState(() => _error = 'Vui lòng chọn lớp, ca học và phòng học.');
      return;
    }
    // Keep the exact request after a timeout; retry cannot create a duplicate.
    _pending ??= {
      'requestId':
          '${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}',
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
        // Only a definitive validation rejection permits editing a new request.
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

  Widget _dropdown(
    String label,
    String? value,
    List<DropdownMenuItem<String>> items,
    ValueChanged<String?> changed,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items,
      onChanged: changed,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final classes = _rows('classes');
    final selected = classes
        .where((c) => c['classCode'] == _classCode)
        .firstOrNull;
    return PopScope(
      canPop: !_saving,
      child: Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700, maxHeight: 850),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Tạo lịch học mới & Đăng ký dạy bù',
                        style: TextStyle(
                          fontSize: 22,
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
                const SizedBox(height: 16),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                if (!_loading && _options == null) ...[
                  Text(_error ?? 'Không tải được dữ liệu.'),
                  TextButton(onPressed: _load, child: const Text('Thử lại')),
                ],
                if (!_loading && _options != null) ...[
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AbsorbPointer(
                            absorbing: _saving || _pending != null,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _dropdown('Loại buổi học', _type, const [
                                  DropdownMenuItem(
                                    value: 'makeup',
                                    child: Text('Học bù kế hoạch'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'workshop',
                                    child: Text('Phụ đạo / Workshop'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'review',
                                    child: Text('Review đồ án'),
                                  ),
                                ], (v) => setState(() => _type = v!)),
                                if (classes.isEmpty)
                                  const Text(
                                    'Tài khoản chưa được phân công lớp nào trong Class_Section.',
                                  ),
                                _dropdown(
                                  'Lớp học',
                                  _classCode,
                                  classes
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
                                  (v) => setState(() {
                                    _classCode = v;
                                  }),
                                ),
                                if (selected != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Text(
                                      'Sĩ số theo Enrollment: ${selected['studentCount']} sinh viên',
                                    ),
                                  ),
                                OutlinedButton.icon(
                                  onPressed: _pickDate,
                                  icon: const Icon(Icons.calendar_month),
                                  label: Text('Ngày học: $_day (giờ Việt Nam)'),
                                ),
                                const SizedBox(height: 18),
                                _dropdown(
                                  'Ca học',
                                  _slotCode,
                                  _rows('slots')
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s['slotCode'] as String,
                                          enabled: s['available'] == true,
                                          child: Text(
                                            '${s['slotCode']} • ${s['startTime']} – ${s['endTime']}${s['available'] == true ? '' : ' (giờ chưa hợp lệ)'}',
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  (v) => setState(() => _slotCode = v),
                                ),
                                _dropdown(
                                  'Phòng học',
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
                                ),
                                const Text(
                                  'Phòng lấy từ Class_Section. Hệ thống kiểm tra trùng giảng viên, lớp và phòng khi xác nhận.',
                                ),
                                const SizedBox(height: 16),
                                const InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Hình thức học',
                                    border: OutlineInputBorder(),
                                  ),
                                  child: Text(
                                    'Trực tiếp tại phòng học (On-Campus)',
                                  ),
                                ),
                                const SizedBox(height: 18),
                                TextField(
                                  controller: _note,
                                  maxLength: 2000,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    labelText: 'Nội dung / Ghi chú',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SwitchListTile(
                            value: false,
                            onChanged: null,
                            title: Text('Tự động mở Dynamic QR'),
                            subtitle: Text(
                              'Chưa hỗ trợ. Mở phiên điểm danh thủ công khi bắt đầu buổi học.',
                            ),
                          ),
                          const SwitchListTile(
                            value: false,
                            onChanged: null,
                            title: Text('Gửi thông báo / email sinh viên'),
                            subtitle: Text('Chưa tích hợp dịch vụ thông báo.'),
                          ),
                          const SwitchListTile(
                            value: false,
                            onChanged: null,
                            title: Text('Đồng bộ FAP Edu'),
                            subtitle: Text(
                              'Chưa có kết nối với cổng FAP. Lịch được lưu trong ứng dụng.',
                            ),
                          ),
                          Text('Giảng viên: ${_options!['teacherName']}'),
                          if (_rows('schedules').isNotEmpty) ...[
                            const SizedBox(height: 18),
                            const Text(
                              'Lịch đã tạo',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ..._rows('schedules').map(
                              (s) => Text(
                                '${s['scheduleDate']} • ${s['startTime']}–${s['endTime']} • ${s['classCode']} • P.${s['room']}',
                              ),
                            ),
                          ],
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          if (_pending != null && !_saving)
                            const Text(
                              'Chưa xác nhận được kết quả. Bấm thử lại để kiểm tra/lưu cùng yêu cầu; nội dung tạm khóa để tránh tạo trùng.',
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _saving || classes.isEmpty ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(
                        _saving
                            ? 'Đang lưu…'
                            : _pending != null
                            ? 'Thử lại cùng yêu cầu'
                            : 'Xác nhận tạo lịch',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
