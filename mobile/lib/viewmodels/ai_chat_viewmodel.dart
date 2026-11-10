// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:fapcheckin_core/ai/ai_tool_executor.dart';
import 'package:fapcheckin_core/repositories/ai_assistant_repository.dart';
import 'package:fapcheckin_core/result/api_result.dart';

import '../core/services/spoken_text.dart';
import '../core/services/speech_service.dart';
import '../core/services/tts_service.dart';

enum AiMessageRole { user, assistant }

enum AiActionState { awaiting, confirmed, cancelled, failed }

class AiMessage {
  AiMessage({
    required this.id,
    required this.role,
    this.text = '',
    this.action,
    this.isError = false,
  });

  final int id;
  final AiMessageRole role;
  final String text;

  /// Thao tác ghi chờ/đã xác nhận — hiển thị dưới dạng thẻ xác nhận.
  final AiPendingAction? action;
  AiActionState actionState = AiActionState.awaiting;
  final bool isError;
}

/// Trạng thái hội thoại của Trợ lý AI + vòng lặp "model đề xuất tool → app chạy tool → gửi kết quả lại".
/// Tool đọc chạy ngay; tool ghi dừng ở [pendingAction] cho tới khi giảng viên xác nhận/huỷ
/// (bằng nút hoặc bằng giọng nói "xác nhận"/"huỷ").
///
/// Giọng nói:
///  - mic một lượt ([toggleListening]): nói xong → chờ ngắn → tự gửi → AI đọc tóm tắt;
///  - chế độ Live ([startLive]): như trên nhưng tự nghe tiếp sau khi AI đọc xong, tới khi tắt/im lặng lâu.
class AiChatViewModel extends ChangeNotifier {
  AiChatViewModel({
    required this.repository,
    required this.executor,
    SpeechService? speech,
    TtsService? tts,
    this.speechTail = const Duration(milliseconds: 600),
  }) : _speech = speech,
       _tts = tts;

  final AiAssistantRepository repository;
  final AiToolExecutor executor;
  final SpeechService? _speech;
  final TtsService? _tts;

  /// Nghỉ sau khi đọc xong rồi mới mở micro: tiếng vang còn lại của loa không bị nhận nhầm là người nói
  /// (nếu không, Live tự gửi lại chính câu AI vừa đọc và các câu trả lời đè lên nhau).
  final Duration speechTail;

  /// Số vòng model↔tool tối đa cho một câu hỏi (chặn vòng lặp vô hạn).
  static const maxRounds = 6;
  static const _maxHistory = 26;
  static const _maxToolResultChars = 20000;

  /// Im lặng bao lâu (tính từ lúc nghe được chữ cuối) thì coi là NÓI XONG và tự gửi. Do ứng dụng quyết định,
  /// không dựa vào "kết quả cuối" của bộ nhận dạng (nó chốt ngay ở nhịp ngắt đầu tiên nên hay cắt ngang câu).
  static const sendDelay = Duration(milliseconds: 2000);

  /// Như trên nhưng khi câu có vẻ chưa trọn (kết thúc bằng "lớp", "và", "slot"…): chờ lâu hơn.
  static const sendDelayIncomplete = Duration(milliseconds: 3500);

  /// Câu trả lời xác nhận thường chỉ một từ ("xác nhận") nên chờ ngắn.
  static const confirmDelay = Duration(milliseconds: 900);

  /// Thời gian im lặng để chính bộ nhận dạng ngắt một phiên; ứng dụng tự mở lại và nối chữ vào cùng một lượt.
  static const enginePause = Duration(seconds: 3);

  /// Số lần mở lại bộ nhận dạng tối đa trong một lượt nói.
  static const maxEngineRestarts = 12;

  /// Sau khi mở bộ nhận dạng, trong khoảng này mọi tín hiệu "đã dừng/không có tiếng" bị coi là TÍN HIỆU MUỘN của phiên
  /// trước (plugin dùng chung một bộ lắng nghe trạng thái) chứ không phải người dùng im lặng — nếu không, lượt nghe mới
  /// bị kết thúc ngay và hai lần liền thì Live tự thoát ("chỉ nói được một lần"). Im lặng thật chỉ được tính sau mốc này.
  static const engineWarmup = Duration(milliseconds: 1200);

  /// Số tín hiệu muộn tối đa được bỏ qua (rồi mở lại) trong một lượt trước khi coi là bộ nhận dạng hỏng.
  static const maxStaleSignals = 6;

  /// Số lỗi tạm thời liên tiếp (busy, network chập chờn…) được thử lại trước khi thoát Live.
  static const maxTransientErrors = 3;

  /// Không nói gì trong khoảng này thì kết thúc lượt nghe.
  static const noSpeechLimit = Duration(seconds: 12);

  /// Số lượt nghe liền nhau không có tiếng thì tự thoát Live.
  static const maxSilentTurns = 2;

  /// Số lần nhắc "nói xác nhận hoặc huỷ" trước khi để thẻ chờ bấm tay.
  static const maxConfirmRetries = 2;

  final List<AiMessage> messages = [];
  final List<Map<String, dynamic>> _history = [];
  int _nextId = 0;
  bool _disposed = false;
  int _generation = 0;

  bool sending = false;

  /// Nguồn AI của lượt trả lời gần nhất (`gemini` | `ollama`); `ollama` = đang chạy bằng AI dự phòng.
  String lastProvider = '';
  bool get usingBackupAi => lastProvider == 'ollama';

  // Trạng thái dở dang khi chờ xác nhận.
  AiPendingAction? pendingAction;
  AiMessage? _pendingMessage;
  AiToolCall? _pendingCall;
  List<AiToolCall> _remainingCalls = const [];
  int _round = 0;

  // Dành cho đọc to sau mỗi lượt gọi AI.
  String? _postReply;
  bool _postConfirm = false;

  /// Câu trả lời lỗi gần nhất có thể thử lại.
  bool get canRetry => !sending && pendingAction == null && _retryable;
  bool _retryable = false;

  bool get busy => sending || pendingAction != null;

  /// Có thể ngắt: AI đang đọc hoặc đang xử lý.
  bool get canInterrupt => sending || speaking;

  // Yêu cầu gửi lúc AI đang GHI điểm danh hoặc đang chờ xác nhận: xếp hàng rồi gửi ngay sau đó (không bị bỏ mất).
  final List<String> _queued = [];

  /// Số yêu cầu đang xếp hàng (để giao diện báo).
  int get queuedCount => _queued.length;

  // Điểm cắt của history: ngắt giữa chừng thì bỏ phần model/tool dở dang để history luôn hợp lệ.
  int _checkpoint = 0;

  // Đang ghi điểm danh: không thể huỷ giữa chừng (tránh ghi dở).
  bool _writing = false;

  // ── giọng nói: trạng thái ──────────────────────────────────────────────────

  bool listening = false;
  bool speaking = false;

  /// Đang ở chế độ Live (nghe liên tục).
  bool live = false;

  /// Đang nghe câu trả lời "xác nhận/huỷ" cho thẻ điểm danh.
  bool confirmingByVoice = false;

  /// Đọc to câu trả lời khi lượt nhập là giọng nói (hoặc đang Live).
  bool voiceReplies = true;
  String? voiceError;

  bool get voiceSupported => _speech != null;

  int _turnId = 0; // mỗi lượt nghe một mã; callback của lượt cũ bị bỏ qua
  bool _turnDone = true;
  int _voiceEpoch =
      0; // tăng khi dừng Live/reset để vòng đọc→nghe đang chạy tự huỷ
  String _heard = ''; // đoạn đang nói (chưa chốt)
  String _committed = ''; // các đoạn đã chốt trong cùng một lượt nói
  int _restarts = 0;
  int _staleSignals = 0;
  int _transientErrors = 0;
  bool _engineWarm = false;
  Timer? _warmTimer;
  Timer? _sendTimer;
  int _silentTurns = 0;
  int _confirmRetries = 0;
  bool _lastInputWasVoice = false;
  Timer? _noSpeechTimer;
  void Function(String text)? _onTranscript;

  /// Dòng trạng thái cho giao diện (null khi rảnh).
  String? get statusText {
    final base = _baseStatus;
    if (base == null || _queued.isEmpty) return base;
    return '$base · ${_queued.length} yêu cầu đang chờ';
  }

  String? get _baseStatus {
    if (speaking) return 'Đang đọc…';
    if (listening) {
      if (confirmingByVoice) return 'Nói "xác nhận" hoặc "huỷ"';
      return sending
          ? 'Đang nghe thêm · AI đang xử lý, câu mới sẽ được gộp'
          : 'Đang nghe…';
    }
    if (sending) return 'Đang xử lý…';
    return null;
  }

  // ── gửi tin ────────────────────────────────────────────────────────────────

  /// Gửi một yêu cầu. Lúc AI đang xử lý, yêu cầu mới được GỘP vào cùng ngữ cảnh (huỷ lượt đang chạy rồi trả lời chung
  /// cả hai); lúc AI đang ghi điểm danh hoặc chờ xác nhận thì xếp hàng và gửi ngay sau đó.
  Future<void> send(String rawText, {bool fromVoice = false}) async {
    final text = rawText.trim();
    if (text.isEmpty) return;

    if (pendingAction != null) {
      // Đang chờ xác nhận: câu ngắn kiểu "xác nhận"/"huỷ" được hiểu là quyết định; câu khác xếp hàng.
      if (text.split(RegExp(r'\s+')).length <= 4) {
        switch (parseVoiceDecision(text)) {
          case VoiceDecision.confirm:
            await confirmPending();
            return;
          case VoiceDecision.cancel:
            await cancelPending();
            return;
          case VoiceDecision.unknown:
            break;
        }
      }
      _enqueue(text, fromVoice);
      return;
    }
    if (sending && _writing) {
      _enqueue(
        text,
        fromVoice,
      ); // đang ghi điểm danh: không chen ngang, gửi ngay sau khi ghi xong
      return;
    }
    if (sending) {
      // Gộp: huỷ lượt đang chạy (kết quả về muộn bị bỏ), giữ nguyên các tin đã gửi; AI sẽ thấy cả hai yêu cầu cùng lúc.
      await interrupt(relisten: false, announce: false);
    } else if (speaking) {
      await _tts?.stop();
    }
    if (listening && !fromVoice) await _haltListen();
    _lastInputWasVoice = fromVoice;
    _retryable = false;
    _add(AiMessage(id: _nextId++, role: AiMessageRole.user, text: text));
    _history.add(AiHistory.user(text));
    _checkpoint = _history.length;
    _round = 0;
    await _drive();
  }

  void _enqueue(String text, bool fromVoice) {
    _queued.add(text);
    if (fromVoice) _lastInputWasVoice = true;
    _add(AiMessage(id: _nextId++, role: AiMessageRole.user, text: text));
  }

  /// Gửi các yêu cầu đã xếp hàng (cùng một lượt gọi AI để AI xử lý gộp).
  Future<void> _flushQueued() async {
    if (_queued.isEmpty || busy || _disposed) return;
    final texts = List<String>.of(_queued);
    _queued.clear();
    for (final t in texts) {
      _history.add(AiHistory.user(t));
    }
    _checkpoint = _history.length;
    _retryable = false;
    _round = 0;
    await _drive();
  }

  Future<void> retry() async {
    if (!canRetry) return;
    _retryable = false;
    // Bỏ bong bóng lỗi cuối rồi gọi lại với cùng history.
    if (messages.isNotEmpty && messages.last.isError) messages.removeLast();
    _checkpoint = _history.length;
    _round = 0;
    await _drive();
  }

  Future<void> _drive() async {
    final generation = _generation;
    await _driveCore(generation);
    if (_disposed || generation != _generation) return;
    if (_queued.isNotEmpty && pendingAction == null && !_writing) {
      // Có yêu cầu bổ sung đang chờ: câu trả lời vừa rồi sắp bị thay thế nên không đọc to, trả lời gộp luôn.
      await _flushQueued();
      return;
    }
    await _afterDrive();
  }

  Future<void> _driveCore(int generation) async {
    _postReply = null;
    _postConfirm = false;
    sending = true;
    notifyListeners();
    try {
      while (_round < maxRounds) {
        _round++;
        _trimHistory();
        final result = await repository.chat(List.of(_history));
        if (_disposed || generation != _generation) return;
        switch (result) {
          case ApiSuccess<AiTurn>(:final data):
            lastProvider = data.provider;
            _history.add(AiHistory.model(data));
            if (data.text.isNotEmpty) {
              _add(
                AiMessage(
                  id: _nextId++,
                  role: AiMessageRole.assistant,
                  text: data.text,
                ),
              );
            }
            if (!data.hasToolCalls) {
              _postReply = data.text;
              return;
            }
            final paused = await _runCalls(data.calls, generation);
            if (paused || _disposed || generation != _generation) {
              _postConfirm = pendingAction != null;
              return;
            }
          case ApiFailure<AiTurn>(:final error):
            _fail(error.message);
            _postReply = error.message;
            return;
          default:
            _fail('Không nhận được phản hồi từ trợ lý AI.');
            _postReply = 'Không nhận được phản hồi từ trợ lý AI.';
            return;
        }
      }
      const giveUp =
          'Mình chưa hoàn tất được yêu cầu này. Bạn thử diễn đạt cụ thể hơn nhé.';
      _add(
        AiMessage(id: _nextId++, role: AiMessageRole.assistant, text: giveUp),
      );
      _postReply = giveUp;
    } finally {
      if (!_disposed && generation == _generation) {
        sending = false;
        notifyListeners();
      }
    }
  }

  /// Chạy lần lượt các tool call; dừng (trả `true`) khi gặp tool ghi cần xác nhận.
  Future<bool> _runCalls(List<AiToolCall> calls, int generation) async {
    for (var i = 0; i < calls.length; i++) {
      final call = calls[i];
      final outcome = await executor.run(call);
      if (_disposed || generation != _generation) return true;
      final pending = outcome.pending;
      if (pending != null) {
        final message = AiMessage(
          id: _nextId++,
          role: AiMessageRole.assistant,
          action: pending,
        );
        pendingAction = pending;
        _pendingMessage = message;
        _pendingCall = call;
        _remainingCalls = calls.sublist(i + 1);
        _add(message);
        return true;
      }
      _history.add(AiHistory.tool(call.name, _bounded(outcome.result!)));
    }
    return false;
  }

  // ── xác nhận / huỷ thao tác ghi ────────────────────────────────────────────

  /// Ghi điểm danh theo thẻ xác nhận. Trả `true` nếu ghi thành công.
  Future<bool> confirmPending() async {
    final action = pendingAction;
    final call = _pendingCall;
    final message = _pendingMessage;
    if (action == null || call == null || message == null || sending) {
      return false;
    }
    await _haltListen();
    await _tts?.stop();
    final generation = _generation;
    sending = true;
    notifyListeners();
    _writing = true;
    final Map<String, dynamic> result;
    try {
      result = await executor.confirm(action);
    } finally {
      _writing = false;
    }
    if (_disposed || generation != _generation) return false;
    final ok = result['ok'] == true;
    message.actionState = ok ? AiActionState.confirmed : AiActionState.failed;
    await _resumeAfterAction(call, result, generation);
    return ok;
  }

  Future<void> cancelPending() async {
    final call = _pendingCall;
    final message = _pendingMessage;
    if (pendingAction == null || call == null || message == null || sending) {
      return;
    }
    await _haltListen();
    await _tts?.stop();
    final generation = _generation;
    sending = true;
    notifyListeners();
    message.actionState = AiActionState.cancelled;
    await _resumeAfterAction(call, executor.cancelled(), generation);
  }

  Future<void> _resumeAfterAction(
    AiToolCall call,
    Map<String, dynamic> result,
    int generation,
  ) async {
    final remaining = _remainingCalls;
    pendingAction = null;
    _pendingMessage = null;
    _pendingCall = null;
    _remainingCalls = const [];
    confirmingByVoice = false;
    _history.add(AiHistory.tool(call.name, _bounded(result)));
    if (remaining.isNotEmpty) {
      final paused = await _runCalls(remaining, generation);
      if (paused || _disposed || generation != _generation) {
        sending = false;
        notifyListeners();
        if (!_disposed && generation == _generation && pendingAction != null) {
          _postConfirm = true;
          await _afterDrive();
        }
        return;
      }
    }
    sending = false;
    _round = 0;
    // Mọi tool call đã có kết quả (kể cả lệnh ghi đã thực thi): ngắt sau đây không được bỏ chúng khỏi history,
    // nếu không AI sẽ "quên" là đã ghi điểm danh.
    _checkpoint = _history.length;
    await _drive();
  }

  /// Ngắt AI: cắt giọng đang đọc và huỷ yêu cầu đang xử lý (kết quả trả về muộn bị bỏ qua).
  /// Lệnh ghi điểm danh đang thực thi thì KHÔNG huỷ (chỉ cắt giọng). Ở chế độ Live, ngắt xong tự nghe tiếp.
  Future<void> interrupt({bool relisten = true, bool announce = true}) async {
    await _tts
        ?.stop(); // speak() hoàn thành -> vòng đọc→nghe đang chờ tự đi tiếp
    if (!sending || _writing) return;
    _generation++;
    if (_history.length > _checkpoint) {
      _history.removeRange(_checkpoint, _history.length);
    }
    _postReply = null;
    _postConfirm = false;
    sending = false;
    if (announce) {
      _add(
        AiMessage(
          id: _nextId++,
          role: AiMessageRole.assistant,
          text: 'Đã dừng.',
        ),
      );
    } else {
      notifyListeners();
    }
    if (relisten && live && !listening && !_disposed) await _listenTurn();
  }

  // ── giọng nói: điều khiển ──────────────────────────────────────────────────

  /// Mic một lượt: nói → chờ ngắn → tự gửi → AI đọc tóm tắt. Bấm lần nữa khi đang nghe để dừng.
  /// Trả `false` nếu không dùng được micro (xem [voiceError]).
  Future<bool> toggleListening(void Function(String text) onTranscript) async {
    if (_speech == null) return false;
    if (listening) {
      // Đang nghe: bấm lần nữa = nói xong, gửi ngay những gì đã nói (không có chữ thì chỉ dừng).
      if (_fullHeard.isEmpty) {
        await _haltListen();
      } else {
        finishListeningNow();
      }
      return true;
    }
    if (!await _ensureSpeech()) return false;
    _onTranscript = onTranscript;
    live = false;
    _silentTurns = 0;
    if (pendingAction != null) {
      _confirmRetries = 0;
      await _listenTurn(
        forConfirm: true,
      ); // đang chờ xác nhận: mic = nói "xác nhận"/"huỷ"
      return true;
    }
    await _listenTurn(); // kể cả lúc AI đang xử lý: câu nói thêm được gộp vào ngữ cảnh
    return true;
  }

  /// Bật chế độ Live: hội thoại liên tục (nghe → xử lý → đọc → nghe tiếp) tới khi [stopLive].
  Future<bool> startLive(void Function(String text) onTranscript) async {
    if (_speech == null) return false;
    if (!await _ensureSpeech()) return false;
    _onTranscript = onTranscript;
    live = true;
    _silentTurns = 0;
    _lastInputWasVoice = true;
    notifyListeners();
    if (pendingAction != null) {
      _confirmRetries = 0;
      await _listenTurn(forConfirm: true);
      return true;
    }
    await _listenTurn();
    return true;
  }

  Future<bool> toggleLive(void Function(String text) onTranscript) async {
    if (live) {
      await stopLive();
      return true;
    }
    return startLive(onTranscript);
  }

  /// Tắt Live ngay: dừng đọc, dừng nghe, huỷ các vòng đang chờ.
  Future<void> stopLive() async {
    live = false;
    _voiceEpoch++;
    _turnId++;
    _turnDone = true;
    _noSpeechTimer?.cancel();
    _sendTimer?.cancel();
    _warmTimer?.cancel();
    listening = false;
    speaking = false;
    confirmingByVoice = false;
    notifyListeners();
    await _tts?.stop();
    await _speech?.cancel();
  }

  void setVoiceReplies(bool value) {
    voiceReplies = value;
    if (!value) unawaited(_tts?.stop());
    notifyListeners();
  }

  Future<bool> _ensureSpeech() async {
    voiceError = null;
    final ready = await _speech!.initialize();
    if (_disposed) return false;
    if (!ready) {
      voiceError = 'Không dùng được micro. Hãy cấp quyền micro/nhận dạng giọng nói cho ứng dụng rồi thử lại.';
      notifyListeners();
      return false;
    }
    return true;
  }

  /// Dừng lượt nghe hiện tại (không đụng tới cờ Live).
  Future<void> _haltListen() async {
    _turnId++;
    _turnDone = true;
    _noSpeechTimer?.cancel();
    _sendTimer?.cancel();
    _warmTimer?.cancel();
    if (listening) {
      listening = false;
      confirmingByVoice = false;
      notifyListeners();
      await _speech?.cancel();
    }
  }

  // ── giọng nói: vòng nghe / đọc ────────────────────────────────────────────

  String get _fullHeard => _join(_committed, _heard);

  static String _join(String a, String b) {
    final x = a.trim();
    final y = b.trim();
    if (x.isEmpty) return y;
    if (y.isEmpty) return x;
    return '$x $y';
  }

  /// Một lượt nói. Gom nhiều đoạn nói liên tiếp (kể cả khi bộ nhận dạng tự ngắt giữa chừng và được mở lại),
  /// chỉ kết thúc khi im lặng đủ lâu ([sendDelay]), khi không nói gì quá [noSpeechLimit], hoặc khi người dùng bấm xong.
  Future<void> _listenTurn({bool forConfirm = false}) async {
    if (_speech == null || _disposed) return;
    final id = ++_turnId;
    _turnDone = false;
    _heard = '';
    _committed = '';
    _restarts = 0;
    _staleSignals = 0;
    _transientErrors = 0;
    _sendTimer?.cancel();
    _warmTimer?.cancel();
    confirmingByVoice = forConfirm;
    listening = true;
    notifyListeners();

    _noSpeechTimer?.cancel();
    _noSpeechTimer = Timer(noSpeechLimit, () {
      if (id == _turnId && !_turnDone && _fullHeard.isEmpty) {
        unawaited(_speech.stop());
        _endTurn(id, forConfirm);
      }
    });
    await _startEngine(id, forConfirm);
  }

  bool _current(int id) => id == _turnId && !_turnDone && !_disposed;

  Future<void> _startEngine(int id, bool forConfirm) async {
    final speech = _speech;
    if (speech == null || !_current(id)) return;
    try {
      // Phiên trước (nếu còn) phải dừng hẳn rồi mới mở phiên mới — mở chồng làm plugin báo lỗi "busy".
      if (speech.isListening) await speech.cancel();
      if (!_current(id)) return;
      _engineWarm = false;
      _warmTimer?.cancel();
      _warmTimer = Timer(engineWarmup, () {
        if (id == _turnId) _engineWarm = true;
      });
      await speech.start(
        pauseFor: enginePause,
        onResult: (text, isFinal) {
          if (!_current(id)) return;
          _transientErrors = 0;
          _staleSignals = 0;
          _engineWarm =
              true; // đã nghe được tiếng thật: bộ nhận dạng đang chạy đúng
          if (isFinal) {
            _committed = _join(_committed, text);
            _heard = '';
          } else {
            _heard = text;
          }
          final full = _fullHeard;
          _onTranscript?.call(full);
          if (full.isNotEmpty) {
            _noSpeechTimer?.cancel();
            _armSendTimer(id, forConfirm);
          }
        },
        onError: (message) {
          if (!_current(id)) return;
          if (_isSoftSpeechError(message)) {
            _engineEnded(id, forConfirm);
            return;
          }
          if (_isFatalSpeechError(message) ||
              _transientErrors >= maxTransientErrors) {
            voiceError = 'Lỗi nhận dạng giọng nói: $message';
            _turnDone = true;
            _noSpeechTimer?.cancel();
            _sendTimer?.cancel();
            _warmTimer?.cancel();
            listening = false;
            confirmingByVoice = false;
            live = false;
            _voiceEpoch++;
            notifyListeners();
            return;
          }
          // Lỗi tạm thời (busy, mạng chập chờn…): đừng bỏ cuộc hội thoại, mở lại sau một nhịp.
          _transientErrors++;
          unawaited(
            Future<void>.delayed(
              const Duration(milliseconds: 500),
              () => _startEngine(id, forConfirm),
            ),
          );
        },
        onDone: () {
          if (!_current(id)) return;
          _engineEnded(id, forConfirm);
        },
      );
    } catch (e) {
      if (_disposed) return;
      if (DeviceSpeechService.isAlreadyStartedError(e) &&
          _transientErrors < maxTransientErrors &&
          _current(id)) {
        // "recognition has already started": phiên cũ chưa kết thúc hẳn — tạm thời, thử lại sau một nhịp thay vì thoát Live.
        _transientErrors++;
        unawaited(
          Future<void>.delayed(
            const Duration(milliseconds: 600),
            () => _startEngine(id, forConfirm),
          ),
        );
        return;
      }
      voiceError = 'Không bật được micro: $e';
      _turnDone = true;
      _sendTimer?.cancel();
      _warmTimer?.cancel();
      listening = false;
      live = false;
      _voiceEpoch++;
      notifyListeners();
    }
  }

  /// Bộ nhận dạng tự ngắt phiên (Chrome ngắt sau mỗi nhịp dừng). Chưa nói xong thì mở lại và nối tiếp lượt nói.
  void _engineEnded(int id, bool forConfirm) {
    if (!_current(id)) return;
    if (_fullHeard.isEmpty) {
      if (!_engineWarm && _staleSignals < maxStaleSignals) {
        // Chưa qua giai đoạn 'ấm máy' và chưa nghe được gì: đây là tín hiệu muộn của phiên trước, KHÔNG phải im lặng thật.
        _staleSignals++;
        unawaited(
          Future<void>.delayed(
            const Duration(milliseconds: 300),
            () => _startEngine(id, forConfirm),
          ),
        );
        return;
      }
      _endTurn(id, forConfirm); // không có tiếng -> đường "im lặng"
      return;
    }
    if (_restarts >= maxEngineRestarts) {
      _endTurn(id, forConfirm);
      return;
    }
    _restarts++;
    // Chữ đang dở (chưa chốt) được giữ lại để không mất khi mở lại.
    _committed = _fullHeard;
    _heard = '';
    unawaited(
      Future<void>.delayed(
        const Duration(milliseconds: 120),
        () => _startEngine(id, forConfirm),
      ),
    );
  }

  void _armSendTimer(int id, bool forConfirm) {
    _sendTimer?.cancel();
    _warmTimer?.cancel();
    final delay = forConfirm
        ? confirmDelay
        : (looksIncomplete(_fullHeard) ? sendDelayIncomplete : sendDelay);
    _sendTimer = Timer(delay, () => _endTurn(id, forConfirm));
  }

  /// Lỗi không thể tự hết bằng cách thử lại (thiếu quyền micro, dịch vụ/ngôn ngữ không hỗ trợ).
  static bool _isFatalSpeechError(String message) {
    final m = message.toLowerCase();
    return m.contains('permission') ||
        m.contains('not-allowed') ||
        m.contains('not_allowed') ||
        m.contains('service-not-allowed') ||
        m.contains('language-not-supported') ||
        m.contains('insufficient');
  }

  static bool _isSoftSpeechError(String message) {
    final m = message.toLowerCase();
    return m.contains('no_match') ||
        m.contains('no-match') ||
        m.contains('no match') ||
        m.contains('no-speech') ||
        m.contains('no_speech') ||
        m.contains('speech_timeout') ||
        m.contains('timeout') ||
        m.contains('aborted');
  }

  /// Kết thúc lượt nói: gửi (hoặc xử lý xác nhận) với toàn bộ chữ đã gom.
  void _endTurn(int id, bool forConfirm) {
    if (id != _turnId || _turnDone) return;
    _turnDone = true;
    _noSpeechTimer?.cancel();
    _sendTimer?.cancel();
    _warmTimer?.cancel();
    _sendTimer?.cancel();
    _warmTimer?.cancel();
    listening = false;
    final text = _fullHeard.trim();
    _heard = '';
    _committed = '';
    unawaited(_speech?.stop());
    notifyListeners();
    final epoch = _voiceEpoch;
    if (text.isEmpty) {
      unawaited(_onSilence(forConfirm, epoch));
      return;
    }
    _silentTurns = 0;
    _onTranscript?.call(''); // xoá bản chép tạm trong ô nhập: câu đã được gửi
    unawaited(
      forConfirm ? _handleDecision(text, epoch) : send(text, fromVoice: true),
    );
    if (live && !forConfirm) {
      // Live: gửi xong là nghe tiếp ngay, không chờ AI xử lý — nói thêm lúc này sẽ được gộp vào cùng ngữ cảnh.
      unawaited(
        Future<void>.microtask(() {
          // Không mở mic nếu AI đã trả lời xong và đang đọc (khi đó _afterDrive sẽ mở lại sau khi đọc xong).
          if (epoch == _voiceEpoch && live && !listening && !speaking && !_disposed) {
            return _listenTurn();
          }
        }),
      );
    }
  }

  /// Người dùng bấm mic khi đang nghe: coi như nói xong, gửi ngay những gì đã nói (không chờ im lặng).
  void finishListeningNow() {
    if (!listening || _turnDone) return;
    _endTurn(_turnId, confirmingByVoice);
  }

  Future<void> _onSilence(bool forConfirm, int epoch) async {
    if (epoch != _voiceEpoch) return;
    if (forConfirm) {
      await _confirmUnclear(epoch);
      return;
    }
    if (live && sending) {
      await _listenTurn(); // AI còn đang xử lý: chờ tiếp, không tính là im lặng
      return;
    }
    _silentTurns++;
    if (live && _silentTurns < maxSilentTurns) {
      await _listenTurn();
    } else if (live) {
      await stopLive(); // im lặng quá lâu: tự thoát, không treo micro
    }
  }

  Future<void> _handleDecision(String heard, int epoch) async {
    if (epoch != _voiceEpoch) return;
    switch (parseVoiceDecision(heard)) {
      case VoiceDecision.confirm:
        confirmingByVoice = false;
        await confirmPending();
      case VoiceDecision.cancel:
        confirmingByVoice = false;
        await cancelPending();
      case VoiceDecision.unknown:
        await _confirmUnclear(epoch);
    }
  }

  Future<void> _confirmUnclear(int epoch) async {
    if (epoch != _voiceEpoch || pendingAction == null) return;
    _confirmRetries++;
    if (_confirmRetries >= maxConfirmRetries) {
      confirmingByVoice = false;
      notifyListeners();
      if (voiceReplies) {
        await _speak('Mình giữ nguyên thẻ, bạn bấm xác nhận hoặc huỷ nhé.');
      }
      if (live) await stopLive(); // thẻ vẫn còn, bấm tay được
      return;
    }
    if (voiceReplies) await _speak('Mình chưa nghe rõ. Nói xác nhận hoặc huỷ.');
    if (epoch != _voiceEpoch || pendingAction == null) return;
    await _listenTurn(forConfirm: true);
  }

  /// Sau mỗi lượt gọi AI: đọc tóm tắt (nếu lượt nhập là giọng nói) rồi nghe tiếp.
  Future<void> _afterDrive() async {
    final reply = _postReply;
    final wantsConfirm = _postConfirm;
    _postReply = null;
    _postConfirm = false;
    if (_speech == null || !(_lastInputWasVoice || live)) return;
    final epoch = _voiceEpoch;

    // Mic có thể đang mở để nghe thêm yêu cầu trong lúc AI xử lý (một lượt nói thường, không phải lượt xác nhận).
    final openTurn = listening && !confirmingByVoice;
    final userIsTalking = openTurn && _fullHeard.isNotEmpty;

    final action = pendingAction;
    if (wantsConfirm && action != null) {
      if (userIsTalking) {
        // Người dùng đang nói dở: chốt câu đó ngay (nếu là "xác nhận"/"huỷ" thì hiểu là quyết định, còn lại xếp hàng).
        _endTurn(_turnId, false);
        await Future<void>.delayed(Duration.zero);
        if (pendingAction == null) return;
      } else if (openTurn) {
        await _haltListen(); // đóng mic trước khi đọc để không thu lại giọng máy
      }
      if (voiceReplies) await _speak(confirmPrompt(action));
      if (epoch != _voiceEpoch || _disposed || pendingAction == null) return;
      _confirmRetries = 0;
      await _listenTurn(forConfirm: true);
      return;
    }

    if (userIsTalking) {
      // Không nói đè lên người đang nói. Câu trả lời đã hiện trong chat; câu họ đang nói sẽ được gộp vào ngữ cảnh.
      return;
    }
    if (reply != null && reply.isNotEmpty && voiceReplies) {
      if (openTurn) await _haltListen(); // đóng mic trước khi đọc (tránh vang loa bị nhận nhầm)
      await _speak(spokenSummary(reply));
    }
    if (epoch != _voiceEpoch || _disposed) return;
    if (live && !listening) await _listenTurn();
  }

  Future<void> _speak(String text) async {
    final tts = _tts;
    if (tts == null || text.trim().isEmpty || _disposed) return;
    speaking = true;
    notifyListeners();
    try {
      await tts.speak(text);
      if (speechTail > Duration.zero && !_disposed) {
        await Future<void>.delayed(speechTail);
      }
    } finally {
      speaking = false;
      final problem = tts.takeError();
      if (problem != null) {
        voiceError = problem; // hiện cho người dùng (toast) thay vì im lặng
      }
      if (!_disposed) notifyListeners();
    }
  }

  // ── tiện ích ───────────────────────────────────────────────────────────────

  /// Xoá hội thoại (đổi tài khoản hoặc bấm "Cuộc trò chuyện mới").
  void reset() {
    _generation++;
    _voiceEpoch++;
    _turnId++;
    _turnDone = true;
    _noSpeechTimer?.cancel();
    _sendTimer?.cancel();
    _warmTimer?.cancel();
    unawaited(_tts?.stop());
    unawaited(_speech?.cancel());
    messages.clear();
    _history.clear();
    pendingAction = null;
    _pendingMessage = null;
    _pendingCall = null;
    _remainingCalls = const [];
    _postReply = null;
    _postConfirm = false;
    _queued.clear();
    _checkpoint = 0;
    _writing = false;
    sending = false;
    listening = false;
    speaking = false;
    live = false;
    confirmingByVoice = false;
    voiceError = null;
    _lastInputWasVoice = false;
    _retryable = false;
    _round = 0;
    notifyListeners();
  }

  void _add(AiMessage message) {
    messages.add(message);
    notifyListeners();
  }

  void _fail(String message) {
    _retryable = true;
    _add(
      AiMessage(
        id: _nextId++,
        role: AiMessageRole.assistant,
        text: message,
        isError: true,
      ),
    );
  }

  Map<String, dynamic> _bounded(Map<String, dynamic> result) {
    if (jsonEncode(result).length <= _maxToolResultChars) return result;
    return {
      'error': 'Kết quả quá lớn, hãy hỏi cụ thể hơn (một lớp hoặc một khoảng thời gian).',
      'code': 'TOO_LARGE',
    };
  }

  /// Giữ history dưới giới hạn của server bằng cách bỏ các lượt hỏi-đáp cũ nhất.
  void _trimHistory() {
    while (_history.length > _maxHistory) {
      final next = _history.indexWhere((m) => m['role'] == 'user', 1);
      if (next < 0) break;
      _history.removeRange(0, next);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _voiceEpoch++;
    _turnId++;
    _noSpeechTimer?.cancel();
    _sendTimer?.cancel();
    _warmTimer?.cancel();
    unawaited(_tts?.stop());
    unawaited(_speech?.cancel());
    super.dispose();
  }
}
