// ignore_for_file: prefer_initializing_formals
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:fapcheckin_core/ai/ai_tool_executor.dart';
import 'package:fapcheckin_core/repositories/ai_assistant_repository.dart';
import 'package:fapcheckin_core/result/api_result.dart';

import '../core/services/speech_service.dart';

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
/// Tool đọc chạy ngay; tool ghi dừng ở [pendingAction] cho tới khi giảng viên xác nhận/huỷ.
class AiChatViewModel extends ChangeNotifier {
  AiChatViewModel({
    required this.repository,
    required this.executor,
    SpeechService? speech,
  }) : _speech = speech;

  final AiAssistantRepository repository;
  final AiToolExecutor executor;
  final SpeechService? _speech;

  /// Số vòng model↔tool tối đa cho một câu hỏi (chặn vòng lặp vô hạn).
  static const maxRounds = 6;
  static const _maxHistory = 26;
  static const _maxToolResultChars = 20000;

  final List<AiMessage> messages = [];
  final List<Map<String, dynamic>> _history = [];
  int _nextId = 0;
  bool _disposed = false;
  int _generation = 0;

  bool sending = false;
  bool listening = false;
  String? voiceError;

  // Trạng thái dở dang khi chờ xác nhận.
  AiPendingAction? pendingAction;
  AiMessage? _pendingMessage;
  AiToolCall? _pendingCall;
  List<AiToolCall> _remainingCalls = const [];
  int _round = 0;

  /// Câu trả lời lỗi gần nhất có thể thử lại.
  bool get canRetry => !sending && pendingAction == null && _retryable;
  bool _retryable = false;

  bool get busy => sending || pendingAction != null;

  // ── gửi tin ────────────────────────────────────────────────────────────────

  Future<void> send(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || busy) return;
    if (listening) await stopListening();
    _retryable = false;
    _add(AiMessage(id: _nextId++, role: AiMessageRole.user, text: text));
    _history.add(AiHistory.user(text));
    _round = 0;
    await _drive();
  }

  Future<void> retry() async {
    if (!canRetry) return;
    _retryable = false;
    // Bỏ bong bóng lỗi cuối rồi gọi lại với cùng history.
    if (messages.isNotEmpty && messages.last.isError) messages.removeLast();
    _round = 0;
    await _drive();
  }

  Future<void> _drive() async {
    final generation = _generation;
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
            _history.add(AiHistory.model(data));
            if (data.text.isNotEmpty) {
              _add(AiMessage(id: _nextId++, role: AiMessageRole.assistant, text: data.text));
            }
            if (!data.hasToolCalls) return;
            final paused = await _runCalls(data.calls, generation);
            if (paused || _disposed || generation != _generation) return;
          case ApiFailure<AiTurn>(:final error):
            _fail(error.message);
            return;
          default:
            _fail('Không nhận được phản hồi từ trợ lý AI.');
            return;
        }
      }
      _add(AiMessage(
        id: _nextId++,
        role: AiMessageRole.assistant,
        text: 'Mình chưa hoàn tất được yêu cầu này. Bạn thử diễn đạt cụ thể hơn nhé.',
      ));
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
    if (action == null || call == null || message == null || sending) return false;
    final generation = _generation;
    sending = true;
    notifyListeners();
    final result = await executor.confirm(action);
    if (_disposed || generation != _generation) return false;
    final ok = result['ok'] == true;
    message.actionState = ok ? AiActionState.confirmed : AiActionState.failed;
    await _resumeAfterAction(call, result, generation);
    return ok;
  }

  Future<void> cancelPending() async {
    final call = _pendingCall;
    final message = _pendingMessage;
    if (pendingAction == null || call == null || message == null || sending) return;
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
    _history.add(AiHistory.tool(call.name, _bounded(result)));
    if (remaining.isNotEmpty) {
      final paused = await _runCalls(remaining, generation);
      if (paused || _disposed || generation != _generation) {
        sending = false;
        notifyListeners();
        return;
      }
    }
    sending = false;
    _round = 0;
    await _drive();
  }

  // ── giọng nói ──────────────────────────────────────────────────────────────

  bool get voiceSupported => _speech != null;

  /// Bật/tắt micro. [onTranscript] nhận bản chép tạm thời để hiện vào ô nhập.
  /// Trả `false` nếu không dùng được micro (xem [voiceError]).
  Future<bool> toggleListening(void Function(String text) onTranscript) async {
    final speech = _speech;
    if (speech == null || busy) return false;
    if (listening) {
      await stopListening();
      return true;
    }
    voiceError = null;
    final ready = await speech.initialize();
    if (_disposed) return false;
    if (!ready) {
      voiceError =
          'Không dùng được micro. Hãy cấp quyền micro/nhận dạng giọng nói cho ứng dụng rồi thử lại.';
      notifyListeners();
      return false;
    }
    listening = true;
    notifyListeners();
    await speech.start(
      onResult: (text, isFinal) {
        if (!_disposed) onTranscript(text);
      },
      onError: (message) {
        voiceError = 'Lỗi nhận dạng giọng nói: $message';
        listening = false;
        if (!_disposed) notifyListeners();
      },
      onDone: () {
        if (listening) {
          listening = false;
          if (!_disposed) notifyListeners();
        }
      },
    );
    return true;
  }

  Future<void> stopListening() async {
    final speech = _speech;
    if (speech == null || !listening) return;
    listening = false;
    notifyListeners();
    await speech.stop();
  }

  // ── tiện ích ───────────────────────────────────────────────────────────────

  /// Xoá hội thoại (đổi tài khoản hoặc bấm "Cuộc trò chuyện mới").
  void reset() {
    _generation++;
    _speech?.cancel();
    messages.clear();
    _history.clear();
    pendingAction = null;
    _pendingMessage = null;
    _pendingCall = null;
    _remainingCalls = const [];
    sending = false;
    listening = false;
    voiceError = null;
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
    _add(AiMessage(
      id: _nextId++,
      role: AiMessageRole.assistant,
      text: message,
      isError: true,
    ));
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
    _speech?.cancel();
    super.dispose();
  }
}
