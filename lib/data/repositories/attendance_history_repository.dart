import '../../core/network/api_result.dart';
import '../../core/network/api_service.dart';
import '../models/history_class.dart';
import '../models/history_detail.dart';
import '../models/session_model.dart';

class AttendanceHistoryRepository {
  final ApiService _api;
  AttendanceHistoryRepository(this._api);
  Future<ApiResult<List<HistoryClass>>> getClasses() => _api.postAction(
    'getHistoryClasses',
    fromJsonT: (data) => (data as List)
        .map((c) => HistoryClass.fromJson(Map<String, dynamic>.from(c)))
        .toList(),
  );
  Future<ApiResult<HistoryDetail>> getDetail(
    String classCode, {
    String? sessionId,
  }) => _api.postAction(
    'getHistoryDetail',
    payload: {
      'classCode': classCode,
      if (sessionId != null) 'sessionId': sessionId,
    },
    fromJsonT: (data) =>
        HistoryDetail.fromJson(Map<String, dynamic>.from(data)),
  );
  Future<ApiResult<HistoryDetail>> save(
    String classCode,
    String sessionId,
    List<Map<String, dynamic>> changes,
  ) => _api.postAction(
    'saveAttendanceChanges',
    payload: {
      'classCode': classCode,
      'sessionId': sessionId,
      'changes': changes,
    },
    fromJsonT: (data) =>
        HistoryDetail.fromJson(Map<String, dynamic>.from(data)),
  );
  Future<ApiResult<AttendanceMatrix>> getMatrix(String classCode) =>
      _api.postAction(
        'getAttendanceMatrix',
        payload: {'classCode': classCode},
        fromJsonT: (data) =>
            AttendanceMatrix.fromJson(Map<String, dynamic>.from(data)),
      );
  Future<ApiResult<HistoryExport>> export(
    String classCode,
    String? sessionId,
  ) => _api.postAction(
    'exportAttendanceHistory',
    payload: {
      'classCode': classCode,
      if (sessionId != null) 'sessionId': sessionId,
    },
    fromJsonT: (data) =>
        HistoryExport.fromJson(Map<String, dynamic>.from(data)),
  );
  Future<ApiResult<SessionModel>> startSession(
    String classCode,
    String slotCode,
    String teacherIp,
  ) => _api.postAction(
    'startHistorySession',
    payload: {
      'classCode': classCode,
      'slotCode': slotCode,
      'teacherIp': teacherIp,
    },
    fromJsonT: (data) => SessionModel.fromJson(Map<String, dynamic>.from(data)),
  );
}
