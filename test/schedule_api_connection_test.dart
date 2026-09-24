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

  test('native API follows the Apps Script POST redirect with GET', () async {
    final client = Dio(BaseOptions(baseUrl: 'https://example.test/exec'));
    final methods = <String>[];
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          methods.add(request.method);
          if (request.method == 'POST') {
            handler.resolve(
              Response(
                requestOptions: request,
                statusCode: 302,
                data: '',
                headers: Headers.fromMap({
                  'location': ['https://result.example.test/response'],
                }),
              ),
            );
            return;
          }
          handler.resolve(
            Response(
              requestOptions: request,
              statusCode: 200,
              data: jsonEncode({
                'success': true,
                'data': {'value': 'redirected'},
                'error': null,
              }),
            ),
          );
        },
      ),
    );

    final result = await ApiService(client: client)
        .postAction<Map<String, dynamic>>(
          'testRedirect',
          fromJsonT: (data) => data as Map<String, dynamic>,
        );

    expect(methods, ['POST', 'GET']);
    expect(
      (result as ApiSuccess<Map<String, dynamic>>).data['value'],
      'redirected',
    );
  });

  test('empty Apps Script response returns a readable API error', () async {
    final client = Dio(BaseOptions(baseUrl: 'https://example.test/exec'));
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) => handler.resolve(
          Response(requestOptions: request, statusCode: 200, data: ''),
        ),
      ),
    );

    final result = await ApiService(client: client).postAction<Object>('test');
    final error = (result as ApiFailure<Object>).error;
    expect(error.code, 'EMPTY_RESPONSE');
    expect(error.message, contains('không trả về dữ liệu'));
  });
}
