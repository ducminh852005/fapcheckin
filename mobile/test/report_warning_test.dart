import 'package:fapcheckin/views/teacher/report/components/warning_table.dart';
import 'package:fapcheckin_core/models/report_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(ReportData data) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: WarningTable(data: data))),
);

Map<String, dynamic> _warning(String roll, String name, double rate) => {
  'classCode': 'REAL_CLASS',
  'subjectName': 'Course',
  'rollNumber': roll,
  'fullName': name,
  'email': '$roll@example.test',
  'absent': 3,
  'total': 10,
  'absenceRate': rate,
  'status': rate > 0.2 ? 'Cần lưu ý' : 'Nguy cơ',
};

void main() {
  testWidgets('warning table lists students from the report data', (
    tester,
  ) async {
    final data = ReportData.fromJson({
      'warnings': [
        _warning('TEST001', 'Student from report', 0.3),
        _warning('TEST002', 'Another student', 0.18),
      ],
    });
    await tester.pumpWidget(_host(data));
    await tester.pumpAndSettle();

    expect(find.text('Student from report'), findsOneWidget);
    expect(find.text('Another student'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('warning table shows no student rows without warnings', (
    tester,
  ) async {
    await tester.pumpWidget(_host(ReportData.fromJson({})));
    await tester.pumpAndSettle();

    expect(find.text('Student from report'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
