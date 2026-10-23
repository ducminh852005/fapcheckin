[← Mục lục](README.md)

# 06 · Rủi ro, giới hạn & hướng mở rộng

| Rủi ro / giới hạn | Cách xử lý trong thiết kế này |
|---|---|
| Nhiều SV quét cùng lúc, hoặc một SV quét hai lần | Id bản ghi `{sessionId}_{rollNumber}` + SV chỉ được `create` → lần ghi thứ hai bị Rules từ chối; trang SV hiện "Đã ghi nhận". |
| Client ghi thẳng vào CSDL nên Rules là hàng rào duy nhất | Rules deny-by-default, mỗi collection có test allowed/denied trên Emulator (77 test) và chạy trong CI; mọi thay đổi Rules phải kèm test ([08](08-security-rules.md)). |
| Rules chỉ trả `permission-denied`, không phân biệt lý do | Trang SV chẩn đoán bằng cách đọc thêm dữ liệu SV được phép đọc ([02](02-luong-diem-danh-qr.md#thông-báo-lỗi-cho-sinh-viên)); thông báo có thể gộp "QR hết hạn" với "khác mạng" khi phiên bật kiểm tra IP. |
| Rules giới hạn truy vấn: GV phải lọc theo `teacherMemberCode` | Repository luôn kèm điều kiện này; đổi GV phụ trách lớp phải cập nhật `classes` và `enrollments` cùng batch (đã làm khi nhận lớp qua import TKB). Admin đổi `teacherMemberCode` cần cập nhật cả `enrollments`, `sessions`, `attendance_records`, `class_schedules` liên quan. |
| Báo cáo/lịch sử tính ở client | Mỗi lần mở trang đọc dữ liệu của giảng viên (số bản ghi ∼ SV × buổi). Đủ cho quy mô lớp/khoa; nếu lớn hơn, dùng truy vấn tổng hợp (`count()`) hoặc Cloud Function tính sẵn ([06](06-rui-ro-va-mo-rong.md#hướng-mở-rộng)). `getClasses` đã dùng `count()` để không đọc từng bản ghi. |
| Phát hiện trùng lịch học bù chỉ trong phạm vi lịch của chính GV | Rules không cho đọc lịch/phòng của GV khác, nên không phát hiện trùng phòng giữa các GV; hạn chế đã biết (trước đây backend đọc toàn bộ bảng). |
| OCR cần Cloud Function → gói Blaze + Cloud Vision | Chỉ tính năng import TKB bằng ảnh bị ảnh hưởng; mọi chức năng điểm danh chạy trên gói Spark. Có thể nhập lớp bằng admin thay thế. |
| API FAP "cung cấp sau" — chưa biết hình dạng thật | `syncToFap` là điểm tích hợp duy nhất (trường `syncedToFap` đánh dấu bản ghi chưa đẩy); đổi cách gọi FAP không phải sửa schema hay UI. |
| Mạng yếu khi SV điểm danh | Trang hiện nút "Thử lại" + thông báo rõ nguyên nhân; Firestore SDK tự retry; mã QR có hiệu lực trong chu kỳ 60 giây. |
| GV không tích "Kiểm tra IP mạng" (mặc định) nên SV có thể điểm danh từ xa bằng cách chuyển tiếp QR | Đánh đổi có chủ ý: kiểm tra IP là tùy chọn theo phiên. Bản ghi được đánh dấu `Skipped` để báo cáo phân biệt; bật tùy chọn cho phiên cần chặt. QR đổi mỗi 60 giây. |
| `ipAddress` do client gửi nên SV kỹ thuật có thể khai IP giả (phiên bật kiểm tra IP) | Giới hạn của kiểm tra phía client mà không có backend riêng. Chấp nhận ở quy mô đồ án; muốn chặt hơn cần Cloud Function đọc IP từ request (xem [06](06-rui-ro-va-mo-rong.md#hướng-mở-rộng)). |
| Nhiều phòng/lớp dùng chung một IP công khai của trường (NAT) | Kiểm tra chỉ ở mức "cùng mạng trường", không phân biệt phòng. Đổi lại không cần xin quyền vị trí. |
| SV dùng 4G hoặc VPN/proxy (phiên bật kiểm tra IP) | IP khác `teacherIp` nên bị từ chối — hành vi mong muốn; trang nêu rõ lý do và cách sửa. |
| Lộ khóa | Khóa Firebase client là công khai theo thiết kế; **không** commit khóa service account (`.gitignore` đã chặn các mẫu thường gặp). Script Admin SDK dùng Application Default Credentials. |
| Dữ liệu thật (họ tên, email SV) là PII | Firestore đóng với người lạ; SV chỉ đọc dữ liệu của mình; không commit file xlsx/CSV chứa PII. Collection cũ sau migrate cần được xóa hoặc giữ kín. |
| Flutter trên Windows/Linux dùng Firebase Auth | Hỗ trợ desktop của plugin Firebase còn hạn chế; đã kiểm chứng đường đi mobile/web. Nếu `signInWithCredential` lỗi trên desktop, dùng Android hoặc web. |


## Hướng mở rộng

- **Web Admin**: hoàn thiện [`web/admin/`](../web/admin/README.md) (Flutter Web dùng lại `packages/core`); schema và Rules đã sẵn sàng.
- **Báo cáo khi dữ liệu lớn**: Cloud Function `onWrite` cập nhật tổng hợp theo lớp, hoặc truy vấn tổng hợp `count()`/`sum()`.
- **Xác thực IP phía máy chủ**: check-in qua callable function đọc IP thật từ request, ghi bằng Admin SDK (Rules chặn SV ghi trực tiếp). Cần gói Blaze.
- **Roster real-time**: dùng `snapshots()` cho `attendance_records` của phiên đang mở (app hiện làm mới mỗi 5 giây).
- **Sinh sẵn buổi học thường** từ `slots.weekdays` vào `class_schedules` để có tổng số buổi thật thay cho số cố định 30.
- **Đồng bộ FAP** thành Cloud Function theo lịch khi nhà trường cung cấp API.
- **Custom claims** cho `role`: bỏ một lần `get()` hồ sơ trong mỗi request của Rules.
- **Desktop**: `flutter build windows/macos` trong `mobile/` (`viewmodels/` và `packages/core` dùng lại nguyên vẹn; lưu ý giới hạn Firebase Auth trên desktop ở bảng trên).
- **Định vị chặt hơn IP**: so khớp SSID hoặc GPS như lớp kiểm tra thứ hai (tùy chọn, xin quyền rõ ràng).

[← Mục lục](README.md)
