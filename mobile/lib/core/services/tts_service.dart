import 'package:flutter_tts/flutter_tts.dart';

/// Đọc câu trả lời của Trợ lý AI thành tiếng. Tách interface để test thay bằng bản giả.
abstract class TtsService {
  /// Đọc [text] và hoàn thành khi đọc xong (hoặc bị [stop]). Không bao giờ ném lỗi.
  Future<void> speak(String text);

  Future<void> stop();

  /// Lỗi/cảnh báo giọng đọc gần nhất (rồi xoá). Để giao diện báo cho người dùng thay vì im lặng.
  String? takeError();
}

/// Cài đặt thật bằng `flutter_tts`, giọng tiếng Việt (vi-VN).
class DeviceTtsService implements TtsService {
  DeviceTtsService({FlutterTts? engine}) : _tts = engine ?? FlutterTts();

  final FlutterTts _tts;
  bool _ready = false;
  String? _error;
  bool _warnedNoVietnamese = false;

  @override
  String? takeError() {
    final e = _error;
    _error = null;
    return e;
  }

  /// Đặt giọng đọc TIẾNG VIỆT. Thử `vi-VN` rồi `vi_VN`, sau đó chọn tường minh một giọng vi nếu thiết bị có
  /// (một số máy/trình duyệt bỏ qua setLanguage nên phải chọn giọng theo tên).
  Future<void> _init() async {
    if (_ready) return;
    try {
      var ok = _isOk(await _tts.setLanguage('vi-VN'));
      if (!ok) ok = _isOk(await _tts.setLanguage('vi_VN'));
      try {
        final voices = await _tts.getVoices;
        if (voices is List) {
          for (final v in voices) {
            if (v is! Map) continue;
            final locale = (v['locale'] ?? '').toString().toLowerCase().replaceAll('_', '-');
            if (locale == 'vi-vn' || locale.startsWith('vi')) {
              await _tts.setVoice({
                'name': v['name'].toString(),
                'locale': v['locale'].toString(),
              });
              ok = true;
              break;
            }
          }
        }
      } catch (_) {}
      vietnameseVoiceFound = ok;
      if (!ok && !_warnedNoVietnamese) {
        _warnedNoVietnamese = true;
        _error = 'Thiết bị chưa có giọng đọc tiếng Việt nên sẽ đọc bằng giọng mặc định. '
            'Hãy cài gói giọng nói Tiếng Việt trong cài đặt Text-to-speech.';
      }
      _tts.setErrorHandler((message) => _error = 'Giọng đọc báo lỗi: $message');
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
    } catch (e) {
      // Thiết bị/trình duyệt không hỗ trợ một số tuỳ chọn: vẫn đọc bằng giọng mặc định.
      _error ??= 'Không khởi tạo được giọng đọc: $e';
    }
    _ready = true;
  }

  /// `false` nếu thiết bị không có giọng tiếng Việt (sẽ đọc bằng giọng mặc định, có thể sai).
  bool vietnameseVoiceFound = false;

  static bool _isOk(dynamic result) => result == 1 || result == true || result == 'true';

  @override
  Future<void> speak(String text) async {
    final value = text.trim();
    if (value.isEmpty) return;
    try {
      await _init();
      // Trên web `awaitSpeakCompletion` không đáng tin: có thời gian chờ tối đa theo độ dài chữ
      // để vòng hội thoại live không bị treo vì không bao giờ nhận được "đọc xong".
      final cap = Duration(milliseconds: 4000 + value.length * 120);
      await _tts.speak(value).timeout(cap, onTimeout: () => null);
    } catch (e) {
      // Lỗi giọng đọc không được làm hỏng hội thoại, nhưng phải báo cho người dùng biết.
      // MissingPluginException = plugin mới thêm chưa được nạp: cần chạy lại ứng dụng (không phải hot reload).
      _error = e.toString().contains('MissingPlugin')
          ? 'Giọng đọc chưa được nạp: hãy dừng và chạy lại ứng dụng (flutter run) để nạp plugin flutter_tts.'
          : 'Không đọc to được: $e';
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
