# FAP Check-in

Điểm danh bằng QR: giảng viên dùng app Flutter (MVVM) mở buổi điểm danh, sinh viên quét QR bằng camera điện thoại và điểm danh qua một trang web nhẹ — không cần cài app. Backend là Google Apps Script; dữ liệu nằm trong Cloud Firestore (Google Sheet cũ chỉ còn là nguồn để migrate), trang của sinh viên host trên Firebase Hosting — trong lúc chờ API chính thức từ FAP. Kiểm tra IP mạng là tùy chọn của từng phiên (mặc định tắt).

**Tài liệu kiến trúc đầy đủ:** [docs/README.md](docs/README.md)
**Pattern code & chuẩn giao tiếp với backend:** [docs/quick-start.md](docs/quick-start.md)
**Chạy & build app trên mobile:** [docs/quick-start-mobile.md](docs/quick-start-mobile.md)

## Cấu trúc repo

```
lib/                # App Flutter cho Giảng viên (MVVM) — xem docs/04, docs/quick-start
├─ main.dart        # Khung MaterialApp tối thiểu (chưa nối luồng thật)
├─ app/             # MaterialApp, router
├─ core/            # constants, services (ApiService...), utils (ApiResult...)
├─ data/            # models (ApiResponse...), repositories
├─ viewmodels/      # BaseViewModel + các ViewModel màn hình
└─ views/

checkin-web/        # Trang web check-in cho Sinh viên (HTML/CSS/JS thuần), host trên Firebase Hosting — xem docs/04, docs/deploy-firebase.md
apps-script/        # Backend Google Apps Script (API/BFF, lớp dữ liệu SheetDB -> Firestore hoặc Sheet) — xem docs/01, 03, quick-start §3
scripts/deploy.ps1  # Deploy backend + Hosting + Firestore — xem docs/deploy-firebase.md
firebase.json, firestore.rules, firestore.indexes.json  # Cấu hình Firebase
docs/               # Blueprint kiến trúc (00–10) + quick-start pattern
```

> `lib/main.dart` mới là khung tối thiểu; các thư mục con còn lại đang rỗng (giữ chỗ bằng `.gitkeep`). Trước khi code, đọc [docs/quick-start.md](docs/quick-start.md) — chốt sẵn chuẩn request/response (`action` + envelope JSON) và pattern MVVM (`ApiResponse`, `ApiResult`, `BaseViewModel`) để cả nhóm code thống nhất.

## Getting Started (Flutter)

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
