import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/api_result.dart';
import '../../../../core/network/api_service.dart';
import '../../../../viewmodels/auth_viewmodel.dart';

class SavedSchedules extends StatefulWidget {
  const SavedSchedules({super.key});
  @override
  State<SavedSchedules> createState() => _SavedSchedulesState();
}

class _SavedSchedulesState extends State<SavedSchedules> {
  Future<ApiResult<List<dynamic>>>? _future;
  String? _token;
  void _reload() {
    _future = context.read<ApiService>().postAction<List<dynamic>>(
      'getClassSchedules',
      fromJsonT: (data) => data as List<dynamic>,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final token = context.watch<AuthViewModel>().session?.token;
    if (_future == null || token != _token) {
      _token = token;
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<ApiResult<List<dynamic>>>(
    future: _future,
    builder: (context, snapshot) {
      final result = snapshot.data;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Lịch học đã tạo',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tải lại lịch',
                    onPressed: () => setState(_reload),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              if (snapshot.connectionState != ConnectionState.done)
                const LinearProgressIndicator()
              else if (result is ApiFailure<List<dynamic>>)
                Text(result.error.message)
              else if (result is ApiSuccess<List<dynamic>>) ...[
                if (result.data.isEmpty) const Text('Chưa có lịch được tạo.'),
                ...result.data.map(
                  (s) => ListTile(
                    leading: const Icon(Icons.event),
                    title: Text('${s['classCode']} • ${s['scheduleDate']}'),
                    subtitle: Text(
                      'Ca ${s['slotCode']} (${s['startTime']}–${s['endTime']}) • Phòng ${s['room']}\n${s['note'] ?? ''}',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
