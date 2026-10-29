import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fapcheckin/cloudary/cloudary.dart';
import 'package:fapcheckin/views/teacher/profile/account_dialogs.dart';

class FakeAdapter implements HttpClientAdapter {
  late ResponseBody Function(RequestOptions) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('CloudinaryService', () {
    test('uploadAvatar gửi đúng folder cloudary và parse kết quả trả về', () async {
      final dio = Dio();
      final adapter = FakeAdapter();
      dio.httpClientAdapter = adapter;

      late FormData capturedData;
      late String capturedUrl;

      adapter.handler = (options) {
        capturedUrl = options.path;
        capturedData = options.data as FormData;
        final jsonResponse = {
          'url': 'http://res.cloudinary.com/fapcheckin/image/upload/v1/cloudary/sample.jpg',
          'secure_url': 'https://res.cloudinary.com/fapcheckin/image/upload/v1/cloudary/sample.jpg',
          'public_id': 'cloudary/sample',
          'format': 'jpg',
          'width': 250,
          'height': 250,
          'bytes': 10240,
        };
        return ResponseBody.fromString(
          jsonEncode(jsonResponse),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final service = CloudinaryService(client: dio);
      final result = await service.uploadAvatar(
        bytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'avatar.jpg',
        folder: 'cloudary',
      );

      expect(capturedUrl, contains('/image/upload'));
      expect(
        capturedData.fields.firstWhere((f) => f.key == 'folder').value,
        'cloudary',
      );
      expect(result.secureUrl, 'https://res.cloudinary.com/fapcheckin/image/upload/v1/cloudary/sample.jpg');
      expect(result.publicId, 'cloudary/sample');
      expect(result.format, 'jpg');
    });

    testWidgets('AccountAvatar render base64 data URI thành công', (tester) async {
      final base64Png = base64Encode(Uint8List.fromList([
        137, 80, 78, 71, 13, 10, 26, 10,
        0, 0, 0, 13, 73, 72, 68, 82,
        0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137,
        0, 0, 0, 10, 73, 68, 65, 84, 120, 156, 99, 0, 1, 0, 0, 5, 0, 1, 13, 10, 45, 180,
        0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130
      ]));
      final dataUri = 'data:image/png;base64,$base64Png';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccountAvatar(path: dataUri, initials: 'KH'),
          ),
        ),
      );

      expect(find.byType(CircleAvatar), findsOneWidget);
    });
  });
}
