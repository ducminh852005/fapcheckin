// Luồng đầu-cuối của Trợ lý AI ở tầng app: MainScreen thật + AiChatViewModel thật + AiToolExecutor thật,
// chỉ thay phần ngoài (Gemini bằng kịch bản, Firestore bằng repository giả, micro bằng SpeechService giả).
// Phần Cloud Function + Security Rules được kiểm trong e2e_test/ai_assistant.e2e.test.mjs (Emulator).
import 'dart:async';

import 'package:fapcheckin/core/services/google_auth_service.dart';
import 'package:fapcheckin/core/services/speech_service.dart';
import 'package:fapcheckin/core/services/tts_service.dart';
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
  Completer<void>? writeHold;

  @override
  Future<ApiResult<List<ClassSectionModel>>> getClasses({required String teacherMemberCode}) async =>
      ApiSuccess([]);

  @override
  Future<ApiResult<void>> manualCheckinBulk({
    required String sessionId,
    required List<Map<String, dynamic>> changes,
  }) async {
    if (writeHold != null) await writeHold!.future;
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

  /// Nếu đặt, lời gọi kế tiếp chờ tới khi hoàn thành (mô phỏng AI đang xử lý lâu).
  Completer<void>? hold;
  int holdAtCall = 1; // giữ ở lời gọi thứ mấy (đếm từ 1)

  @override
  Future<ApiResult<AiTurn>> chat(List<Map<String, dynamic>> history) async {
    received.add([for (final m in history) Map<String, dynamic>.from(m)]);
    // Lấy phản hồi theo thứ tự GỌI (như server thật): lời gọi bị giữ vẫn "thuộc" câu hỏi của nó.
    final response = script.isEmpty ? ApiSuccess(const AiTurn(text: '(hết kịch bản)')) : script.removeAt(0);
    final gate = hold;
    if (gate != null && received.length == holdAtCall) {
      hold = null;
      await gate.future;
    }
    return response;
  }
}

ApiResult<AiTurn> _say(String text) => ApiSuccess(AiTurn(text: text));

ApiResult<AiTurn> _call(String name, Map<String, dynamic> args) =>
    ApiSuccess(AiTurn(calls: [AiToolCall(name: name, args: args)]));

/// Micro giả: ghi lại các lượt nghe; test "nói" bằng [say].
class _FakeSpeech implements SpeechService {
  _FakeSpeech({this.allowed = true, this.log});

  final bool allowed;
  final List<String>? log; // thứ tự sự kiện chung với TTS giả
  void Function(String, bool)? _onResult;
  void Function(String)? _onError;
  void Function()? _onDone;
  bool _listening = false;
  int starts = 0;
  Duration? lastPauseFor;

  @override
  bool get isListening => _listening;

  @override
  Future<bool> initialize() async => allowed;

  @override
  Future<void> start({
    required void Function(String text, bool isFinal) onResult,
    void Function(String message)? onError,
    void Function()? onDone,
    Duration? pauseFor,
  }) async {
    final failure = throwOnNextStart;
    if (failure != null) {
      throwOnNextStart = null;
      throw failure;
    }
    _listening = true;
    starts++;
    lastPauseFor = pauseFor;
    log?.add('listen');
    _onResult = onResult;
    _onError = onError;
    _onDone = onDone;
  }

  void say(String text, {bool isFinal = false}) => _onResult?.call(text, isFinal);

  /// Nếu đặt, `start` kế tiếp ném lỗi này (mô phỏng "recognition has already started" của trình duyệt).
  Object? throwOnNextStart;

  /// Hết lượt nghe mà không có tiếng (bộ nhận dạng tự dừng).
  void endSilently() {
    _listening = false;
    _onDone?.call();
  }

  void fail(String message) => _onError?.call(message);

  @override
  Future<void> stop() async {
    _listening = false;
    _onDone?.call();
  }

  @override
  Future<void> cancel() async => _listening = false;
}

/// Loa giả: ghi lại các câu được đọc; [hold] giữ lại để test "không nghe khi đang đọc".
class _FakeTts implements TtsService {
  _FakeTts({this.log});

  final List<String>? log;
  final List<String> spoken = [];
  int stops = 0;
  Completer<void>? hold;
  String? error;

  @override
  String? takeError() {
    final e = error;
    error = null;
    return e;
  }

  @override
  Future<void> speak(String text) async {
    spoken.add(text);
    log?.add('speak');
    if (hold != null) await hold!.future;
    log?.add('spoken');
  }

  @override
  Future<void> stop() async {
    stops++;
    if (hold != null && !hold!.isCompleted) hold!.complete();
  }
}

// ── harness ──────────────────────────────────────────────────────────────────

class _Rig {
  _Rig({
    required this.ai,
    this.sessions = const [],
    this.previous = const {},
    this.writeFailure,
    SpeechService? speech,
    TtsService? tts,
    Duration speechTail = Duration.zero,
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
    vm = AiChatViewModel(repository: ai, executor: executor, speech: speech, tts: tts, speechTail: speechTail);
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
      // Đang chờ xác nhận ô nhập VẪN dùng được (gõ "xác nhận"/"huỷ" hoặc gõ thêm yêu cầu để xếp hàng).
      expect(tester.widget<TextField>(find.byKey(const Key('ai-input'))).enabled, isNot(isFalse));

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
      expect(tester.widget<TextField>(find.byKey(const Key('ai-input'))).enabled, isNot(isFalse));
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
    testWidgets('nói xong -> TỰ GỬI (không bấm Gửi) -> thẻ xác nhận; bản chép tạm hiện khi đang nói', (tester) async {
      final speech = _FakeSpeech();
      final ai = _ScriptedAi([
        _call('mark_attendance', {
          'classCode': 'SWP391_SE1801',
          'students': [{'rollNumber': 'HE123456', 'status': 'ManualByGV'}],
        }),
      ]);
      final rig = _Rig(ai: ai, sessions: [_session()], speech: speech, tts: _FakeTts());
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
      expect(ai.received, isEmpty); // chưa nói xong -> chưa gửi

      speech.say('điểm danh sinh viên HE123456 có mặt', isFinal: true);
      await tester.pump(const Duration(milliseconds: 500));
      expect(ai.received, isEmpty); // vừa dứt lời: còn chờ xem có nói tiếp không
      await tester.pump(AiChatViewModel.sendDelay);
      await tester.pump(const Duration(milliseconds: 300));

      expect(speech.isListening, isTrue); // đang nghe lượt xác nhận
      expect(ai.received.first.first['text'], 'điểm danh sinh viên HE123456 có mặt');
      expect(tester.widget<TextField>(find.byKey(const Key('ai-input'))).controller!.text, isEmpty);
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

  group('trợ lý Live (rảnh tay)', () {
    Future<void> settle(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    // Nói xong một câu: chờ qua khoảng im lặng (sendDelay) để ứng dụng tự gửi/thực thi.
    Future<void> say(WidgetTester tester, _FakeSpeech speech, String text) async {
      speech.say(text, isFinal: true);
      await tester.pump(AiChatViewModel.sendDelay + const Duration(milliseconds: 100));
      await settle(tester);
    }

    testWidgets('Live: nói -> tự gửi -> AI đọc TÓM TẮT -> chat hiện đầy đủ -> tự nghe tiếp (đúng thứ tự)', (tester) async {
      final log = <String>[];
      final speech = _FakeSpeech(log: log);
      final tts = _FakeTts(log: log);
      const full = 'Có **1** sinh viên cần lưu ý.\n\n- HE123457 vắng 4/10 buổi\n- Tỷ lệ chung 91%';
      final ai = _ScriptedAi([_call('get_attendance_report', {}), _say(full)]);
      final rig = _Rig(ai: ai, speech: speech, tts: tts);
      await _pumpApp(tester, rig);

      await tester.tap(find.byKey(const Key('ai-live')));
      await settle(tester);
      expect(rig.vm.live, isTrue);
      expect(speech.lastPauseFor, AiChatViewModel.enginePause);
      expect(find.byKey(const Key('ai-status')), findsOneWidget);

      await say(tester, speech, 'báo cáo chuyên cần tổng quan');

      // Chat hiện ĐẦY ĐỦ; chỉ phần tóm tắt được đọc (không ký hiệu markdown, không chi tiết).
      expect(find.textContaining('HE123457 vắng 4/10 buổi'), findsOneWidget);
      expect(tts.spoken, ['Có 1 sinh viên cần lưu ý.']);
      // Mic mở khi bắt đầu, nghe tiếp lúc AI đang xử lý (để nói thêm được), ĐÓNG khi AI đọc, mở lại sau khi đọc xong.
      expect(log, ['listen', 'listen', 'speak', 'spoken', 'listen']);
      expect(speech.isListening, isTrue);
      expect(rig.vm.live, isTrue);
    });

    testWidgets('Live: micro chỉ mở lại SAU khi đọc xong', (tester) async {
      final speech = _FakeSpeech();
      final tts = _FakeTts()..hold = Completer<void>();
      final rig = _Rig(ai: _ScriptedAi([_say('Xin chào thầy cô.')]), speech: speech, tts: tts);
      await _pumpApp(tester, rig);

      await tester.tap(find.byKey(const Key('ai-live')));
      await settle(tester);
      await say(tester, speech, 'xin chào');

      expect(rig.vm.speaking, isTrue);
      expect(speech.starts, 1); // đang đọc: chưa mở lại micro
      expect(find.textContaining('Đang đọc'), findsOneWidget);
      tts.hold!.complete();
      await settle(tester);
      expect(speech.starts, 2);
      expect(rig.vm.speaking, isFalse);
    });

    testWidgets('Live: sau khi đọc xong còn NGHỈ một nhịp (speechTail) rồi mới mở micro — tránh thu lại giọng loa', (tester) async {
      final speech = _FakeSpeech();
      final tts = _FakeTts();
      final rig = _Rig(ai: _ScriptedAi([_say('Xin chào thầy cô.')]), speech: speech, tts: tts, speechTail: const Duration(milliseconds: 600));
      await _pumpApp(tester, rig);
      await tester.tap(find.byKey(const Key('ai-live')));
      await settle(tester);
      speech.say('xin chào', isFinal: true);
      await tester.pump(AiChatViewModel.sendDelay + const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tts.spoken, hasLength(1));
      expect(speech.starts, 1); // đọc xong rồi nhưng chưa hết nhịp nghỉ: micro vẫn đóng
      expect(rig.vm.speaking, isTrue);
      await tester.pump(const Duration(milliseconds: 600));
      await settle(tester);
      expect(speech.starts, 2);
      expect(speech.isListening, isTrue);
    });

    testWidgets('Live: lệnh điểm danh -> AI đọc thẻ -> nói "xác nhận" -> ghi đúng 1 lần -> đọc kết quả -> nghe tiếp', (tester) async {
      final speech = _FakeSpeech();
      final tts = _FakeTts();
      final ai = _ScriptedAi([
        _call('mark_attendance', {
          'classCode': 'SWP391_SE1801',
          'students': [{'rollNumber': 'HE123456', 'status': 'ManualByGV'}],
        }),
        _say('Đã điểm danh Nguyễn Văn An có mặt.'),
      ]);
      final rig = _Rig(ai: ai, sessions: [_session()], speech: speech, tts: tts);
      await _pumpApp(tester, rig);

      await tester.tap(find.byKey(const Key('ai-live')));
      await settle(tester);
      await say(tester, speech, 'điểm danh HE123456 lớp SWP391 có mặt');

      expect(find.byKey(const Key('ai-confirm-card')), findsOneWidget);
      expect(tts.spoken.single, contains('Nguyễn Văn An'));
      expect(tts.spoken.single, contains('HE123456'));
      expect(tts.spoken.single, contains('xác nhận hoặc huỷ'));
      expect(rig.vm.confirmingByVoice, isTrue);
      expect(find.textContaining('Nói "xác nhận" hoặc "huỷ"'), findsWidgets);
      expect(rig.teacher.writes, isEmpty);

      await say(tester, speech, 'xác nhận');

      expect(rig.teacher.writes, hasLength(1));
      expect(rig.teacher.writes.single['changes'], [
        {'rollNumber': 'HE123456', 'status': 'ManualByGV'},
      ]);
      expect(find.byKey(const Key('ai-result-confirmed')), findsOneWidget);
      expect(tts.spoken.last, 'Đã điểm danh Nguyễn Văn An có mặt.');
      expect(rig.vm.live, isTrue);
      expect(speech.isListening, isTrue); // nghe tiếp sau khi đọc xong
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('Live: nói "huỷ" -> không ghi gì', (tester) async {
      final speech = _FakeSpeech();
      final ai = _ScriptedAi([
        _call('mark_attendance', {
          'classCode': 'SWP391_SE1801',
          'students': [{'rollNumber': 'HE123456', 'status': 'Absent'}],
        }),
        _say('Ok, mình không ghi gì.'),
      ]);
      final rig = _Rig(ai: ai, sessions: [_session()], speech: speech, tts: _FakeTts());
      await _pumpApp(tester, rig);
      await tester.tap(find.byKey(const Key('ai-live')));
      await settle(tester);
      await say(tester, speech, 'đánh vắng HE123456');
      await say(tester, speech, 'huỷ đi');

      expect(rig.teacher.writes, isEmpty);
      expect(find.byKey(const Key('ai-result-cancelled')), findsOneWidget);
      expect((ai.received.last.last['result'] as Map)['cancelled'], true);
    });

    testWidgets('Live: câu xác nhận mơ hồ -> nhắc lại; sau 2 lần để thẻ chờ bấm tay và thoát Live', (tester) async {
      final speech = _FakeSpeech();
      final tts = _FakeTts();
      final ai = _ScriptedAi([
        _call('mark_attendance', {
          'classCode': 'SWP391_SE1801',
          'students': [{'rollNumber': 'HE123456', 'status': 'ManualByGV'}],
        }),
      ]);
      final rig = _Rig(ai: ai, sessions: [_session()], speech: speech, tts: tts);
      await _pumpApp(tester, rig);
      await tester.tap(find.byKey(const Key('ai-live')));
      await settle(tester);
      await say(tester, speech, 'điểm danh HE123456');

      await say(tester, speech, 'ừm để xem');
      expect(tts.spoken.last, contains('chưa nghe rõ'));
      expect(rig.vm.pendingAction, isNotNull);
      expect(speech.isListening, isTrue);

      await say(tester, speech, 'hmm');
      expect(tts.spoken.last, contains('giữ nguyên thẻ'));
      expect(rig.vm.live, isFalse);
      expect(rig.vm.pendingAction, isNotNull); // thẻ còn, bấm tay được
      expect(rig.teacher.writes, isEmpty);

      await tester.tap(find.byKey(const Key('ai-confirm')));
      await settle(tester);
      expect(rig.teacher.writes, hasLength(1));
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('Live: bấm nút Xác nhận khi đang nghe xác nhận bằng giọng nói -> ghi đúng 1 lần', (tester) async {
      final speech = _FakeSpeech();
      final ai = _ScriptedAi([
        _call('mark_attendance', {
          'classCode': 'SWP391_SE1801',
          'students': [{'rollNumber': 'HE123456', 'status': 'ManualByGV'}],
        }),
        _say('Xong.'),
      ]);
      final rig = _Rig(ai: ai, sessions: [_session()], speech: speech, tts: _FakeTts());
      await _pumpApp(tester, rig);
      await tester.tap(find.byKey(const Key('ai-live')));
      await settle(tester);
      await say(tester, speech, 'điểm danh HE123456');
      expect(speech.isListening, isTrue);

      await tester.tap(find.byKey(const Key('ai-confirm')));
      await settle(tester);
      speech.say('xác nhận', isFinal: true); // tiếng nói muộn của lượt cũ không được ghi lần hai
      await settle(tester);
      expect(rig.teacher.writes, hasLength(1));
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('Live: hội thoại LIÊN TỤC nhiều lượt (nói -> AI đọc -> nghe tiếp -> nói tiếp ...), không rơi về trạng thái thường', (tester) async {
      final speech = _FakeSpeech();
      final tts = _FakeTts();
      final ai = _ScriptedAi([_say('Trả lời một.'), _say('Trả lời hai.'), _say('Trả lời ba.')]);
      final rig = _Rig(ai: ai, speech: speech, tts: tts);
      await _pumpApp(tester, rig);
      await tester.tap(find.byKey(const Key('ai-live')));
      await settle(tester);

      for (final q in ['câu một', 'câu hai', 'câu ba']) {
        await say(tester, speech, q);
        expect(rig.vm.live, isTrue, reason: 'sau "$q" vẫn phải ở chế độ Live');
        expect(speech.isListening, isTrue, reason: 'sau "$q" phải tự nghe tiếp');
      }
      expect(find.text('Trả lời một.'), findsOneWidget);
      expect(find.text('Trả lời hai.'), findsOneWidget);
      expect(find.text('Trả lời ba.'), findsOneWidget);
      expect(tts.spoken, ['Trả lời một.', 'Trả lời hai.', 'Trả lời ba.']);
      expect(ai.received.last.where((m) => m['role'] == 'user').map((m) => m['text']), ['câu một', 'câu hai', 'câu ba']);
    });

    testWidgets('Live: tín hiệu "đã dừng" MUỘN của phiên trước ngay sau khi mở lại micro KHÔNG bị coi là im lặng (lỗi "chỉ nói được một lần")', (tester) async {
      final speech = _FakeSpeech();
      final ai = _ScriptedAi([_say('Trả lời một.'), _say('Trả lời hai.')]);
      final rig = _Rig(ai: ai, speech: speech, tts: _FakeTts());
      await _pumpApp(tester, rig);
      await tester.tap(find.byKey(const Key('ai-live')));
      await settle(tester);
      await say(tester, speech, 'câu một'); // AI đọc xong, micro mở lại cho lượt 2

      // Plugin bắn các tín hiệu dừng muộn của phiên cũ ngay lúc phiên mới vừa mở (trước đây: 2 lần = thoát Live).
      speech.endSilently();
      await tester.pump(const Duration(milliseconds: 400));
      speech.endSilently();
      await tester.pump(const Duration(milliseconds: 400));
      speech.endSilently();
      await tester.pump(const Duration(milliseconds: 400));
      expect(rig.vm.live, isTrue);
      expect(speech.isListening, isTrue); // đã tự mở lại, vẫn đang chờ bạn nói

      await say(tester, speech, 'câu hai');
      expect(find.text('Trả lời hai.'), findsOneWidget);
      expect(rig.vm.live, isTrue);
    });

    testWidgets('Live: lỗi micro TẠM THỜI (busy/mạng chập chờn) được thử lại; quá 3 lần liên tiếp mới thoát kèm thông báo', (tester) async {
      final speech = _FakeSpeech();
      final ai = _ScriptedAi([_say('Trả lời.')]);
      final rig = _Rig(ai: ai, speech: speech, tts: _FakeTts());
      await _pumpApp(tester, rig);
      await tester.tap(find.byKey(const Key('ai-live')));
      await settle(tester);

      speech.fail('error_busy');
      await tester.pump(const Duration(milliseconds: 700));
      expect(rig.vm.live, isTrue);
      expect(speech.starts, 2); // đã mở lại

      await say(tester, speech, 'xin chào'); // sau khi hồi phục vẫn nói chuyện bình thường
      expect(find.text('Trả lời.'), findsOneWidget);
      expect(rig.vm.live, isTrue);

      for (var i = 0; i < 4; i++) {
        speech.fail('error_network');
        await tester.pump(const Duration(milliseconds: 700));
      }
      expect(rig.vm.live, isFalse);
      expect(rig.vm.voiceError, contains('error_network'));
      await tester.pump(const Duration(seconds: 5)); // toast tự tắt
    });

    testWidgets('Live: trình duyệt báo "recognition has already started" -> thử lại sau một nhịp, KHÔNG thoát Live', (tester) async {
      final speech = _FakeSpeech();
      final rig = _Rig(ai: _ScriptedAi([_say('Trả lời.')]), speech: speech, tts: _FakeTts());
      await _pumpApp(tester, rig);
      speech.throwOnNextStart = StateError("InvalidStateError: Failed to execute 'start' on 'SpeechRecognition': recognition has already started.");
      await tester.tap(find.byKey(const Key('ai-live')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900)); // chờ lần thử lại

      expect(rig.vm.live, isTrue);
      expect(speech.isListening, isTrue); // đã tự mở lại thành công
      expect(rig.vm.voiceError, isNull);

      await say(tester, speech, 'xin chào');
      expect(find.text('Trả lời.'), findsOneWidget);
      expect(rig.vm.live, isTrue);
    });

    testWidgets('Live: lỗi quyền micro là lỗi nghiêm trọng -> thoát ngay, không thử lại', (tester) async {
      final speech = _FakeSpeech();
      final rig = _Rig(ai: _ScriptedAi([]), speech: speech, tts: _FakeTts());
      await _pumpApp(tester, rig);
      await tester.tap(find.byKey(const Key('ai-live')));
      await settle(tester);
      speech.fail('error_permission');
      await settle(tester);
      expect(rig.vm.live, isFalse);
      expect(speech.starts, 1);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('Live: im lặng 2 lượt liên tiếp -> tự thoát, không treo micro', (tester) async {
      final speech = _FakeSpeech();
      final rig = _Rig(ai: _ScriptedAi([]), speech: speech, tts: _FakeTts());
      await _pumpApp(tester, rig);
      await tester.tap(find.byKey(const Key('ai-live')));
      await settle(tester);
      expect(rig.vm.live, isTrue);

      await tester.pump(AiChatViewModel.engineWarmup + const Duration(milliseconds: 100)); // im lặng THẬT (qua giai đoạn khởi động)
      speech.endSilently();
      await settle(tester);
      expect(rig.vm.live, isTrue); // lượt 1: nghe lại
      expect(speech.starts, 2);

      await tester.pump(AiChatViewModel.engineWarmup + const Duration(milliseconds: 100));
      speech.endSilently();
      await settle(tester);
      expect(rig.vm.live, isFalse); // lượt 2: thoát
      expect(speech.isListening, isFalse);
    });

    testWidgets('Dừng Live giữa chừng: dừng đọc + dừng nghe, không gửi gì', (tester) async {
      final speech = _FakeSpeech();
      final tts = _FakeTts();
      final ai = _ScriptedAi([]);
      final rig = _Rig(ai: ai, speech: speech, tts: tts);
      await _pumpApp(tester, rig);
      await tester.tap(find.byKey(const Key('ai-live')));
      await settle(tester);
      speech.say('xin chào'); // mới có bản chép tạm, chưa nói xong
      await tester.tap(find.byKey(const Key('ai-live')));
      await settle(tester);

      expect(rig.vm.live, isFalse);
      expect(speech.isListening, isFalse);
      expect(tts.stops, greaterThan(0));
      expect(ai.received, isEmpty);
    });

    testWidgets('Lỗi micro nghiêm trọng -> thoát Live; lỗi "không có tiếng" chỉ coi là im lặng', (tester) async {
      final speech = _FakeSpeech();
      final rig = _Rig(ai: _ScriptedAi([]), speech: speech, tts: _FakeTts());
      await _pumpApp(tester, rig);
      await tester.tap(find.byKey(const Key('ai-live')));
      await settle(tester);

      speech.fail('error_no_match');
      await settle(tester);
      expect(rig.vm.live, isTrue);
      expect(speech.starts, 2);

      speech.fail('error_permission');
      await settle(tester);
      expect(rig.vm.live, isFalse);
      expect(rig.vm.voiceError, contains('error_permission'));
      await tester.pump(const Duration(seconds: 5)); // toast lỗi tự tắt
    });

    testWidgets('gõ chữ: KHÔNG đọc to; tắt loa thì Live vẫn hiện chữ nhưng im lặng', (tester) async {
      final speech = _FakeSpeech();
      final tts = _FakeTts();
      final rig = _Rig(ai: _ScriptedAi([_say('Chào bạn'), _say('Lại chào')]), speech: speech, tts: tts);
      await _pumpApp(tester, rig);
      await _type(tester, 'hi');
      await _tapSend(tester);
      expect(find.text('Chào bạn'), findsOneWidget);
      expect(tts.spoken, isEmpty);

      await tester.tap(find.byKey(const Key('ai-voice-mode'))); // tắt đọc to
      await tester.pump();
      expect(rig.vm.voiceReplies, isFalse);
      await tester.tap(find.byKey(const Key('ai-live')));
      await settle(tester);
      await say(tester, speech, 'chào');
      expect(find.text('Lại chào'), findsOneWidget);
      expect(tts.spoken, isEmpty); // tắt loa: vẫn hiện chữ nhưng không đọc
      expect(speech.isListening, isTrue); // Live vẫn tiếp tục nghe
    });

    testWidgets('rời tab AI khi đang Live -> tắt micro và loa', (tester) async {
      final speech = _FakeSpeech();
      final tts = _FakeTts();
      final rig = _Rig(ai: _ScriptedAi([]), speech: speech, tts: tts);
      await _pumpApp(tester, rig);
      await tester.tap(find.byKey(const Key('ai-live')));
      await settle(tester);
      expect(speech.isListening, isTrue);

      await tester.pumpWidget(const SizedBox()); // AiBody bị gỡ khỏi cây (đổi tab)
      await tester.pump();
      expect(rig.vm.live, isFalse);
      expect(speech.isListening, isFalse);
    });
  });

  group('nói câu dài: không được gửi khi chưa nói hết', () {
    Future<void> settle(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('nói nhiều đoạn, nghỉ ngắn giữa chừng -> gom thành MỘT câu, chỉ gửi một lần sau khi im lặng', (tester) async {
      final speech = _FakeSpeech();
      final ai = _ScriptedAi([_say('Ok.')]);
      final rig = _Rig(ai: ai, speech: speech, tts: _FakeTts());
      await _pumpApp(tester, rig);
      await tester.tap(find.byKey(const Key('ai-mic')));
      await settle(tester);

      speech.say('điểm danh sinh viên', isFinal: true); // bộ nhận dạng chốt sớm ở nhịp ngắt
      await tester.pump(const Duration(milliseconds: 1000)); // nghỉ chưa đủ lâu
      expect(ai.received, isEmpty);
      speech.say('HE123456 lớp SWP391', isFinal: true);
      await tester.pump(const Duration(milliseconds: 1000));
      expect(ai.received, isEmpty);
      expect(tester.widget<TextField>(find.byKey(const Key('ai-input'))).controller!.text, 'điểm danh sinh viên HE123456 lớp SWP391');

      await tester.pump(AiChatViewModel.sendDelayIncomplete); // câu trọn -> im lặng đủ thì gửi
      await settle(tester);
      expect(ai.received, hasLength(1));
      expect(ai.received.single.single['text'], 'điểm danh sinh viên HE123456 lớp SWP391');
    });

    testWidgets('bộ nhận dạng tự ngắt giữa câu (Chrome) -> mở lại, KHÔNG gửi, nối tiếp chữ', (tester) async {
      final speech = _FakeSpeech();
      final ai = _ScriptedAi([_say('Ok.')]);
      final rig = _Rig(ai: ai, speech: speech, tts: _FakeTts());
      await _pumpApp(tester, rig);
      await tester.tap(find.byKey(const Key('ai-mic')));
      await settle(tester);

      speech.say('báo cáo chuyên cần', isFinal: true);
      speech.endSilently(); // phiên nhận dạng tự kết thúc
      await tester.pump(const Duration(milliseconds: 300));
      expect(speech.starts, 2); // đã mở lại
      expect(ai.received, isEmpty); // chưa gửi

      speech.say('của hôm nay', isFinal: true);
      await tester.pump(AiChatViewModel.sendDelay + const Duration(milliseconds: 100));
      await settle(tester);
      expect(ai.received.single.single['text'], 'báo cáo chuyên cần của hôm nay');
    });

    testWidgets('câu chưa trọn ("...lớp") chờ lâu hơn trước khi gửi', (tester) async {
      final speech = _FakeSpeech();
      final ai = _ScriptedAi([_say('Ok.')]);
      final rig = _Rig(ai: ai, speech: speech, tts: _FakeTts());
      await _pumpApp(tester, rig);
      await tester.tap(find.byKey(const Key('ai-mic')));
      await settle(tester);

      speech.say('điểm danh sinh viên lớp', isFinal: true);
      await tester.pump(AiChatViewModel.sendDelay + const Duration(milliseconds: 200));
      expect(ai.received, isEmpty); // thường thì đã gửi, nhưng câu dở nên còn chờ
      await tester.pump(AiChatViewModel.sendDelayIncomplete - AiChatViewModel.sendDelay);
      await settle(tester);
      expect(ai.received, hasLength(1));
    });

    testWidgets('bấm mic lần nữa khi đang nghe = nói xong, gửi ngay (không chờ im lặng)', (tester) async {
      final speech = _FakeSpeech();
      final ai = _ScriptedAi([_say('Ok.')]);
      final rig = _Rig(ai: ai, speech: speech, tts: _FakeTts());
      await _pumpApp(tester, rig);
      await tester.tap(find.byKey(const Key('ai-mic')));
      await settle(tester);
      speech.say('xin chào', isFinal: true);
      await tester.pump(const Duration(milliseconds: 200));
      expect(ai.received, isEmpty);

      await tester.tap(find.byKey(const Key('ai-mic')));
      await settle(tester);
      expect(ai.received.single.single['text'], 'xin chào');
    });

    testWidgets('mic: nói một câu -> AI trả lời -> dừng (không nghe tiếp); Live thì nghe tiếp', (tester) async {
      final speech = _FakeSpeech();
      final rig = _Rig(ai: _ScriptedAi([_say('Chào.'), _say('Chào lại.')]), speech: speech, tts: _FakeTts());
      await _pumpApp(tester, rig);

      await tester.tap(find.byKey(const Key('ai-mic')));
      await settle(tester);
      speech.say('xin chào', isFinal: true);
      await tester.pump(AiChatViewModel.sendDelay + const Duration(milliseconds: 100));
      await settle(tester);
      expect(find.text('Chào.'), findsOneWidget);
      expect(speech.isListening, isFalse); // mic một lượt: dừng
      expect(rig.vm.live, isFalse);

      await tester.tap(find.byKey(const Key('ai-live')));
      await settle(tester);
      expect(find.byKey(const Key('ai-mic')), findsNothing); // Live: ẩn mic, chỉ còn nút Live đang bật
      speech.say('chào nữa', isFinal: true);
      await tester.pump(AiChatViewModel.sendDelay + const Duration(milliseconds: 100));
      await settle(tester);
      expect(find.text('Chào lại.'), findsOneWidget);
      expect(speech.isListening, isTrue); // Live: tự nghe tiếp
    });
  });

  group('giọng đọc: lỗi phải hiện ra, không im lặng', () {
    testWidgets('TTS lỗi/không nạp được -> toast cho người dùng, hội thoại vẫn chạy', (tester) async {
      final speech = _FakeSpeech();
      final tts = _FakeTts()..error = 'Giọng đọc chưa được nạp: hãy dừng và chạy lại ứng dụng';
      final rig = _Rig(ai: _ScriptedAi([_say('Xin chào thầy cô.')]), speech: speech, tts: tts);
      await _pumpApp(tester, rig);
      await tester.tap(find.byKey(const Key('ai-mic')));
      await tester.pump();
      speech.say('xin chào', isFinal: true);
      await tester.pump(AiChatViewModel.sendDelay + const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Xin chào thầy cô.'), findsOneWidget);
      expect(rig.vm.voiceError, contains('chạy lại ứng dụng'));
      expect(find.textContaining('chạy lại ứng dụng'), findsOneWidget); // toast
      await tester.pump(const Duration(seconds: 5));
    });
  });

  group('gộp yêu cầu khi AI đang xử lý', () {
    Future<void> settle(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    Future<void> say(WidgetTester tester, _FakeSpeech speech, String text) async {
      speech.say(text, isFinal: true);
      await tester.pump(AiChatViewModel.sendDelay + const Duration(milliseconds: 100));
      await settle(tester);
    }

    Iterable<Object?> userTexts(List<Map<String, dynamic>> history) =>
        history.where((m) => m['role'] == 'user').map((m) => m['text']);

    testWidgets('Live: AI đang xử lý mà bạn nói thêm -> mic vẫn nghe, yêu cầu mới GỘP vào cùng ngữ cảnh, AI trả lời chung một lần', (tester) async {
      final speech = _FakeSpeech();
      final tts = _FakeTts();
      final ai = _ScriptedAi([_say('Trả lời cho yêu cầu một (bị thay thế).'), _say('Trả lời gộp cả hai.')]);
      final gate = Completer<void>();
      ai.hold = gate;
      final rig = _Rig(ai: ai, speech: speech, tts: tts);
      await _pumpApp(tester, rig);
      await tester.tap(find.byKey(const Key('ai-live')));
      await settle(tester);

      await say(tester, speech, 'cho tôi báo cáo chuyên cần'); // AI bắt đầu xử lý (bị giữ lại)
      expect(rig.vm.sending, isTrue);
      expect(speech.isListening, isTrue, reason: 'lúc AI xử lý mic vẫn nghe để nhận yêu cầu thêm');
      expect(find.textContaining('AI đang xử lý, câu mới sẽ được gộp'), findsOneWidget);

      await say(tester, speech, 'và cả sinh viên có nguy cơ'); // nói thêm giữa lúc AI đang xử lý
      gate.complete(); // kết quả của yêu cầu một về muộn: phải bị bỏ qua
      await settle(tester);

      expect(find.text('Trả lời cho yêu cầu một (bị thay thế).'), findsNothing);
      expect(find.text('Trả lời gộp cả hai.'), findsOneWidget);
      expect(userTexts(ai.received.last), ['cho tôi báo cáo chuyên cần', 'và cả sinh viên có nguy cơ']);
      expect(tts.spoken, ['Trả lời gộp cả hai.']); // chỉ đọc MỘT câu trả lời chung
      expect(rig.vm.live, isTrue);
      expect(speech.isListening, isTrue);
    });

    testWidgets('mic một lượt: bấm mic lúc AI đang xử lý vẫn nói thêm được, được gộp vào ngữ cảnh', (tester) async {
      final speech = _FakeSpeech();
      final ai = _ScriptedAi([_say('Bị thay thế.'), _say('Trả lời gộp.')]);
      final gate = Completer<void>();
      ai.hold = gate;
      final rig = _Rig(ai: ai, speech: speech, tts: _FakeTts());
      await _pumpApp(tester, rig);

      await _type(tester, 'yêu cầu một');
      await tester.tap(find.byKey(const Key('ai-send')));
      await tester.pump();
      expect(rig.vm.sending, isTrue);

      await tester.tap(find.byKey(const Key('ai-mic'))); // mic không bị khoá lúc AI đang xử lý
      await settle(tester);
      expect(speech.isListening, isTrue);
      await say(tester, speech, 'yêu cầu hai');
      gate.complete();
      await settle(tester);

      expect(find.text('Trả lời gộp.'), findsOneWidget);
      expect(find.text('Bị thay thế.'), findsNothing);
      expect(userTexts(ai.received.last), ['yêu cầu một', 'yêu cầu hai']);
    });

    testWidgets('AI trả lời xong mà bạn đang nói dở: KHÔNG đọc đè lên bạn; câu bạn nói sau đó được gộp vào ngữ cảnh', (tester) async {
      final speech = _FakeSpeech();
      final tts = _FakeTts();
      final ai = _ScriptedAi([_say('Trả lời một.'), _say('Trả lời gộp.')]);
      final gate = Completer<void>();
      ai.hold = gate;
      final rig = _Rig(ai: ai, speech: speech, tts: tts);
      await _pumpApp(tester, rig);
      await tester.tap(find.byKey(const Key('ai-live')));
      await settle(tester);

      await say(tester, speech, 'yêu cầu một');
      speech.say('tôi muốn thêm'); // đang nói dở (chưa dứt lời)
      await tester.pump(const Duration(milliseconds: 200));
      gate.complete(); // AI trả lời đúng lúc bạn đang nói
      await settle(tester);

      expect(find.text('Trả lời một.'), findsOneWidget); // vẫn hiện trong chat
      expect(tts.spoken, isEmpty, reason: 'không nói đè lên người đang nói');
      expect(speech.isListening, isTrue);

      speech.say('tôi muốn thêm một điều nữa', isFinal: true);
      await tester.pump(AiChatViewModel.sendDelay + const Duration(milliseconds: 100));
      await settle(tester);

      expect(find.text('Trả lời gộp.'), findsOneWidget);
      // Lượt sau thấy cả yêu cầu một, câu trả lời một và phần nói thêm.
      expect(ai.received.last.map((m) => m['role']), ['user', 'model', 'user']);
      expect(userTexts(ai.received.last), ['yêu cầu một', 'tôi muốn thêm một điều nữa']);
      expect(tts.spoken, ['Trả lời gộp.']);
    });

    testWidgets('Live: im lặng lúc AI còn đang xử lý KHÔNG bị tính để thoát Live', (tester) async {
      final speech = _FakeSpeech();
      final ai = _ScriptedAi([_say('Xong.')]);
      final gate = Completer<void>();
      ai.hold = gate;
      final rig = _Rig(ai: ai, speech: speech, tts: _FakeTts());
      await _pumpApp(tester, rig);
      await tester.tap(find.byKey(const Key('ai-live')));
      await settle(tester);
      await say(tester, speech, 'yêu cầu chạy lâu');

      for (var i = 0; i < 4; i++) {
        await tester.pump(AiChatViewModel.engineWarmup + const Duration(milliseconds: 100));
        speech.endSilently(); // im lặng thật, nhiều lần liên tiếp
        await settle(tester);
        expect(rig.vm.live, isTrue, reason: 'AI vẫn đang xử lý, chưa được thoát (lần ${i + 1})');
      }
      gate.complete();
      await settle(tester);
      expect(find.text('Xong.'), findsOneWidget);
      expect(rig.vm.live, isTrue);
    });

    testWidgets('đang GHI điểm danh: yêu cầu thêm xếp hàng (hiện ngay trong chat), gửi ngay sau khi ghi xong', (tester) async {
      final ai = _ScriptedAi([
        _call('mark_attendance', {
          'classCode': 'SWP391_SE1801',
          'students': [{'rollNumber': 'HE123456', 'status': 'ManualByGV'}],
        }),
        _say('Đã ghi xong.'),
        _say('Đây là báo cáo bạn hỏi thêm.'),
      ]);
      final rig = _Rig(ai: ai, sessions: [_session()], tts: _FakeTts());
      rig.teacher.writeHold = Completer<void>();
      await _pumpApp(tester, rig);

      await _type(tester, 'điểm danh HE123456');
      await _tapSend(tester);
      await tester.tap(find.byKey(const Key('ai-confirm')));
      await tester.pump();
      expect(rig.vm.sending, isTrue); // đang ghi

      await _type(tester, 'cho tôi báo cáo luôn');
      await tester.tap(find.byKey(const Key('ai-send')));
      await tester.pump();
      expect(find.text('cho tôi báo cáo luôn'), findsOneWidget); // hiện ngay
      expect(rig.vm.queuedCount, 1);
      expect(find.textContaining('1 yêu cầu đang chờ'), findsOneWidget); // dòng trạng thái báo có yêu cầu đang chờ
      expect(ai.received, hasLength(1)); // chưa gọi AI cho yêu cầu thêm

      rig.teacher.writeHold!.complete();
      await settle(tester);
      expect(rig.teacher.writes, hasLength(1)); // ghi hoàn tất đúng 1 lần
      expect(find.text('Đây là báo cáo bạn hỏi thêm.'), findsOneWidget);
      expect(rig.vm.queuedCount, 0);
      // Lượt cuối: kết quả ghi đã nằm trong ngữ cảnh, sau đó là yêu cầu thêm.
      final last = ai.received.last;
      expect(last.last, {'role': 'user', 'text': 'cho tôi báo cáo luôn'});
      expect(last.any((m) => m['role'] == 'tool' && m['name'] == 'mark_attendance'), isTrue);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('đang chờ thẻ xác nhận: gõ "xác nhận" là xác nhận; gõ yêu cầu khác thì xếp hàng', (tester) async {
      final ai = _ScriptedAi([
        _call('mark_attendance', {
          'classCode': 'SWP391_SE1801',
          'students': [{'rollNumber': 'HE123456', 'status': 'ManualByGV'}],
        }),
        _say('Đã ghi xong.'),
        _say('Báo cáo cho yêu cầu thêm.'),
      ]);
      final rig = _Rig(ai: ai, sessions: [_session()], tts: _FakeTts());
      await _pumpApp(tester, rig);

      await _type(tester, 'điểm danh HE123456');
      await _tapSend(tester);
      expect(rig.vm.pendingAction, isNotNull);

      await _type(tester, 'cho tôi báo cáo chuyên cần'); // không phải quyết định -> xếp hàng
      await tester.tap(find.byKey(const Key('ai-send')));
      await tester.pump();
      expect(rig.vm.pendingAction, isNotNull);
      expect(rig.vm.queuedCount, 1);
      expect(rig.teacher.writes, isEmpty);

      await _type(tester, 'xác nhận');
      await _tapSend(tester); // gõ chữ thay cho bấm nút
      await settle(tester);

      expect(rig.teacher.writes, hasLength(1));
      expect(find.byKey(const Key('ai-result-confirmed')), findsOneWidget);
      expect(find.text('Báo cáo cho yêu cầu thêm.'), findsOneWidget); // yêu cầu xếp hàng được gửi sau khi xác nhận
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('đang chờ thẻ xác nhận: gõ "huỷ" là huỷ', (tester) async {
      final ai = _ScriptedAi([
        _call('mark_attendance', {
          'classCode': 'SWP391_SE1801',
          'students': [{'rollNumber': 'HE123456', 'status': 'Absent'}],
        }),
        _say('Ok, mình không ghi.'),
      ]);
      final rig = _Rig(ai: ai, sessions: [_session()], tts: _FakeTts());
      await _pumpApp(tester, rig);
      await _type(tester, 'đánh vắng HE123456');
      await _tapSend(tester);
      await _type(tester, 'huỷ');
      await _tapSend(tester);
      await settle(tester);
      expect(rig.teacher.writes, isEmpty);
      expect(find.byKey(const Key('ai-result-cancelled')), findsOneWidget);
    });

    testWidgets('đang chờ thẻ xác nhận: bấm mic = nói "xác nhận"/"huỷ" bằng giọng', (tester) async {
      final speech = _FakeSpeech();
      final ai = _ScriptedAi([
        _call('mark_attendance', {
          'classCode': 'SWP391_SE1801',
          'students': [{'rollNumber': 'HE123456', 'status': 'ManualByGV'}],
        }),
        _say('Xong.'),
      ]);
      final rig = _Rig(ai: ai, sessions: [_session()], speech: speech, tts: _FakeTts());
      await _pumpApp(tester, rig);
      await _type(tester, 'điểm danh HE123456');
      await _tapSend(tester);
      expect(rig.vm.pendingAction, isNotNull);

      await tester.tap(find.byKey(const Key('ai-mic')));
      await settle(tester);
      expect(rig.vm.confirmingByVoice, isTrue);
      speech.say('xác nhận', isFinal: true);
      await tester.pump(AiChatViewModel.confirmDelay + const Duration(milliseconds: 100));
      await settle(tester);
      expect(rig.teacher.writes, hasLength(1));
      await tester.pump(const Duration(seconds: 5));
    });
  });

  group('ngắt AI giữa chừng', () {
    Future<void> settle(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('đang ĐỌC: bấm Dừng -> cắt giọng ngay; Live thì nghe tiếp luôn', (tester) async {
      final speech = _FakeSpeech();
      final tts = _FakeTts()..hold = Completer<void>();
      final rig = _Rig(ai: _ScriptedAi([_say('Một câu trả lời rất dài.')]), speech: speech, tts: tts);
      await _pumpApp(tester, rig);
      await tester.tap(find.byKey(const Key('ai-live')));
      await settle(tester);
      speech.say('xin chào', isFinal: true);
      await tester.pump(AiChatViewModel.sendDelay + const Duration(milliseconds: 100));
      await settle(tester);
      expect(rig.vm.speaking, isTrue);
      expect(find.byKey(const Key('ai-stop')), findsOneWidget);
      final startsBefore = speech.starts;

      await tester.tap(find.byKey(const Key('ai-stop')));
      await settle(tester);

      expect(tts.stops, greaterThan(0));
      expect(rig.vm.speaking, isFalse);
      expect(speech.starts, startsBefore + 1); // nghe tiếp ngay để GV nói câu mới
      expect(find.byKey(const Key('ai-send')), findsOneWidget); // nút Dừng đổi lại thành Gửi
    });

    testWidgets('đang XỬ LÝ: bấm Dừng -> huỷ yêu cầu, kết quả về muộn bị bỏ qua, history không còn mảnh dở', (tester) async {
      final ai = _ScriptedAi([_say('Trả lời muộn không được hiện.'), _say('Trả lời cho câu hai.')]);
      final gate = Completer<void>();
      ai.hold = gate;
      final rig = _Rig(ai: ai, tts: _FakeTts());
      await _pumpApp(tester, rig);

      await _type(tester, 'câu một');
      await tester.tap(find.byKey(const Key('ai-send')));
      await tester.pump();
      expect(rig.vm.sending, isTrue);
      expect(find.byKey(const Key('ai-stop')), findsOneWidget);

      await tester.tap(find.byKey(const Key('ai-stop')));
      await tester.pump();
      expect(rig.vm.sending, isFalse);
      expect(find.text('Đã dừng.'), findsOneWidget);

      gate.complete(); // kết quả của lượt bị ngắt vẫn về muộn, nhưng phải bị bỏ qua
      await settle(tester);
      expect(find.text('Trả lời muộn không được hiện.'), findsNothing);

      await _type(tester, 'câu hai');
      await _tapSend(tester);
      expect(find.text('Trả lời cho câu hai.'), findsOneWidget);
      // history gửi lượt 2: hai tin người dùng, không có tin model/tool dở dang của lượt bị ngắt.
      expect(ai.received.last.map((m) => m['role']), ['user', 'user']);
    });

    testWidgets('gõ câu mới khi AI đang xử lý -> tự ngắt câu cũ rồi trả lời câu mới', (tester) async {
      final ai = _ScriptedAi([_say('Trả lời cho câu một (bị bỏ).'), _say('Trả lời cho câu hai.')]);
      final gate = Completer<void>();
      ai.hold = gate;
      final rig = _Rig(ai: ai, tts: _FakeTts());
      await _pumpApp(tester, rig);

      await _type(tester, 'câu một');
      await tester.tap(find.byKey(const Key('ai-send')));
      await tester.pump();
      expect(rig.vm.sending, isTrue);

      await _type(tester, 'câu hai');
      expect(find.byKey(const Key('ai-send')), findsOneWidget); // đã gõ chữ: hiện Gửi thay vì Dừng
      await _tapSend(tester);
      gate.complete(); // câu một về muộn: phải bị bỏ qua
      await settle(tester);

      expect(find.text('Trả lời cho câu hai.'), findsOneWidget);
      expect(find.text('Trả lời cho câu một (bị bỏ).'), findsNothing);
    });

    testWidgets('ngắt giữa chuỗi tool: history bị cắt về trước lượt dở (không còn functionCall mồ côi)', (tester) async {
      final ai = _ScriptedAi([
        _call('list_my_classes', {}),
        _say('Không bao giờ hiện.'),
        _say('Câu trả lời kế tiếp.'),
      ]);
      ai.hold = Completer<void>();
      ai.holdAtCall = 2; // lượt 1 trả tool call, lượt 2 (sau khi tool chạy xong) bị giữ lại
      final rig = _Rig(ai: ai, tts: _FakeTts());
      await _pumpApp(tester, rig);

      await _type(tester, 'hôm nay dạy lớp nào');
      await tester.tap(find.byKey(const Key('ai-send')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(ai.received, hasLength(2)); // đã chạy tool, đang chờ lượt 2
      expect(rig.vm.sending, isTrue);

      await tester.tap(find.byKey(const Key('ai-stop')));
      await tester.pump();
      expect(rig.vm.sending, isFalse);

      await _type(tester, 'thôi hỏi câu khác');
      await _tapSend(tester);
      expect(find.text('Không bao giờ hiện.'), findsNothing);
      // Lượt sau chỉ có hai tin người dùng: không còn model(toolCalls)/tool dở dang của lượt bị ngắt.
      expect(ai.received.last.map((m) => m['role']), ['user', 'user']);
    });

    testWidgets('lệnh GHI đang thực thi: ngắt KHÔNG huỷ ghi (chỉ cắt giọng) và ghi vẫn hoàn tất đúng 1 lần', (tester) async {
      final speech = _FakeSpeech();
      final ai = _ScriptedAi([
        _call('mark_attendance', {
          'classCode': 'SWP391_SE1801',
          'students': [{'rollNumber': 'HE123456', 'status': 'ManualByGV'}],
        }),
        _say('Đã ghi xong.'),
      ]);
      final rig = _Rig(ai: ai, sessions: [_session()], speech: speech, tts: _FakeTts());
      rig.teacher.writeHold = Completer<void>();
      await _pumpApp(tester, rig);

      await _type(tester, 'điểm danh HE123456');
      await _tapSend(tester);
      await tester.tap(find.byKey(const Key('ai-confirm')));
      await tester.pump();
      expect(rig.vm.sending, isTrue);

      await rig.vm.interrupt(); // cố ngắt giữa lúc đang ghi
      expect(rig.vm.sending, isTrue); // không huỷ ghi
      expect(find.text('Đã dừng.'), findsNothing);

      rig.teacher.writeHold!.complete();
      await settle(tester);
      expect(rig.teacher.writes, hasLength(1));
      expect(find.byKey(const Key('ai-result-confirmed')), findsOneWidget);
      expect(find.text('Đã ghi xong.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
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
