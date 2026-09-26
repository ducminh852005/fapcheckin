// Run this function once from the Apps Script editor as the account that owns
// the web-app deployment. It triggers the OAuth consent flow and verifies that
// Drive API, DriveApp and DocumentApp are all available to timetable OCR.
function authorizeTimetableOcr() {
  ScriptApp.requireAllScopes(ScriptApp.AuthMode.FULL);

  var testDocument = DocumentApp.create('fapcheckin-ocr-permission-check');
  var documentId = testDocument.getId();
  try {
    testDocument.getBody().setText('FAP Check-in OCR permission check');
    testDocument.saveAndClose();

    var driveFile = Drive.Files.get(documentId, {
      fields: 'id,mimeType'
    });
    if (!driveFile || driveFile.mimeType !== 'application/vnd.google-apps.document') {
      throw new Error('Google Drive API did not return the permission-check document.');
    }

    console.log('Timetable OCR authorization is ready.');
    return 'OK: Google Drive/Docs OCR permissions are ready.';
  } finally {
    try { DriveApp.getFileById(documentId).setTrashed(true); } catch (ignored) {}
  }
}
