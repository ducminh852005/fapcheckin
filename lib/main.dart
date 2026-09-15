import 'package:flutter/material.dart';
import 'data/repositories/class_repository.dart';
import 'views/teacher/class_list_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ClassListScreen(
        teacherId: 'GV001', // sau này lấy từ kết quả đăng nhập thật
        classRepository: MockClassRepository(),
      ),
    );
  }
}
