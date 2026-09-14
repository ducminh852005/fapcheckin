// File: Router.gs

/**
 * Dispatches the action to the corresponding service handler
 */
function dispatch(action, params) {
  var handlers = {
    'login': AuthService.login,
    'getClasses': TeacherService.getClasses,
    'startSession': TeacherService.startSession,
    'getRoster': TeacherService.getRoster,
    'manualCheckin': TeacherService.manualCheckin,
    'getStats': TeacherService.getStats,
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
