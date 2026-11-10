import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:speech_to_text/speech_to_text.dart';

/// Nhận dạng giọng nói cho ô chat của Trợ lý AI. Tách interface để test thay bằng bản giả.
abstract class SpeechService {
  /// Xin quyền micro + khởi tạo bộ nhận dạng. `false` nếu bị từ chối hoặc thiết bị không hỗ trợ.
  Future<bool> initialize();

  bool get isListening;

  /// Bắt đầu nghe; [onResult] được gọi liên tục với bản chép tạm (`isFinal=false`) rồi bản cuối.
  /// [onDone] gọi khi phiên nghe kết thúc (hết lượt nói, dừng tay hoặc lỗi).
  ///
  /// [pauseFor]: im lặng bao lâu thì coi là nói xong (mặc định của bộ nhận dạng nếu null).
  Future<void> start({
    required void Function(String text, bool isFinal) onResult,
    void Function(String message)? onError,
    void Function()? onDone,
    Duration? pauseFor,
  });

  Future<void> stop();
  Future<void> cancel();
}

/// Cài đặt thật bằng plugin `speech_to_text`, ưu tiên locale tiếng Việt (vi_VN).
class DeviceSpeechService implements SpeechService {
  DeviceSpeechService({SpeechToText? engine}) : _speech = engine ?? SpeechToText();

  final SpeechToText _speech;
  bool _ready = false;
  String? _localeId;
  void Function(String message)? _onError;
  void Function()? _onDone;

  @override
  bool get isListening => _speech.isListening;

  @override
  Future<bool> initialize() async {
    if (_ready) return true;
    try {
      _ready = await _speech.initialize(
        onError: (e) => _onError?.call(e.errorMsg),
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') _onDone?.call();
        },
      );
      if (_ready) {
        final locales = await _speech.locales();
        _localeId = locales
            .where((l) => l.localeId.toLowerCase().replaceAll('-', '_') == 'vi_vn')
            .map((l) => l.localeId)
            .firstOrNull ??
            locales
                .where((l) => l.localeId.toLowerCase().startsWith('vi'))
                .map((l) => l.localeId)
                .firstOrNull;
        // Trình duyệt (Chrome) thường trả danh sách locale rỗng -> vẫn phải ép tiếng Việt,
        // nếu không bộ nhận dạng dùng ngôn ngữ mặc định của trình duyệt (thường là tiếng Anh).
        _localeId ??= kIsWeb ? 'vi-VN' : 'vi_VN';
      }
    } catch (_) {
      _ready = false;
    }
    return _ready;
  }

  @override
  Future<void> start({
    required void Function(String text, bool isFinal) onResult,
    void Function(String message)? onError,
    void Function()? onDone,
    Duration? pauseFor,
  }) async {
    _onError = onError;
    _onDone = onDone;
    await _speech.listen(
      onResult: (r) => onResult(r.recognizedWords, r.finalResult),
      listenOptions: SpeechListenOptions(
        localeId: _localeId,
        listenFor: const Duration(seconds: 45),
        pauseFor: pauseFor ?? const Duration(seconds: 4),
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  @override
  Future<void> stop() => _speech.stop();

  @override
  Future<void> cancel() => _speech.cancel();
}
