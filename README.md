# FAP Check-in

Điểm danh bằng QR: giảng viên dùng app Flutter (MVVM) mở buổi điểm danh, sinh viên quét QR bằng camera điện thoại và điểm danh qua một trang web nhẹ — không cần cài app. Backend là Google Apps Script; dữ liệu nằm trong Cloud Firestore (Google Sheet cũ chỉ còn là nguồn để migrate), trang của sinh viên host trên Firebase Hosting — trong lúc chờ API chính thức từ FAP. Kiểm tra IP mạng là tùy chọn của từng phiên (mặc định tắt).

**Tài liệu kiến trúc đầy đủ:** [docs/README.md](docs/README.md)
**Pattern code & chuẩn giao tiếp với backend:** [docs/quick-start.md](docs/quick-start.md)
**Chạy & build app trên mobile:** [docs/quick-start-mobile.md](docs/quick-start-mobile.md)

## PRM323 Lab 2 Artifacts & UX Documentation

- 📄 **User Persona & Success Metrics:** [ux/persona.md](ux/persona.md)
- 📑 **PRM393 Persona Specification (Full Guideline):** [docs/prm393-persona-document.md](docs/prm393-persona-document.md)
- 🖥️ **Interactive Persona Presentation Deck:** [docs/persona-slides/index.html](docs/persona-slides/index.html)
- 🗺️ **Information Architecture & User Flows:** [ux/user-flow.md](ux/user-flow.md)
- 🤖 **AI UI Generation & Critique Log:** [ux/ai-design-log.md](ux/ai-design-log.md)
- 🎨 **Design Decisions & Accessibility Audit:** [ux/design-decisions.md](ux/design-decisions.md)
- 🛠️ **Flutter Handoff Specifications:** [ux/flutter-handoff.md](ux/flutter-handoff.md)
- 📊 **Slide Presentation & Demo Guide:** [docs/presentation-slide-guide.md](docs/presentation-slide-guide.md)

## Cấu trúc repo

```
lib/                # App Flutter cho Giảng viên (MVVM) — xem docs/04, docs/quick-start
├─ main.dart        # Khung ứng dụng Flutter
├─ core/            # AppColors, AppTextStyles, Theme, Services
├─ data/            # Models, Repositories
├─ viewmodels/      # ViewModel quản lý trạng thái
└─ views/           # Các màn hình chính (Dashboard, Live Session, Report, History, Settings...)

ux/                 # Bàn giao UX/UI & Nhật ký AI cho PRM323 Lab 2
checkin-web/        # Trang web check-in cho Sinh viên (HTML/CSS/JS thuần), host trên Firebase Hosting
apps-script/        # Backend Google Apps Script (API/BFF)
scripts/            # Deploy scripts
docs/               # Blueprint kiến trúc (00–11) + Hướng dẫn Slide Presentation & Demo
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
