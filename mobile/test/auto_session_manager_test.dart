import 'package:flutter_test/flutter_test.dart';
import 'package:fapcheckin_core/models/class_section_model.dart';
import 'package:fapcheckin_core/models/close_session_model.dart';
import 'package:fapcheckin_core/models/roster_entry_model.dart';
import 'package:fapcheckin_core/models/session_model.dart';
import 'package:fapcheckin_core/repositories/teacher_repository.dart';
import 'package:fapcheckin_core/result/api_result.dart';
import 'package:fapcheckin_core/session/current_user.dart';
import 'package:fapcheckin/core/services/auto_session_manager.dart';
import 'package:fapcheckin/viewmodels/dashboard_viewmodel.dart';
import 'package:fapcheckin/viewmodels/live_session_viewmodel.dart';

class _FakeTeacherRepository extends TeacherRepository {
  _FakeTeacherRepository() : super(currentUser: CurrentUser());

  List<ClassSectionModel> fakeClasses = [];
  int startSessionCalls = 0;
  int closeSessionCalls = 0;

  @override
  Future<ApiResult<List<ClassSectionModel>>> getClasses({
    required String teacherMemberCode,
  }) async =>
      ApiSuccess(fakeClasses);

  @override
  Future<ApiResult<SessionModel>> startSession({
    required String classCode,
    required String slotCode,
    String teacherIp = '',
    bool ipCheck = false,
  }) async {
    startSessionCalls++;
    return ApiSuccess(
      SessionModel(
        sessionId: 'sess_auto_$classCode',
        classCode: classCode,
        sessionDate: '2026-11-03',
        slotCode: slotCode,
        sessionStatus: 'open',
        qrToken: 'test_secret_123456789',
        ipCheck: false,
      ),
    );
  }

  @override
  Future<ApiResult<CloseSessionResult>> closeSession({
    required String sessionId,
  }) async {
    closeSessionCalls++;
    return ApiSuccess(
      const CloseSessionResult(
        sessionId: 'sess_1',
        sessionStatus: 'closed',
        autoAbsentCount: 5,
      ),
    );
  }

  @override
  Future<ApiResult<List<RosterEntryModel>>> getRoster({
    required String sessionId,
  }) async =>
      ApiSuccess([]);
}

void main() {
  group('TimeSlotHelper', () {
    test('resolves explicit startTime and endTime', () {
      final date = DateTime(2026, 11, 3);
      const cls = ClassSectionModel(
        classCode: 'SWD392_SE1927',
        subjectCode: 'SWD392',
        subjectName: 'Kiến trúc phần mềm',
        room: '611',
        studentCount: 35,
        teacherMemberCode: 'GV01',
        slotCode: 'A4',
        startTime: '09:30',
        endTime: '11:45',
        timeLabel: 'Slot A4 (09:30 - 11:45)',
        completedSessions: 5,
        totalSessions: 30,
        averageAttendance: 95.0,
        isActive: false,
      );

      final (start, end) = TimeSlotHelper.resolveSlotRange(date, cls);
      expect(start, DateTime(2026, 11, 3, 9, 30));
      expect(end, DateTime(2026, 11, 3, 11, 45));
    });

    test('falls back to slotCode A2 when times are missing', () {
      final date = DateTime(2026, 11, 3);
      const cls = ClassSectionModel(
        classCode: 'SWD392_SE1927',
        subjectCode: 'SWD392',
        subjectName: 'Kiến trúc phần mềm',
        room: '611',
        studentCount: 35,
        teacherMemberCode: 'GV01',
        slotCode: 'A2',
        timeLabel: 'Slot A2',
        completedSessions: 5,
        totalSessions: 30,
        averageAttendance: 95.0,
        isActive: false,
      );

      final (start, end) = TimeSlotHelper.resolveSlotRange(date, cls);
      expect(start, DateTime(2026, 11, 3, 9, 30));
      expect(end, DateTime(2026, 11, 3, 11, 45));
    });
  });

  group('AutoSessionManager', () {
    test('auto-starts session when current time enters slot', () async {
      final repo = _FakeTeacherRepository();
      final dashboardVm = DashboardViewModel(repo);
      final liveVm = LiveSessionViewModel(repo);

      // 2026-11-03 is Tuesday (weekday = 2)
      // Slot A2 has weekdays: [2, 5] (Tue, Fri)
      const cls = ClassSectionModel(
        classCode: 'SWD392_SE1927',
        subjectCode: 'SWD392',
        subjectName: 'Kiến trúc phần mềm',
        room: '611',
        studentCount: 35,
        teacherMemberCode: 'GV01',
        slotCode: 'A4',
        startTime: '09:30',
        endTime: '11:45',
        timeLabel: 'Slot A4 (09:30 - 11:45)',
        completedSessions: 5,
        totalSessions: 30,
        averageAttendance: 95.0,
        isActive: false,
      );
      repo.fakeClasses = [cls];
      dashboardVm.setTeacherInfo(name: 'GV', email: 'gv@fe.edu.vn', memberCode: 'GV01');
      await dashboardVm.loadClasses();

      // Current time is 10:05 AM (inside 09:30 - 11:45)
      var currentTime = DateTime(2026, 11, 3, 10, 5);
      final manager = AutoSessionManager(
        liveSessionViewModel: liveVm,
        dashboardViewModel: dashboardVm,
        teacherRepository: repo,
        now: () => currentTime,
      );

      await manager.checkRealtimeSessions();

      expect(repo.startSessionCalls, 1);
      expect(liveVm.session?.isOpen, isTrue);
      expect(liveVm.session?.classCode, 'SWD392_SE1927');

      // Now time passes to 11:50 AM (past 11:45)
      currentTime = DateTime(2026, 11, 3, 11, 50);
      await manager.checkRealtimeSessions();

      expect(repo.closeSessionCalls, 1);
      expect(liveVm.isClosed, isTrue);

      manager.stop();
    });
  });
}
