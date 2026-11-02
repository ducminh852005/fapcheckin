import 'package:fapcheckin_core/models/class_section_model.dart';
import 'package:fapcheckin_core/models/session_model.dart';
import 'package:fapcheckin/views/teacher/live_session/dialogs/start_session_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _cls = ClassSectionModel(
  classCode: 'PRN232_SE1917',
  subjectCode: 'PRN232',
  subjectName: 'End Application With .NET',
  room: '602',
  studentCount: 35,
  teacherMemberCode: 'T1',
  timeLabel: '',
  completedSessions: 0,
  totalSessions: 30,
  averageAttendance: 0,
  isActive: false,
);

Future<void> _open(WidgetTester tester, void Function(bool?) onResult) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async =>
                  onResult(await showStartSessionDialog(context, _cls)),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('IP check checkbox is off by default', (tester) async {
    bool? result;
    var done = false;
    await _open(tester, (value) {
      result = value;
      done = true;
    });

    final box = tester.widget<CheckboxListTile>(
      find.byKey(const Key('ip-check-toggle')),
    );
    expect(box.value, isFalse);

    await tester.tap(find.text('Mở phiên'));
    await tester.pumpAndSettle();
    expect(done, isTrue);
    expect(result, isFalse);
  });

  testWidgets('ticking the checkbox turns the IP check on', (tester) async {
    bool? result;
    await _open(tester, (value) => result = value);

    await tester.tap(find.byKey(const Key('ip-check-toggle')));
    await tester.pump();
    expect(
      tester
          .widget<CheckboxListTile>(find.byKey(const Key('ip-check-toggle')))
          .value,
      isTrue,
    );

    await tester.tap(find.text('Mở phiên'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('cancelling returns null so no session is opened', (
    tester,
  ) async {
    bool? result = true;
    var done = false;
    await _open(tester, (value) {
      result = value;
      done = true;
    });

    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(done, isTrue);
    expect(result, isNull);
  });

  test('SessionModel reads ipCheck and defaults to off', () {
    expect(
      SessionModel.fromJson({
        'session': {'sessionId': 's1', 'ipCheck': true},
        'qrToken': 'q',
      }).ipCheck,
      isTrue,
    );
    expect(
      SessionModel.fromJson({'sessionId': 's1', 'ipCheck': 'FALSE'}).ipCheck,
      isFalse,
    );
    expect(SessionModel.fromJson({'sessionId': 's1'}).ipCheck, isFalse);
    expect(
      SessionModel.fromJson({'sessionId': 's1', 'ipCheck': true})
          .copyWith(qrToken: 'new')
          .ipCheck,
      isTrue,
    );
  });
}
