# FAP Check-in — Tài liệu kiến trúc (Blueprint v3 · Firebase)

> Nguồn gốc: `FAP-Checkin-Kien-truc.docx` (REV. v2, 12/09/2026), cập nhật khi chuyển toàn bộ backend và cơ sở dữ liệu sang Firebase.

Giảng viên dùng app Flutter (MVVM) để mở buổi điểm danh bằng QR; sinh viên chỉ cần dùng camera điện thoại quét mã và mở một trang web nhẹ (host trên Firebase Hosting) — không cần cài app. Backend là **Firebase**: Authentication, Cloud Firestore + Security Rules, Storage, Remote Config, Hosting và Cloud Functions (OCR, nhắc lịch, góp ý, đồng bộ FAP, trợ lý AI). Không còn Google Apps Script hay Google Sheet.

| | |
|---|---|
| **Nhóm** | 5 thành viên |
| **Thời hạn** | 14 ngày |
| **Nền tảng** | Flutter (GV, `mobile/`) · Web check-in (SV, `web/checkin/`) · Web Admin (`web/admin/`, React + Vite, UI prototype) |
| **Kiến trúc app GV** | MVVM; model/Repository/design system dùng chung ở `packages/core/` |
| **Backend** | Firebase: Auth (Google) · Firestore + Rules · Storage · Remote Config · Hosting · Cloud Functions (OCR, nhắc lịch, góp ý, `syncToFap`, `aiAssistant`) |
| **Phân quyền** | RBAC `user` (SV) · `staff` (GV) · `admin` bằng Security Rules, có test trên Emulator |

## Giả định & phạm vi

- API chính thức của FAP "sẽ được cung cấp sau" → dữ liệu vận hành nằm trong Firestore, với một điểm đồng bộ (`syncToFap`) tách riêng — khi có API thật chỉ thay phần này, không đụng app.
- Giảng viên/sinh viên đều có email trường và được admin cấp trước trong `user_invites`.
- Xác thực "đang ở gần lớp học" dùng địa chỉ IP mạng công khai — **không** xin quyền định vị (GPS). Đây là kiểm tra tùy chọn "cùng mạng Wi-Fi trường", không phải đo khoảng cách chính xác (giới hạn nêu ở [06](06-rui-ro-va-mo-rong.md)).

## Yêu cầu lõi

| # | Yêu cầu | Diễn giải kỹ thuật |
|---|---|---|
| 1 | Đăng nhập giảng viên / sinh viên | Firebase Authentication (Google) cho cả app GV và trang web SV; phân quyền `user`/`staff`/`admin` bằng Security Rules. |
| 2 | GV bấm điểm danh → hiện QR → SV quét → tự điểm danh | QR mã hóa URL mang phiên điểm danh có hạn dùng; SV quét bằng camera có sẵn, trang web tự điểm danh nếu trình duyệt đã đăng nhập. |
| 3 | Lưu dữ liệu, sau đó đẩy lên hệ thống chính thức của trường | Cloud Firestore là CSDL duy nhất; đẩy lên FAP là bước đồng bộ độc lập (`syncToFap`), chạy sau. |

## Mục lục

| # | Tài liệu |
|---|---|
| 01 | [Kiến trúc tổng thể hệ thống](01-kien-truc-tong-the.md) |
| 02 | [Luồng điểm danh QR](02-luong-diem-danh-qr.md) |
| 03 | [Dữ liệu & cấu trúc Firestore](03-du-lieu-firestore.md) |
| 04 | [Cấu trúc monorepo, App Giảng viên & Trang Web Sinh viên](04-kien-truc-app-va-web.md) |
| 05 | [Xác thực & phân quyền (RBAC)](05-xac-thuc-va-phan-quyen.md) |
| 06 | [Rủi ro, giới hạn & hướng mở rộng](06-rui-ro-va-mo-rong.md) |
| 07 | [Import thời khóa biểu bằng ảnh (OCR)](07-timetable-ocr.md) |
| 08 | [Security Rules & kiểm thử](08-security-rules.md) |
| 09 | [Repository (cách app đọc/ghi dữ liệu)](09-repository-api.md) |
| — | [Trợ lý AI (tab AI): kiến trúc, tool, AI dự phòng Ollama, giọng nói/Live/ngắt AI, triển khai, kiểm thử](ai-assistant.md) |
| — | [Quick Start — Pattern MVVM + Repository trên Firebase](quick-start.md) |
| — | [Quick Start Mobile — chạy & build app GV trên Android/iOS](quick-start-mobile.md) |
| — | [Thiết lập & deploy Firebase, migrate dữ liệu cũ](deploy-firebase.md) |
| — | [Thiết lập đăng nhập Google (Firebase Auth)](google-oauth-setup.md) |
| — | [ERD (Mermaid)](db-erd.mermaid) |
| — | [Data model — đặc tả collection, quyền và rule](data-model.md) |
| — | [Kết nối mobile ↔ Firebase: màn hình ↔ repository](mobile-api-integration.md) |
| — | [Tài liệu bài nộp môn học (báo cáo cuối, persona, báo cáo test, gap review…)](course/README.md) |

Mã nguồn tương ứng: [`firebase/`](../firebase) (rules, test, script, function) · [`packages/core/`](../packages/core) · [`mobile/`](../mobile) · [`web/`](../web) · [`e2e_test/`](../e2e_test).
