import '../../core/network/api_result.dart';
import '../../core/network/api_service.dart';
import '../models/report_model.dart';

class ReportRepository {
  final ApiService _api;
  ReportRepository(this._api);

  Future<ApiResult<ReportData>> getReport() => _api.postAction(
    'getReport',
    fromJsonT: (data) => ReportData.fromJson(Map<String, dynamic>.from(data)),
  );
}
