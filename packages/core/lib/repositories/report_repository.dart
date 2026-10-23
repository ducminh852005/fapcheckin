import 'package:cloud_firestore/cloud_firestore.dart';

import '../firebase/firestore_json.dart';
import '../models/report_model.dart';
import '../result/api_result.dart';
import '../result/guard.dart';
import '../session/current_user.dart';
import 'internal/teacher_data.dart';

/// Tổng hợp báo cáo điểm danh cho dashboard giảng viên (port của ReportService.gs).
class ReportRepository {
  ReportRepository({
    required this.currentUser,
    FirebaseFirestore? firestore,
    DateTime Function()? now,
  }) : _injectedDb = firestore,
       _now = now ?? DateTime.now;

  final CurrentUser currentUser;
  final FirebaseFirestore? _injectedDb;

  /// Truy cập chậm để repository dựng được khi chưa khởi tạo Firebase (widget test);
  /// lỗi khi gọi sẽ được `guardApi` đổi thành `ApiFailure`.
  FirebaseFirestore get _db => _injectedDb ?? FirebaseFirestore.instance;
  final DateTime Function() _now;

  Future<ApiResult<ReportData>> getReport() => guardApi(() async {
    final tables = await TeacherTables.load(_db, currentUser.memberCode);
    return ReportData.fromJson(buildReport(tables, now: _now()));
  });

  /// Tách riêng (hàm thuần) để test không cần Firestore.
  static Json buildReport(TeacherTables tables, {required DateTime now}) {
    final classes = tables.classes;
    final ownedCodes = classes.map((c) => text(c['classCode'])).toSet();

    final sessions =
        tables.sessions.where((s) {
          final status = text(s['sessionStatus']);
          final target = status == 'closed' || status == 'open' || status == 'active' || status.isEmpty;
          return target && ownedCodes.contains(text(s['classCode']));
        }).toList()..sort(
          (a, b) => fmtDate(a['sessionDate']).compareTo(fmtDate(b['sessionDate'])),
        );
    final closedSessionCount = tables.sessions
        .where((s) => s['sessionStatus'] == 'closed' && ownedCodes.contains(text(s['classCode'])))
        .length;

    final recordMap = {
      for (final r in tables.records) '${text(r['sessionId'])}|${text(r['rollNumber'])}': r,
    };

    final studentsByClass = <String, List<Json>>{};
    for (final c in classes) {
      final code = text(c['classCode']);
      final seen = <String>{};
      studentsByClass[code] = [
        for (final e in tables.enrollments)
          if (text(e['classCode']) == code &&
              text(e['rollNumber']).isNotEmpty &&
              seen.add(text(e['rollNumber'])))
            {
              'rollNumber': text(e['rollNumber']),
              'fullName': text(e['fullName']),
              'email': text(e['email']),
            },
      ];
    }

    var presentCount = 0, lateCount = 0, expected = 0;
    final methods = {'qr': 0, 'other': 0, 'manual': 0};
    final warningMap = <String, Json>{};
    final classStats = <String, Map<String, int>>{};
    for (final c in classes) {
      final code = text(c['classCode']);
      classStats[code] = {'present': 0, 'late': 0, 'absent': 0, 'expected': 0};
      for (final student in studentsByClass[code]!) {
        warningMap['$code|${student['rollNumber']}'] = {
          'classCode': code,
          'subjectName': text(c['subjectName']),
          'rollNumber': student['rollNumber'],
          'fullName': student['fullName'],
          'email': student['email'],
          'absent': 0,
          'total': 0,
        };
      }
    }

    String statusOf(Json session, Json student) {
      final record = recordMap['${text(session['sessionId'])}|${student['rollNumber']}'];
      if (record != null && text(record['status']).isNotEmpty) return text(record['status']);
      return session['sessionStatus'] == 'closed' ? 'Absent' : 'Unchecked';
    }

    for (final session in sessions) {
      final code = text(session['classCode']);
      final stats = classStats[code]!;
      for (final student in studentsByClass[code]!) {
        final record = recordMap['${text(session['sessionId'])}|${student['rollNumber']}'];
        final status = statusOf(session, student);
        final warning = warningMap['$code|${student['rollNumber']}']!;
        if (status == 'Absent') {
          expected++;
          stats['expected'] = stats['expected']! + 1;
          warning['total'] = (warning['total'] as int) + 1;
          warning['absent'] = (warning['absent'] as int) + 1;
          stats['absent'] = stats['absent']! + 1;
        } else if (isPresentStatus(status)) {
          expected++;
          stats['expected'] = stats['expected']! + 1;
          warning['total'] = (warning['total'] as int) + 1;
          stats['present'] = stats['present']! + 1;
          presentCount++;
          if (status == 'Late') lateCount++;
          final network = text(record?['networkVerificationResult']);
          if (status == 'ManualByGV' || network == 'Manual') {
            methods['manual'] = methods['manual']! + 1;
          } else if (network == 'Match' || network == 'Skipped') {
            methods['qr'] = methods['qr']! + 1;
          } else {
            methods['other'] = methods['other']! + 1;
          }
        }
      }
    }

    final subjects = [
      for (final c in classes)
        () {
          final code = text(c['classCode']);
          final stat = classStats[code]!;
          final exp = stat['expected']!;
          return {
            'classCode': code,
            'subjectName': text(c['subjectName']),
            'attendanceRate': exp > 0 ? stat['present']! / exp : 0.0,
            'absentRate': exp > 0 ? stat['absent']! / exp : 0.0,
            'studentCount': studentsByClass[code]!.length,
          };
        }(),
    ];

    // Gom theo tuần tính từ buổi học đầu tiên.
    final weeks = <int, Map<String, dynamic>>{};
    if (sessions.isNotEmpty) {
      final first = DateTime.parse(fmtDate(sessions.first['sessionDate']));
      for (final session in sessions) {
        final date = DateTime.parse(fmtDate(session['sessionDate']));
        final week = date.difference(first).inDays ~/ 7 + 1;
        final bucket = weeks.putIfAbsent(
          week,
          () => {'label': 'W$week', 'present': 0, 'late': 0, 'absent': 0, 'total': 0},
        );
        for (final student in studentsByClass[text(session['classCode'])]!) {
          final status = statusOf(session, student);
          if (status == 'Absent') {
            bucket['total'] = bucket['total'] + 1;
            bucket['absent'] = bucket['absent'] + 1;
          } else if (isPresentStatus(status)) {
            bucket['total'] = bucket['total'] + 1;
            bucket['present'] = bucket['present'] + 1;
            if (status == 'Late') bucket['late'] = bucket['late'] + 1;
          }
        }
      }
    }

    final warnings =
        warningMap.values
            .map((item) {
              final total = item['total'] as int;
              final rate = total > 0 ? (item['absent'] as int) / total : 0.0;
              return {
                ...item,
                'absenceRate': rate,
                'status': rate > 0.2 ? 'Cần lưu ý' : 'Nguy cơ',
              };
            })
            .where((item) => (item['absenceRate'] as double) > 0.15)
            .toList()
          ..sort((a, b) => (b['absenceRate'] as double).compareTo(a['absenceRate'] as double));
    final topWarnings = warnings.take(50).toList();

    final methodTotal = methods.values.fold<int>(0, (a, b) => a + b);
    double rate(int n) => methodTotal > 0 ? n / methodTotal : 0.0;

    return {
      'generatedAt': now.toUtc().toIso8601String(),
      'kpis': {
        'attendanceRate': expected > 0 ? presentCount / expected : 0.0,
        'totalCheckins': presentCount,
        'atRiskCount': topWarnings.where((w) => (w['absenceRate'] as double) > 0.2).length,
        'studentCount': warningMap.length,
        'lateRate': expected > 0 ? lateCount / expected : 0.0,
      },
      'methods': [
        {'key': 'qr', 'label': 'Điểm danh QR', 'count': methods['qr'], 'rate': rate(methods['qr']!)},
        {'key': 'other', 'label': 'Khác / chưa xác định', 'count': methods['other'], 'rate': rate(methods['other']!)},
        {'key': 'manual', 'label': 'GV xác nhận thủ công', 'count': methods['manual'], 'rate': rate(methods['manual']!)},
      ],
      'weekly': [
        for (final k in (weeks.keys.toList()..sort()))
          () {
            final w = weeks[k]!;
            final total = w['total'] as int;
            return {
              'label': w['label'],
              'presentRate': total > 0 ? w['present'] / total : 0.0,
              'lateRate': total > 0 ? w['late'] / total : 0.0,
              'absentRate': total > 0 ? w['absent'] / total : 0.0,
            };
          }(),
      ],
      'subjects': subjects,
      'warnings': topWarnings,
      'classCount': classes.length,
      'closedSessionCount': closedSessionCount,
      'semester': _semesterLabel(classes, sessions, now),
    };
  }

  static String _semesterLabel(List<Json> classes, List<Json> sessions, DateTime now) {
    for (final source in [...classes, ...sessions]) {
      final value = source['semester'] ?? source['semesterName'] ?? source['term'];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    final dated = sessions.where((s) => text(s['sessionDate']).isNotEmpty).toList()
      ..sort((a, b) => fmtDate(b['sessionDate']).compareTo(fmtDate(a['sessionDate'])));
    if (dated.isEmpty) return 'Fall ${now.year}';
    final date = DateTime.parse(fmtDate(dated.first['sessionDate']));
    final season = date.month <= 5 ? 'Spring' : (date.month <= 8 ? 'Summer' : 'Fall');
    return '$season ${date.year}';
  }
}
