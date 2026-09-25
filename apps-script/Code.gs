// File: Code.gs

var CHECKIN_WEB_APP_URL = 'https://script.google.com/macros/s/AKfycbwhbrv6Y76dGETuwDeMqObH1Dvf9RwQ5obDkxuuR-x5m2T3JoCByY0EuuB4ptuTHC3cwA/exec';

function authorizeTimetableOCR() {
  return authorizeTimetableOcr();
}

function renderCheckinPage_(token, oauthResult) {
  var nonce = Utilities.getUuid().replace(/-/g, '');
  CacheService.getScriptCache().put('google-login-nonce:' + nonce, '1', 600);

  var template = HtmlService.createTemplateFromFile('index.html');
  template.token = token || '';
  template.googleClientId = GOOGLE_WEB_CLIENT_ID;
  template.googleLoginUri = CHECKIN_WEB_APP_URL;
  template.googleLoginNonce = nonce;
  template.oauthResult = oauthResult || null;

  return template.evaluate()
    .setTitle('FAP Check-in')
    .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL);
}

/**
 * Entry point for HTTP GET requests
 */
function doGet(e) {
  // CORS check and HTML page rendering for student checkin web app
  if (e.parameter && e.parameter.page === 'checkin') {
    try {
      return renderCheckinPage_(e.parameter.token || '', null);
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
  // Google Identity Services redirect mode posts the ID token as form data.
  // This avoids popup origin checks against Apps Script's googleusercontent
  // sandbox, whose host cannot be registered as a JavaScript OAuth origin.
  if (e.parameter && e.parameter.credential) {
    var oauthResult;
    try {
      oauthResult = {
        success: true,
        data: AuthService.login({
          idToken: e.parameter.credential,
          requireLoginNonce: true
        }),
        error: null
      };
    } catch (oauthError) {
      oauthResult = {
        success: false,
        data: null,
        error: {
          code: oauthError.code || 'INVALID_TOKEN',
          message: oauthError.message || String(oauthError)
        }
      };
    }
    return renderCheckinPage_(e.parameter.state || '', oauthResult);
  }

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
