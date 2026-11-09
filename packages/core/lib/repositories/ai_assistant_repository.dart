import 'package:cloud_functions/cloud_functions.dart';

import '../result/api_result.dart';
import '../result/guard.dart';

/// Một lời gọi tool do model đề xuất (ví dụ `find_student`, `mark_attendance`).
class AiToolCall {
  const AiToolCall({
    required this.name,
    this.args = const {},
    this.thoughtSignature,
  });

  final String name;
  final Map<String, dynamic> args;

  /// Chữ ký suy luận của Gemini — phải gửi lại nguyên vẹn trong history lượt sau.
  final String? thoughtSignature;

  factory AiToolCall.fromJson(Map<String, dynamic> json) => AiToolCall(
    name: json['name']?.toString() ?? '',
    args: json['args'] is Map
        ? Map<String, dynamic>.from(json['args'] as Map)
        : const {},
    thoughtSignature: json['thoughtSignature']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'args': args,
    if (thoughtSignature != null) 'thoughtSignature': thoughtSignature,
  };
}

/// Lượt trả lời của model: chữ (trả lời cuối) hoặc yêu cầu chạy tool.
class AiTurn {
  const AiTurn({this.text = '', this.calls = const []});

  final String text;
  final List<AiToolCall> calls;

  bool get hasToolCalls => calls.isNotEmpty;

  factory AiTurn.fromJson(Map<String, dynamic> json) {
    final calls = json['type'] == 'tool_calls'
        ? [
            for (final c in (json['calls'] as List? ?? const []))
              if (c is Map) AiToolCall.fromJson(Map<String, dynamic>.from(c)),
          ]
        : <AiToolCall>[];
    return AiTurn(text: json['text']?.toString() ?? '', calls: calls);
  }
}

/// Hội thoại gửi lên `aiAssistant` — định dạng history xem `firebase/functions/src/ai_assistant.js`.
abstract final class AiHistory {
  static Map<String, dynamic> user(String text) => {
    'role': 'user',
    'text': text,
  };

  static Map<String, dynamic> model(AiTurn turn) => {
    'role': 'model',
    if (turn.text.isNotEmpty) 'text': turn.text,
    if (turn.hasToolCalls)
      'toolCalls': [for (final c in turn.calls) c.toJson()],
  };

  static Map<String, dynamic> tool(String name, Map<String, dynamic> result) => {
    'role': 'tool',
    'name': name,
    'result': result,
  };
}

/// Gọi Cloud Function `aiAssistant` (Gemini function-calling). Function chỉ là proxy LLM:
/// việc đọc/ghi dữ liệu do app thực thi qua `AiToolExecutor` với quyền của giảng viên.
class AiAssistantRepository {
  AiAssistantRepository({FirebaseFunctions? functions})
    : _injectedFunctions = functions;

  final FirebaseFunctions? _injectedFunctions;

  FirebaseFunctions get _functions =>
      _injectedFunctions ??
      FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  Future<ApiResult<AiTurn>> chat(List<Map<String, dynamic>> history) =>
      guardApi(() async {
        final response = await _functions
            .httpsCallable(
              'aiAssistant',
              options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
            )
            .call({'history': history});
        final raw = response.data;
        if (raw is! Map) {
          throw ApiException(
            'INVALID_RESPONSE',
            'Trợ lý AI trả về dữ liệu không hợp lệ.',
          );
        }
        return AiTurn.fromJson(Map<String, dynamic>.from(raw));
      });
}
