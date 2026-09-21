import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fapcheckin/core/network/api_service.dart';
import 'package:fapcheckin/core/network/api_result.dart';
import 'package:fapcheckin/data/repositories/schedule_repository.dart';

void main() {
  test(
    'schedule repository sends action and login token through shared API',
    () async {
      final client = Dio(BaseOptions(baseUrl: 'https://example.test/exec'));
      final requests = <Map<String, dynamic>>[];
      client.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            requests.add(
              jsonDecode(request.data as String) as Map<String, dynamic>,
            );
            handler.resolve(
              Response(
                requestOptions: request,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': {'scheduleId': 'saved'},
                  'error': null,
                },
              ),
            );
          },
        ),
      );
      final api = ApiService(client: client)..setSessionToken('server-session');
      final repository = ScheduleRepository(api);
      await repository.options();
      final result = await repository.create({
        'requestId': 'request-123',
        'classCode': 'C1',
      });
      expect(requests[0], {
        'action': 'getScheduleOptions',
        'sessionToken': 'server-session',
      });
      expect(requests[1]['action'], 'createClassSchedule');
      expect(requests[1]['classCode'], 'C1');
      expect(requests[1]['sessionToken'], 'server-session');
      expect(
        (result as ApiSuccess<Map<String, dynamic>>).data['scheduleId'],
        'saved',
      );
    },
  );
  test(
    'old deployment returns actionable error instead of hiding missing API',
    () async {
      final client = Dio(BaseOptions(baseUrl: 'https://example.test/exec'));
      client.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            handler.resolve(
              Response(
                requestOptions: request,
                statusCode: 200,
                data: jsonEncode({
                  'success': false,
                  'data': null,
                  'error': {
                    'code': 'UNKNOWN_ACTION',
                    'message': 'Hành động không hợp lệ',
                  },
                }),
              ),
            );
          },
        ),
      );
      final result = await ScheduleRepository(ApiService(client: client))
          .options();
      final error = (result as ApiFailure<Map<String, dynamic>>).error;
      expect(error.code, 'BACKEND_UPDATE_REQUIRED');
      expect(error.message, contains('getScheduleOptions'));
      expect(error.message, contains('New version'));
    },
  );
}
