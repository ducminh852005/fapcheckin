import '../../core/network/api_result.dart';
import '../../core/network/api_service.dart';

class ScheduleRepository {
  ScheduleRepository(this.api);
  final ApiService api;

  Future<ApiResult<Map<String, dynamic>>> options() => api.postAction(
    'getScheduleOptions',
    fromJsonT: (data) => Map<String, dynamic>.from(data as Map),
  );

  Future<ApiResult<Map<String, dynamic>>> create(Map<String, dynamic> input) =>
      api.postAction(
        'createClassSchedule',
        payload: input,
        fromJsonT: (data) => Map<String, dynamic>.from(data as Map),
      );
}
