[← Mục lục](README.md)

# 10 · Định hướng mở rộng

Những gì nên xem lại khi hệ thống vượt quy mô một lớp/khoa thử nghiệm.

## Khi số lớp/SV tăng

Cơ sở dữ liệu đã là Firestore (không còn là Google Sheet) đứng sau cùng một hợp đồng API, nên app GV và trang SV không đổi. Điểm nghẽn tiếp theo là **Backend Apps Script** (quota `UrlFetchApp`, 6 phút/lần chạy, độ trễ gọi REST — xem [09](09-rui-ro-va-gioi-han.md)). Lộ trình gợi ý:

1. **Port từng action sang Cloud Functions (Node + Admin SDK)**: bật gói Blaze, đặt `functions/` trong `firebase.json`, thay `FirestoreStore.gs` bằng truy cập Admin SDK trực tiếp (nhanh, có giao dịch/batch thật). Đổi `API_BASE_URL` của app GV và `BACKEND_URL` của trang SV sang URL function; có thể chạy song song với Apps Script rồi chuyển dần.
2. **Firebase Auth** thay cho token phiên tự cấp (dùng sẵn trường `users.authUid`); phân quyền theo vai trò trong `firestore.rules`.
3. **Roster real-time**: app GV đọc `attendanceRecords` bằng client SDK (listener) thay vì polling; cần nới `firestore.rules` theo `request.auth` + lớp thuộc giảng viên.
4. Sinh sẵn các buổi học thường (từ `slots.weekdays`) vào `classSchedules` để có tổng số buổi thật thay cho số cố định, và nối `attendanceSessions.scheduleId`.

## Bản Desktop cho Giảng viên (đúng ý "Desktop hỗ trợ" của đề bài)

Cùng một codebase Flutter build thêm `flutter build windows/macos`: chỉ viết lại `views/` cho màn hình lớn, còn `viewmodels/`, `data/`, `core/` dùng lại nguyên vẹn nhờ tách lớp MVVM. Trang web của SV thì khỏi cần làm gì thêm — nó vốn đã chạy được trên mọi trình duyệt, kể cả desktop.

## Nếu cần định vị chặt hơn IP

Có thể bổ sung so khớp SSID Wi-Fi, hoặc quay lại GPS như một lớp kiểm tra thứ hai (tuỳ chọn, xin quyền rõ ràng) — nhưng đó là hướng nâng cấp sau này, ngoài phạm vi bản 2 tuần này.

---

[← Mục lục](README.md)
