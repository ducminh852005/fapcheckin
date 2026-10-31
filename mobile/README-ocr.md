# Android offline timetable OCR

Android uses bundled ML Kit Latin text recognition (16.0.1), called through
`fapcheckin/ocr`. Images never leave the device. No Storage, callable OCR,
API key or model download is needed. Other platforms return an explicit
unsupported message. Restart/rebuild Android after native changes; hot reload
alone cannot register the new channel.

Input: JPEG/PNG, at most 5 MiB. Native decoding downsamples images to at most
2500 pixels on the longest side and applies EXIF rotation. The parser extracts
class/subject pairs, deduplicates them and suggests rooms. Dates are informational;
it does not reconstruct timetable cells or create schedules automatically.

The existing review screen lets users select recognized classes before import.
Firestore is still required to match/claim classes. Queries only read the user's
classes and unassigned classes, in accordance with existing rules. Results are
cached per account for two minutes; imports re-read ownership and remain subject
to Security Rules. Inaccessible classes cannot be distinguished from missing ones.
OCR results are not proof of teaching authorization.

The previous cloud OCR function is retained for compatibility but is no longer
called by mobile. Other Storage/Functions features are unaffected.

Checks:
```
flutter test test/timetable_ocr_test.dart test/import_timetable_bottom_sheet_test.dart
flutter run -d <android-device>
```
On device: select a clear timetable screenshot, check class/subject/room matches,
cancel then retry, test oversized and invalid files. With networking disabled,
recognition still works, but an uncached Firestore match/import needs connectivity.
Firestore quota exhaustion must be handled separately from OCR.
