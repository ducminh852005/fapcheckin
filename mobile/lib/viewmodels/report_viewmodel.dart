import 'package:flutter/foundation.dart';

import 'package:fapcheckin_core/result/api_result.dart';
import 'package:fapcheckin_core/models/report_model.dart';
import 'package:fapcheckin_core/repositories/report_repository.dart';

class ReportViewModel extends ChangeNotifier {
  final ReportRepository repository;
  ReportViewModel(this.repository);

  DateTime? from, to;
  ReportData? report;
  String? errorMessage;
  bool loading = false;
  bool _disposed = false;

  int _generation = 0;
  void reset() {
    _generation++;
    from = to = null;
    report = null;
    errorMessage = null;
    loading = false;
    notifyListeners();
  }

  Future<void> load({bool force = false}) async {
    if (loading || (!force && report != null)) return;
    final generation = ++_generation;
    loading = true;
    errorMessage = null;
    notifyListeners();
    final result = from == null ? await repository.getReport() : await repository.getReportForRange(from!, to!);
    if (_disposed || generation != _generation) return;
    loading = false;
    switch (result) {
      case ApiSuccess<ReportData>(:final data):
        report = data;
      case ApiFailure<ReportData>(:final error):
        errorMessage = error.message;
    }
    notifyListeners();
  }

  Future<void> setRange(DateTime? start, DateTime? end) async {
    _generation++;
    loading = false;
    report = null;
    from = start; to = end;
    await load(force: true);
  }
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
