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
      rollNumber: json['rollNumber'] as String? ?? '',
      attendancePercentage:
          (json['attendancePercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
