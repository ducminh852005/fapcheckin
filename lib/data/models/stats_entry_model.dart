import '../../core/network/json_values.dart';

/// Model for stats entry from getStats action
class StatsEntryModel {
  final String rollNumber;
  final double attendancePercentage;

  const StatsEntryModel({
    required this.rollNumber,
    required this.attendancePercentage,
  });

  factory StatsEntryModel.fromJson(Map<String, dynamic> json) {
    return StatsEntryModel(
      rollNumber: jsonText(json['rollNumber']) ?? '',
      attendancePercentage:
          jsonNumber(json['attendancePercentage'])?.toDouble() ?? 0.0,
    );
  }
}
