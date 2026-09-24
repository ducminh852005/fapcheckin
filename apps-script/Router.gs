// File: Router.gs

/**
 * Dispatches the action to the corresponding service handler
 */
function dispatch(action, params) {
  var handlers = {
    'getScheduleOptions': function(p) { return ScheduleService.getOptions(p); },
    'getClassSchedules': function(p) { return ScheduleService.list(p); },
    'createClassSchedule': function(p) { return ScheduleService.create(p); },
    'getHistoryClasses': function(p) { return AttendanceHistoryService.getClasses(p); },
    'getHistoryDetail': function(p) { return AttendanceHistoryService.getDetail(p); },
    'getHistorySummary': function(p) { return AttendanceHistoryService.getSummary(p); },
    'saveAttendanceChanges': function(p) { return AttendanceHistoryService.saveChanges(p); },
    'getAttendanceMatrix': function(p) { return AttendanceHistoryService.getMatrix(p); },
    'exportAttendanceHistory': function(p) { return AttendanceHistoryService.exportHistory(p); },
    'startHistorySession': function(p) { return AttendanceHistoryService.startSession(p); },
    'getReport': function(p) { return ReportService.getReport(p); },
    'login': AuthService.login,
    'getClasses': TeacherService.getClasses,
    'startSession': TeacherService.startSession,
    'syncSessionTeacherIp': TeacherService.syncSessionTeacherIp,
    'rotateQr': TeacherService.rotateQr,
    'closeSession': TeacherService.closeSession,
    'getSessions': TeacherService.getSessions,
    'getRoster': TeacherService.getRoster,
    'getAttendanceHistory': TeacherService.getAttendanceHistory,
    'manualCheckin': TeacherService.manualCheckin,
    'manualCheckinBulk': TeacherService.manualCheckinBulk,
    'getStats': TeacherService.getStats,
    'syncToFap': SyncService.syncToFap,
    'checkin': StudentService.checkin
  };

  try {
    if (!action) {
      throwError('MISSING_ACTION', 'Vui lòng cung cấp tham số action.');
    }
    
    var handler = handlers[action];
    if (!handler) {
      throwError('UNKNOWN_ACTION', 'Hành động không hợp lệ: ' + action);
    }

    var data = handler(params);
    return jsonResponse({ success: true, data: data, error: null });
  } catch (err) {
    return jsonResponse({
      success: false,
      data: null,
      error: { code: err.code || 'UNKNOWN_ERROR', message: err.message || err.toString() }
    });
  }
}
