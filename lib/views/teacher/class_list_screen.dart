import 'package:flutter/material.dart';

import '../../data/models/class_model.dart';
import '../../data/repositories/class_repository.dart';
import 'start_session_screen.dart';

/// Màn hình đầu tiên GV thấy sau khi đăng nhập: danh sách các lớp GV dạy.
/// Chọn 1 lớp để mở phiên điểm danh cho lớp đó.
class ClassListScreen extends StatefulWidget {
  const ClassListScreen({
    super.key,
    required this.teacherId,
    required this.classRepository,
  });

  final String teacherId;
  final ClassRepository classRepository;

  @override
  State<ClassListScreen> createState() => _ClassListScreenState();
}

class _ClassListScreenState extends State<ClassListScreen> {
  late Future<List<ClassModel>> _classesFuture;

  @override
  void initState() {
    super.initState();
    // Gọi đúng 1 lần khi màn hình khởi tạo. FutureBuilder bên dưới sẽ tự vẽ
    // lại UI khi Future này hoàn tất — không cần gọi setState() thủ công.
    _classesFuture = widget.classRepository.fetchClassesForTeacher(widget.teacherId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lớp của tôi')),
      body: FutureBuilder<List<ClassModel>>(
        future: _classesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải danh sách lớp: ${snapshot.error}'));
          }

          final classes = snapshot.data ?? [];
          if (classes.isEmpty) {
            return const Center(child: Text('Chưa có lớp nào được phân công.'));
          }

          return ListView.separated(
            itemCount: classes.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final classModel = classes[index];
              return ListTile(
                title: Text(classModel.className),
                subtitle: Text(
                  '${classModel.subjectCode} · ${classModel.schedule} · Phòng ${classModel.room}',
                ),
                trailing: const Icon(Icons.qr_code),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StartSessionScreen(classModel: classModel),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
