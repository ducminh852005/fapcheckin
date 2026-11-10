import 'package:fapcheckin_core/ai/ai_tool_executor.dart';

/// Hàm thuần phục vụ trợ lý giọng nói: chuẩn bị chữ để ĐỌC (khác với chữ hiển thị đầy đủ trong chat)
/// và hiểu câu trả lời xác nhận bằng giọng nói.

const _foldGroups = {
  'a': 'àáạảãâầấậẩẫăằắặẳẵ',
  'e': 'èéẹẻẽêềếệểễ',
  'i': 'ìíịỉĩ',
  'o': 'òóọỏõôồốộổỗơờớợởỡ',
  'u': 'ùúụủũưừứựửữ',
  'y': 'ỳýỵỷỹ',
  'd': 'đ',
};
final Map<String, String> _foldMap = {
  for (final e in _foldGroups.entries)
    for (final ch in e.value.split('')) ch: e.key,
};

/// Chữ thường, bỏ dấu tiếng Việt, bỏ dấu câu, gộp khoảng trắng.
String foldVietnamese(String input) {
  final b = StringBuffer();
  for (final ch in input.toLowerCase().split('')) {
    b.write(_foldMap[ch] ?? ch);
  }
  return b
      .toString()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

final _emoji = RegExp(
  '[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}]',
  unicode: true,
);

/// Phần TÓM TẮT để đọc to: đoạn đầu (trước dòng trống) hoặc tối đa 2 câu, bỏ ký hiệu markdown/emoji,
/// cắt ≤ [maxChars]. Chi tiết đầy đủ vẫn nằm trong khung chat.
String spokenSummary(String text, {int maxChars = 240}) {
  var t = text.replaceAll('**', '').replaceAll(RegExp(r'[`#_]'), '').replaceAll(_emoji, '');
  final paragraphs = t.split(RegExp(r'\n\s*\n')).map((p) => p.trim()).where((p) => p.isNotEmpty);
  if (paragraphs.isEmpty) return '';
  // Đoạn đầu: các gạch đầu dòng nối thành một câu liền mạch.
  var first = paragraphs.first
      .split('\n')
      .map((l) => l.replaceFirst(RegExp(r'^\s*[*\-•]\s+'), '').trim())
      .where((l) => l.isNotEmpty)
      .join(', ');
  final sentences = first.split(RegExp(r'(?<=[.!?])\s+'));
  first = sentences.take(2).join(' ');
  if (first.length > maxChars) {
    final cut = first.substring(0, maxChars);
    final space = cut.lastIndexOf(' ');
    first = '${space > maxChars ~/ 2 ? cut.substring(0, space) : cut}…';
  }
  return first.trim();
}

String _statusPhrase(String status) => switch (status) {
  'Late' => 'đi muộn',
  'Absent' => 'vắng',
  'Unchecked' => 'chưa điểm danh',
  _ => 'có mặt',
};

/// Lời đọc khi hiện thẻ xác nhận điểm danh.
String confirmPrompt(AiPendingAction action, {int maxNames = 3}) {
  final parts = [
    for (final s in action.students.take(maxNames))
      '${s.fullName}, MSSV ${s.rollNumber}, ${_statusPhrase(s.status)}',
  ];
  final more = action.students.length - parts.length;
  final list = parts.join('; ');
  return 'Điểm danh ${action.students.length} sinh viên lớp ${action.classCode}, slot ${action.slotCode}: '
      '$list${more > 0 ? ' và $more bạn khác' : ''}. Nói xác nhận hoặc huỷ.';
}

enum VoiceDecision { confirm, cancel, unknown }

const _cancelWords = {'huy', 'thoi', 'bo', 'khong'};
const _cancelPhrases = ['dung lai', 'bo qua'];
const _confirmPhrases = ['xac nhan', 'dong y', 'lam di', 'ghi di', 'chot', 'dung roi', 'ok', 'okay', 'duoc roi', 'duoc'];

/// Hiểu câu nói trong bước xác nhận. Huỷ ưu tiên hơn xác nhận (an toàn khi câu mơ hồ).
VoiceDecision parseVoiceDecision(String heard) {
  final t = foldVietnamese(heard);
  if (t.isEmpty) return VoiceDecision.unknown;
  if (t.contains('khong sao')) return VoiceDecision.unknown;
  final words = t.split(' ').toSet();
  if (words.any(_cancelWords.contains) || _cancelPhrases.any((p) => ' $t '.contains(' $p '))) {
    return VoiceDecision.cancel;
  }
  if (_confirmPhrases.any((p) => ' $t '.contains(' $p '))) return VoiceDecision.confirm;
  return VoiceDecision.unknown;
}

/// Câu đang nói có vẻ CHƯA TRỌN (kết thúc bằng từ nối/từ chờ danh từ như "lớp", "và", "slot", "MSSV"...)?
/// Khi đó chờ im lặng lâu hơn trước khi tự gửi để không cắt ngang câu.
bool looksIncomplete(String heard) {
  final t = foldVietnamese(heard);
  if (t.isEmpty) return false;
  if (RegExp(r'[,;:]\s*$').hasMatch(heard.trim())) return true;
  const tails = [
    'va', 'voi', 'cua', 'cho', 'la', 'o', 'trong', 'ma', 'hoac', 'nhung', 'thi', 'de',
    'lop', 'slot', 'mon', 'mssv', 'ma so', 'sinh vien', 'ngay', 'buoi', 'tiet', 'ca',
    'diem danh', 'bao cao', 'thong ke', 'tu', 'den',
  ];
  return tails.any((w) => t == w || t.endsWith(' $w'));
}
