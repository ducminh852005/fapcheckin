[← Mục lục](README.md)

# 07 · Phân công nhóm 5 người

Chia theo lát cắt tính năng (vertical slice) để mỗi người tự chạy được từ UI đến API, không nghẽn chờ nhau.

| Vai trò | Phụ trách | Đầu ra chính |
|---|---|---|
| **Backend & Dữ liệu** (kiêm Trưởng nhóm) | Apps Script Web App (bao gồm route phục vụ trang web SV), schema Sheet, kiểm tra IP, `LockService` chống ghi trùng, khung `syncToFap()` | API + trang web sống trước **Ngày 3** để cả nhóm có chỗ gọi vào |
| **Mobile GV — Nền tảng & Xác thực** | Khung dự án MVVM, `go_router`, Google Sign-In, quản lý session/token | App chạy được, đăng nhập xong vào đúng màn |
| **Mobile GV — Luồng điểm danh** | Tạo buổi học, sinh & xoay QR, roster real-time, điểm danh tay dự phòng, thống kê | Toàn bộ `views/teacher` + `teacher_session_viewmodel.dart` |
| **Web SV — Trang check-in** | HTML/CSS/JS nhẹ, nút đăng nhập Google (GIS), lấy IP qua ipify, gọi `/checkin`, hiển thị trạng thái + thử lại khi lỗi mạng | Toàn bộ `checkin-web/` |
| **QA / UI-UX / DevOps** | Thiết kế UI cho cả app GV lẫn trang web SV, test đa thiết bị & trình duyệt, build APK, README bàn giao | Checklist test + bản build demo **Ngày 13** |

[→ 08 Kế hoạch 14 ngày](08-ke-hoach-14-ngay.md)
