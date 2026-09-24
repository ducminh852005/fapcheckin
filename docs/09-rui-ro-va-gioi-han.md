[← Mục lục](README.md)

# 09 · Rủi ro & giới hạn cần lưu ý

| Rủi ro | Cách xử lý trong thiết kế này |
|---|---|
| Google Sheet không có transaction thật, nhiều SV quét cùng lúc có thể ghi trùng dòng | Dùng `LockService` trong Apps Script để khoá mềm khi ghi `AttendanceLog`. |
| Quota Apps Script (thời gian chạy, số request/ngày) giới hạn hơn server riêng | Đủ cho quy mô lớp/khoa; nếu dùng toàn trường cần chuyển hạ tầng — xem [10](10-dinh-huong-mo-rong.md). |
| Không được nhúng khoá dịch vụ (service account) vào app | App chỉ gọi HTTPS công khai của Web App; mọi quyền ghi Sheet nằm ở phía Apps Script, chạy dưới quyền chủ sở hữu. |
| API FAP "cung cấp sau" — chưa biết hình dạng thật | `SyncService` tách riêng theo Adapter pattern: đổi cách gọi FAP không phải sửa app hay schema Sheet. |
| Mạng yếu khi SV gửi `/checkin` trên web | Trang hiện nút "Thử lại" + thông báo rõ nguyên nhân; mỗi mã QR có hiệu lực trong chu kỳ 60 giây. |
| Nhiều phòng/lớp dùng chung một IP công khai của trường (NAT chung cho cả toà nhà) | Đây là đánh đổi đã biết: kiểm tra chỉ ở mức "cùng mạng trường", không phân biệt được phòng cụ thể. Đổi lại không cần xin quyền vị trí — nếu cần chặt hơn, có thể bổ sung sau (xem [10](10-dinh-huong-mo-rong.md)). |
| SV dùng 4G/mạng di động thay vì Wi-Fi trường | IP sẽ khác `teacherIp` nên bị từ chối — đây là hành vi mong muốn (bắt buộc SV vào lớp phải bật Wi-Fi trường); trang cần nói rõ lý do để SV biết cách sửa. |
| SV dùng VPN/proxy làm đổi IP | Giới hạn đã biết của phương án dùng IP thay GPS; chấp nhận được ở quy mô đồ án 2 tuần, ghi rõ trong tài liệu bàn giao. |

[→ 10 Định hướng mở rộng](10-dinh-huong-mo-rong.md)
