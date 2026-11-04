import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fapcheckin_core/repositories/request_repository.dart';
import 'package:fapcheckin_core/result/api_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sessionOptions returns only sessions for the selected teacher class', () async {
    final db = FakeFirebaseFirestore();
    await db.collection('sessions').doc('session-new').set({
      'teacherMemberCode': 'GV001',
      'classCode': 'PRM393_SE1917',
      'sessionDate': '2026-11-03',
      'slotCode': 'A02',
      'sessionStatus': 'open',
      'createdAt': Timestamp.fromDate(DateTime.utc(2026, 11, 3)),
    });
    await db.collection('sessions').doc('session-old').set({
      'teacherMemberCode': 'GV001',
      'classCode': 'PRM393_SE1917',
      'sessionDate': '2026-10-27',
      'slotCode': 'A02',
      'sessionStatus': 'closed',
      'createdAt': Timestamp.fromDate(DateTime.utc(2026, 10, 27)),
    });
    await db.collection('sessions').doc('other-class').set({
      'teacherMemberCode': 'GV001',
      'classCode': 'OTHER_CLASS',
      'sessionDate': '2026-11-03',
    });
    await db.collection('sessions').doc('other-teacher').set({
      'teacherMemberCode': 'GV002',
      'classCode': 'PRM393_SE1917',
      'sessionDate': '2026-11-03',
    });

    final repository = RequestRepository(
      uid: 'u-t1',
      memberCode: 'GV001',
      firestore: db,
    );
    final result = await repository.sessionOptions('PRM393_SE1917');

    expect(result, isA<ApiSuccess<List<Map<String, dynamic>>>>());
    final rows = (result as ApiSuccess<List<Map<String, dynamic>>>).data;
    expect(rows.map((row) => row['sessionId']), ['session-new', 'session-old']);
    expect(rows.first['sessionDate'], '2026-11-03');
    expect(rows.first['slotCode'], 'A02');
    expect(rows.first['sessionStatus'], 'open');
  });
}
