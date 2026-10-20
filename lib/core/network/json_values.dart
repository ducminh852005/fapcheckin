/// Google Sheets can return the same scalar as a number or as text depending
/// on the cell format. Normalize these values at the API/model boundary.
String? jsonText(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();
  throw const FormatException('Expected a scalar text value');
}

num? jsonNumber(dynamic value) {
  if (value == null || value == '') return null;
  if (value is num) return value;
  if (value is String) {
    final parsed = num.tryParse(value.trim());
    if (parsed != null) return parsed;
  }
  throw const FormatException('Expected a numeric value');
}

bool? jsonBool(dynamic value) {
  if (value == null || value == '') return null;
  if (value is bool) return value;
  if (value == 1 || value == '1') return true;
  if (value == 0 || value == '0') return false;
  if (value is String) {
    if (value.trim().toLowerCase() == 'true') return true;
    if (value.trim().toLowerCase() == 'false') return false;
  }
  throw const FormatException('Expected a boolean value');
}

/// Normalizes and formats time ranges or raw GMT date strings into clean "HH:mm - HH:mm" or date strings.
String formatTimeLabel(dynamic value) {
  final raw = jsonText(value);
  if (raw == null || raw.trim().isEmpty) return 'Chưa rõ';

  String text = raw.trim();

  final is1899Date =
      text.contains('GMT') ||
      text.contains('Indochina') ||
      text.contains('1899');
  final timeMatches = RegExp(r'(\d{1,2}):(\d{2})(?::\d{2})?').allMatches(text);

  String norm(Match m) {
    final h = int.parse(m.group(1)!);
    final min = int.parse(m.group(2)!);
    int totalMins = h * 60 + min;
    if (is1899Date || (min % 15 == 6)) {
      totalMins = ((totalMins - 906) % 1440 + 1440) % 1440;
    }
    final normH = (totalMins ~/ 60).toString().padLeft(2, '0');
    final normMin = (totalMins % 60).toString().padLeft(2, '0');
    return '$normH:$normMin';
  }

  if (is1899Date) {
    if (timeMatches.length >= 2) {
      return '${norm(timeMatches.first)} - ${norm(timeMatches.elementAt(1))}';
    } else if (timeMatches.isNotEmpty) {
      return norm(timeMatches.first);
    }
  }

  if (timeMatches.length >= 2 && text.contains('-')) {
    return '${norm(timeMatches.first)} - ${norm(timeMatches.elementAt(1))}';
  } else if (timeMatches.length == 1) {
    return norm(timeMatches.first);
  }

  // Format any hh:mm:ss -> hh:mm fallback
  text = text.replaceAllMapped(
    RegExp(r'(\d{1,2}):(\d{2}):\d{2}'),
    (m) => norm(m),
  );

  // Remove trailing GMT / timezone strings if present
  text = text.replaceAll(RegExp(r'\s*GMT\+?\d*.*'), '').trim();
  text = text
      .replaceAll(RegExp(r'\(.*Time.*\)', caseSensitive: false), '')
      .trim();

  return text;
}
