[← Mục lục](README.md)

# 09 · Rủi ro & giới hạn cần lưu ý

| Rủi ro | Cách xử lý trong thiết kế này |
|---|---|
| Nhiều SV quét cùng lúc có thể ghi trùng bản ghi điểm danh | Firestore: document id `{sessionId}_{rollNumber}` — ghi trùng bị từ chối và API trả `ALREADY_CHECKED_IN`. `LockService` vẫn dùng cho các batch ghi nhiều bản ghi (lịch sử, tạo lịch). *(Google Sheet cũ không có giao dịch thật, phải dựa hoàn toàn vào khoá mềm.)* |
| Quota Apps Script (thời gian chạy 6 phút/lần, số request/ngày) giới hạn hơn server riêng | Đủ cho quy mô lớp/khoa; nếu dùng toàn trường cần chuyển hạ tầng — xem [10](10-dinh-huong-mo-rong.md). |
| Mỗi thao tác Firestore là một `UrlFetchApp` (quota ~20.000 lượt/ngày với tài khoản thường, mỗi lượt ~100–300 ms); đọc cả bảng lớn (`attendanceRecords`) tốn nhiều lượt | Đọc có "gợi ý lọc" (chỉ lấy đúng tài liệu cần) ở đường nóng: check-in, mở/đóng phiên, roster; ghi nhớ `users`/`slots`/`classSections` trong một lần chạy. Các màn tổng hợp (lịch sử, báo cáo, dashboard) vẫn đọc nhiều — theo dõi quota, và cân nhắc port sang Cloud Functions nếu vượt. |
| Quyền truy cập Firestore của Apps Script phụ thuộc token OAuth + IAM của **chủ script** | Chủ script cần vai trò *Cloud Datastore User* trên project và phải cấp quyền lại một lần sau khi manifest thêm scope `datastore`; nếu thiếu, mọi API lỗi `DB_PERMISSION`. Không có khóa dịch vụ nào trong app hay repo. |
| Cutover sang Firestore là một chiều | Quay lại Google Sheet (`setDbBackend('sheet')`) không mang theo dữ liệu ghi sau cutover. Chạy `verifyMigration` trước cutover, và thử với dữ liệu thật trong ngày ít tải. |
| Tab `Slot` không còn ghi được từ Firestore | Giờ slot cố định theo quy tắc A/P ([03](03-du-lieu-firestore.md#3-quy-tắc-lịch-slot-ap)); tính năng OCR ảnh thời khóa biểu không còn tự tạo/sửa slot, chỉ tạo lớp. |
| Không được nhúng khoá dịch vụ (service account) vào app | App chỉ gọi HTTPS công khai của Web App; quyền ghi CSDL nằm ở phía Apps Script (quyền chủ script). `firestore.rules` chặn mọi truy cập trực tiếp từ client. |
| API FAP "cung cấp sau" — chưa biết hình dạng thật | `SyncService` tách riêng theo Adapter pattern: đổi cách gọi FAP không phải sửa app hay schema (`syncedToFap` đánh dấu bản ghi chưa đẩy). |
| Mạng yếu khi SV gửi `checkin` trên web | Trang hiện nút "Thử lại" + thông báo rõ nguyên nhân; mỗi mã QR có hiệu lực trong chu kỳ 60 giây. |
| GV không tích "Kiểm tra IP mạng" (mặc định) nên SV có thể điểm danh từ xa bằng cách chuyển tiếp QR | Đây là đánh đổi có chủ ý: kiểm tra IP là tùy chọn theo từng phiên. Bản ghi được đánh dấu `networkVerificationResult = Skipped` để báo cáo phân biệt được; bật tùy chọn cho phiên cần chặt. Mã QR vẫn đổi mỗi 60 giây. |
| Nhiều phòng/lớp dùng chung một IP công khai của trường (NAT chung cho cả toà nhà) | Đây là đánh đổi đã biết: kiểm tra chỉ ở mức "cùng mạng trường", không phân biệt được phòng cụ thể. Đổi lại không cần xin quyền vị trí — nếu cần chặt hơn, có thể bổ sung sau (xem [10](10-dinh-huong-mo-rong.md)). |
| SV dùng 4G/mạng di động thay vì Wi-Fi trường (chỉ khi phiên bật kiểm tra IP) | IP sẽ khác `teacherIp` nên bị từ chối — đây là hành vi mong muốn (bắt buộc SV vào lớp phải bật Wi-Fi trường); trang cần nói rõ lý do để SV biết cách sửa. |
| SV dùng VPN/proxy làm đổi IP (chỉ khi phiên bật kiểm tra IP) | Giới hạn đã biết của phương án dùng IP thay GPS; chấp nhận được ở quy mô đồ án 2 tuần, ghi rõ trong tài liệu bàn giao. |
| Dữ liệu thật (họ tên, email SV) nằm trong Sheet cũ/xlsx và Firestore | Không commit file xlsx chứa PII; Firestore đóng với client; chỉ chủ script/IAM đọc được. |

[→ 10 Định hướng mở rộng](10-dinh-huong-mo-rong.md)
