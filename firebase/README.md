# firebase/

Backend của FAP Check-in: Security Rules, test Rules, script vận hành và Cloud Functions. Cấu hình `firebase.json` / `.firebaserc` nằm ở thư mục gốc repo (CLI tìm từ thư mục hiện tại trở lên).

| Đường dẫn | Nội dung |
|---|---|
| `firestore.rules` | Security Rules Firestore — deny by default, RBAC `user`/`staff`/`admin` ([docs/08](../docs/08-security-rules.md)) |
| `storage.rules` | Rules Storage — chỉ GV tải ảnh thời khóa biểu vào `timetable_scans/{uid}/` |
| `firestore.indexes.json` | Composite index cho truy vấn có sắp xếp |
| `remoteconfig.template.json` | `qr_refresh_seconds`, `ip_check_default`, `maintenance_mode` |
| `tests/` | Test Rules (`@firebase/rules-unit-testing` + `node:test`) chạy trên Emulator |
| `functions/` | Cloud Functions: `scanTimetable` (OCR), `sendTeachingReminders`, `onFeedbackCreated/Updated`, `resolveFeedback`, `syncToFap`, `aiAssistant` (trợ lý AI, Gemini — cần secret `GEMINI_API_KEY`), `aiSpeak` (giọng đọc Google Cloud Text-to-Speech — cần bật API; xem [docs/ai-assistant.md](../docs/ai-assistant.md)). `npm test` chạy unit test với Vision/Gemini giả |
| `scripts/` | `seed-reference.mjs`, `seed-admin.mjs`, `migrate-legacy.mjs` (Node + Admin SDK) |

```bash
npm ci
npm test                 # Emulator (firestore + storage) + toàn bộ test Rules
npm run emulators        # firebase emulators:start --project demo-fapcheckin
```

Script vận hành nhận `--emulator` (dùng Emulator) hoặc `--project <id>` (project thật, cần Application Default Credentials — không commit khóa service account). Hướng dẫn đầy đủ: [docs/deploy-firebase.md](../docs/deploy-firebase.md).

Cổng Emulator: Auth 9099 · Firestore **8085** · Storage 9199 · Functions 5001 · Hosting 5000 · UI 4000.
