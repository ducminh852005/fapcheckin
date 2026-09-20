// File: TeacherService.gs

var TeacherService = (function() {
  
  function getClasses(params) {
    var teacherMemberCode = params.teacherMemberCode;
    if (!teacherMemberCode) throwError('VALIDATION_ERROR', 'Thiếu teacherMemberCode.');
    
    var classes = SheetDB.getRowsAsObjects('Class_Section').filter(function(c) {
      return c.teacherMemberCode === teacherMemberCode;
    });

    var sessions = SheetDB.getRowsAsObjects('Attendance_Session');
    var records = SheetDB.getRowsAsObjects('Attendance_Record');

    var enriched = classes.map(function(cls) {
       var classSessions = sessions.filter(function(s) { return s.classCode === cls.classCode; });
       var completed = classSessions.filter(function(s) { return s.sessionStatus === 'closed'; }).length;
       var activeSession = classSessions.filter(function(s) { return s.sessionStatus === 'open'; })[0] || null;
       
       var classRecords = records.filter(function(r) { 
           return classSessions.some(function(s) { return s.sessionId === r.sessionId; });
       });
       var presentRecords = classRecords.filter(function(r) { return r.status === 'Present' || r.status === 'Late' || r.status === 'ManualByGV'; });
       
       var sCount = parseInt(cls.studentCount) || 0;
       var totalExpected = classSessions.length * sCount; 
       var avgAttendance = totalExpected > 0 ? (presentRecords.length / totalExpected) * 100 : 0.0;
       
       var sName = cls.subjectName || '';
       var subjectCode = cls.subjectCode || (sName ? sName.split(' ')[0] : 'UNK');
       var timeLabel = cls.timeLabel || "Lịch học chưa cập nhật";
       
       return {
         classCode: cls.classCode,
         subjectCode: subjectCode,
         subjectName: sName,
         room: cls.room,
         studentCount: sCount,
         teacherMemberCode: cls.teacherMemberCode,
         timeLabel: timeLabel,
         completedSessions: completed,
         totalSessions: 30, // Mock 30 sessions per class
         averageAttendance: avgAttendance,
         isActive: activeSession != null,
         activeSessionId: activeSession ? activeSession.sessionId : null
       };
    });
    return enriched;
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
  
  function closeSession(params) {
    var sessionId = params.sessionId;
    if (!sessionId) throwError('VALIDATION_ERROR', 'Thiếu sessionId.');

    var sessions = SheetDB.getRowsAsObjects('Attendance_Session');
    var session = sessions.filter(function(s) { return s.sessionId === sessionId; })[0];
    if (!session) throwError('SESSION_NOT_FOUND', 'Không tìm thấy phiên.');

    // Cập nhật trạng thái session thành closed
    SheetDB.updateRow('Attendance_Session', 'sessionId', sessionId, {
      sessionStatus: 'closed'
    });

    // Tự động sinh bản ghi Absent cho sinh viên chưa điểm danh
    var enrollments = SheetDB.getRowsAsObjects('Enrollment').filter(function(e) {
      return e.classCode === session.classCode;
    });

    var existingRecords = SheetDB.getRowsAsObjects('Attendance_Record').filter(function(r) {
      return r.sessionId === sessionId;
    });

    var absentCount = 0;
    for (var i = 0; i < enrollments.length; i++) {
      var rollNumber = enrollments[i].rollNumber;
      var hasRecord = existingRecords.some(function(r) { return r.rollNumber === rollNumber; });
      if (!hasRecord) {
        SheetDB.insertRow('Attendance_Record', {
          recordId: Utilities.getUuid(),
          rollNumber: rollNumber,
          sessionId: sessionId,
          checkinTime: '',
          status: 'Absent',
          networkVerificationResult: 'AutoAbsent',
          syncedToFap: false
        });
        absentCount++;
      }
    }

    return {
      sessionId: sessionId,
      sessionStatus: 'closed',
      autoAbsentCount: absentCount
    };
  }

  function getSessions(params) {
    var classCode = params.classCode;
    if (!classCode) throwError('VALIDATION_ERROR', 'Thiếu classCode.');

    var sessions = SheetDB.getRowsAsObjects('Attendance_Session').filter(function(s) {
      return s.classCode === classCode;
    });

    // Sắp xếp ngày mới nhất lên trước
    sessions.sort(function(a, b) {
      var dateA = new Date(a.sessionDate);
      var dateB = new Date(b.sessionDate);
      return dateB - dateA;
    });

    return sessions;
  }

  function getAttendanceHistory(params) {
    var classCode = params.classCode;
    var sessionId = params.sessionId;
    if (!classCode) throwError('VALIDATION_ERROR', 'Thiếu classCode.');

    var sessions = SheetDB.getRowsAsObjects('Attendance_Session').filter(function(s) {
      return s.classCode === classCode;
    });

    if (sessions.length === 0) return { sessionId: sessionId || null, classCode: classCode, students: [] };

    // Nếu không truyền sessionId, lấy session mới nhất
    if (!sessionId) {
      sessions.sort(function(a, b) { return new Date(b.sessionDate) - new Date(a.sessionDate); });
      sessionId = sessions[0].sessionId;
    }

    var sessionIds = sessions.map(function(s) { return s.sessionId; });
    var allRecords = SheetDB.getRowsAsObjects('Attendance_Record').filter(function(r) {
      return sessionIds.indexOf(r.sessionId) !== -1;
    });

    var currentSessionRecords = allRecords.filter(function(r) {
      return r.sessionId === sessionId;
    });

    var enrollments = SheetDB.getRowsAsObjects('Enrollment').filter(function(e) {
      return e.classCode === classCode;
    });

    var users = SheetDB.getRowsAsObjects('Users');
    var totalSessions = sessionIds.length;

    var studentList = [];
    for (var i = 0; i < enrollments.length; i++) {
      var rollNumber = enrollments[i].rollNumber;
      var user = users.filter(function(u) { return u.rollNumber === rollNumber; })[0] || {};
      var record = currentSessionRecords.filter(function(r) { return r.rollNumber === rollNumber; })[0];
      
      // Tính số buổi vắng của sinh viên trong cả môn này
      var studentAbsences = allRecords.filter(function(r) {
        return r.rollNumber === rollNumber && r.status === 'Absent';
      }).length;

      studentList.push({
        rollNumber: rollNumber,
        memberCode: user.memberCode || '',
        fullName: user.fullName || '',
        email: user.email || '',
        checkinTime: record ? record.checkinTime : '',
        status: record ? record.status : 'Absent',
        networkVerificationResult: record ? record.networkVerificationResult : '',
        absenceCount: studentAbsences,
        totalSessions: totalSessions
      });
    }

    return {
      sessionId: sessionId,
      classCode: classCode,
      totalSessions: totalSessions,
      students: studentList
    };
  }
  
  return {
    getClasses: getClasses,
    startSession: startSession,
    closeSession: closeSession,
    getSessions: getSessions,
    getRoster: getRoster,
    getAttendanceHistory: getAttendanceHistory,
    manualCheckin: manualCheckin,
    getStats: getStats
  };
})();
