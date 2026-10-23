[← Mục lục](README.md)

# Hướng dẫn thiết lập & deploy Firebase

Toàn bộ backend là Firebase; script [`scripts/deploy.ps1`](../scripts/deploy.ps1) chạy test Security Rules trên Emulator rồi `firebase deploy` các thành phần: **Hosting** (trang SV), **Firestore** (rules + indexes), **Storage** (rules), **Remote Config** và **Functions** (OCR).

> **App Giảng viên KHÔNG được deploy bằng script này.** App GV là app Flutter cài trên máy giảng viên ([`mobile/`](../mobile)); xem [quick-start-mobile.md](quick-start-mobile.md). Chỉ trang web của sinh viên cần địa chỉ công khai, vì SV mở nó bằng cách quét QR.

## 1. Tổng quan

| Thành phần | Nguồn trong repo | Đích |
|---|---|---|
| Trang check-in SV | `web/checkin/` | Hosting (gốc `/`) — `https://<project-id>.web.app/?s=…&t=…` |
| Cấu hình Firebase | `firebase.json`, `.firebaserc` | — |
| Firestore rules / indexes | `firebase/firestore.rules`, `firebase/firestore.indexes.json` | Firestore |
| Storage rules | `firebase/storage.rules` | Storage |
| Remote Config | `firebase/remoteconfig.template.json` | Remote Config (`qr_refresh_seconds`, `ip_check_default`, `maintenance_mode`) |
| Cloud Function OCR | `firebase/functions/` (`scanTimetable`, region `asia-southeast1`) | Functions (cần Blaze) |
| App Giảng viên | `mobile/` | **Không deploy ở đây** |
| Web Admin | `web/admin/` | Chưa triển khai |

Project mặc định: `fapcheckin-3bn2di` (`.firebaserc`).

## 2. Chuẩn bị (làm một lần)

1. **Project Firebase**: tạo tại [console.firebase.google.com](https://console.firebase.google.com) (hoặc dùng `fapcheckin-3bn2di`). Region Firestore không đổi được sau khi tạo — chọn gần Việt Nam (vd `asia-southeast1`).
2. **Bật dịch vụ** trong Console:
   - *Authentication → Sign-in method → Google* (đặt email hỗ trợ dự án).
   - *Firestore Database → Create database* (chế độ Native, **Production mode** — Rules do repo quản lý).
   - *Hosting → Get started*; *Storage → Get started*; *Remote Config*.
   - *Functions*: nâng lên gói **Blaze** và bật **Cloud Vision API** (chỉ cần cho import thời khóa biểu).
3. **Công cụ**: Node.js 22+, Java 21 (cho Emulator), Firebase CLI:
   ```powershell
   npm install -g firebase-tools
   firebase login
   firebase use --add   # chọn project, alias "default" (đã có sẵn trong .firebaserc)
   ```
4. **Cài thư viện cho script/test**:
   ```powershell
   cd firebase; npm ci; cd functions; npm ci; cd ../../e2e_test; npm ci; cd ..
   ```
5. **Domain được phép cho Auth**: *Authentication → Settings → Authorized domains* đã có `<project-id>.web.app`; thêm `localhost` nếu chạy thử cục bộ.

## 3. Tài khoản Admin đầu tiên

Rules không cho client tự đặt role, nên admin đầu tiên tạo bằng một trong hai cách (ghi email đã tạo vào bảng ở [README gốc](../README.md#tài-khoản-admin-đầu-tiên)):

**Cách A — script (khuyến nghị)**, cần Application Default Credentials (`gcloud auth application-default login`) hoặc `GOOGLE_APPLICATION_CREDENTIALS` trỏ tới khóa service account (không commit):

```powershell
cd firebase
node scripts/seed-admin.mjs --email admin@fpt.edu.vn --name "Quản trị viên" --member-code AD001
```

Script tìm hoặc tạo user trong Firebase Auth rồi ghi `users/{uid}` với `role: "admin"`. Sau đó đăng nhập Google bằng đúng email này.

**Cách B — thủ công trong Console**: *Authentication → Users → Add user* (hoặc để người đó đăng nhập Google một lần), copy **UID**; *Firestore → users → Add document* với **Document ID = UID** và các trường: `memberCode` (string), `fullName` (string), `email` (string), `role` = `admin`, `active` = `true`, `createdAt` (timestamp).

Admin cấp tài khoản cho người khác bằng cách tạo `user_invites/{email}` (Web Admin khi có; hiện qua Console hoặc script).

## 4. Dữ liệu tham chiếu

```powershell
cd firebase
node scripts/seed-reference.mjs      # 4 timeSlots + 12 slots (project mặc định)
```

## 5. Chạy script deploy

```powershell
./scripts/deploy.ps1                          # test Rules + deploy tất cả (hosting, firestore, storage, remoteconfig, functions)
./scripts/deploy.ps1 -Only firestore          # chỉ rules + indexes
./scripts/deploy.ps1 -Only hosting -Channel preview   # xem thử trang SV trên preview channel
./scripts/deploy.ps1 -DryRun                  # chỉ in các bước
./scripts/deploy.ps1 -SkipTests               # bỏ test (không khuyến khích)
```

`-Only functions` / `all` yêu cầu gói Blaze và Cloud Vision API. Chưa có Blaze thì deploy từng phần (`-Only hosting`, `-Only firestore`, `-Only storage`, `-Only remoteconfig`) hoặc `firebase deploy --only hosting,firestore,storage,remoteconfig`.

Script **luôn** chạy `npm test` trong `firebase/` trước khi deploy (Rules sai là lỗi bảo mật nghiêm trọng).

## 6. Sau khi deploy — checklist

1. Mở `https://<project-id>.web.app/` (không kèm tham số): phải hiện "Thiếu mã điểm danh".
2. Đăng nhập app GV bằng email có `user_invites` role `staff`, mở một phiên, quét QR bằng điện thoại khác bằng tài khoản SV → "Điểm danh thành công".
3. Quét lại cùng QR → "Đã ghi nhận" (không tạo bản ghi thứ hai).
4. Firestore Console: có `attendance_records/{sessionId}_{rollNumber}` với `checkinTime` là Timestamp.
5. *(Nếu đã bật OCR)* import một ảnh thời khóa biểu thử.

## 7. Migrate dữ liệu cũ

Dữ liệu do backend Apps Script cũ ghi (`classSections`, `attendanceSessions`, `attendanceRecords`, `users` role GV/SV…) được chuyển sang schema mới bằng [`firebase/scripts/migrate-legacy.mjs`](../firebase/scripts/migrate-legacy.mjs). Collection cũ **không bị sửa**; script idempotent.

```powershell
cd firebase
node scripts/migrate-legacy.mjs --dry-run          # thống kê + cảnh báo, chưa ghi gì
node scripts/migrate-legacy.mjs                    # ghi: user_invites, classes, enrollments, class_schedules, sessions, attendance_records
node scripts/migrate-legacy.mjs --only classes,sessions   # chạy một phần
node scripts/migrate-legacy.mjs --purge-legacy-users      # xóa users/{memberCode} cũ SAU khi đã có user_invites
```

| Cũ | Mới |
|---|---|
| `users/{memberCode}` (`GV`/`SV`) | `user_invites/{email}` (`staff`/`user`) |
| `classSections` + `subjects` | `classes` |
| `enrollments` | `enrollments` (+ `teacherMemberCode`, `fullName`, `email`) |
| `classSchedules` | `class_schedules` |
| `attendanceSessions` | `sessions` (+ `teacherMemberCode`; phiên cũ thiếu `ipCheck` → `true`) |
| `attendanceRecords` | `attendance_records` (+ `classCode`, `teacherMemberCode`; chuỗi ISO → `Timestamp`) |

Lưu ý:

- Collection `users` được **dùng lại tên** cho hồ sơ mới (id = `uid`). Bản ghi cũ nhận biết bằng việc thiếu trường `active`; dùng `--purge-legacy-users` để dọn sau khi kiểm tra `user_invites`.
- Chạy **trước** khi người dùng đăng nhập bằng hệ thống mới để mọi người có invite.
- Sau khi kiểm tra dữ liệu mới (Firestore Console / app), xóa các collection cũ còn lại (`classSections`, `attendanceSessions`, `attendanceRecords`, `classSchedules`, `subjects` nếu không dùng) để không còn dữ liệu trùng chứa thông tin cá nhân.
- Dùng `--emulator` để thử trước trên Emulator đã nạp dữ liệu cũ.

## 8. Rollback

- **Hosting**: Console → Hosting → Release history → *Rollback*, hoặc `firebase hosting:clone <site>:<channel> <site>:live`.
- **Rules**: `git revert` commit đổi Rules rồi `./scripts/deploy.ps1 -Only firestore`.
- **Dữ liệu**: Firestore chưa bật PITR mặc định — bật *Point-in-time recovery* hoặc export định kỳ (`gcloud firestore export`) nếu cần khôi phục.

## 9. Xử lý sự cố

| Triệu chứng | Cách xử lý |
|---|---|
| `Missing or insufficient permissions` trong app | Rules từ chối: truy vấn thiếu `teacherMemberCode`, hoặc tài liệu không thuộc GV ([08](08-security-rules.md)). Chạy lại truy vấn trong Emulator với `firebase emulators:start` để xem log Rules. |
| "The query requires an index" | Deploy indexes: `./scripts/deploy.ps1 -Only firestore`. |
| Trang SV trắng / "Không tải được cấu hình Firebase" | Mở qua Hosting (có `/__/firebase/init.json`); khi tự host nơi khác phải thay bằng cấu hình thật. |
| Đăng nhập Google bị chặn popup | Trình duyệt chặn pop-up: trang tự chuyển sang redirect; kiểm tra *Authorized domains*. |
| `functions: ... billing account` khi deploy | Chưa bật Blaze; deploy phần còn lại bằng `-Only` từng phần. |
| `OCR_NOT_CONFIGURED` | Chưa bật Cloud Vision API cho project. |
| Port 8080 bận khi chạy Emulator | Dự án dùng Firestore Emulator cổng **8085** (`firebase.json`). |
| `firebase: command not found` | `npm install -g firebase-tools` (script cũng thử `npx firebase-tools`). |

## 10. CI

[`.github/workflows/ci.yml`](../.github/workflows/ci.yml) chạy mỗi lần push/PR: test Rules + Functions + e2e trên Emulator, `flutter analyze`/`test` cho `packages/core` và `mobile`. CI **không** tự deploy; deploy là bước thủ công có kiểm soát.

[← Mục lục](README.md)
