// Aggregate real attendance data for the teacher report dashboard.
var ReportService = (function() {
  function key(value) { return value == null ? '' : String(value); }
  function present(status) {
    return ['Present', 'Late', 'ManualByGV'].indexOf(key(status)) !== -1;
  }
  function ownedClasses(teacher) {
    return SheetDB.getRowsAsObjects('Class_Section').filter(function(c) {
      return key(c.teacherMemberCode) === key(teacher.memberCode);
    });
  }
  function loadStudents(classCode, enrollments, users) {
    var seen = {};
    return enrollments.filter(function(e) {
      var roll = key(e.rollNumber);
      if (key(e.classCode) !== classCode || !roll || seen[roll]) return false;
      seen[roll] = true;
      var user = users.filter(function(u) { return key(u.rollNumber) === roll; })[0] || {};
      return true;
    }).map(function(e) {
      var user = users.filter(function(u) { return key(u.rollNumber) === key(e.rollNumber); })[0] || {};
      return {
        rollNumber: key(e.rollNumber),
        fullName: key(user.fullName),
        email: key(user.email)
      };
    });
  }
  function semesterLabel(classes, sessions) {
    var sources = classes.concat(sessions);
    for (var i = 0; i < sources.length; i++) {
      var value = sources[i].semester || sources[i].semesterName || sources[i].term;
      if (value != null && String(value).trim()) return String(value).trim();
    }

    var dated = sessions.filter(function(s) { return s.sessionDate; })
      .sort(function(a, b) {
        return new Date(b.sessionDate) - new Date(a.sessionDate);
      });
    if (!dated.length) return '';

    var date = new Date(dated[0].sessionDate);
    var month = date.getMonth() + 1;
    var season = month >= 1 && month <= 5 ? 'Spring' : (month >= 6 && month <= 8 ? 'Summer' : 'Fall');
    return season + ' ' + date.getFullYear();
  }
  function getReport(params) {
    var teacher = AuthService.requireTeacher(params);
    var classes = ownedClasses(teacher);
    var sessions = SheetDB.getRowsAsObjects('Attendance_Session');
    var records = SheetDB.getRowsAsObjects('Attendance_Record');
    var enrollments = SheetDB.getRowsAsObjects('Enrollment');
    var users = SheetDB.getRowsAsObjects('Users');
    var ownedCodes = classes.map(function(c) { return key(c.classCode); });
    var closed = sessions.filter(function(s) {
      return s.sessionStatus === 'closed' && ownedCodes.indexOf(key(s.classCode)) !== -1;
    }).sort(function(a, b) {
      return new Date(a.sessionDate) - new Date(b.sessionDate);
    });
    var recordMap = {};
    records.forEach(function(r) {
      var id = key(r.sessionId) + '|' + key(r.rollNumber);
      recordMap[id] = r;
    });
    var studentsByClass = {};
    classes.forEach(function(c) {
      studentsByClass[key(c.classCode)] = loadStudents(key(c.classCode), enrollments, users);
    });

    var presentCount = 0, lateCount = 0, expected = 0;
    var methodCounts = { qr: 0, other: 0, manual: 0 };
    var warningMap = {};
    var classStats = {};
    classes.forEach(function(c) {
      classStats[key(c.classCode)] = { present: 0, late: 0, absent: 0, expected: 0 };
      studentsByClass[key(c.classCode)].forEach(function(student) {
        warningMap[key(c.classCode) + '|' + student.rollNumber] = {
          classCode: key(c.classCode), subjectName: key(c.subjectName),
          rollNumber: student.rollNumber, fullName: student.fullName,
          email: student.email, absent: 0, total: 0
        };
      });
    });
    closed.forEach(function(session) {
      var code = key(session.classCode);
      var stats = classStats[code];
      studentsByClass[code].forEach(function(student) {
        var record = recordMap[key(session.sessionId) + '|' + student.rollNumber];
        var status = record && record.status ? key(record.status) : 'Absent';
        var warning = warningMap[code + '|' + student.rollNumber];
        expected++;
        stats.expected++;
        warning.total++;
        if (status === 'Absent') {
          stats.absent++;
          warning.absent++;
        } else {
          stats.present++;
          presentCount++;
          if (status === 'Late') lateCount++;
          if (status === 'ManualByGV' || (record && key(record.networkVerificationResult) === 'Manual')) methodCounts.manual++;
          else if (record && key(record.networkVerificationResult) === 'Match') methodCounts.qr++;
          else methodCounts.other++;
        }
      });
    });
    var subjects = classes.map(function(c) {
      var stat = classStats[key(c.classCode)];
      return {
        classCode: key(c.classCode), subjectName: key(c.subjectName),
        attendanceRate: stat.expected ? stat.present / stat.expected : 0,
        absentRate: stat.expected ? stat.absent / stat.expected : 0,
        studentCount: studentsByClass[key(c.classCode)].length
      };
    });
    var weeks = {};
    closed.forEach(function(session) {
      var date = new Date(session.sessionDate);
      var first = closed.length ? new Date(closed[0].sessionDate) : date;
      var week = Math.floor((date - first) / (7 * 24 * 60 * 60 * 1000)) + 1;
      var bucket = weeks[week] || { label: 'W' + week, present: 0, late: 0, absent: 0, total: 0 };
      var code = key(session.classCode);
      studentsByClass[code].forEach(function(student) {
        var record = recordMap[key(session.sessionId) + '|' + student.rollNumber];
        var status = record && record.status ? key(record.status) : 'Absent';
        bucket.total++;
        if (status === 'Absent') bucket.absent++;
        else { bucket.present++; if (status === 'Late') bucket.late++; }
      });
      weeks[week] = bucket;
    });
    var warnings = Object.keys(warningMap).map(function(id) {
      var item = warningMap[id];
      item.absenceRate = item.total ? item.absent / item.total : 0;
      item.status = item.absenceRate > 0.2 ? 'Cần lưu ý' : 'Nguy cơ';
      return item;
    }).filter(function(item) { return item.absenceRate > 0.15; })
      .sort(function(a, b) { return b.absenceRate - a.absenceRate; })
      .slice(0, 50);
    var methodTotal = methodCounts.qr + methodCounts.fap + methodCounts.manual;
    return {
      generatedAt: new Date().toISOString(),
      kpis: {
        attendanceRate: expected ? presentCount / expected : 0,
        totalCheckins: presentCount,
        atRiskCount: warnings.filter(function(w) { return w.absenceRate > 0.2; }).length,
        studentCount: Object.keys(warningMap).length,
        lateRate: expected ? lateCount / expected : 0
      },
      methods: [
        { key: 'qr', label: 'Điểm danh QR', count: methodCounts.qr, rate: methodTotal ? methodCounts.qr / methodTotal : 0 },
        { key: 'other', label: 'Khác / chưa xác định', count: methodCounts.other, rate: methodTotal ? methodCounts.other / methodTotal : 0 },
        { key: 'manual', label: 'GV xác nhận thủ công', count: methodCounts.manual, rate: methodTotal ? methodCounts.manual / methodTotal : 0 }
      ],
      weekly: Object.keys(weeks).sort(function(a, b) { return Number(a) - Number(b); }).map(function(k) {
        var w = weeks[k];
        return { label: w.label, presentRate: w.total ? w.present / w.total : 0,
          lateRate: w.total ? w.late / w.total : 0, absentRate: w.total ? w.absent / w.total : 0 };
      }),
      subjects: subjects,
      warnings: warnings,
      classCount: classes.length,
      closedSessionCount: closed.length,
      semester: semesterLabel(classes, closed)
    };
  }
  return { getReport: getReport };
})();
