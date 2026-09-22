// File: Code.gs

/**
 * Entry point for HTTP GET requests
 */
function doGet(e) {
  // CORS check and HTML page rendering for student checkin web app
  if (e.parameter && e.parameter.page === 'checkin') {
    try {
      var template = HtmlService.createTemplateFromFile('index.html');
      template.token = e.parameter.token || '';
      return template.evaluate()
        .setTitle('FAP Check-in')
        .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL);
    } catch(err) {
      return ContentService.createTextOutput("Check-in Web UI is not deployed yet: " + err.message);
    }
  }
  
  // Otherwise, handle as API request
  var action = e.parameter ? e.parameter.action : null;
  return dispatch(action, e.parameter || {});
}

/**
 * Entry point for HTTP POST requests
 */
function doPost(e) {
  try {
    // Parse the payload (sent as text/plain to avoid CORS preflight)
    var body = {};
    if (e.postData && e.postData.contents) {
      body = JSON.parse(e.postData.contents);
    }
    return dispatch(body.action, body);
  } catch (error) {
    return jsonResponse({
      success: false,
      data: null,
      error: { code: 'BAD_REQUEST', message: 'Lỗi cú pháp JSON.' }
    });
  }
}

/**
 * Entry point for google.script.run from HtmlService (Web Sinh viên)
 * Trả về raw Object thay vì TextOutput
 */
function handleRpc(action, params) {
  var handlers = {
    'login': AuthService.login,
    'checkin': StudentService.checkin
  };
  
  try {
    if (!action) throwError('MISSING_ACTION', 'Thiếu action');
    var handler = handlers[action];
    if (!handler) throwError('UNKNOWN_ACTION', 'Action không hợp lệ: ' + action);
    
    var data = handler(params || {});
    return { success: true, data: data, error: null };
  } catch (err) {
    return { 
      success: false, 
      data: null, 
      error: { code: err.code || 'UNKNOWN_ERROR', message: err.message || err.toString() } 
    };
  }
}
