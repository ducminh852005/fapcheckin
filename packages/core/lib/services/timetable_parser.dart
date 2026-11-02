import '../models/timetable_scan_model.dart';

String _code(Object? value) =>
    (value ?? '').toString().toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');

class ParsedTimetable {
  const ParsedTimetable(this.entries, this.dates);
  final List<Map<String, String>> entries;
  final List<String> dates;
}

/// Extract class/subject pairs; dates are informational, never imported as schedules.
ParsedTimetable parseTimetable(String text) {
  final source = text
      .toUpperCase()
      .replaceAll(RegExp('[–—−_]'), '-')
      .replaceAllMapped(
        RegExp(r'\b([A-Z]{2,5}) +([0-9]{3,5})\b'),
        (m) => '${m[1]}${m[2]}',
      );
  final entries = <Map<String, String>>[];
  final seen = <String>{};
  final pair = RegExp(
    r'\b([A-Z]{2,4}\d{3,5})(?:\s*-\s*|\s+)([A-Z]{2,5}\d{3})\b',
  );
  for (final match in pair.allMatches(source)) {
    final key = '${match[1]}|${match[2]}';
    if (!seen.add(key)) continue;
    final tail = source.substring(match.end);
    final room = RegExp(
      r'^\s+AT\s+[A-Z]{2,8}(?:\s*-)?\s*(\d{3,4}|[A-Z]\d{2,4})\b',
    ).firstMatch(tail);
    entries.add({
      'key': key,
      'classCode': match[1]!,
      'subjectCode': match[2]!,
      'room': room?[1] ?? '',
    });
  }
  final dates = <String>{};
  for (final m in RegExp(
    r'\b(\d{1,2})[/-](\d{1,2})(?:[/-](\d{2,4}))?\b',
  ).allMatches(source)) {
    final day = int.parse(m[1]!);
    final month = int.parse(m[2]!);
    final year = m[3] == null ? 2000 : int.parse(m[3]!);
    if (month < 1 ||
        month > 12 ||
        day < 1 ||
        DateTime(year, month, day).month != month) {
      continue;
    }
    dates.add(
      '${m[1]!.padLeft(2, '0')}/${m[2]!.padLeft(2, '0')}${m[3] == null ? '' : '/${m[3]}'}',
    );
  }
  return ParsedTimetable(entries, dates.toList());
}

String _subject(Map<String, dynamic> row) {
  if (_code(row['subjectCode']).isNotEmpty) return _code(row['subjectCode']);
  final parts = '${row['classCode'] ?? ''}'.toUpperCase().split(
    RegExp('[^A-Z0-9]+'),
  );
  for (final part in parts) {
    if (RegExp(r'^[A-Z]{2,5}\d{3}$').hasMatch(part)) return part;
  }
  return RegExp(r'^([A-Z]{2,5}\d{3})\b')
          .firstMatch('${row['subjectName'] ?? ''}'.toUpperCase())?[1] ??
      '';
}

List<TimetableScanEntry> matchTimetable(
  ParsedTimetable parsed,
  List<Map<String, dynamic>> classes,
  String memberCode,
) {
  return parsed.entries.map((entry) {
    final group = _code(entry['classCode']);
    final subject = _code(entry['subjectCode']);
    final matches = classes
        .where(
          (row) =>
              {
                group,
                '$group$subject',
                '$subject$group',
              }.contains(_code(row['classCode'])) &&
              _subject(row) == subject,
        )
        .toList();
    var status = 'notFound';
    var message = 'Không khớp lớp trong danh sách bạn được phép nhận. Nhờ quản trị viên kiểm tra mã lớp, mã môn và phân công.';
    String? matched;
    if (matches.length > 1) {
      status = 'ambiguous';
      message = 'Có nhiều lớp trùng mã; cần kiểm tra dữ liệu.';
    } else if (matches.length == 1) {
      matched = '${matches.single['documentId'] ?? matches.single['classCode']}';
      final owner = '${matches.single['teacherMemberCode'] ?? ''}'.trim();
      status = owner.isEmpty
          ? 'available'
          : owner == memberCode
          ? 'alreadyAssigned'
          : 'conflict';
      message = switch (status) {
        'available' => 'Sẵn sàng thêm vào lớp.',
        'alreadyAssigned' => 'Bạn đã được phân công lớp này.',
        _ => 'Lớp đã được phân công cho giảng viên khác.',
      };
    }
    return TimetableScanEntry(
      key: entry['key']!,
      classCode: entry['classCode']!,
      subjectCode: entry['subjectCode']!,
      room: entry['room']!,
      matchedClassCode: matched,
      status: status,
      message: message,
    );
  }).toList();
}
