// Real attendance history. All endpoints derive the teacher from the login token.
var AttendanceHistoryService = (function() {
  function key(value) { return value == null ? '' : String(value); }
  function isPresent(status) { return ['Present', 'Late', 'ManualByGV'].indexOf(status) !== -1; }
  function ownedClass(params) {
    var teacher = AuthService.requireTeacher(params);
    if (!params.classCode) throwError('VALIDATION_ERROR', 'Thiếu classCode.');
    var cls = SheetDB.getRowsAsObjects('Class_Section').filter(function(c) {
      return key(c.classCode) === key(params.classCode) && key(c.teacherMemberCode) === key(teacher.memberCode);
    })[0];
    if (!cls) throwError('FORBIDDEN', 'Lớp không thuộc giảng viên đang đăng nhập.');
    return { teacher: teacher, cls: cls };
  }
  function sessionDto(s) {
    return { sessionId: key(s.sessionId), sessionDate: s.sessionDate,
      slotCode: key(s.slotCode), sessionStatus: key(s.sessionStatus) };
  }
  function readTables() {
    return { sessions: SheetDB.getRowsAsObjects('Attendance_Session'), users: SheetDB.getRowsAsObjects('Users'),
      enrollments: SheetDB.getRowsAsObjects('Enrollment'), records: SheetDB.getRowsAsObjects('Attendance_Record') };
  }
  function loadClass(cls, tables) {
    tables = tables || readTables();
    var sessions = tables.sessions.filter(function(s) {
      return key(s.classCode) === key(cls.classCode);
    }).sort(function(a, b) {
      return new Date(b.sessionDate) - new Date(a.sessionDate) || key(b.sessionId).localeCompare(key(a.sessionId));
    });
    var users = tables.users;
    var seen = {};
    var students = tables.enrollments.filter(function(e) {
      if (key(e.classCode) !== key(cls.classCode) || !e.rollNumber || seen[key(e.rollNumber)]) return false;
      seen[key(e.rollNumber)] = true;
      return true;
    }).map(function(e) {
      var user = users.filter(function(u) { return key(u.rollNumber) === key(e.rollNumber); })[0] || {};
      return { rollNumber: key(e.rollNumber), fullName: key(user.fullName), email: key(user.email) };
    });
    // A session/student has one effective record. Latest sheet row wins for legacy duplicates.
    var records = {};
    var ids = sessions.map(function(s) { return key(s.sessionId); });
    tables.records.forEach(function(r) {
      if (ids.indexOf(key(r.sessionId)) !== -1 && seen[key(r.rollNumber)]) {
        records[key(r.sessionId) + '|' + key(r.rollNumber)] = r;
      }
    });
    return { sessions: sessions, students: students, records: records };
  }
  function statusFor(data, session, student) {
    if (!session) return 'Unchecked';
    var record = data.records[key(session.sessionId) + '|' + student.rollNumber];
    return record && record.status ? key(record.status) : session.sessionStatus === 'closed' ? 'Absent' : 'Unchecked';
  }
  function summary(data) {
    var closed = data.sessions.filter(function(s) { return s.sessionStatus === 'closed'; });
    var present = 0, late = 0, atRisk = 0;
    data.students.forEach(function(student) {
      var absences = 0;
      closed.forEach(function(session) {
        var status = statusFor(data, session, student);
        if (isPresent(status)) present++;
        if (status === 'Late') late++;
        if (status === 'Absent') absences++;
      });
      if (closed.length && absences / closed.length > 0.2) atRisk++;
    });
    var expected = closed.length * data.students.length;
    return { studentCount: data.students.length, completedSessions: closed.length,
      totalSessions: data.sessions.length, attendanceRate: expected ? present / expected : 0,
      lateRate: expected ? late / expected : 0, atRiskCount: atRisk };
  }
  function classDto(cls, data) {
    var result = summary(data);
    result.classCode = key(cls.classCode);
    result.subjectCode = key(cls.subjectCode) || key(cls.classCode).split('_')[0];
    result.subjectName = key(cls.subjectName);
    result.room = key(cls.room);
    result.slotCode = key(cls.slotCode);
    result.latestSession = data.sessions.length ? sessionDto(data.sessions[0]) : null;
    return result;
  }
  function getClasses(params) {
    var teacher = AuthService.requireTeacher(params);
    var classes = SheetDB.getRowsAsObjects('Class_Section').filter(function(c) {
      return key(c.teacherMemberCode) === key(teacher.memberCode);
    });
    var tables = readTables();
    return classes.map(function(cls) { return classDto(cls, loadClass(cls, tables)); });
  }
  function getDetail(params) {
    var owner = ownedClass(params), data = loadClass(owner.cls);
    var selected = params.sessionId ? data.sessions.filter(function(s) {
      return key(s.sessionId) === key(params.sessionId);
    })[0] : data.sessions[0];
    if (params.sessionId && !selected) throwError('SESSION_NOT_FOUND', 'Buổi học không thuộc lớp được chọn.');
    var closed = data.sessions.filter(function(s) { return s.sessionStatus === 'closed'; });
    var students = data.students.map(function(student) {
      var record = selected && data.records[key(selected.sessionId) + '|' + student.rollNumber];
      var absences = closed.filter(function(s) { return statusFor(data, s, student) === 'Absent'; }).length;
      return { rollNumber: student.rollNumber, fullName: student.fullName, email: student.email,
        status: statusFor(data, selected, student), checkinTime: record ? record.checkinTime : '',
        networkVerificationResult: record ? key(record.networkVerificationResult) : '',
        note: record ? key(record.note) : '', absenceCount: absences, totalSessions: closed.length,
        // Optimistic concurrency also detects changes from check-in/manual APIs.
        revision: record ? JSON.stringify([record.recordId, record.status, key(record.note), key(record.updatedAt), key(record.checkinTime)]) : '' };
    });
    return { classInfo: classDto(owner.cls, data), teacherName: key(owner.teacher.fullName),
      sessions: data.sessions.map(sessionDto), selectedSession: selected ? sessionDto(selected) : null,
      slots: SheetDB.getRowsAsObjects('Slot').map(function(s) {
        return { slotCode: key(s.slotCode), startTime: s.startTime, endTime: s.endTime };
      }), students: students };
  }
  function saveChanges(params) {
    var lock = LockService.getScriptLock();
    lock.waitLock(10000);
    try {
      if (!params.sessionId || !Array.isArray(params.changes) || !params.changes.length || params.changes.length > 500) {
        throwError('VALIDATION_ERROR', 'Chọn buổi học và ít nhất một thay đổi (tối đa 500).');
      }
      var detail = getDetail(params), seen = {};
      var allowed = ['Present', 'Late', 'Absent', 'ManualByGV', 'Unchecked'];
      params.changes.forEach(function(change) {
        var student = detail.students.filter(function(s) { return s.rollNumber === key(change.rollNumber); })[0];
        if (!student || seen[student.rollNumber]) throwError('VALIDATION_ERROR', 'Sinh viên không thuộc lớp hoặc bị trùng.');
        seen[student.rollNumber] = true;
        if (allowed.indexOf(change.status) === -1 || typeof change.note !== 'string' || change.note.length > 2000) {
          throwError('VALIDATION_ERROR', 'Trạng thái hoặc ghi chú không hợp lệ (tối đa 2000 ký tự).');
        }
        if (change.revision !== student.revision) throwError('CONFLICT', 'Dữ liệu đã thay đổi. Tải lại trước khi chỉnh sửa.');
      });
      SheetDB.ensureColumns('Attendance_Record', ['note', 'updatedAt', 'updatedBy', 'syncedToFap']);
      var teacher = AuthService.requireTeacher(params);
      var records = SheetDB.getRowsAsObjects('Attendance_Record');
      params.changes.forEach(function(change) {
        var existing = records.filter(function(r) {
          return key(r.sessionId) === key(params.sessionId) && key(r.rollNumber) === key(change.rollNumber);
        }).pop();
        var update = { status: change.status, note: change.note, updatedAt: new Date().toISOString(),
          updatedBy: key(teacher.memberCode), syncedToFap: false };
        if (!existing || key(existing.status) !== change.status) update.networkVerificationResult = 'Manual';
        if (existing) {
          if (!SheetDB.updateRow('Attendance_Record', 'recordId', existing.recordId, update)) {
            throwError('SAVE_FAILED', 'Không cập nhật được bản ghi. Vui lòng tải lại.');
          }
        } else {
          update.recordId = Utilities.getUuid(); update.sessionId = key(params.sessionId);
          update.rollNumber = key(change.rollNumber); update.checkinTime = '';
          SheetDB.insertRow('Attendance_Record', update);
        }
      });
      return getDetail(params);
    } finally { lock.releaseLock(); }
  }
  function getMatrix(params) {
    var owner = ownedClass(params), data = loadClass(owner.cls);
    return { sessions: data.sessions.map(sessionDto), students: data.students.map(function(student) {
      return { rollNumber: student.rollNumber, fullName: student.fullName,
        statuses: data.sessions.map(function(s) { return statusFor(data, s, student); }) };
    }) };
  }
  function exportHistory(params) {
    var detail = getDetail(params);
    var rows = [['Mã lớp', 'Buổi học', 'MSSV', 'Họ và tên', 'Email', 'Trạng thái', 'Thời gian điểm danh', 'Số buổi vắng', 'Số buổi đã kết thúc', 'Ghi chú']];
    detail.students.forEach(function(s) {
      rows.push([detail.classInfo.classCode, detail.selectedSession ? key(detail.selectedSession.sessionDate) : '',
        s.rollNumber, s.fullName, s.email, s.status, key(s.checkinTime), s.absenceCount, s.totalSessions, s.note]);
    });
    return HistoryExcel.create(rows, detail.classInfo.classCode);
  }
  function startSession(params) {
    ownedClass(params);
    var slots = SheetDB.getRowsAsObjects('Slot');
    if (!slots.some(function(s) { return key(s.slotCode) === key(params.slotCode); }) || !params.teacherIp) {
      throwError('VALIDATION_ERROR', 'Chọn ca học hợp lệ và nhập IP mạng giảng viên.');
    }
    var lock = LockService.getScriptLock(); lock.waitLock(10000);
    try {
      var open = SheetDB.getRowsAsObjects('Attendance_Session').some(function(s) {
        return key(s.classCode) === key(params.classCode) && s.sessionStatus === 'open';
      });
      if (open) throwError('SESSION_ALREADY_OPEN', 'Lớp đang có phiên mở. Kết thúc phiên đó trước khi tạo phiên mới.');
      return TeacherService.startSession(params);
    } finally { lock.releaseLock(); }
  }
  return { getClasses: getClasses, getDetail: getDetail, saveChanges: saveChanges,
    getMatrix: getMatrix, exportHistory: exportHistory, startSession: startSession };
})();
