// Future teaching plans are separate from attendance sessions (which open now).
var ScheduleService = (function() {
  var TABLE = 'Class_Schedule';
  var COLUMNS = ['scheduleId','requestId','teacherMemberCode','classCode','scheduleDate','slotCode',
    'startTime','endTime','room','lessonType','teachingMethod','note','status','createdAt'];
  var TYPES = ['makeup','workshop','review'];
  var ZONE = 'Asia/Ho_Chi_Minh';
  function text(v) { return v == null ? '' : String(v).trim(); }
  function date(v) { return v instanceof Date ? Utilities.formatDate(v, ZONE, 'yyyy-MM-dd') : text(v).slice(0,10); }
  function time(v) {
    if (v instanceof Date) return Utilities.formatDate(v, ZONE, 'HH:mm');
    var match = /^(\d{1,2}):(\d{2})(?::\d{2})?$/.exec(text(v));
    return match && +match[1] < 24 && +match[2] < 60 ? ('0'+match[1]).slice(-2)+':'+match[2] : '';
  }
  function slots() {
    return SheetDB.getRowsAsObjects('Slot').map(function(s) {
      var start = time(s.startTime), end = time(s.endTime);
      return {slotCode:text(s.slotCode), startTime:start, endTime:end, available:!!start && end > start};
    });
  }
  function rows() {
    // Reading options never creates a sheet. Creation happens under the write lock.
    try { return SheetDB.getRowsAsObjects(TABLE); }
    catch(e) { if (e.code === 'SHEET_NOT_FOUND') return []; throw e; }
  }
  function dto(r) {
    var result = {};
    COLUMNS.forEach(function(k) { result[k] = text(r[k]); });
    result.scheduleDate = date(r.scheduleDate);
    result.startTime = time(r.startTime); result.endTime = time(r.endTime);
    return result;
  }
  function listFor(teacher) {
    return rows().filter(function(r) { return text(r.teacherMemberCode) === text(teacher.memberCode); })
      .map(dto).sort(function(a,b) { return (a.scheduleDate+a.startTime).localeCompare(b.scheduleDate+b.startTime); });
  }
  function getOptions(p) {
    var teacher = AuthService.requireTeacher(p), classes = SheetDB.getRowsAsObjects('Class_Section');
    var enrollments = SheetDB.getRowsAsObjects('Enrollment');
    return {teacherName:text(teacher.fullName), today:Utilities.formatDate(new Date(), ZONE, 'yyyy-MM-dd'),
      classes:classes.filter(function(c) { return text(c.teacherMemberCode) === text(teacher.memberCode); }).map(function(c) {
        var ids = {};
        enrollments.forEach(function(e) { if(text(e.classCode) === text(c.classCode) && text(e.rollNumber)) ids[text(e.rollNumber)] = true; });
        return {classCode:text(c.classCode),subjectName:text(c.subjectName),room:text(c.room),studentCount:Object.keys(ids).length};
      }), slots:slots(), rooms:classes.map(function(c) { return text(c.room); }).filter(function(r,i,a) { return r && a.indexOf(r) === i; }).sort(),
      capabilities:{autoQR:false,sendEmail:false,syncFap:false}, schedules:listFor(teacher)};
  }
  function create(p) {
    var teacher = AuthService.requireTeacher(p);
    var lock = LockService.getScriptLock(); lock.waitLock(30000);
    try {
      var classes = SheetDB.getRowsAsObjects('Class_Section');
      var cls = classes.filter(function(c) { return text(c.classCode) === text(p.classCode) && text(c.teacherMemberCode) === text(teacher.memberCode); })[0];
      if (!cls) throwError('FORBIDDEN','Lớp không thuộc giảng viên đang đăng nhập.');
      if (!/^[a-zA-Z0-9_-]{8,100}$/.test(text(p.requestId))) throwError('VALIDATION_ERROR','requestId không hợp lệ.');
      if (p.autoQR || p.sendEmail || p.syncFap) throwError('NOT_SUPPORTED','QR tự động, email và đồng bộ FAP chưa được tích hợp.');
      var slot = slots().filter(function(s) { return s.slotCode === text(p.slotCode) && s.available; })[0];
      if (!slot) throwError('VALIDATION_ERROR','Ca học không hợp lệ. Kiểm tra giờ bắt đầu/kết thúc trong tab Slot (24 giờ).');
      var day = text(p.scheduleDate), parsed = new Date(day+'T00:00:00Z');
      if (!/^\d{4}-\d{2}-\d{2}$/.test(day) || isNaN(parsed.getTime()) || parsed.toISOString().slice(0,10) !== day)
        throwError('VALIDATION_ERROR','Ngày học không hợp lệ.');
      if (TYPES.indexOf(p.lessonType) < 0 || p.teachingMethod !== 'onCampus') throwError('VALIDATION_ERROR','Loại buổi học hoặc hình thức học không hợp lệ.');
      var room = text(p.room), note = text(p.note);
      if (!room || !classes.some(function(c) { return text(c.room) === room; }) || note.length > 2000)
        throwError('VALIDATION_ERROR','Phòng học không hợp lệ hoặc ghi chú quá 2000 ký tự.');
      var input = {teacherMemberCode:text(teacher.memberCode),classCode:text(cls.classCode),scheduleDate:day,
        slotCode:slot.slotCode,room:room,lessonType:p.lessonType,teachingMethod:p.teachingMethod,note:note};
      var existing = rows();
      var retry = existing.filter(function(r) { return text(r.teacherMemberCode) === input.teacherMemberCode && text(r.requestId) === p.requestId; })[0];
      if (retry) {
        var saved = dto(retry);
        if (Object.keys(input).some(function(k) { return saved[k] !== input[k]; })) throwError('CONFLICT','Yêu cầu đã được sử dụng cho một lịch khác.');
        return saved;
      }
      if (new Date(day+'T'+slot.startTime+':00+07:00').getTime() <= Date.now()) throwError('VALIDATION_ERROR','Chọn ca học chưa bắt đầu.');
      function overlaps(start,end) { return !start || !end || (start < slot.endTime && end > slot.startTime); }
      var conflict = existing.some(function(r) {
        return r.status !== 'cancelled' && date(r.scheduleDate) === day && overlaps(time(r.startTime),time(r.endTime)) &&
          (text(r.teacherMemberCode) === input.teacherMemberCode || text(r.classCode) === input.classCode || text(r.room) === room);
      });
      var allSlots = slots();
      conflict = conflict || SheetDB.getRowsAsObjects('Attendance_Session').some(function(s) {
        if (date(s.sessionDate) !== day || s.sessionStatus === 'cancelled') return false;
        var c = classes.filter(function(c) { return text(c.classCode) === text(s.classCode); })[0];
        if (!c) return false;
        var other = allSlots.filter(function(x) { return x.slotCode === text(s.slotCode); })[0];
        return overlaps(other && other.startTime,other && other.endTime) &&
          (text(c.teacherMemberCode) === input.teacherMemberCode || text(c.classCode) === input.classCode || text(c.room) === room);
      });
      if (conflict) throwError('SCHEDULE_CONFLICT','Giảng viên, lớp hoặc phòng đã có lịch trong khoảng thời gian này.');
      input.scheduleId = Utilities.getUuid(); input.requestId = p.requestId;
      input.startTime = slot.startTime; input.endTime = slot.endTime;
      input.status = 'scheduled'; input.createdAt = new Date().toISOString();
      SheetDB.ensureSheet(TABLE,COLUMNS);
      SheetDB.insertRow(TABLE,input);
      return dto(input);
    } finally { lock.releaseLock(); }
  }
  return {getOptions:getOptions, list:function(p) { return listFor(AuthService.requireTeacher(p)); }, create:create};
})();
