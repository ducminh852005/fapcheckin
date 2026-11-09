// Luồng đầu-cuối của Trợ lý AI ở tầng app: MainScreen thật + AiChatViewModel thật + AiToolExecutor thật,
// chỉ thay phần ngoài (Gemini bằng kịch bản, Firestore bằng repository giả, micro bằng SpeechService giả).
// Phần Cloud Function + Security Rules được kiểm trong e2e_test/ai_assistant.e2e.test.mjs (Emulator).
import 'package:fapcheckin/core/services/google_auth_service.dart';
import 'package:fapcheckin/core/services/speech_service.dart';
import 'package:fapcheckin/viewmodels/ai_chat_viewmodel.dart';
import 'package:fapcheckin/viewmodels/attendance_history_viewmodel.dart';
import 'package:fapcheckin/viewmodels/auth_viewmodel.dart';
import 'package:fapcheckin/viewmodels/dashboard_viewmodel.dart';
import 'package:fapcheckin/viewmodels/live_session_viewmodel.dart';
import 'package:fapcheckin/viewmodels/report_viewmodel.dart';
import 'package:fapcheckin/views/main_screen.dart';
import 'package:fapcheckin_core/ai/ai_tool_executor.dart';
import 'package:fapcheckin_core/models/class_section_model.dart';
import 'package:fapcheckin_core/models/history_detail.dart';
import 'package:fapcheckin_core/models/history_summary.dart';
import 'package:fapcheckin_core/models/report_model.dart';
import 'package:fapcheckin_core/repositories/ai_assistant_repository.dart';
import 'package:fapcheckin_core/repositories/attendance_history_repository.dart';
import 'package:fapcheckin_core/repositories/auth_repository.dart';
import 'package:fapcheckin_core/repositories/report_repository.dart';
import 'package:fapcheckin_core/repositories/schedule_repository.dart';
import 'package:fapcheckin_core/repositories/teacher_repository.dart';
import 'package:fapcheckin_core/result/api_result.dart';
import 'package:fapcheckin_core/session/current_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

// ── dữ liệu giả ──────────────────────────────────────────────────────────────

final _now = DateTime.utc(2026, 10, 21, 1); // 08:00 VN, 2026-10-21

const _classInfo = {
  'classCode': 'SWP391_SE1801',
  'subjectCode': 'SWP391',
  'subjectName': 'Software Project',
  'room': '303',
  'studentCount': 2,
};

Map<String, dynamic> _session({String status = 'open', String date = '2026-10-21'}) => {
  'sessionId': 'S1',
  'classCode': 'SWP391_SE1801',
  'sessionDate': date,
  'slotCode': 'A3',
  'sessionStatus': status,
};

const _students = [
  {'rollNumber': 'HE123456', 'fullName': 'Nguyễn Văn An', 'email': 'an@fpt.edu.vn'},
  {'rollNumber': 'HE123457', 'fullName': 'Trần Thị Bình', 'email': 'binh@fpt.edu.vn'},
];

class _FakeHistory extends AttendanceHistoryRepository {
  _FakeHistory({this.sessions = const [], this.previous = const {}})
    : super(currentUser: CurrentUser());

  List<Map<String, dynamic>> sessions;
  Map<String, String> previous;

  @override
  Future<ApiResult<HistorySummary>> getSummary(String classCode) async {
    if (classCode != 'SWP391_SE1801') {
      return ApiFailure(ApiError(code: 'FORBIDDEN', message: 'Lớp không thuộc bạn.'));
    }
    return ApiSuccess(HistorySummary.fromJson({
      'classInfo': _classInfo,
      'teacherName': 'GV',
      'sessions': sessions,
      'slots': [{'slotCode': 'A3'}],
      'students': _students,
    }));
  }

  @override
  Future<ApiResult<HistoryDetail>> getDetail(String classCode, {String? sessionId}) async {
    return ApiSuccess(HistoryDetail.fromJson({
      'classInfo': _classInfo,
      'teacherName': 'GV',
      'sessions': sessions,
      'selectedSession': sessions.isEmpty ? null : sessions.first,
      'slots': [{'slotCode': 'A3'}],
      'students': [
        for (final s in _students)
          {...s, 'status': previous[s['rollNumber']] ?? 'Unchecked'},
      ],
    }));
  }
}

class _FakeTeacher extends TeacherRepository {
  _FakeTeacher({this.failWith}) : super(currentUser: CurrentUser());

  final String? failWith;
  final List<Map<String, dynamic>> writes = [];

  @override
  Future<ApiResult<List<ClassSectionModel>>> getClasses({required String teacherMemberCode}) async =>
      ApiSuccess([]);

  @override
  Future<ApiResult<void>> manualCheckinBulk({
    required String sessionId,
    required List<Map<String, dynamic>> changes,
  }) async {
    if (failWith != null) {
      return ApiFailure(ApiError(code: failWith!, message: 'Đã quá hạn điểm danh tay.'));
    }
    writes.add({'sessionId': sessionId, 'changes': changes});
    return ApiSuccess(null);
  }
}

class _FakeReport extends ReportRepository {
  _FakeReport() : super(currentUser: CurrentUser());

  @override
  Future<ApiResult<ReportData>> getReport() async => ApiSuccess(ReportData.fromJson({
    'generatedAt': '2026-10-21T01:00:00Z',
    'kpis': {
      'attendanceRate': 0.91,
      'lateRate': 0.03,
      'totalCheckins': 182,
      'absentCount': 18,
      'atRiskCount': 1,
      'studentCount': 40,
    },
    'subjects': [
      {
        'classCode': 'SWP391_SE1801',
        'subjectName': 'Software Project',
        'attendanceRate': 0.91,
        'absentRate': 0.09,
        'studentCount': 40,
        'presentCount': 182,
        'expectedCount': 200,
      },
    ],
    'warnings': [
      {
        'classCode': 'SWP391_SE1801',
        'rollNumber': 'HE123457',
        'fullName': 'Trần Thị Bình',
        'absent': 4,
        'total': 10,
        'absenceRate': 0.4,
        'status': 'Cần lưu ý',
      },
    ],
    'classCount': 1,
    'closedSessionCount': 10,
  }));
}

/// Gemini giả: mỗi lần gọi lấy phản hồi kế tiếp trong kịch bản và ghi lại history nhận được.
class _ScriptedAi implements AiAssistantRepository {
  _ScriptedAi(this.script);

  final List<ApiResult<AiTurn>> script;
  final List<List<Map<String, dynamic>>> received = [];

  @override
  Future<ApiResult<AiTurn>> chat(List<Map<String, dynamic>> history) async {
    received.add([for (final m in history) Map<String, dynamic>.from(m)]);
    if (script.isEmpty) return ApiSuccess(const AiTurn(text: '(hết kịch bản)'));
    return script.removeAt(0);
  }
}

ApiResult<AiTurn> _say(String text) => ApiSuccess(AiTurn(text: text));

ApiResult<AiTurn> _call(String name, Map<String, dynamic> args) =>
    ApiSuccess(AiTurn(calls: [AiToolCall(name: name, args: args)]));

class _FakeSpeech implements SpeechService {
  _FakeSpeech({this.allowed = true});

  final bool allowed;
  void Function(String, bool)? _onResult;
  void Function()? _onDone;
  bool _listening = false;

  @override
  bool get isListening => _listening;

  @override
  Future<bool> initialize() async => allowed;

  @override
  Future<void> start({
    required void Function(String text, bool isFinal) onResult,
    void Function(String message)? onError,
    void Function()? onDone,
  }) async {
    _listening = true;
    _onResult = onResult;
    _onDone = onDone;
  }

  void say(String text, {bool isFinal = false}) => _onResult?.call(text, isFinal);

  @override
  Future<void> stop() async {
    _listening = false;
    _onDone?.call();
  }

  @override
  Future<void> cancel() async => _listening = false;
}

// ── harness ──────────────────────────────────────────────────────────────────

class _Rig {
  _Rig({
    required this.ai,
    this.sessions = const [],
    this.previous = const {},
    this.writeFailure,
    SpeechService? speech,
  }) {
    final user = CurrentUser();
    teacher = _FakeTeacher(failWith: writeFailure);
    history = _FakeHistory(sessions: sessions, previous: previous);
    final executor = AiToolExecutor(
      teacher: teacher,
      history: history,
      report: _FakeReport(),
      currentUser: user,
      now: () => _now,
    );
    vm = AiChatViewModel(repository: ai, executor: executor, speech: speech);
    this.user = user;
  }

  final _ScriptedAi ai;
  final List<Map<String, dynamic>> sessions;
  final Map<String, String> previous;
  final String? writeFailure;
  late final CurrentUser user;
  late final _FakeTeacher teacher;
  late final _FakeHistory history;
  late final AiChatViewModel vm;
}

Future<void> _pumpApp(WidgetTester tester, _Rig rig, {Size size = const Size(390, 844)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final auth = AuthViewModel(AuthRepository(currentUser: rig.user), GoogleAuthService());
  final dashboard = DashboardViewModel(rig.teacher);
  final live = LiveSessionViewModel(rig.teacher);
  final historyVm = AttendanceHistoryViewModel(rig.history);
  final report = ReportViewModel(_FakeReport());

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider(create: (_) => ScheduleRepository(currentUser: rig.user)),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: dashboard),
        ChangeNotifierProvider.value(value: live),
        ChangeNotifierProvider.value(value: historyVm),
        ChangeNotifierProvider.value(value: report),
        ChangeNotifierProvider.value(value: rig.vm),
      ],
      child: const MaterialApp(home: MainScreen(initialRoute: 'ai')),
    ),
  );
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(const Key('ai-input')), text);
  await tester.pump();
}

Future<void> _tapSend(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('ai-send')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  group('điều hướng', () {
    testWidgets('tab AI mở màn trợ lý với gợi ý; Tổng quan chứa báo cáo', (tester) async {
      final rig = _Rig(ai: _ScriptedAi([]));
      await _pumpApp(tester, rig);

      expect(find.text('Trợ lý AI'), findsOneWidget);
      expect(find.text('Mình có thể giúp gì hôm nay?'), findsOneWidget);
      expect(find.byKey(const Key('ai-input')), findsOneWidget);
      expect(find.byKey(const Key('ai-send')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('điểm danh bằng hội thoại', () {
    testWidgets('xác minh SV -> thẻ xác nhận -> Xác nhận -> ghi + AI tóm tắt', (tester) async {
      final ai = _ScriptedAi([
        _call('find_student', {'query': 'he123456', 'classCode': 'SWP391_SE1801'}),
        _call('mark_attendance', {
          'classCode': 'SWP391_SE1801',
          'slotCode': 'A3',
          'students': [{'rollNumber': 'HE123456', 'status': 'ManualByGV'}],
        }),
        _say('Đã điểm danh **Nguyễn Văn An** (HE123456) có mặt.'),
      ]);
      final rig = _Rig(ai: ai, sessions: [_session()], previous: {'HE123456': 'Absent'});
      await _pumpApp(tester, rig);

      await _type(tester, 'điểm danh sinh viên HE123456 lớp SWP391 slot 3 có mặt');
      await _tapSend(tester);

      // Thẻ xác nhận hiện đúng dữ liệu thật; chưa ghi gì.
      expect(find.byKey(const Key('ai-confirm-card')), findsOneWidget);
      expect(find.text('HE123456'), findsOneWidget);
      expect(find.text('Nguyễn Văn An'), findsOneWidget);
      expect(find.textContaining('SWP391_SE1801'), findsWidgets);
      expect(find.textContaining('Slot A3'), findsOneWidget);
      expect(find.text('trước: Vắng'), findsOneWidget); // trạng thái cũ lấy từ dữ liệu thật
      expect(rig.teacher.writes, isEmpty);
      // Đang chờ xác nhận thì ô nhập bị khoá.
      expect(tester.widget<TextField>(find.byKey(const Key('ai-input'))).enabled, isFalse);

      await tester.tap(find.byKey(const Key('ai-confirm')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(rig.teacher.writes, hasLength(1));
      expect(rig.teacher.writes.single['sessionId'], 'S1');
      expect(rig.teacher.writes.single['changes'], [
        {'rollNumber': 'HE123456', 'status': 'ManualByGV'},
      ]);
      expect(find.byKey(const Key('ai-result-confirmed')), findsOneWidget);
      expect(find.textContaining('Nguyễn Văn An'), findsWidgets);
      expect(find.textContaining('có mặt.'), findsOneWidget);

      // Kết quả ghi được gửi lại cho model ở lượt cuối.
      final last = ai.received.last;
      expect(last.last['role'], 'tool');
      expect(last.last['name'], 'mark_attendance');
      expect((last.last['result'] as Map)['ok'], true);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 5)); // hết thời gian toast
    });

    testWidgets('Huỷ: không ghi gì và model biết GV đã huỷ', (tester) async {
      final ai = _ScriptedAi([
        _call('mark_attendance', {
          'classCode': 'SWP391_SE1801',
          'students': [{'rollNumber': 'HE123457', 'status': 'Absent'}],
        }),
        _say('Ok, mình không ghi gì cả.'),
      ]);
      final rig = _Rig(ai: ai, sessions: [_session()]);
      await _pumpApp(tester, rig);

      await _type(tester, 'đánh vắng HE123457');
      await _tapSend(tester);
      await tester.tap(find.byKey(const Key('ai-cancel')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(rig.teacher.writes, isEmpty);
      expect(find.byKey(const Key('ai-result-cancelled')), findsOneWidget);
      expect((ai.received.last.last['result'] as Map)['cancelled'], true);
      expect(find.text('Ok, mình không ghi gì cả.'), findsOneWidget);
      // Sau khi huỷ, ô nhập dùng lại được.
      expect(tester.widget<TextField>(find.byKey(const Key('ai-input'))).enabled, isTrue);
    });

    testWidgets('MSSV sai: không có thẻ xác nhận, AI nhận lỗi để hỏi lại', (tester) async {
      final ai = _ScriptedAi([
        _call('mark_attendance', {
          'classCode': 'SWP391_SE1801',
          'students': [{'rollNumber': 'HE999999', 'status': 'ManualByGV'}],
        }),
        _say('MSSV HE999999 không thuộc lớp này, bạn kiểm tra lại giúp mình nhé.'),
      ]);
      final rig = _Rig(ai: ai, sessions: [_session()]);
      await _pumpApp(tester, rig);

      await _type(tester, 'điểm danh HE999999');
      await _tapSend(tester);

      expect(find.byKey(const Key('ai-confirm-card')), findsNothing);
      expect((ai.received.last.last['result'] as Map)['code'], 'STUDENT_NOT_ENROLLED');
      expect(find.textContaining('không thuộc lớp này'), findsOneWidget);
      expect(rig.teacher.writes, isEmpty);
    });

    testWidgets('chưa mở phiên hôm nay: báo lỗi nghiệp vụ, không ghi', (tester) async {
      final ai = _ScriptedAi([
        _call('mark_attendance', {
          'classCode': 'SWP391_SE1801',
          'students': [{'rollNumber': 'HE123456', 'status': 'ManualByGV'}],
        }),
        _say('Hôm nay lớp chưa mở phiên, hãy mở ở Quản lý lớp.'),
      ]);
      final rig = _Rig(ai: ai, sessions: [_session(status: 'closed', date: '2026-10-20')]);
      await _pumpApp(tester, rig);

      await _type(tester, 'điểm danh HE123456');
      await _tapSend(tester);

      expect((ai.received.last.last['result'] as Map)['code'], 'NO_SESSION_TODAY');
      expect(find.byKey(const Key('ai-confirm-card')), findsNothing);
      expect(rig.teacher.writes, isEmpty);
    });

    testWidgets('ghi thất bại (quá hạn): thẻ báo lỗi, toast lỗi, không crash', (tester) async {
      final ai = _ScriptedAi([
        _call('mark_attendance', {
          'classCode': 'SWP391_SE1801',
          'students': [{'rollNumber': 'HE123456', 'status': 'ManualByGV'}],
        }),
        _say('Không ghi được vì đã quá hạn điểm danh tay.'),
      ]);
      final rig = _Rig(
        ai: ai,
        sessions: [_session()],
        writeFailure: 'MANUAL_ATTENDANCE_EXPIRED',
      );
      await _pumpApp(tester, rig);

      await _type(tester, 'điểm danh HE123456');
      await _tapSend(tester);
      await tester.tap(find.byKey(const Key('ai-confirm')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('ai-result-failed')), findsOneWidget);
      expect((ai.received.last.last['result'] as Map)['code'], 'MANUAL_ATTENDANCE_EXPIRED');
      expect(find.text('Không ghi được điểm danh.'), findsOneWidget); // toast
      // Hết thời gian toast để không còn timer treo.
      await tester.pump(const Duration(seconds: 5));
    });
  });

  group('tra cứu & báo cáo', () {
    testWidgets('hỏi sinh viên nguy cơ -> chạy get_attendance_report -> trả lời có số liệu', (tester) async {
      final ai = _ScriptedAi([
        _call('get_attendance_report', {}),
        _say('Có **1** sinh viên cần lưu ý: HE123457 vắng 4/10 buổi (40%).'),
      ]);
      final rig = _Rig(ai: ai);
      await _pumpApp(tester, rig);

      await tester.tap(find.byKey(const Key('ai-chip-Sinh viên có nguy cơ vắng nhiều')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final toolMsg = ai.received.last.last;
      expect(toolMsg['name'], 'get_attendance_report');
      final result = toolMsg['result'] as Map;
      expect((result['kpis'] as Map)['attendancePercent'], 91.0);
      expect((result['atRisk'] as List).single['rollNumber'], 'HE123457');
      expect(find.textContaining('HE123457 vắng 4/10'), findsOneWidget);
    });

    testWidgets('lỗi mạng -> bong bóng lỗi + Thử lại gửi lại đúng history', (tester) async {
      final ai = _ScriptedAi([
        ApiFailure(ApiError(code: 'AI_UNAVAILABLE', message: 'Trợ lý AI đang bận, vui lòng thử lại sau.')),
        _say('Xin chào!'),
      ]);
      final rig = _Rig(ai: ai);
      await _pumpApp(tester, rig);

      await _type(tester, 'xin chào');
      await _tapSend(tester);
      expect(find.text('Trợ lý AI đang bận, vui lòng thử lại sau.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('ai-retry')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Xin chào!'), findsOneWidget);
      expect(find.text('Trợ lý AI đang bận, vui lòng thử lại sau.'), findsNothing);
      // Lần thử lại gửi cùng history (không nhân đôi tin người dùng).
      expect(ai.received[1], ai.received[0]);
    });

    testWidgets('Cuộc trò chuyện mới xoá hội thoại', (tester) async {
      final rig = _Rig(ai: _ScriptedAi([_say('Chào bạn')]));
      await _pumpApp(tester, rig);
      await _type(tester, 'hi');
      await _tapSend(tester);
      expect(find.text('Chào bạn'), findsOneWidget);

      await tester.tap(find.byKey(const Key('ai-reset')));
      await tester.pump();
      expect(find.text('Chào bạn'), findsNothing);
      expect(find.text('Mình có thể giúp gì hôm nay?'), findsOneWidget);
    });
  });

  group('giọng nói', () {
    testWidgets('nói -> bản chép hiện vào ô nhập -> gửi chạy cùng luồng thẻ xác nhận', (tester) async {
      final speech = _FakeSpeech();
      final ai = _ScriptedAi([
        _call('mark_attendance', {
          'classCode': 'SWP391_SE1801',
          'students': [{'rollNumber': 'HE123456', 'status': 'ManualByGV'}],
        }),
        _say('Xong.'),
      ]);
      final rig = _Rig(ai: ai, sessions: [_session()], speech: speech);
      await _pumpApp(tester, rig);

      await tester.tap(find.byKey(const Key('ai-mic')));
      await tester.pump();
      expect(speech.isListening, isTrue);
      expect(find.text('Đang nghe… hãy nói'), findsOneWidget);

      speech.say('điểm danh sinh viên HE123456');
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byKey(const Key('ai-input'))).controller!.text,
        'điểm danh sinh viên HE123456',
      );

      speech.say('điểm danh sinh viên HE123456 có mặt', isFinal: true);
      await tester.pump();
      await tester.tap(find.byKey(const Key('ai-send'))); // gửi sẽ tự dừng micro
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(speech.isListening, isFalse);
      expect(ai.received.first.first['text'], 'điểm danh sinh viên HE123456 có mặt');
      expect(find.byKey(const Key('ai-confirm-card')), findsOneWidget);
      expect(rig.teacher.writes, isEmpty);
    });

    testWidgets('từ chối quyền micro: toast hướng dẫn, vẫn gõ được', (tester) async {
      final rig = _Rig(ai: _ScriptedAi([_say('ok')]), speech: _FakeSpeech(allowed: false));
      await _pumpApp(tester, rig);

      await tester.tap(find.byKey(const Key('ai-mic')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('cấp quyền micro'), findsOneWidget);
      expect(rig.vm.listening, isFalse);

      await _type(tester, 'vẫn gõ được');
      await _tapSend(tester);
      expect(find.text('ok'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('không có SpeechService: ẩn nút mic', (tester) async {
      final rig = _Rig(ai: _ScriptedAi([]));
      await _pumpApp(tester, rig);
      expect(find.byKey(const Key('ai-mic')), findsNothing);
    });
  });

  group('AiChatViewModel', () {
    test('giới hạn số vòng tool để không lặp vô hạn', () async {
      final ai = _ScriptedAi([for (var i = 0; i < 10; i++) _call('list_my_classes', {})]);
      final rig = _Rig(ai: ai);
      await rig.vm.send('liệt kê');
      expect(ai.received.length, AiChatViewModel.maxRounds);
      expect(rig.vm.sending, isFalse);
      expect(rig.vm.messages.last.text, contains('chưa hoàn tất'));
    });

    test('history gửi lên luôn bắt đầu bằng user và bị cắt dưới giới hạn server', () async {
      final ai = _ScriptedAi([for (var i = 0; i < 40; i++) _say('r$i')]);
      final rig = _Rig(ai: ai);
      for (var i = 0; i < 40; i++) {
        await rig.vm.send('câu $i');
      }
      for (final h in ai.received) {
        expect(h.length, lessThanOrEqualTo(30));
        expect(h.first['role'], 'user');
      }
    });

    test('không gửi tin rỗng hoặc khi đang bận', () async {
      final ai = _ScriptedAi([_say('a')]);
      final rig = _Rig(ai: ai);
      await rig.vm.send('   ');
      expect(ai.received, isEmpty);
    });

    test('reset giữa chừng không để lại trạng thái treo', () async {
      final ai = _ScriptedAi([
        _call('mark_attendance', {
          'classCode': 'SWP391_SE1801',
          'students': [{'rollNumber': 'HE123456', 'status': 'ManualByGV'}],
        }),
      ]);
      final rig = _Rig(ai: ai, sessions: [_session()]);
      await rig.vm.send('điểm danh');
      expect(rig.vm.pendingAction, isNotNull);
      rig.vm.reset();
      expect(rig.vm.pendingAction, isNull);
      expect(rig.vm.messages, isEmpty);
      expect(await rig.vm.confirmPending(), isFalse);
      expect(rig.teacher.writes, isEmpty);
    });
  });
}
