// File: StudentService.gs

var StudentService = (function() {

  // IP check is optional per session (default off when the teacher opens it).
  // Sessions created before the option existed have no `ipCheck` value and keep
  // the original behaviour (on).
  function ipCheckEnabled(session) {
    var value = session ? session.ipCheck : undefined;
    if (value === undefined || value === null || value === '') return true;
    return value === true || String(value).toUpperCase() === 'TRUE';
  }

  function checkin(params) {
    var qrToken = params.qrToken;
    var studentIp = params.studentIp;
    var rollNumber = params.rollNumber; // Trong thực tế lấy từ auth token của SV sau khi đăng nhập

    if (!qrToken || !rollNumber) {
      throwError('VALIDATION_ERROR', 'Thiếu dữ liệu: qrToken hoặc rollNumber.');
    }
    
    // 1. Tìm phiên có chứa qrToken này
    // The second argument is a read hint (used by the Firestore store only); the
    // checks below still run on whatever rows come back.
    var sessions = SheetDB.getRowsAsObjects('Attendance_Session', { qrSecret: String(qrToken), sessionStatus: 'open' });
    var targetSession = null;
    for (var i = 0; i < sessions.length; i++) {
      if (sessions[i].qrSecret === qrToken && sessions[i].sessionStatus === 'open') {
        targetSession = sessions[i];
        break;
      }
    }
    
    if (!targetSession) {
      throwError('SESSION_NOT_FOUND', 'Mã QR không hợp lệ hoặc phiên điểm danh đã kết thúc.');
    }
    
    // 2. Kiểm tra sinh viên có trong Enrollment của lớp này không
    var enrollments = SheetDB.getRowsAsObjects('Enrollment', {
      classCode: String(targetSession.classCode), rollNumber: String(rollNumber)
    });
    var isEnrolled = false;
    for (var j = 0; j < enrollments.length; j++) {
      if (enrollments[j].classCode === targetSession.classCode && enrollments[j].rollNumber === rollNumber) {
        isEnrolled = true;
        break;
      }
    }
    
    if (!isEnrolled) {
      throwError('NOT_ENROLLED', 'Bạn không có tên trong danh sách lớp này.');
    }
    
    // 3. Kiểm tra xem sinh viên đã checkin chưa
    var records = SheetDB.getRowsAsObjects('Attendance_Record', {
      sessionId: String(targetSession.sessionId), rollNumber: String(rollNumber)
    });
    var existingRecord = null;
    for (var k = 0; k < records.length; k++) {
      if (records[k].sessionId === targetSession.sessionId && records[k].rollNumber === rollNumber) {
        existingRecord = records[k];
        break;
      }
    }
    
    // 4. Đối chiếu IP — chỉ khi giảng viên bật kiểm tra IP cho phiên này
    var sIp = String(studentIp || '').trim();
    var checkIp = ipCheckEnabled(targetSession);
    var networkResult = 'Skipped';
    if (checkIp) {
      // The student page sends no IP first and retries with it after IP_REQUIRED,
      // so it only depends on the IP lookup service when the check is on.
      if (sIp === '') {
        throwError('IP_REQUIRED', 'Phiên này yêu cầu kiểm tra IP mạng. Cần gửi kèm IP công khai của thiết bị.');
      }
      var tIp = String(targetSession.teacherIp || '').trim();
      var isIpMatch = tIp !== '' && sIp === tIp;

      // A failed network check must never create a Present attendance record.
      // The student page already handles IP_MISMATCH and lets the student retry
      // after connecting to the correct classroom Wi-Fi.
      if (!isIpMatch) {
        throwError(
          'IP_MISMATCH',
          'IP công khai của thiết bị không trùng với IP của phiên điểm danh.'
        );
      }
      networkResult = 'Match';
    }
    
    // 5. Lưu kết quả
    var now = new Date().toISOString();

    // Repair legacy rows created by the old implementation, which incorrectly
    // stored Present together with Mismatch. A successful retry converts that
    // same row to a valid attendance record instead of creating a duplicate.
    if (existingRecord) {
      var previousNetworkResult = String(existingRecord.networkVerificationResult || '').trim().toLowerCase();
      if (previousNetworkResult !== 'mismatch') {
        throwError('ALREADY_CHECKED_IN', 'Bạn đã điểm danh trong phiên này rồi.');
      }

      var repairedRecord = {
        checkinTime: now,
        status: 'Present',
        networkVerificationResult: networkResult,
        ipAddress: sIp,
        syncedToFap: false
      };
      SheetDB.updateRow('Attendance_Record', 'recordId', existingRecord.recordId, repairedRecord);
      repairedRecord.recordId = existingRecord.recordId;
      repairedRecord.rollNumber = rollNumber;
      repairedRecord.sessionId = targetSession.sessionId;
      return repairedRecord;
    }

    var recordId = Utilities.getUuid();
    var newRecord = {
      recordId: recordId,
      rollNumber: rollNumber,
      sessionId: targetSession.sessionId,
      checkinTime: now,
      status: 'Present',
      networkVerificationResult: networkResult,
      ipAddress: sIp,
      syncedToFap: false
    };

    SheetDB.ensureColumns('Attendance_Record', ['ipAddress']);
    try {
      SheetDB.insertRow('Attendance_Record', newRecord);
    } catch (e) {
      // Firestore document ids are sessionId_rollNumber: a concurrent scan of the
      // same QR by the same student loses the race here instead of duplicating.
      if (e && e.code === 'DB_CONFLICT') {
        throwError('ALREADY_CHECKED_IN', 'Bạn đã điểm danh trong phiên này rồi.');
      }
      throw e;
    }
    
    return newRecord;
  }

  return {
    checkin: checkin
  };
})();
