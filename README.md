# FAP Check-in

Điểm danh bằng QR: giảng viên dùng app Flutter (MVVM) mở buổi điểm danh, sinh viên quét QR bằng camera điện thoại và điểm danh qua một trang web nhẹ — không cần cài app. Google Sheet là cơ sở dữ liệu tạm thời trong lúc chờ API chính thức từ FAP.

**Tài liệu kiến trúc đầy đủ:** [docs/README.md](docs/README.md)

## Cấu trúc repo

```
lib/                # App Flutter cho Giảng viên (MVVM) — xem docs/04
├─ app/             # MaterialApp, router
├─ core/            # constants, services, utils
├─ data/            # models, repositories
├─ viewmodels/
└─ views/

checkin-web/        # Trang web check-in cho Sinh viên (HTML/CSS/JS thuần) — xem docs/04
apps-script/        # Backend Google Apps Script (BFF + phục vụ checkin-web) — xem docs/01, 03
docs/               # Blueprint kiến trúc, chia theo mục 00–10
```

> Các thư mục trên hiện đang rỗng (giữ chỗ bằng `.gitkeep`) — chưa có code triển khai, chỉ dựng khung theo thiết kế.

## Getting Started (Flutter)

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
