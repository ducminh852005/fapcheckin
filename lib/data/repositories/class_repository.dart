import 'package:dio/dio.dart';

import '../../core/services/api_service.dart';
import '../models/class_model.dart';

/// Lấy danh sách lớp mà 1 GV đang dạy — dùng cho ClassListScreen.
abstract class ClassRepository {
  Future<List<ClassModel>> fetchClassesForTeacher(String teacherId);
}

class ApiClassRepository implements ClassRepository {
  ApiClassRepository({Dio? dio}) : _dio = dio ?? ApiService.instance.client;

  final Dio _dio;

  @override
  Future<List<ClassModel>> fetchClassesForTeacher(String teacherId) async {
    try {
      // TODO(Backend): thống nhất endpoint, ví dụ GET /classes?teacherId=...
      final response = await _dio.get('/classes', queryParameters: {
        'teacherId': teacherId,
      });
      final list = response.data as List<dynamic>;
      return list.map((e) => ClassModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception('Tải danh sách lớp thất bại: ${e.message}');
    }
  }
}

/// Bản giả lập — dùng để phát triển/test ClassListScreen độc lập.
class MockClassRepository implements ClassRepository {
  @override
  Future<List<ClassModel>> fetchClassesForTeacher(String teacherId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      const ClassModel(
        classId: 'CLS001',
        className: 'Lập trình di động',
        subjectCode: 'PRM392',
        teacherId: 'GV001',
        room: 'A302',
        schedule: 'Thứ 3 · Tiết 4-6',
      ),
      const ClassModel(
        classId: 'CLS002',
        className: 'Phát triển ứng dụng Web',
        subjectCode: 'PRJ301',
        teacherId: 'GV001',
        room: 'B105',
        schedule: 'Thứ 5 · Tiết 1-3',
      ),
    ];
  }
}
