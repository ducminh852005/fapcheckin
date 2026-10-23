class TimetableScanEntry {
  const TimetableScanEntry({
    required this.key,
    required this.classCode,
    required this.subjectCode,
    required this.room,
    required this.matchedClassCode,
    required this.status,
    required this.message,
  });

  final String key;
  final String classCode;
  final String subjectCode;
  final String room;
  final String? matchedClassCode;
  final String status;
  final String message;

  bool get canImport => status == 'available';
  bool get isAlreadyAssigned => status == 'alreadyAssigned';

  factory TimetableScanEntry.fromJson(Map<String, dynamic> json) {
    return TimetableScanEntry(
      key: json['key']?.toString() ?? '',
      classCode: json['classCode']?.toString() ?? '',
      subjectCode: json['subjectCode']?.toString() ?? '',
      room: json['room']?.toString() ?? '',
      matchedClassCode: json['matchedClassCode']?.toString(),
      status: json['status']?.toString() ?? 'notFound',
      message: json['message']?.toString() ?? '',
    );
  }
}

class TimetableScanResult {
  const TimetableScanResult({
    required this.scanToken,
    required this.entries,
    required this.detectedDates,
  });

  final String scanToken;
  final List<TimetableScanEntry> entries;
  final List<String> detectedDates;

  factory TimetableScanResult.fromJson(Map<String, dynamic> json) {
    return TimetableScanResult(
      scanToken: json['scanToken']?.toString() ?? '',
      entries: ((json['entries'] as List?) ?? const [])
          .map(
            (entry) => TimetableScanEntry.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList(),
      detectedDates: ((json['detectedDates'] as List?) ?? const [])
          .map((date) => date.toString())
          .toList(),
    );
  }
}

class TimetableImportResult {
  const TimetableImportResult({
    required this.assignedCount,
    required this.alreadyAssignedCount,
    required this.classCodes,
  });

  final int assignedCount;
  final int alreadyAssignedCount;
  final List<String> classCodes;

  factory TimetableImportResult.fromJson(Map<String, dynamic> json) {
    return TimetableImportResult(
      assignedCount: (json['assignedCount'] as num?)?.toInt() ?? 0,
      alreadyAssignedCount:
          (json['alreadyAssignedCount'] as num?)?.toInt() ?? 0,
      classCodes: ((json['classCodes'] as List?) ?? const [])
          .map((code) => code.toString())
          .toList(),
    );
  }
}
