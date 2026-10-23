import 'package:flutter/foundation.dart';

import 'package:fapcheckin_core/result/api_result.dart';
import 'package:fapcheckin_core/models/report_model.dart';
import 'package:fapcheckin_core/repositories/report_repository.dart';

class ReportViewModel extends ChangeNotifier {
  final ReportRepository repository;
  ReportViewModel(this.repository);

  ReportData? report;
  String? errorMessage;
  bool loading = false;
  bool _disposed = false;

  Future<void> load({bool force = false}) async {
    if (loading || (!force && report != null)) return;
    loading = true;
    errorMessage = null;
    notifyListeners();
    final result = await repository.getReport();
    if (_disposed) return;
    loading = false;
    switch (result) {
      case ApiSuccess<ReportData>(:final data):
        report = data;
      case ApiFailure<ReportData>(:final error):
        errorMessage = error.message;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
