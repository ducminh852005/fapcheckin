# 11 - Timetable OCR Import

This feature lets a teacher upload or capture a timetable image, sends it to the
Apps Script Web App, runs Drive OCR, parses the extracted text into timetable
rows, and optionally saves the result into the database (Google Sheet, or
Firestore once `DB_BACKEND=firestore`, see `docs/03-du-lieu-firestore.md`).

> **Firestore note:** slot codes/times are fixed by the A/P schedule rule and the
> `Slot` data is read-only there, so saving an OCR result only creates missing
> classes (`Class_Section`); slot rows detected in the photo are ignored.

## Apps Script setup

The Apps Script project must enable the Advanced Drive service:

- Service: Drive API
- Identifier: `Drive`
- Version: `v3`

`appsscript.json` must include these scopes:

- `https://www.googleapis.com/auth/spreadsheets`
- `https://www.googleapis.com/auth/documents`
- `https://www.googleapis.com/auth/drive`
- `https://www.googleapis.com/auth/script.external_request`
- `https://www.googleapis.com/auth/datastore` (Firestore, see `docs/deploy-firebase.md`)

After pushing the Apps Script source, run `authorizeTimetableOCR()` manually one
time from the Apps Script editor. The expected log is:

```text
Timetable OCR authorization is ready.
```

Then deploy the Web App again with:

- Execute as: Me
- Who has access: Anyone, or the school domain if deployment is restricted

## API contract

Action name:

```json
{
  "action": "ocrTimetable"
}
```

The endpoint accepts either raw text for parser testing, a base64 image, or a
Drive file ID:

```json
{
  "action": "ocrTimetable",
  "imageBase64": "...",
  "fileName": "timetable.jpg",
  "mimeType": "image/jpeg"
}
```

```json
{
  "action": "ocrTimetable",
  "fileId": "drive-file-id"
}
```

```json
{
  "action": "ocrTimetable",
  "rawText": "Monday | PRM392 | Class SE18D01 | Slot A1 | 07:30 - 09:50 | Room BE-301"
}
```

By default the action only returns OCR and parser output for teacher review. To
write parsed slots/classes into the database, send `save: true` or `persist: true`
with a valid teacher session token.

Successful response data:

```json
{
  "rawText": "...",
  "parsedRows": [
    {
      "classCode": "SE18D01",
      "subjectName": "PRM392",
      "dayOfWeek": "Monday",
      "slotCode": "A1",
      "startTime": "07:30",
      "endTime": "09:50",
      "room": "BE-301",
      "confidence": "high",
      "warnings": []
    }
  ],
  "warnings": [],
  "saved": false
}
```

If parsing fails, the normal API envelope returns `success: false`, while
`data.rawText` and `data.parsedRows` are preserved when available so the Flutter
UI can show the teacher what OCR saw.

## Cleanup

The service creates a temporary Google Doc for OCR and moves it to trash in a
`finally` block after reading the text. Base64 uploads do not leave the original
image in Drive; Drive-file imports only trash the generated OCR document, not the
teacher's source file.
