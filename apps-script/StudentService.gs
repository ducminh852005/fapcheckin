// File: StudentService.gs

var StudentService = (function() {

  function checkin(params) {
    var qrToken = params.qrToken;
    var studentIp = params.studentIp;
    var rollNumber = params.rollNumber; // Trong thực tế lấy từ auth token của SV sau khi đăng nhập
    
    if (!qrToken || !studentIp || !rollNumber) {
      throwError('VALIDATION_ERROR', 'Thiếu dữ liệu: qrToken, studentIp hoặc rollNumber.');
    }
    
    // 1. Tìm phiên có chứa qrToken này
    var sessions = SheetDB.getRowsAsObjects('Attendance_Session');
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
    var enrollments = SheetDB.getRowsAsObjects('Enrollment');
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
    var records = SheetDB.getRowsAsObjects('Attendance_Record');
    for (var k = 0; k < records.length; k++) {
      if (records[k].sessionId === targetSession.sessionId && records[k].rollNumber === rollNumber) {
        throwError('ALREADY_CHECKED_IN', 'Bạn đã điểm danh trong phiên này rồi.');
      }
    }
    
    // 4. Đối chiếu IP
    var isIpMatch = (studentIp === targetSession.teacherIp);
    var networkVerificationResult = isIpMatch ? 'Match' : 'Mismatch';
    var status = 'Present'; // Mặc định nếu tự quét được là Present
    
    // 5. Lưu kết quả
    var recordId = Utilities.getUuid();
    var now = new Date().toISOString();
    var newRecord = {
      recordId: recordId,
      rollNumber: rollNumber,
      sessionId: targetSession.sessionId,
      checkinTime: now,
      status: status,
      networkVerificationResult: networkVerificationResult,
      ipAddress: studentIp,
      syncedToFap: false
    };

    SheetDB.ensureColumns('Attendance_Record', ['ipAddress']);
    SheetDB.insertRow('Attendance_Record', newRecord);
    
    return newRecord;
  }

  return {
    checkin: checkin
  };
})();
