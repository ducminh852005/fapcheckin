[← Mục lục](README.md)

# 00 · Tổng quan & yêu cầu

Ba yêu cầu lõi từ đề bài, giữ nguyên làm kim chỉ nam cho mọi quyết định kỹ thuật.

| # | Yêu cầu | Diễn giải kỹ thuật |
|---|---|---|
| 1 | Đăng nhập giảng viên / sinh viên | GV đăng nhập trong app Flutter; SV đăng nhập ngay trên trang web (Google Identity Services) — cùng domain trường, cùng cơ chế phân quyền, không cần cài gì thêm. |
| 2 | GV bấm điểm danh → hiện QR → SV quét → tự điểm danh | QR mã hoá một URL mang "phiên điểm danh" có hạn dùng; SV dùng camera có sẵn để quét (không cần app riêng) → trình duyệt tự mở trang và ghi nhận ngay nếu trước đó đã đăng nhập. |
| 3 | Lưu vào Google Sheet, sau đó đẩy lên hệ thống chính thức của trường | Sheet là DB vận hành ngay bây giờ; việc đẩy lên FAP là một job đồng bộ độc lập, chạy sau. |

[→ 01 Kiến trúc tổng thể hệ thống](01-kien-truc-tong-the.md)
