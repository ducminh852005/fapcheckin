# FAP Check-in

Điểm danh bằng QR: giảng viên dùng app Flutter (MVVM) mở buổi điểm danh, sinh viên quét QR bằng camera điện thoại và điểm danh qua một trang web nhẹ — không cần cài app. **Toàn bộ backend và cơ sở dữ liệu là Firebase** (Authentication, Cloud Firestore + Security Rules, Storage, Remote Config, Hosting, và một Cloud Function cho OCR); phân quyền theo vai trò `user` / `staff` / `admin` được kiểm thử trên Firebase Emulator. Kiểm tra IP mạng là tùy chọn của từng phiên (mặc định tắt).

**Tài liệu kiến trúc đầy đủ:** [docs/README.md](docs/README.md) ·
**Pattern code:** [docs/quick-start.md](docs/quick-start.md) ·
**Chạy & build app mobile:** [docs/quick-start-mobile.md](docs/quick-start-mobile.md) ·
**Deploy & migrate dữ liệu:** [docs/deploy-firebase.md](docs/deploy-firebase.md) ·
**Security Rules:** [docs/08-security-rules.md](docs/08-security-rules.md)

## Cấu trúc monorepo

```
fapcheckin/
├─ packages/core/     # Dart package `fapcheckin_core`: model, Repository Firestore, theme/design system — dùng chung
├─ mobile/            # App Flutter cho Giảng viên (staff): lib/{app,viewmodels,views,core}, android/ ios/ windows/ ...
├─ web/
│  ├─ checkin/        # Trang điểm danh cho Sinh viên (HTML + Firebase JS SDK), host trên Firebase Hosting
│  └─ admin/          # Web Admin (chưa code — README thiết kế)
├─ firebase/
│  ├─ firestore.rules, storage.rules, firestore.indexes.json, remoteconfig.template.json
│  ├─ functions/      # Cloud Function scanTimetable (OCR thời khóa biểu)
│  ├─ tests/          # Test Security Rules chạy trên Firebase Emulator
│  └─ scripts/        # seed-admin, seed-reference, migrate-legacy (Node + Admin SDK)
├─ e2e_test/          # Luồng end-to-end trên Emulator: admin → GV mở phiên → SV điểm danh → GV đóng phiên
├─ scripts/deploy.ps1 # Chạy test Rules rồi firebase deploy
├─ firebase.json, .firebaserc
└─ docs/              # Blueprint kiến trúc (01–09) + quick-start
```

| Vai trò | Ứng dụng | Quyền chính |
|---|---|---|
| `staff` (giảng viên) | `mobile/` | Quản lý lớp mình phụ trách: mở phiên, QR xoay 60 giây, điểm danh tay, lịch sử, báo cáo |
| `user` (sinh viên) | `web/checkin/` (quét QR) | Tạo bản ghi điểm danh của chính mình; xem dữ liệu của mình |
| `admin` | `web/admin/` (chưa code) | Cấp tài khoản, quản lý lớp/ghi danh, duyệt đơn, phát thông báo |

## Chạy thử nhanh (Firebase Emulator)

Cần Node.js 22+, Java 21, `npm install -g firebase-tools`.

```bash
cd firebase && npm ci && cd ..
firebase emulators:start --project demo-fapcheckin     # Auth 9099, Firestore 8085, Storage 9199, Functions 5001, Hosting 5000, UI 4000

# terminal khác: dữ liệu mẫu
cd firebase
node scripts/seed-reference.mjs --emulator
node scripts/seed-admin.mjs --emulator --email admin@fpt.edu.vn --password Passw0rd!
```

## Kiểm thử

```bash
cd firebase && npm test              # Security Rules (Firestore + Storage) trên Emulator — 77 test
cd firebase/functions && npm test    # Parser/OCR của Cloud Function
cd e2e_test && npm test              # Luồng end-to-end trên Emulator
cd packages/core && flutter test     # Repository (fake_cloud_firestore)
cd mobile && flutter test            # Model, ViewModel, widget (xem lưu ý 2 test lỗi sẵn có ở docs/quick-start-mobile.md §7)
```

## Chạy app giảng viên

```bash
cd mobile
dart pub global activate flutterfire_cli
flutterfire configure --project=fapcheckin-3bn2di     # sinh lib/firebase_options.dart, google-services.json (một lần)
flutter pub get
flutter run -d <device-id>
```

Chi tiết (đăng nhập Google, SHA-1, build, lỗi thường gặp): [docs/quick-start-mobile.md](docs/quick-start-mobile.md).

## Tài khoản Admin đầu tiên

Rules không cho client tự đặt role, nên admin đầu tiên được tạo ngoài ứng dụng (đăng nhập bằng **Google**, không có mật khẩu):

1. Firebase Console → **Authentication → Users → Add user** (hoặc người đó đăng nhập Google một lần), ghi lại **UID**.
2. Console → **Firestore → `users` → Add document**, *Document ID = UID*, các trường: `memberCode`, `fullName`, `email`, `role = "admin"`, `active = true`, `createdAt`.
   Hoặc dùng script (cần Application Default Credentials): `node firebase/scripts/seed-admin.mjs --email <email> --name "<tên>"`.
3. Ghi thông tin tài khoản đã tạo vào bảng dưới (**không** ghi mật khẩu hay khóa vào repo).

| Mục | Giá trị |
|---|---|
| Project Firebase | `fapcheckin-3bn2di` |
| Email admin đầu tiên | `<điền email đã tạo>` |
| Phương thức đăng nhập | Google (Firebase Authentication) |
| Người tạo / ngày | `<điền>` |

Admin cấp tài khoản GV/SV bằng cách tạo `user_invites/{email}` (role `staff` / `user`, `memberCode`, `rollNumber`). Hướng dẫn đầy đủ: [docs/deploy-firebase.md §3](docs/deploy-firebase.md#3-tài-khoản-admin-đầu-tiên).

## CI/CD

GitHub Actions, chỉ chạy khi push lên `main`: `ci.yml` (test Rules/Functions/e2e trên Emulator + Flutter), `deploy.yml` (preview + smoke test, rồi deploy Firebase khi CI xanh), `mobile-build.yml` (APK debug). Thiết lập secret và quy trình: [docs/deploy-firebase.md §10](docs/deploy-firebase.md#10-cicd-github-actions).

## Deploy

```powershell
./scripts/deploy.ps1                 # test Rules + deploy hosting, firestore, storage, remoteconfig, functions
./scripts/deploy.ps1 -Only firestore # chỉ rules + indexes
```

App Flutter (`mobile/`) không deploy bằng script này. Chuyển dữ liệu từ hệ thống Apps Script cũ: [docs/deploy-firebase.md §7](docs/deploy-firebase.md#7-migrate-dữ-liệu-cũ).
