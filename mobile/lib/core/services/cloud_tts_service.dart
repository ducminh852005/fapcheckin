import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:fapcheckin_core/repositories/ai_assistant_repository.dart';
import 'package:fapcheckin_core/result/api_result.dart';

import 'tts_service.dart';

/// Phát âm thanh đã tạo sẵn. Tách interface để test thay bằng bản giả.
abstract class AudioOutput {
  /// Phát [bytes] và hoàn thành khi phát xong (hoặc bị [stop]).
  ///
  /// QUY ƯỚC QUAN TRỌNG: chỉ được ném lỗi nếu CHƯA phát được. Một khi âm thanh đã bắt đầu phát thì mọi lỗi sau đó
  /// phải bị nuốt — nếu không lớp dự phòng sẽ tưởng giọng Google thất bại và đọc thêm giọng của máy, hai giọng đè lên nhau.
  Future<void> play(Uint8List bytes, String mimeType);

  Future<void> stop();
}

/// Cài đặt thật bằng `audioplayers` (web, Android, iOS, Windows…).
///
/// Mỗi câu dùng MỘT BỘ PHÁT MỚI rồi giải phóng: tái sử dụng cùng một `AudioPlayer` cho nhiều câu liên tiếp hay làm lần phát
/// thứ hai trở đi lỗi trên web (trạng thái "completed" + nguồn Blob cũ), khiến giọng Google thất bại và app rơi sang giọng máy.
class AudioplayersOutput implements AudioOutput {
  AudioPlayer? _current;
  Completer<void>? _finished;

  @override
  Future<void> play(Uint8List bytes, String mimeType) async {
    await stop(); // câu trước (nếu còn) kết thúc hẳn trước khi phát câu mới
    final player = AudioPlayer();
    final finished = Completer<void>();
    _current = player;
    _finished = finished;
    final sub = player.onPlayerComplete.listen((_) {
      if (!finished.isCompleted) finished.complete();
    });
    try {
      await player.setReleaseMode(ReleaseMode.stop);
      await player.play(BytesSource(bytes, mimeType: mimeType)); // lỗi ở đây = chưa phát được -> ném ra
    } catch (_) {
      await sub.cancel();
      if (!finished.isCompleted) finished.complete();
      if (identical(_current, player)) _current = null;
      try {
        await player.dispose();
      } catch (_) {}
      rethrow;
    }
    // Đã bắt đầu phát: từ đây KHÔNG ném lỗi nữa. Chờ phát xong (hoặc bị stop); có trần để không treo hội thoại.
    try {
      await finished.future.timeout(const Duration(seconds: 90));
    } catch (_) {
      // hết giờ chờ: coi như xong
    } finally {
      await sub.cancel();
      if (identical(_current, player)) _current = null;
      try {
        await player.dispose();
      } catch (_) {}
    }
  }

  @override
  Future<void> stop() async {
    final f = _finished;
    if (f != null && !f.isCompleted) f.complete();
    final p = _current;
    if (p != null) {
      try {
        await p.stop();
      } catch (_) {}
    }
  }
}

/// Nguồn đọc "chất lượng cao" có thể thất bại (mạng/API) để lớp dự phòng chuyển sang giọng của máy.
abstract class CloudSpeaker {
  /// `true` nếu đã đọc xong (hoặc bị ngắt có chủ đích); `false` nếu giọng đám mây KHÔNG dùng được.
  Future<bool> trySpeak(String text);

  Future<void> stop();

  /// Lý do thất bại gần nhất (null nếu chưa lỗi) — đưa vào thông báo để biết vì sao phải dùng giọng của máy.
  String? get lastFailure;
}

/// Giọng tiếng Việt của Google Cloud Text-to-Speech (qua Cloud Function `aiSpeak`).
class CloudTtsService implements CloudSpeaker {
  CloudTtsService({
    required this.repository,
    AudioOutput? output,
    this.cacheSize = 24,
  }) : _output = output ?? AudioplayersOutput();

  final AiSpeakRepository repository;
  final AudioOutput _output;
  final int cacheSize;

  final LinkedHashMap<String, AiSpeech> _cache = LinkedHashMap();
  int _epoch = 0; // tăng khi stop(): yêu cầu đang chờ mạng sẽ không phát nữa

  /// Lý do thất bại gần nhất (để chẩn đoán/hiển thị).
  @override
  String? lastFailure;

  @override
  Future<bool> trySpeak(String text) async {
    final value = text.trim();
    if (value.isEmpty) return true;
    final epoch = ++_epoch;
    try {
      var speech = _cache.remove(value);
      if (speech == null) {
        final result = await repository.synthesize(value);
        switch (result) {
          case ApiSuccess<AiSpeech>(:final data):
            speech = data;
          case ApiFailure<AiSpeech>(:final error):
            lastFailure = '${error.code}: ${error.message}';
            return false;
          default:
            lastFailure = 'Không nhận được âm thanh.';
            return false;
        }
      }
      _cache[value] = speech; // giữ câu mới dùng gần đây
      while (_cache.length > cacheSize) {
        _cache.remove(_cache.keys.first);
      }
      if (epoch != _epoch) return true; // bị ngắt trong lúc chờ mạng: coi như đã xong, không phát
      await _output.play(speech.bytes, speech.mimeType);
      return true;
    } catch (e) {
      lastFailure = e.toString();
      return false;
    }
  }

  @override
  Future<void> stop() async {
    _epoch++;
    try {
      await _output.stop();
    } catch (_) {}
  }
}

/// Đọc bằng giọng Google đám mây; lỗi/chậm thì chuyển sang giọng của máy và tạm bỏ qua đám mây một lúc
/// ([cooldown]) để các câu sau không phải chờ lại lỗi.
class FallbackTtsService implements TtsService {
  FallbackTtsService({
    required this.cloud,
    required this.device,
    this.cooldown = const Duration(seconds: 20),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final CloudSpeaker cloud;
  final TtsService device;
  final Duration cooldown;
  final DateTime Function() _now;

  DateTime? _cloudDownUntil;
  String? _note;

  /// Đã dùng giọng của máy cho câu gần nhất (để chẩn đoán/kiểm thử).
  bool lastUsedDevice = false;

  int _speakId = 0;

  @override
  Future<void> speak(String text) async {
    final value = text.trim();
    if (value.isEmpty) return;
    // Chỉ MỘT giọng được phát tại một thời điểm: tắt hết âm thanh còn đang chạy của câu trước trước khi đọc câu mới.
    final id = ++_speakId;
    await cloud.stop();
    await device.stop();
    if (id != _speakId) return; // đã có câu mới hơn / bị stop trong lúc tắt
    final down = _cloudDownUntil;
    if (down == null || _now().isAfter(down)) {
      _cloudDownUntil = null;
      if (await cloud.trySpeak(value)) {
        lastUsedDevice = false;
        return;
      }
      // Giọng Google thất bại. Nếu trong lúc đó đã có câu mới/bị ngắt thì KHÔNG đọc bằng giọng máy nữa.
      if (id != _speakId) return;
      await cloud.stop(); // chắc chắn không còn âm thanh đám mây nào đang phát trước khi giọng máy lên tiếng
      _cloudDownUntil = _now().add(cooldown);
      final why = cloud.lastFailure;
      _note = 'Giọng Google đám mây chưa dùng được nên đang dùng giọng của máy'
          '${why == null || why.isEmpty ? '' : ' ($why)'}. '
          'Kiểm tra đã bật Cloud Text-to-Speech API và đã deploy hàm aiSpeak.';
    }
    lastUsedDevice = true;
    await device.speak(value);
  }

  @override
  Future<void> stop() async {
    _speakId++; // huỷ mọi câu đang chờ (kể cả câu đang chờ mạng để rơi sang giọng máy)
    await cloud.stop();
    await device.stop();
  }

  @override
  String? takeError() {
    final parts = [?_note, ?device.takeError()];
    _note = null;
    return parts.isEmpty ? null : parts.join(' ');
  }
}
