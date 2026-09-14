// File: Code.gs

/**
 * Entry point for HTTP GET requests
 */
function doGet(e) {
  // CORS check and HTML page rendering for student checkin web app
  if (e.parameter && e.parameter.page === 'checkin') {
    try {
      return HtmlService.createHtmlOutputFromFile('index')
        .setTitle('FAP Check-in')
        .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL);
    } catch(err) {
      return ContentService.createTextOutput("Check-in Web UI is not deployed yet.");
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
