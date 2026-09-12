[← Mục lục](README.md)

# 10 · Định hướng mở rộng

Những gì nên xem lại khi hệ thống vượt quy mô một lớp/khoa thử nghiệm.

## Khi số lớp/SV tăng

Thay Google Sheet bằng Firestore hoặc PostgreSQL đứng sau cùng một hợp đồng API — vì Repository ở app không đổi, chỉ đổi phần lõi Backend.

## Bản Desktop cho Giảng viên (đúng ý "Desktop hỗ trợ" của đề bài)

Cùng một codebase Flutter build thêm `flutter build windows/macos`: chỉ viết lại `views/` cho màn hình lớn, còn `viewmodels/`, `data/`, `core/` dùng lại nguyên vẹn nhờ tách lớp MVVM. Trang web của SV thì khỏi cần làm gì thêm — nó vốn đã chạy được trên mọi trình duyệt, kể cả desktop.

## Nếu cần định vị chặt hơn IP

Có thể bổ sung so khớp SSID Wi-Fi, hoặc quay lại GPS như một lớp kiểm tra thứ hai (tuỳ chọn, xin quyền rõ ràng) — nhưng đó là hướng nâng cấp sau này, ngoài phạm vi bản 2 tuần này.

---

[← Mục lục](README.md)
