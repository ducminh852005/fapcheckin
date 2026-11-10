import 'package:flutter/foundation.dart' show kIsWeb;
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
///
/// Chất lượng giọng phụ thuộc vào giọng có sẵn trên thiết bị/trình duyệt:
///  - Chrome: giọng "Google Tiếng Việt" (cần internet) nghe tự nhiên nhất; Edge/Windows: "Microsoft HoaiMy/NamMinh Online (Natural)".
///  - Android: Google Text-to-speech (cài gói giọng Tiếng Việt); iOS: giọng "Linh".
/// Trình duyệt nạp danh sách giọng KHÔNG đồng bộ (lần đầu hỏi thường rỗng) nên phải chờ rồi mới chọn giọng,
/// nếu không sẽ rơi về giọng tiếng Anh đọc tiếng Việt.
class DeviceTtsService implements TtsService {
  DeviceTtsService({
    FlutterTts? engine,
    this.voiceLoadDelay = const Duration(milliseconds: 300),
    this.voiceLoadAttempts = 10,
  }) : _tts = engine ?? FlutterTts();

  final FlutterTts _tts;

  /// Chờ danh sách giọng nạp xong: tối đa [voiceLoadAttempts] lần, mỗi lần cách nhau [voiceLoadDelay].
  final Duration voiceLoadDelay;
  final int voiceLoadAttempts;

  bool _ready = false;
  String? _error;
  bool _warnedNoVietnamese = false;

  /// Giọng đã chọn (để hiển thị/chẩn đoán), null nếu không tìm thấy giọng tiếng Việt.
  String? selectedVoiceName;

  /// `false` nếu thiết bị không có giọng tiếng Việt (sẽ đọc bằng giọng mặc định, có thể sai).
  bool vietnameseVoiceFound = false;

  @override
  String? takeError() {
    final e = _error;
    _error = null;
    return e;
  }

  /// Chọn giọng tiếng Việt tốt nhất trong danh sách `getVoices` (mỗi phần tử có `name`, `locale`).
  /// Ưu tiên: đúng `vi-VN` > biến thể `vi*`; giọng Google/Neural/Natural/Online > Microsoft > còn lại;
  /// tránh giọng "compact" (bản nén chất lượng thấp trên iOS). Trả null nếu không có giọng tiếng Việt.
  static Map<String, String>? pickVietnameseVoice(Iterable<dynamic> voices) {
    Map<String, String>? best;
    var bestScore = -1 << 30;
    for (final v in voices) {
      if (v is! Map) continue;
      final name = (v['name'] ?? '').toString();
      final rawLocale = (v['locale'] ?? '').toString();
      final locale = rawLocale.toLowerCase().replaceAll('_', '-');
      final n = name.toLowerCase();
      final isVi = locale.startsWith('vi') || n.contains('vietnam') || n.contains('tiếng việt') || n.contains('tieng viet');
      if (!isVi || name.isEmpty) continue;
      var score = 0;
      if (locale == 'vi-vn') score += 100;
      if (n.contains('google')) score += 45; // giọng "Google Tiếng Việt" tự nhiên nhất, ưu tiên khi cùng có mặt
      if (n.contains('natural') || n.contains('neural') || n.contains('online') || n.contains('wavenet')) score += 30;
      if (n.contains('microsoft')) score += 10;
      if (n.contains('compact')) score -= 20;
      if (score > bestScore) {
        bestScore = score;
        best = {'name': name, 'locale': rawLocale.isEmpty ? 'vi-VN' : rawLocale};
      }
    }
    return best;
  }

  Future<Map<String, String>?> _findVietnameseVoice() async {
    for (var attempt = 0; attempt < voiceLoadAttempts; attempt++) {
      try {
        final voices = await _tts.getVoices;
        if (voices is List) {
          final voice = pickVietnameseVoice(voices);
          if (voice != null) return voice;
        }
      } catch (_) {}
      if (attempt < voiceLoadAttempts - 1) await Future<void>.delayed(voiceLoadDelay);
    }
    return null;
  }

  /// Đặt giọng đọc TIẾNG VIỆT: ngôn ngữ vi-VN (rồi vi_VN), rồi chọn tường minh giọng tốt nhất sau khi danh sách giọng nạp xong.
  Future<void> _init() async {
    if (_ready) return;
    try {
      var langOk = _isOk(await _tts.setLanguage('vi-VN'));
      if (!langOk) langOk = _isOk(await _tts.setLanguage('vi_VN'));
      final voice = await _findVietnameseVoice();
      if (voice != null) {
        await _tts.setVoice(voice);
        selectedVoiceName = voice['name'];
      }
      // Web luôn trả "ok" cho setLanguage kể cả khi không có giọng vi, nên ở web chỉ tin việc tìm thấy giọng thật.
      vietnameseVoiceFound = voice != null || (langOk && !kIsWeb);
      if (!vietnameseVoiceFound && !_warnedNoVietnamese) {
        _warnedNoVietnamese = true;
        _error = kIsWeb
            ? 'Trình duyệt chưa có giọng đọc tiếng Việt nên đang đọc bằng giọng mặc định. '
                'Chrome: cần internet để dùng giọng "Google Tiếng Việt"; Edge/Windows: cài giọng Vietnamese trong Cài đặt → Thời gian & ngôn ngữ → Giọng nói.'
            : 'Thiết bị chưa có giọng đọc tiếng Việt nên sẽ đọc bằng giọng mặc định. '
                'Hãy cài gói giọng nói Tiếng Việt (Google Text-to-speech) trong cài đặt Text-to-speech.';
      }
      _tts.setErrorHandler((message) => _error = 'Giọng đọc báo lỗi: $message');
      // Thang tốc độ khác nhau: Android/iOS 0.5 ≈ bình thường; trình duyệt (Web Speech) 1.0 = bình thường
      // (đặt 0.5 trên web sẽ đọc rất chậm).
      await _tts.setSpeechRate(kIsWeb ? 1.0 : 0.5);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
    } catch (e) {
      // Thiết bị/trình duyệt không hỗ trợ một số tuỳ chọn: vẫn đọc bằng giọng mặc định.
      _error ??= 'Không khởi tạo được giọng đọc: $e';
    }
    _ready = true;
  }

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
