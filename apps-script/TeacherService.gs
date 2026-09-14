// File: TeacherService.gs

var TeacherService = (function() {
  
  function getClasses(params) {
    var teacherMemberCode = params.teacherMemberCode;
    if (!teacherMemberCode) throwError('VALIDATION_ERROR', 'Thiếu teacherMemberCode.');
    
    var classes = SheetDB.getRowsAsObjects('Class_Section');
    return classes.filter(function(c) {
      return c.teacherMemberCode === teacherMemberCode;
    });
  }
  
  function startSession(params) {
    var classCode = params.classCode;
    var slotCode = params.slotCode;
    var teacherIp = params.teacherIp;
    
    if (!classCode || !slotCode || !teacherIp) throwError('VALIDATION_ERROR', 'Thiếu dữ liệu mở phiên.');
    
    var sessionId = Utilities.getUuid();
    var qrSecret = Utilities.getUuid(); // Token tạm dùng để mã hoá vào QR
    var sessionDate = new Date().toISOString().split('T')[0];
    
    var newSession = {
      sessionId: sessionId,
      classCode: classCode,
      sessionDate: sessionDate,
      slotCode: slotCode,
      sessionStatus: 'open',
      qrSecret: qrSecret,
      teacherIp: teacherIp
    };
    
    SheetDB.insertRow('Attendance_Session', newSession);
    
    return {
      session: newSession,
      qrToken: qrSecret
    };
  }
  
  function getRoster(params) {
    var sessionId = params.sessionId;
    if (!sessionId) throwError('VALIDATION_ERROR', 'Thiếu sessionId.');
    
    // Lấy session
    var sessions = SheetDB.getRowsAsObjects('Attendance_Session');
    var session = sessions.filter(function(s) { return s.sessionId === sessionId; })[0];
    if (!session) throwError('SESSION_NOT_FOUND', 'Không tìm thấy phiên.');
    
    // Lấy Enrollment
    var enrollments = SheetDB.getRowsAsObjects('Enrollment');
    var classEnrollments = enrollments.filter(function(e) { return e.classCode === session.classCode; });
    
    // Lấy danh sách SV tương ứng
    var users = SheetDB.getRowsAsObjects('Users');
    var enrolledStudents = classEnrollments.map(function(e) {
      return users.filter(function(u) { return u.rollNumber === e.rollNumber; })[0];
    }).filter(function(u) { return !!u; }); // Bỏ qua null
    
    // Lấy bản ghi điểm danh
    var records = SheetDB.getRowsAsObjects('Attendance_Record');
    var sessionRecords = records.filter(function(r) { return r.sessionId === sessionId; });
    
    // Kết hợp
    var roster = enrolledStudents.map(function(student) {
      var record = sessionRecords.filter(function(r) { return r.rollNumber === student.rollNumber; })[0] || null;
      return {
        student: student,
        record: record
      };
    });
    
    return roster;
  }
  
  function manualCheckin(params) {
    var sessionId = params.sessionId;
    var rollNumber = params.rollNumber;
    var status = params.status;
    
    if (!sessionId || !rollNumber || !status) throwError('VALIDATION_ERROR', 'Thiếu dữ liệu.');
    
    var records = SheetDB.getRowsAsObjects('Attendance_Record');
    var existingRecord = records.filter(function(r) { 
      return r.sessionId === sessionId && r.rollNumber === rollNumber; 
    })[0];
    
    if (existingRecord) {
      // Cập nhật
      SheetDB.updateRow('Attendance_Record', 'recordId', existingRecord.recordId, {
        status: status,
        syncedToFap: false
      });
    } else {
      // Thêm mới
      SheetDB.insertRow('Attendance_Record', {
        recordId: Utilities.getUuid(),
        rollNumber: rollNumber,
        sessionId: sessionId,
        checkinTime: new Date().toISOString(),
        status: status,
        networkVerificationResult: 'Manual',
        syncedToFap: false
      });
    }
    return {}; // GenericResponse empty data
  }
  
  function getStats(params) {
    var classCode = params.classCode;
    if (!classCode) throwError('VALIDATION_ERROR', 'Thiếu classCode.');
    
    var sessions = SheetDB.getRowsAsObjects('Attendance_Session').filter(function(s) {
      return s.classCode === classCode;
    });
    var sessionIds = sessions.map(function(s) { return s.sessionId; });
    
    var enrollments = SheetDB.getRowsAsObjects('Enrollment').filter(function(e) {
      return e.classCode === classCode;
    });
    
    var records = SheetDB.getRowsAsObjects('Attendance_Record').filter(function(r) {
      return sessionIds.indexOf(r.sessionId) !== -1;
    });
    
    var stats = [];
    var totalSessions = sessionIds.length;
    
    for (var i = 0; i < enrollments.length; i++) {
      var rNumber = enrollments[i].rollNumber;
      var studentRecords = records.filter(function(r) { return r.rollNumber === rNumber; });
      var presentCount = studentRecords.filter(function(r) { 
        return r.status === 'Present' || r.status === 'Late' || r.status === 'ManualByGV'; 
      }).length;
      
      var percentage = totalSessions > 0 ? (presentCount / totalSessions) * 100 : 0;
      stats.push({
        rollNumber: rNumber,
        attendancePercentage: percentage
      });
    }
    
    return stats;
  }
  
  return {
    getClasses: getClasses,
    startSession: startSession,
    getRoster: getRoster,
    manualCheckin: manualCheckin,
    getStats: getStats
  };
})();
