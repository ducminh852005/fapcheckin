import '../../core/network/api_result.dart';
import '../../core/network/api_response.dart';
import '../../core/network/api_service.dart';
import '../models/class_section_model.dart';
import '../models/roster_entry_model.dart';
import '../models/session_model.dart';
import '../models/stats_entry_model.dart';

/// Repository for all teacher-side API calls.
/// The only place that knows about action names and maps
/// ApiResponse<T> → ApiResult<T> for the ViewModel.
class TeacherRepository {
  final ApiService _api;

  TeacherRepository(this._api);

  // ── getClasses ─────────────────────────────────────────────────────────────

  Future<ApiResult<List<ClassSectionModel>>> getClasses({
    required String teacherMemberCode,
  }) async {
    final result = await _api.postAction<List<ClassSectionModel>>(
      'getClasses',
      payload: {'teacherMemberCode': teacherMemberCode},
      fromJsonT: (data) {
        if (data is List) {
          return data
              .map((e) =>
                  ClassSectionModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return <ClassSectionModel>[];
      },
    );
    return result;
  }

  // ── startSession ────────────────────────────────────────────────────────────

  Future<ApiResult<SessionModel>> startSession({
    required String classCode,
    required String slotCode,
    required String teacherIp,
  }) async {
    final result = await _api.postAction<SessionModel>(
      'startSession',
      payload: {
        'classCode': classCode,
        'slotCode': slotCode,
        'teacherIp': teacherIp,
      },
      fromJsonT: (data) => SessionModel.fromJson(data as Map<String, dynamic>),
    );
    return result;
  }

  // ── getRoster ──────────────────────────────────────────────────────────────

  Future<ApiResult<List<RosterEntryModel>>> getRoster({
    required String sessionId,
  }) async {
    final result = await _api.postAction<List<RosterEntryModel>>(
      'getRoster',
      payload: {'sessionId': sessionId},
      fromJsonT: (data) {
        if (data is List) {
          return data
              .map((e) =>
                  RosterEntryModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return <RosterEntryModel>[];
      },
    );
    return result;
  }

  // ── manualCheckin ──────────────────────────────────────────────────────────

  Future<ApiResult<void>> manualCheckin({
    required String sessionId,
    required String rollNumber,
    String status = 'ManualByGV',
  }) async {
    final result = await _api.postAction<void>(
      'manualCheckin',
      payload: {
        'sessionId': sessionId,
        'rollNumber': rollNumber,
        'status': status,
      },
    );
    return result;
  }

  // ── manualCheckinBulk ──────────────────────────────────────────────────────

  Future<ApiResult<void>> manualCheckinBulk({
    required String sessionId,
    required List<Map<String, dynamic>> changes,
  }) async {
    final result = await _api.postAction<void>(
      'manualCheckinBulk',
      payload: {
        'sessionId': sessionId,
        'changes': changes,
      },
    );
    return result;
  }

  // ── closeSession ───────────────────────────────────────────────────────────

  Future<ApiResult<void>> closeSession({
    required String sessionId,
  }) async {
    final result = await _api.postAction<void>(
      'closeSession',
      payload: {'sessionId': sessionId},
    );
    return result;
  }

  // ── getStats ───────────────────────────────────────────────────────────────

  Future<ApiResult<List<StatsEntryModel>>> getStats({
    required String classCode,
  }) async {
    final result = await _api.postAction<List<StatsEntryModel>>(
      'getStats',
      payload: {'classCode': classCode},
      fromJsonT: (data) {
        if (data is List) {
          return data
              .map((e) =>
                  StatsEntryModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return <StatsEntryModel>[];
      },
    );
    return result;
  }
}
