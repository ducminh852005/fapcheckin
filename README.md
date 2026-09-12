# FAP Check-in

Điểm danh bằng QR: giảng viên dùng app Flutter (MVVM) mở buổi điểm danh, sinh viên quét QR bằng camera điện thoại và điểm danh qua một trang web nhẹ — không cần cài app. Google Sheet là cơ sở dữ liệu tạm thời trong lúc chờ API chính thức từ FAP.

**Tài liệu kiến trúc đầy đủ:** [docs/README.md](docs/README.md)
**Pattern code & chuẩn giao tiếp với backend:** [docs/quick-start.md](docs/quick-start.md)

## Cấu trúc repo

```
lib/                # App Flutter cho Giảng viên (MVVM) — xem docs/04, docs/quick-start
├─ main.dart        # Khung MaterialApp tối thiểu (chưa nối luồng thật)
├─ app/             # MaterialApp, router
├─ core/            # constants, services (ApiService...), utils (ApiResult...)
├─ data/            # models (ApiResponse...), repositories
├─ viewmodels/      # BaseViewModel + các ViewModel màn hình
└─ views/

checkin-web/        # Trang web check-in cho Sinh viên (HTML/CSS/JS thuần) — xem docs/04
apps-script/        # Backend Google Apps Script (BFF + phục vụ checkin-web) — xem docs/01, 03, quick-start §3
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
