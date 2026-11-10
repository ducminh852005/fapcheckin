// Giọng đọc Google Cloud TTS + dự phòng giọng của máy (không gọi mạng/âm thanh thật).
import 'dart:async';
import 'dart:typed_data';

import 'package:fapcheckin/core/services/cloud_tts_service.dart';
import 'package:fapcheckin/core/services/tts_service.dart';
import 'package:fapcheckin_core/repositories/ai_assistant_repository.dart';
import 'package:fapcheckin_core/result/api_result.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSpeakRepo extends Fake implements AiSpeakRepository {
  final List<String> requested = [];
  ApiResult<AiSpeech>? next;
  Completer<void>? hold;

  @override
  Future<ApiResult<AiSpeech>> synthesize(String text) async {
    requested.add(text);
    if (hold != null) await hold!.future;
    return next ?? ApiSuccess(AiSpeech(bytes: Uint8List.fromList([1, 2, 3]), mimeType: 'audio/mpeg', voice: 'vi-VN-Neural2-A'));
  }
}

class _FakeOutput implements AudioOutput {
  final List<Uint8List> played = [];
  int stops = 0;

  @override
  Future<void> play(Uint8List bytes, String mimeType) async => played.add(bytes);

  @override
  Future<void> stop() async => stops++;
}

class _FakeCloud implements CloudSpeaker {
  _FakeCloud(this.results);

  final List<bool> results;
  final List<String> spoken = [];
  int stops = 0;

  @override
  Future<bool> trySpeak(String text) async {
    spoken.add(text);
    return results.isEmpty ? true : results.removeAt(0);
  }

  @override
  Future<void> stop() async => stops++;
}

class _FakeDevice implements TtsService {
  final List<String> spoken = [];
  int stops = 0;
  String? error;

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async => stops++;

  @override
  String? takeError() {
    final e = error;
    error = null;
    return e;
  }
}

void main() {
  group('CloudTtsService', () {
    test('lấy âm thanh từ aiSpeak rồi phát', () async {
      final repo = _FakeSpeakRepo();
      final out = _FakeOutput();
      final tts = CloudTtsService(repository: repo, output: out);
      expect(await tts.trySpeak('  Xin chào  '), isTrue);
      expect(repo.requested, ['Xin chào']);
      expect(out.played.single, [1, 2, 3]);
    });

    test('câu đã đọc được lưu cache: lần sau không gọi mạng; cache có giới hạn', () async {
      final repo = _FakeSpeakRepo();
      final out = _FakeOutput();
      final tts = CloudTtsService(repository: repo, output: out, cacheSize: 2);
      await tts.trySpeak('A');
      await tts.trySpeak('A');
      expect(repo.requested, ['A']);
      expect(out.played, hasLength(2));
      await tts.trySpeak('B');
      await tts.trySpeak('C'); // đẩy 'A' ra khỏi cache (giữ 2 câu dùng gần nhất: B, C)
      await tts.trySpeak('A');
      expect(repo.requested, ['A', 'B', 'C', 'A']);
    });

    test('hàm lỗi (API chưa bật...) -> trả false, ghi lý do, không phát gì', () async {
      final repo = _FakeSpeakRepo()..next = ApiFailure(ApiError(code: 'TTS_UNAVAILABLE', message: 'API chưa bật'));
      final out = _FakeOutput();
      final tts = CloudTtsService(repository: repo, output: out);
      expect(await tts.trySpeak('Xin chào'), isFalse);
      expect(tts.lastFailure, contains('TTS_UNAVAILABLE'));
      expect(out.played, isEmpty);
    });

    test('phát âm thanh lỗi -> trả false (không ném)', () async {
      final out = _ThrowingOutput();
      final tts = CloudTtsService(repository: _FakeSpeakRepo(), output: out);
      expect(await tts.trySpeak('Xin chào'), isFalse);
    });

    test('bị ngắt (stop) trong lúc chờ mạng -> KHÔNG phát khi âm thanh về muộn', () async {
      final repo = _FakeSpeakRepo()..hold = Completer<void>();
      final out = _FakeOutput();
      final tts = CloudTtsService(repository: repo, output: out);
      final pending = tts.trySpeak('Câu dài');
      await Future<void>.delayed(Duration.zero);
      await tts.stop();
      repo.hold!.complete();
      expect(await pending, isTrue); // ngắt có chủ đích: không phải lỗi, không rơi sang giọng máy
      expect(out.played, isEmpty);
      expect(out.stops, greaterThan(0));
    });

    test('chữ rỗng thì không làm gì', () async {
      final repo = _FakeSpeakRepo();
      expect(await CloudTtsService(repository: repo, output: _FakeOutput()).trySpeak('  '), isTrue);
      expect(repo.requested, isEmpty);
    });
  });

  group('FallbackTtsService', () {
    test('giọng Google dùng được -> không đụng giọng máy', () async {
      final cloud = _FakeCloud([true]);
      final device = _FakeDevice();
      final tts = FallbackTtsService(cloud: cloud, device: device);
      await tts.speak('Xin chào');
      expect(cloud.spoken, ['Xin chào']);
      expect(device.spoken, isEmpty);
      expect(tts.lastUsedDevice, isFalse);
      expect(tts.takeError(), isNull);
    });

    test('giọng Google lỗi -> đọc ngay bằng giọng máy + báo lỗi một lần; tạm bỏ qua đám mây (cooldown)', () async {
      var clock = DateTime(2026, 11, 10, 10);
      final cloud = _FakeCloud([false]);
      final device = _FakeDevice();
      final tts = FallbackTtsService(cloud: cloud, device: device, cooldown: const Duration(seconds: 60), now: () => clock);

      await tts.speak('Câu một');
      expect(device.spoken, ['Câu một']);
      expect(tts.lastUsedDevice, isTrue);
      expect(tts.takeError(), contains('giọng của máy'));
      expect(tts.takeError(), isNull); // chỉ báo một lần

      await tts.speak('Câu hai'); // trong thời gian cooldown: không chờ lại lỗi
      expect(cloud.spoken, ['Câu một']);
      expect(device.spoken, ['Câu một', 'Câu hai']);

      clock = clock.add(const Duration(seconds: 61)); // hết cooldown: thử lại đám mây
      await tts.speak('Câu ba');
      expect(cloud.spoken, ['Câu một', 'Câu ba']);
      expect(tts.lastUsedDevice, isFalse);
    });

    test('lỗi của giọng máy cũng được gộp vào takeError', () async {
      final device = _FakeDevice()..error = 'Thiết bị chưa có giọng tiếng Việt';
      final tts = FallbackTtsService(cloud: _FakeCloud([false]), device: device);
      await tts.speak('a');
      final e = tts.takeError()!;
      expect(e, contains('giọng của máy'));
      expect(e, contains('chưa có giọng tiếng Việt'));
    });

    test('stop dừng cả hai nguồn', () async {
      final cloud = _FakeCloud([]);
      final device = _FakeDevice();
      await FallbackTtsService(cloud: cloud, device: device).stop();
      expect(cloud.stops, 1);
      expect(device.stops, 1);
    });

    test('chữ rỗng thì không đọc', () async {
      final cloud = _FakeCloud([]);
      final tts = FallbackTtsService(cloud: cloud, device: _FakeDevice());
      await tts.speak('   ');
      expect(cloud.spoken, isEmpty);
    });
  });
}

class _ThrowingOutput implements AudioOutput {
  @override
  Future<void> play(Uint8List bytes, String mimeType) async => throw StateError('audio device busy');

  @override
  Future<void> stop() async {}
}
