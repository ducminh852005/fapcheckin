// Đảm bảo giọng nói của Trợ lý AI là TIẾNG VIỆT: nhận dạng (STT) ép vi-VN, đọc (TTS) chọn giọng vi,
// và các hàm thuần xử lý chữ để đọc / hiểu câu xác nhận.
import 'package:fapcheckin/core/services/speech_service.dart';
import 'package:fapcheckin/core/services/spoken_text.dart';
import 'package:fapcheckin/core/services/tts_service.dart';
import 'package:fapcheckin_core/ai/ai_tool_executor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

class _FakeEngine extends Fake implements SpeechToText {
  _FakeEngine(this.locales_);

  final List<LocaleName> locales_;
  String? listenedLocale;
  Duration? listenedPause;
  bool initialized = false;

  @override
  Future<bool> initialize({
    SpeechErrorListener? onError,
    SpeechStatusListener? onStatus,
    debugLogging = false,
    Duration finalTimeout = SpeechToText.defaultFinalTimeout,
    List<SpeechConfigOption>? options,
  }) async => initialized = true;

  @override
  Future<List<LocaleName>> locales() async => locales_;

  @override
  bool get isListening => false;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #listen) {
      final options = invocation.namedArguments[#listenOptions] as SpeechListenOptions?;
      listenedLocale = options?.localeId;
      listenedPause = options?.pauseFor;
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

class _FakeFlutterTts extends Fake implements FlutterTts {
  _FakeFlutterTts({this.languageOk = const {'vi-VN': 1}, this.voices = const [], this.emptyCalls = 0});

  /// Số lần đầu `getVoices` trả danh sách RỖNG (trình duyệt nạp giọng không đồng bộ).
  final int emptyCalls;
  int voiceCalls = 0;

  final Map<String, int> languageOk;
  final List<Map<String, String>> voices;
  final List<String> triedLanguages = [];
  Map<String, String>? chosenVoice;
  final List<String> spoken = [];

  @override
  Future<dynamic> setLanguage(String language) async {
    triedLanguages.add(language);
    return languageOk[language] ?? 0;
  }

  @override
  Future<dynamic> get getVoices async => ++voiceCalls <= emptyCalls ? <dynamic>[] : voices;

  @override
  Future<dynamic> setVoice(Map<String, String> voice) async {
    chosenVoice = voice;
    return 1;
  }

  @override
  void setErrorHandler(Function handler) {}

  @override
  Future<dynamic> setSpeechRate(double rate) async => 1;

  @override
  Future<dynamic> setPitch(double pitch) async => 1;

  @override
  Future<dynamic> awaitSpeakCompletion(bool awaitCompletion) async => 1;

  @override
  Future<dynamic> speak(String text, {bool focus = false}) async {
    spoken.add(text);
    return 1;
  }

  @override
  Future<dynamic> stop() async => 1;
}

Future<String?> _listenedLocale(List<LocaleName> locales) async {
  final engine = _FakeEngine(locales);
  final service = DeviceSpeechService(engine: engine);
  expect(await service.initialize(), isTrue);
  await service.start(onResult: (_, _) {});
  return engine.listenedLocale;
}

void main() {
  group('nhận dạng giọng nói (STT) luôn là tiếng Việt', () {
    test('thiết bị có vi_VN -> dùng đúng locale của thiết bị', () async {
      expect(
        await _listenedLocale([LocaleName('en_US', 'English'), LocaleName('vi_VN', 'Tiếng Việt')]),
        'vi_VN',
      );
      expect(await _listenedLocale([LocaleName('vi-VN', 'Tiếng Việt')]), 'vi-VN');
    });

    test('chỉ có biến thể vi khác -> vẫn chọn tiếng Việt', () async {
      expect(await _listenedLocale([LocaleName('en_US', 'English'), LocaleName('vi', 'Vietnamese')]), 'vi');
    });

    test('danh sách locale rỗng (Chrome) hoặc không có tiếng Việt -> VẪN ép vi, không rơi về tiếng Anh', () async {
      for (final list in [<LocaleName>[], [LocaleName('en_US', 'English'), LocaleName('fr_FR', 'Français')]]) {
        final locale = await _listenedLocale(list);
        expect(locale, isNotNull);
        expect(locale!.toLowerCase().startsWith('vi'), isTrue, reason: 'locale=$locale');
        expect(locale.toLowerCase().startsWith('en'), isFalse);
      }
    });

    test('truyền pauseFor (chờ ngắn rồi thực thi) xuống bộ nhận dạng', () async {
      final engine = _FakeEngine([LocaleName('vi_VN', 'Tiếng Việt')]);
      final service = DeviceSpeechService(engine: engine);
      await service.initialize();
      await service.start(onResult: (_, _) {}, pauseFor: const Duration(milliseconds: 1500));
      expect(engine.listenedPause, const Duration(milliseconds: 1500));
    });
  });

  group('đọc to (TTS) luôn là tiếng Việt', () {
    test('đặt vi-VN trước; nếu máy không nhận thì thử vi_VN', () async {
      final engine = _FakeFlutterTts(languageOk: const {'vi_VN': 1});
      final tts = DeviceTtsService(engine: engine, voiceLoadDelay: Duration.zero, voiceLoadAttempts: 3);
      await tts.speak('Xin chào');
      expect(engine.triedLanguages.take(2), ['vi-VN', 'vi_VN']);
      expect(engine.spoken, ['Xin chào']);
    });

    test('máy có giọng vi -> chọn tường minh giọng đó (bỏ qua giọng en)', () async {
      final engine = _FakeFlutterTts(voices: const [
        {'name': 'en-us-x-sfg', 'locale': 'en-US'},
        {'name': 'vi-vn-x-gft', 'locale': 'vi-VN'},
      ]);
      final tts = DeviceTtsService(engine: engine, voiceLoadDelay: Duration.zero, voiceLoadAttempts: 3);
      await tts.speak('Xin chào');
      expect(engine.chosenVoice, {'name': 'vi-vn-x-gft', 'locale': 'vi-VN'});
      expect(tts.vietnameseVoiceFound, isTrue);
    });

    test('máy không có giọng tiếng Việt -> không ném lỗi, báo vietnameseVoiceFound=false', () async {
      final engine = _FakeFlutterTts(languageOk: const {}, voices: const [
        {'name': 'en-us-x-sfg', 'locale': 'en-US'},
      ]);
      final tts = DeviceTtsService(engine: engine, voiceLoadDelay: Duration.zero, voiceLoadAttempts: 3);
      await tts.speak('Xin chào');
      expect(tts.vietnameseVoiceFound, isFalse);
      expect(engine.chosenVoice, isNull);
      expect(engine.spoken, ['Xin chào']); // vẫn đọc bằng giọng mặc định
    });

    test('danh sách giọng nạp muộn (Chrome trả rỗng lần đầu) -> chờ rồi vẫn chọn đúng giọng Việt, không rơi về giọng Anh', () async {
      final engine = _FakeFlutterTts(emptyCalls: 2, voices: const [
        {'name': 'Google US English', 'locale': 'en-US'},
        {'name': 'Google Tiếng Việt', 'locale': 'vi-VN'},
      ]);
      final tts = DeviceTtsService(engine: engine, voiceLoadDelay: Duration.zero, voiceLoadAttempts: 5);
      await tts.speak('Xin chào');
      expect(engine.voiceCalls, 3); // 2 lần rỗng + 1 lần có giọng
      expect(engine.chosenVoice, {'name': 'Google Tiếng Việt', 'locale': 'vi-VN'});
      expect(tts.selectedVoiceName, 'Google Tiếng Việt');
      expect(tts.takeError(), isNull);
    });

    test('hết số lần chờ mà vẫn chưa có giọng Việt -> đọc mặc định + báo lỗi rõ ràng (một lần)', () async {
      final engine = _FakeFlutterTts(languageOk: const {}, emptyCalls: 99);
      final tts = DeviceTtsService(engine: engine, voiceLoadDelay: Duration.zero, voiceLoadAttempts: 3);
      await tts.speak('Xin chào');
      expect(engine.voiceCalls, 3);
      expect(tts.vietnameseVoiceFound, isFalse);
      expect(tts.takeError(), contains('giọng đọc tiếng Việt'));
      await tts.speak('Lần hai');
      expect(tts.takeError(), isNull); // không nhắc lặp lại mỗi câu
    });

    test('chữ rỗng thì không đọc', () async {
      final engine = _FakeFlutterTts();
      await DeviceTtsService(engine: engine, voiceLoadDelay: Duration.zero, voiceLoadAttempts: 3).speak('   ');
      expect(engine.spoken, isEmpty);
    });
  });

  group('pickVietnameseVoice (chọn giọng tiếng Việt tốt nhất)', () {
    Map<String, String>? pick(List<Map<String, String>> v) => DeviceTtsService.pickVietnameseVoice(v);

    test('chỉ chọn giọng vi, bỏ giọng ngôn ngữ khác', () {
      expect(pick(const [{'name': 'Samantha', 'locale': 'en-US'}, {'name': 'Thomas', 'locale': 'fr-FR'}]), isNull);
      expect(pick(const []), isNull);
    });

    test('ưu tiên giọng Google/Natural hơn giọng thường; vi-VN hơn biến thể vi', () {
      expect(
        pick(const [
          {'name': 'Microsoft An - Vietnamese', 'locale': 'vi-VN'},
          {'name': 'Microsoft HoaiMy Online (Natural) - Vietnamese (Vietnam)', 'locale': 'vi-VN'},
          {'name': 'Google Tiếng Việt', 'locale': 'vi-VN'},
        ])!['name'],
        'Google Tiếng Việt',
      );
      expect(
        pick(const [
          {'name': 'Voice A', 'locale': 'vi'},
          {'name': 'Voice B', 'locale': 'vi-VN'},
        ])!['name'],
        'Voice B',
      );
    });

    test('tránh giọng compact (iOS) khi có giọng tốt hơn; định dạng locale vi_VN của Android vẫn nhận', () {
      expect(
        pick(const [
          {'name': 'Linh (compact)', 'locale': 'vi-VN'},
          {'name': 'vi-vn-x-gft-network', 'locale': 'vi_VN'},
        ])!['name'],
        'vi-vn-x-gft-network',
      );
    });

    test('nhận ra giọng tiếng Việt theo tên khi locale thiếu', () {
      expect(pick(const [{'name': 'Google Tiếng Việt', 'locale': ''}])!['locale'], 'vi-VN');
    });
  });

  group('spokenSummary', () {
    test('bỏ markdown/emoji, chỉ lấy đoạn đầu', () {
      expect(
        spokenSummary('Có **1** sinh viên cần lưu ý 🚨.\n\n- HE123457 vắng 4/10\n- Tỷ lệ chung 91%'),
        'Có 1 sinh viên cần lưu ý .',
      );
    });

    test('đoạn đầu là gạch đầu dòng -> nối thành câu', () {
      expect(spokenSummary('- Lớp A: 90%\n- Lớp B: 80%'), 'Lớp A: 90%, Lớp B: 80%');
    });

    test('tối đa 2 câu và cắt theo độ dài', () {
      expect(spokenSummary('Một. Hai. Ba. Bốn.'), 'Một. Hai.');
      final long = List.filled(80, 'chữ').join(' ');
      final out = spokenSummary(long, maxChars: 100);
      expect(out.length, lessThanOrEqualTo(101));
      expect(out.endsWith('…'), isTrue);
    });

    test('rỗng -> rỗng', () {
      expect(spokenSummary('  \n\n '), '');
    });
  });

  group('confirmPrompt', () {
    AiPendingAction action(int n) => AiPendingAction(
      toolName: 'mark_attendance',
      classCode: 'SWP391_SE1801',
      subjectName: 'Software Project',
      sessionId: 'S1',
      sessionDate: '2026-10-21',
      slotCode: 'A3',
      students: [
        for (var i = 0; i < n; i++)
          AiPendingStudent(rollNumber: 'HE12345$i', fullName: 'SV $i', status: i == 1 ? 'Absent' : 'ManualByGV', previousStatus: 'Unchecked'),
      ],
    );

    test('đọc tên, MSSV, trạng thái, lớp, slot và lời nhắc xác nhận', () {
      final text = confirmPrompt(action(2));
      expect(text, contains('2 sinh viên lớp SWP391_SE1801, slot A3'));
      expect(text, contains('SV 0, MSSV HE123450, có mặt'));
      expect(text, contains('SV 1, MSSV HE123451, vắng'));
      expect(text, endsWith('Nói xác nhận hoặc huỷ.'));
    });

    test('nhiều sinh viên -> chỉ đọc 3 người đầu rồi "và N bạn khác"', () {
      final text = confirmPrompt(action(6));
      expect(text, contains('6 sinh viên'));
      expect(text, contains('và 3 bạn khác'));
      expect(text, isNot(contains('SV 3')));
    });
  });

  group('looksIncomplete (chưa nói hết câu thì chờ lâu hơn)', () {
    test('câu dở: kết thúc bằng từ nối / từ chờ danh từ / dấu phẩy', () {
      for (final t in ['điểm danh sinh viên', 'điểm danh sinh viên lớp', 'báo cáo của lớp SWP391 và', 'lớp SWP391 slot', 'sinh viên MSSV', 'điểm danh,', 'cho']) {
        expect(looksIncomplete(t), isTrue, reason: t);
      }
    });

    test('câu trọn: kết thúc bằng mã/số/trạng thái', () {
      for (final t in ['điểm danh HE123456 lớp SWP391 slot 3 có mặt', 'đánh vắng', 'xin chào', 'báo cáo chuyên cần tổng quan của hôm nay', 'HE123456 đi muộn']) {
        expect(looksIncomplete(t), isFalse, reason: t);
      }
      expect(looksIncomplete(''), isFalse);
    });
  });

  group('parseVoiceDecision (câu xác nhận bằng giọng nói)', () {
    test('xác nhận', () {
      for (final t in ['xác nhận', 'Xác nhận đi', 'ok', 'OK nhé', 'đồng ý', 'được rồi', 'làm đi', 'chốt', 'đúng rồi', 'ghi đi']) {
        expect(parseVoiceDecision(t), VoiceDecision.confirm, reason: t);
      }
    });

    test('huỷ (có/không dấu, cả hủy/huỷ)', () {
      for (final t in ['huỷ', 'hủy đi', 'huy', 'thôi', 'không', 'Không, bỏ đi', 'dừng lại', 'bỏ qua']) {
        expect(parseVoiceDecision(t), VoiceDecision.cancel, reason: t);
      }
    });

    test('mơ hồ -> unknown; huỷ ưu tiên hơn xác nhận để an toàn', () {
      for (final t in ['ừm', 'để xem', '', 'không sao', 'sinh viên khác']) {
        expect(parseVoiceDecision(t), VoiceDecision.unknown, reason: t);
      }
      expect(parseVoiceDecision('không, xác nhận'), VoiceDecision.cancel);
    });

    test('foldVietnamese bỏ dấu và dấu câu', () {
      expect(foldVietnamese('  Đồng Ý!!  '), 'dong y');
    });
  });
}
