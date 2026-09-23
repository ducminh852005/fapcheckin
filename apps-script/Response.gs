// File: Response.gs // v2 - redeployed 2026-09-23

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
