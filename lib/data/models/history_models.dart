// Các model trong file này ánh xạ 1-1 với DTO mà `AttendanceHistoryService`
// (Backend thật, file .gs bạn cung cấp) trả về — KHÁC với model
// `ClassModel`/`AttendanceModel` cũ (những model đó dùng tên trường tạm
// đặt trước khi có Backend thật). Cố tình tách riêng để không phải sửa lại
// toàn bộ luồng QR sống đang chạy tốt, trong lúc build tính năng mới này.

/// 1 ca học cố định trong ngày (Slot sheet) — ví dụ "Slot 2" từ 09:45-12:00.
String _text(dynamic value) => value == null ? '' : value.toString();

int _int(dynamic value) =>
    value is num ? value.toInt() : int.tryParse(_text(value)) ?? 0;

class SlotModel {
  final String slotCode;
  final String startTime;
  final String endTime;

  const SlotModel({
    required this.slotCode,
    required this.startTime,
    required this.endTime,
  });

  factory SlotModel.fromJson(Map<String, dynamic> json) {
    return SlotModel(
      slotCode: _text(json['slotCode']),
      startTime: _text(json['startTime']),
      endTime: _text(json['endTime']),
    );
  }
}

/// Tương ứng `sessionDto()` trong Backend — 1 buổi học cụ thể đã/đang diễn ra.
class HistorySessionModel {
  final String sessionId;
  final String sessionDate;
  final String slotCode;
  final String sessionStatus; // 'open' | 'closed' — Backend dùng chữ thường

  const HistorySessionModel({
    required this.sessionId,
    required this.sessionDate,
    required this.slotCode,
    required this.sessionStatus,
  });

  factory HistorySessionModel.fromJson(Map<String, dynamic> json) {
    return HistorySessionModel(
      sessionId: _text(json['sessionId']),
      sessionDate: _text(json['sessionDate']),
      slotCode: _text(json['slotCode']),
      sessionStatus: _text(json['sessionStatus']),
    );
  }

  bool get isClosed => sessionStatus == 'closed';
}

/// Tương ứng `classDto()` — số liệu tóm tắt của 1 lớp (dùng ở danh sách bên
/// trái + phần header của bảng chi tiết).
class ClassSummaryModel {
  final String classCode;
  final String subjectCode;
  final String subjectName;
  final String room;
  final int studentCount;
  final int completedSessions;
  final int totalSessions;
  final double
  attendanceRate; // 0..1 — Backend trả về tỉ lệ thập phân, không phải %
  final double lateRate; // 0..1
  final int atRiskCount; // Số SV vắng > 20% buổi đã học — có nguy cơ cấm thi
  final HistorySessionModel? latestSession;

  const ClassSummaryModel({
    required this.classCode,
    required this.subjectCode,
    required this.subjectName,
    required this.room,
    required this.studentCount,
    required this.completedSessions,
    required this.totalSessions,
    required this.attendanceRate,
    required this.lateRate,
    required this.atRiskCount,
    required this.latestSession,
  });

  factory ClassSummaryModel.fromJson(Map<String, dynamic> json) {
    return ClassSummaryModel(
      classCode: _text(json['classCode']),
      subjectCode: _text(json['subjectCode']),
      subjectName: _text(json['subjectName']),
      room: _text(json['room']),
      studentCount: _int(json['studentCount']),
      completedSessions: _int(json['completedSessions']),
      totalSessions: _int(json['totalSessions']),
      attendanceRate: double.tryParse(_text(json['attendanceRate'])) ?? 0,
      lateRate: double.tryParse(_text(json['lateRate'])) ?? 0,
      atRiskCount: _int(json['atRiskCount']),
      latestSession: json['latestSession'] != null
          ? HistorySessionModel.fromJson(
              json['latestSession'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

/// 1 dòng sinh viên trong bảng chi tiết buổi học.
///
/// [revision] là "vân tay" (fingerprint) của bản ghi tại thời điểm tải về —
/// dùng cho optimistic concurrency: khi Lưu, Backend so sánh revision gửi
/// lên với revision hiện tại trên Sheet. Nếu khác (ai đó đã sửa trong lúc
/// bạn đang xem), Backend từ chối lưu (lỗi CONFLICT) thay vì âm thầm ghi đè.
class StudentHistoryModel {
  final String rollNumber;
  final String fullName;
  final String email;
  final String status; // Present | Late | Absent | ManualByGV | Unchecked
  final String checkinTime;
  final String networkVerificationResult;
  final String note;
  final int absenceCount;
  final int totalSessions;
  final String revision;

  const StudentHistoryModel({
    required this.rollNumber,
    required this.fullName,
    required this.email,
    required this.status,
    required this.checkinTime,
    required this.networkVerificationResult,
    required this.note,
    required this.absenceCount,
    required this.totalSessions,
    required this.revision,
  });

  factory StudentHistoryModel.fromJson(Map<String, dynamic> json) {
    return StudentHistoryModel(
      rollNumber: _text(json['rollNumber']),
      fullName: _text(json['fullName']),
      email: _text(json['email']),
      status: _text(json['status']).isEmpty
          ? 'Unchecked'
          : _text(json['status']),
      checkinTime: _text(json['checkinTime']),
      networkVerificationResult: _text(json['networkVerificationResult']),
      note: _text(json['note']),
      absenceCount: _int(json['absenceCount']),
      totalSessions: _int(json['totalSessions']),
      revision: _text(json['revision']),
    );
  }

  /// Tạo bản sao chỉ đổi status/note — dùng khi GV sửa tại chỗ trong bảng.
  /// [revision] CỐ Ý không đổi theo vì nó phải giữ nguyên giá trị lúc tải
  /// về để Backend so sánh đúng (xem giải thích ở docstring của class).
  StudentHistoryModel copyWith({String? status, String? note}) {
    return StudentHistoryModel(
      rollNumber: rollNumber,
      fullName: fullName,
      email: email,
      status: status ?? this.status,
      checkinTime: checkinTime,
      networkVerificationResult: networkVerificationResult,
      note: note ?? this.note,
      absenceCount: absenceCount,
      totalSessions: totalSessions,
      revision: revision,
    );
  }
}

/// Tương ứng kết quả `getDetail()` — toàn bộ dữ liệu để vẽ màn hình chi tiết
/// 1 lớp + 1 buổi học được chọn.
class ClassHistoryDetailModel {
  final ClassSummaryModel classInfo;
  final String teacherName;
  final List<HistorySessionModel> sessions;
  final HistorySessionModel? selectedSession;
  final List<SlotModel> slots;
  final List<StudentHistoryModel> students;

  const ClassHistoryDetailModel({
    required this.classInfo,
    required this.teacherName,
    required this.sessions,
    required this.selectedSession,
    required this.slots,
    required this.students,
  });

  factory ClassHistoryDetailModel.fromJson(Map<String, dynamic> json) {
    return ClassHistoryDetailModel(
      classInfo: ClassSummaryModel.fromJson(
        json['classInfo'] as Map<String, dynamic>,
      ),
      teacherName: json['teacherName'] as String? ?? '',
      sessions: (json['sessions'] as List<dynamic>? ?? [])
          .map((e) => HistorySessionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      selectedSession: json['selectedSession'] != null
          ? HistorySessionModel.fromJson(
              json['selectedSession'] as Map<String, dynamic>,
            )
          : null,
      slots: (json['slots'] as List<dynamic>? ?? [])
          .map((e) => SlotModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      students: (json['students'] as List<dynamic>? ?? [])
          .map((e) => StudentHistoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Tương ứng `getMatrix()` — toàn bộ lịch sử điểm danh của lớp dưới dạng
/// bảng "sinh viên × buổi học" (giống 1 sổ điểm danh giấy truyền thống).
class AttendanceMatrixModel {
  final List<HistorySessionModel> sessions;
  final List<MatrixStudentRow> students;

  const AttendanceMatrixModel({required this.sessions, required this.students});

  factory AttendanceMatrixModel.fromJson(Map<String, dynamic> json) {
    return AttendanceMatrixModel(
      sessions: (json['sessions'] as List<dynamic>? ?? [])
          .map((e) => HistorySessionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      students: (json['students'] as List<dynamic>? ?? [])
          .map((e) => MatrixStudentRow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MatrixStudentRow {
  final String rollNumber;
  final String fullName;
  final List<String>
  statuses; // Song song 1-1 với AttendanceMatrixModel.sessions

  const MatrixStudentRow({
    required this.rollNumber,
    required this.fullName,
    required this.statuses,
  });

  factory MatrixStudentRow.fromJson(Map<String, dynamic> json) {
    return MatrixStudentRow(
      rollNumber: json['rollNumber'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      statuses: (json['statuses'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }
}

class HistoryExportModel {
  final String filename;
  final String mimeType;
  final String base64;

  const HistoryExportModel({
    required this.filename,
    required this.mimeType,
    required this.base64,
  });

  factory HistoryExportModel.fromJson(Map<String, dynamic> json) {
    return HistoryExportModel(
      filename: _text(json['filename']),
      mimeType: _text(json['mimeType']).isEmpty
          ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
          : _text(json['mimeType']),
      base64: _text(json['base64']),
    );
  }
}

/// 1 thay đổi GV thực hiện trên 1 sinh viên — gửi kèm trong mảng `changes`
/// của `saveChanges()`. Backend giới hạn tối đa 500 thay đổi/lần gọi.
class AttendanceChange {
  final String rollNumber;
  final String status;
  final String note;
  final String revision;

  const AttendanceChange({
    required this.rollNumber,
    required this.status,
    required this.note,
    required this.revision,
  });

  Map<String, dynamic> toJson() => {
    'rollNumber': rollNumber,
    'status': status,
    'note': note,
    'revision': revision,
  };
}

/// 5 trạng thái hợp lệ theo đúng mảng `allowed` trong Backend — dùng để đổ
/// vào Dropdown, tránh gõ nhầm chuỗi ở phía UI.
const kAllowedAttendanceStatuses = [
  'Present',
  'Late',
  'Absent',
  'ManualByGV',
  'Unchecked',
];

String attendanceStatusLabel(String status) {
  switch (status) {
    case 'Present':
      return 'Có mặt';
    case 'Late':
      return 'Đi trễ';
    case 'Absent':
      return 'Vắng';
    case 'ManualByGV':
      return 'GV điểm danh tay';
    case 'Unchecked':
    default:
      return 'Chưa điểm danh';
  }
}
