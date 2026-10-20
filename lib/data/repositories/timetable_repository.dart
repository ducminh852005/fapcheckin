import 'dart:convert';
import 'dart:typed_data';

import '../../core/network/api_result.dart';
import '../../core/network/api_service.dart';
import '../models/timetable_scan_model.dart';

class TimetableRepository {
  TimetableRepository(this._api);

  final ApiService _api;

  Future<ApiResult<TimetableScanResult>> scanImage({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) {
    return _api.postAction<TimetableScanResult>(
      'scanTimetableImage',
      payload: {
        'fileName': fileName,
        'mimeType': mimeType,
        'imageBase64': base64Encode(bytes),
      },
      fromJsonT: (data) =>
          TimetableScanResult.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  Future<ApiResult<TimetableImportResult>> importAssignments({
    required String scanToken,
    required List<String> classCodes,
  }) {
    return _api.postAction<TimetableImportResult>(
      'importTimetableAssignments',
      payload: {'scanToken': scanToken, 'classCodes': classCodes},
      fromJsonT: (data) => TimetableImportResult.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }
}
