import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fapcheckin/core/services/timetable_ocr_service.dart';
import 'package:fapcheckin_core/services/timetable_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('parser normalizes spaced codes, deduplicates and validates dates', () {
    final result = parseTimetable(
      'SE 1917–PRN 232 at NVH 301\nSE1917-PRN232\n31/02/2026 31/10/2026',
    );
    expect(result.entries.length, 1);
    expect(result.entries.single['room'], '301');
    expect(result.dates, ['31/10/2026']);
    expect(parseTimetable('nothing here').entries, isEmpty);
  });
  test('matching protects ambiguous and already assigned classes', () {
    final parsed = parseTimetable('SE1917-PRN232');
    Map<String, dynamic> row(String owner) => {
      'classCode': 'SE1917-PRN232',
      'subjectCode': 'PRN232',
      'teacherMemberCode': owner,
    };
    expect(matchTimetable(parsed, [row('')], 'GV1').single.canImport, isTrue);
    expect(
      matchTimetable(parsed, [row('GV1')], 'GV1').single.status,
      'alreadyAssigned',
    );
    expect(
      matchTimetable(parsed, [row('GV2')], 'GV1').single.canImport,
      isFalse,
    );
    expect(
      matchTimetable(parsed, [row(''), row('')], 'GV1').single.status,
      'ambiguous',
    );
    expect(matchTimetable(parsed, [], 'GV1').single.status, 'notFound');
  });
  test('matching keeps document identity separate from displayed class code', () {
    final result = matchTimetable(parseTimetable('SE1917-PRN232'), [
      {
        'documentId': 'internal-id',
        'classCode': 'PRN232_SE1917',
        'subjectCode': 'PRN232',
        'teacherMemberCode': '',
      },
    ], 'GV1').single;
    expect(result.canImport, isTrue);
    expect(result.matchedClassCode, 'internal-id');
    expect(matchTimetable(parseTimetable('SE1917-PRM393'), [
      {'classCode': 'PRN232_SE1917', 'subjectCode': 'PRN232', 'teacherMemberCode': ''},
    ], 'GV1').single.canImport, isFalse);
  });
  test('Android bridge passes bytes and returns recognized text', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(TimetableOcrService.channel, (
      call,
    ) async {
      expect(call.method, 'recognize');
      expect(call.arguments['bytes'], [1, 2, 3]);
      return 'SE1917-PRN232';
    });
    addTearDown(
      () =>
          messenger.setMockMethodCallHandler(TimetableOcrService.channel, null),
    );
    expect(
      await TimetableOcrService().recognize(Uint8List.fromList([1, 2, 3])),
      'SE1917-PRN232',
    );
    messenger.setMockMethodCallHandler(TimetableOcrService.channel, (_) async {
      throw PlatformException(code: 'INVALID_IMAGE', message: 'Invalid image');
    });
    await expectLater(
      TimetableOcrService().recognize(Uint8List(0)),
      throwsA(anything),
    );
  });
}
