import 'package:cloud_firestore/cloud_firestore.dart';

import '../session/current_user.dart';

/// Audience-filtered query required by Firestore security rules.
class AnnouncementRepository {
  AnnouncementRepository({
    required this.currentUser,
    FirebaseFirestore? firestore,
  }) : _injectedDb = firestore;
  final CurrentUser currentUser;
  final FirebaseFirestore? _injectedDb;

  Stream<List<Map<String, dynamic>>> watch() {
    final user = currentUser.requireUser;
    Query<Map<String, dynamic>> query =
        (_injectedDb ?? FirebaseFirestore.instance).collection('announcements');
    if (user.role != 'admin') {
      query = query.where('audience', whereIn: ['all', user.role]);
    }
    return query.snapshots().map((snapshot) {
      final rows = snapshot.docs
          .map((d) => <String, dynamic>{...d.data(), 'id': d.id})
          .toList();
      rows.sort((a, b) {
        final aTime = a['createdAt'];
        final bTime = b['createdAt'];
        return (bTime is Timestamp ? bTime.millisecondsSinceEpoch : 0)
            .compareTo(aTime is Timestamp ? aTime.millisecondsSinceEpoch : 0);
      });
      return rows;
    });
  }
}
