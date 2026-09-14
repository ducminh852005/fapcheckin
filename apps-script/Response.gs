// File: Response.gs

/**
 * Standardizes the JSON envelope response
 */
function jsonResponse(payload) {
  return ContentService.createTextOutput(JSON.stringify(payload))
    .setMimeType(ContentService.MimeType.JSON);
}

/**
 * Helper to throw formatted API errors
 */
function throwError(code, message) {
  var error = new Error(message);
  error.code = code;
  throw error;
}
