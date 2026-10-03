# FAP Check-in — Tài liệu kiến trúc (Blueprint v2)

> Nguồn: `FAP-Checkin-Kien-truc.docx` · REV. v2 · 12/09/2026

Giảng viên dùng app Flutter (MVVM) để mở buổi điểm danh bằng QR; sinh viên chỉ cần dùng camera điện thoại quét mã và mở một trang web nhẹ (host trên Firebase Hosting) — không cần cài app. Backend là Google Apps Script; dữ liệu nằm trong Cloud Firestore (Google Sheet ban đầu chỉ còn là nguồn dữ liệu cũ để migrate), trong lúc chờ API chính thức từ nhà trường (FAP).

| | |
|---|---|
| **Nhóm** | 5 thành viên |
| **Thời hạn** | 14 ngày |
| **Nền tảng** | Flutter (GV) + Web (SV, Firebase Hosting) |
| **Kiến trúc app GV** | MVVM |
| **Backend** | Google Apps Script Web App (BFF) |
| **Lưu trữ** | Cloud Firestore (chuyển từ Google Sheet — xem [03](03-du-lieu-firestore.md)) |

## Giả định & phạm vi

- API chính thức của FAP "sẽ được cung cấp sau" → dữ liệu vận hành nằm trong Firestore, với một lớp đồng bộ (Sync) tách riêng — khi có API thật chỉ thay lớp này, không đụng app.
- Giảng viên/sinh viên đều có email theo domain trường.
- Xác thực "đang ở gần lớp học" dùng địa chỉ IP mạng công khai — **không** xin quyền định vị (GPS) thiết bị. Đây là kiểm tra "cùng mạng Wi-Fi trường", không phải đo khoảng cách vật lý chính xác theo mét (giới hạn nêu ở [09](09-rui-ro-va-gioi-han.md)).

## Mục lục

| # | Tài liệu |
|---|---|
| 00 | [Tổng quan & yêu cầu](00-tong-quan-va-yeu-cau.md) |
| 01 | [Kiến trúc tổng thể hệ thống](01-kien-truc-tong-the.md) |
| 02 | [Luồng điểm danh QR](02-luong-diem-danh-qr.md) |
| 03 | [Dữ liệu & cấu trúc Firestore](03-du-lieu-firestore.md) |
| 04 | [Kiến trúc App Giảng viên & Trang Web Sinh viên](04-kien-truc-app-va-web.md) |
| 05 | [Xác thực & phân quyền](05-xac-thuc-va-phan-quyen.md) |
| 06 | [Tính năng đề xuất thêm](06-tinh-nang-de-xuat-them.md) |
| 07 | [Phân công nhóm 5 người](07-phan-cong-nhom.md) |
| 08 | [Kế hoạch 14 ngày](08-ke-hoach-14-ngay.md) |
| 09 | [Rủi ro & giới hạn cần lưu ý](09-rui-ro-va-gioi-han.md) |
| 10 | [Định hướng mở rộng](10-dinh-huong-mo-rong.md) |
| — | [Quick Start — Pattern & chuẩn API Response](quick-start.md) |
| — | [Hướng dẫn deploy lên Firebase & chuyển DB sang Firestore](deploy-firebase.md) |
| — | [ERD (Mermaid)](db-erd.mermaid) · [ghi chú ERD & ánh xạ Firestore](db-erd-notes.md) |
