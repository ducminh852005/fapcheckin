[← Mục lục](README.md)

# 08 · Kế hoạch 14 ngày

Ba nhịp: dựng nền (3 ngày) → ráp luồng lõi (5 ngày) → tính năng thêm và ổn định (6 ngày).

| Ngày | Trọng tâm | Chủ yếu bởi |
|---|---|---|
| 1 | Chốt yêu cầu, wireframe (cả app GV lẫn trang web SV), thiết kế schema Sheet, khởi tạo repo Flutter + Apps Script | Cả nhóm |
| 2 | Deploy Web App thử nghiệm (kèm route phục vụ trang HTML cho SV), cấu hình OAuth Google (app & web), khung MVVM rỗng chạy được | Backend, Nền tảng |
| 3–4 | Đăng nhập end-to-end cho GV (app) và SV (web), phân quyền theo role | Nền tảng, Web SV, Backend |
| 5–6 | Luồng Giảng viên: tạo phiên, sinh & xoay QR mã hoá URL (`/session/start`, `/session/token`) | Mobile GV, Backend |
| 7–8 | Trang web SV: nút đăng nhập Google, lấy IP qua ipify, gọi `/checkin`, hiển thị kết quả | Web SV, Backend |
| 9 | Kiểm tra IP mạng: đối chiếu `teacherIp`/`studentIp`, xử lý VPN/4G, thông báo lỗi rõ ràng | Backend, Web SV |
| 10 | Xử lý lỗi mạng trên trang web (nút thử lại), hoàn thiện điểm danh tay dự phòng trên app GV | Web SV, Mobile GV |
| 11 | Thống kê chuyên cần (biểu đồ), roster real-time cho GV | Mobile GV |
| 12 | Test tích hợp toàn luồng trên nhiều trình duyệt & thiết bị thật, sửa lỗi | QA, cả nhóm |
| 13 | Hoàn thiện UI/UX, README bàn giao, dữ liệu demo mẫu | QA/UI-UX |
| 14 | Demo nội bộ, quay video, buffer sửa lỗi phát sinh, họp rút kinh nghiệm | Cả nhóm |

[→ 09 Rủi ro & giới hạn cần lưu ý](09-rui-ro-va-gioi-han.md)
