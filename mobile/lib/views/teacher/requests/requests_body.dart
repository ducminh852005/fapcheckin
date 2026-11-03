import '../dashboard/components/notification_modal.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:fapcheckin_core/repositories/request_repository.dart';

import 'package:fapcheckin_core/result/api_result.dart';



import '../../../viewmodels/auth_viewmodel.dart';

import 'request_modal_sheet.dart';



const _statuses = {

  'pending': 'Chờ duyệt',

  'approved': 'Đã duyệt',

  'rejected': 'Đã từ chối',

};



class RequestsBody extends StatefulWidget {

  const RequestsBody({super.key, this.repository});

  final RequestRepository? repository;

  @override

  State<RequestsBody> createState() => _RequestsBodyState();

}



class _RequestsBodyState extends State<RequestsBody> {

  late RequestRepository _repo;

  late Stream<List<Map<String, dynamic>>> _requests;

  String? _uid;

  @override

  void didChangeDependencies() {

    super.didChangeDependencies();

    final session = context.watch<AuthViewModel>().session;

    if (session == null) return;

    if (_uid != session.token) {

      _uid = session.token;

      _repo = widget.repository ?? RequestRepository(

        uid: session.token,

        memberCode: session.user.memberCode,

      );

      _requests = _repo.watchMine();

    }

  }



  @override

  Widget build(BuildContext context) => Scaffold(

    appBar: AppBar(

      title: const Text('Yêu cầu điểm danh / nghỉ phép'),

      actions: [
        IconButton(tooltip: 'Thông báo', onPressed: () => showNotificationModal(context), icon: const Icon(Icons.notifications_outlined)),

        IconButton(

          tooltip: 'Đăng xuất',

          onPressed: () => context.read<AuthViewModel>().signOut(),

          icon: const Icon(Icons.logout),

        ),

      ],

    ),

    floatingActionButton: FloatingActionButton.extended(

      onPressed: () => showRequestBottomSheet(context, repository: _repo),

      icon: const Icon(Icons.add),

      label: const Text('Gửi yêu cầu'),

    ),

    body: StreamBuilder<List<Map<String, dynamic>>>(

      stream: _requests,

      builder: (context, snapshot) {

        if (snapshot.hasError) {

          return Center(

            child: Column(

              mainAxisSize: MainAxisSize.min,

              children: [

                Text('Không tải được yêu cầu: ${snapshot.error}'),

                TextButton(

                  onPressed: () =>

                      setState(() => _requests = _repo.watchMine()),

                  child: const Text('Thử lại'),

                ),

              ],

            ),

          );

        }

        if (!snapshot.hasData) {

          return const Center(child: CircularProgressIndicator());

        }

        if (snapshot.data!.isEmpty) {

          return const Center(child: Text('Bạn chưa gửi yêu cầu nào.'));

        }

        return ListView(

          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),

          children: [

            for (final row in snapshot.data!)

              Card(

                child: ListTile(

                  title: Text(

                    '${row['type'] == 'leave' ? 'Nghỉ phép' : 'Sửa điểm danh'} · ${row['classCode'] ?? ''}',

                  ),

                  subtitle: Text(

                    '${row['reason']}\nMã phiên: ${row['sessionId'] ?? ''}\n${_statuses[row['status']] ?? row['status']}${row['adminNote'] == null || row['adminNote'] == '' ? '' : '\nPhản hồi: ${row['adminNote']}'}',

                  ),

                  isThreeLine: true,

                ),

              ),

          ],

        );

      },

    ),

  );

}



class _RequestForm extends StatefulWidget {

  const _RequestForm({required this.repo});

  final RequestRepository repo;

  @override

  State<_RequestForm> createState() => _RequestFormState();

}



class _RequestFormState extends State<_RequestForm> {

  final _reason = TextEditingController(),

      _classCode = TextEditingController(),

      _sessionId = TextEditingController();

  final _id = DateTime.now().microsecondsSinceEpoch.toString();

  String _type = 'attendance_fix';

  String? _error;

  bool _saving = false, _submitted = false;

  @override

  void dispose() {

    _reason.dispose();

    _classCode.dispose();

    _sessionId.dispose();

    super.dispose();

  }



  Future<void> _send() async {

    setState(() {

      _saving = true;

      _error = null;

      _submitted = true;

    });

    final result = await widget.repo.submit(

      id: _id,

      type: _type,

      reason: _reason.text,

      classCode: _classCode.text,

      sessionId: _sessionId.text,

    );

    if (!mounted) return;

    if (result is ApiSuccess<void>) {

      Navigator.pop(context);

      return;

    }

    final error = (result as ApiFailure<void>).error;

    setState(() {

      _saving = false;

      _error = error.message;

      if (error.code == 'VALIDATION_ERROR') _submitted = false;

    });

  }



  @override

  Widget build(BuildContext context) => AlertDialog(

    title: const Text('Gửi yêu cầu'),

    content: SingleChildScrollView(

      child: Column(

        mainAxisSize: MainAxisSize.min,

        children: [

          DropdownButtonFormField<String>(

            initialValue: _type,

            items: const [

              DropdownMenuItem(

                value: 'attendance_fix',

                child: Text('Sửa điểm danh'),

              ),

              DropdownMenuItem(value: 'leave', child: Text('Nghỉ phép')),

            ],

            onChanged: _submitted ? null : (v) => setState(() => _type = v!),

          ),

          TextField(

            controller: _classCode,

            enabled: !_submitted,

            decoration: const InputDecoration(labelText: 'Mã lớp *'),

          ),

          TextField(

            controller: _sessionId,

            enabled: !_submitted,

            decoration: InputDecoration(

              labelText: _type == 'attendance_fix'

                  ? 'Mã phiên *'

                  : 'Mã phiên (nếu có)',

            ),

          ),

          TextField(

            controller: _reason,

            enabled: !_submitted,

            maxLength: 2000,

            maxLines: 4,

            decoration: const InputDecoration(labelText: 'Lý do *'),

          ),

          if (_error != null) Text(_error!),

          if (_saving) const LinearProgressIndicator(),

        ],

      ),

    ),

    actions: [

      TextButton(

        onPressed: _saving ? null : () => Navigator.pop(context),

        child: const Text('Đóng'),

      ),

      FilledButton(

        onPressed: _saving ? null : _send,

        child: Text(_submitted ? 'Thử lại' : 'Gửi'),

      ),

    ],

  );

}

