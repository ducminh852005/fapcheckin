# Test cases Android và Firebase

Bộ kiểm thử gồm 30 Test Case. TC01–TC10 là phạm vi ban đầu và đã có kết quả riêng trong `docs/test-report.md`; TC11–TC30 là phạm vi mở rộng, chưa được tính Pass cho đến khi chạy thực tế. Mỗi case cần trạng thái ban đầu rõ ràng, dữ liệu test riêng và ba lượt độc lập. Không dùng thao tác trực tiếp trên Firebase Console để thay thế một bước E2E của người dùng.

| ID | Luồng | Dữ liệu / tiền điều kiện | Bước chính | Expected | Trạng thái tự động hóa |
|---|---|---|---|---|---|
| TC01 | Google Sign-In | GV staff active có invite | Mở app; chọn Google; chọn tài khoản GV | Vào Dashboard đúng GV; Firebase giữ phiên | Đã có Appium; cần chạy lại ARTEMIS trên Firebase mới |
| TC02 | Role không hợp lệ | Tài khoản `user` và tài khoản inactive | Đăng nhập từng tài khoản | Từ chối Dashboard; không giữ phiên staff | Đã có Appium; cần seed hai tài khoản trên Firebase mới |
| TC03 | Tạo và đóng phiên | GV001, lớp được phân công, slot hợp lệ | Chọn lớp; mở phiên; đóng phiên | Session open rồi closed; Absent records đúng; UI đồng bộ | Đang có defect; rerun sau bản sửa |
| TC04 | QR thay đổi theo chu kỳ | Phiên open, thiết bị/tài khoản SV | Mở QR; lưu QR cũ; chờ chu kỳ; dùng QR cũ và mới | QR cũ bị chặn; QR mới điểm danh được | Partial; cần thiết bị SV |
| TC05 | Lịch sử điểm danh | Lớp có Present/Absent | Đóng phiên; mở lịch sử | Đúng lớp, SV và trạng thái; không lộ lớp GV khác | Basic pass; còn kiểm isolation |
| TC06 | Lọc lịch sử theo môn | Hai lớp khác môn có dữ liệu | Mở lịch sử; chọn từng môn | Chỉ hiện dữ liệu thuộc môn đã chọn | Đã có Appium; cần rerun ARTEMIS |
| TC07 | Xuất báo cáo | Lớp có dữ liệu | Chọn xuất; mở/chia sẻ file thực tế | XLSX có dữ liệu đúng và người dùng truy cập được | Đang có defect private cache |
| TC08 | Yêu cầu sửa điểm danh | SV absent, admin test | Mobile gửi đơn; admin xử lý; mobile xem kết quả | `pending` được lưu; approve/reject cập nhật realtime | Blocked nếu mobile/admin chưa nối Firebase |
| TC09 | Empty/error/offline | Lớp rỗng; thiết bị có thể tắt mạng | Mở danh sách rỗng; tắt mạng; retry | Phân biệt empty và lỗi mạng; không crash; phục hồi được | Đang có defect offline feedback |
| TC10 | Popup native | App mới cài, chưa cấp thông báo | Hủy account chooser; deny/allow notification | Không crash; quay lại login; quyền phản ánh đúng | Đã có Appium; phù hợp demo ARTEMIS |
| TC11 | Chặn mở hai phiên cùng lớp | Một session của lớp đang `open` | Từ màn quản lý lớp thử mở thêm phiên | App chặn tạo trùng; không có session open thứ hai | Có thể tự động hóa sau khi seed session |
| TC12 | Đóng phiên tạo Absent | Lớp có 3 SV, 1 Present, 2 chưa check-in | Đóng phiên; mở lịch sử/roster | Giữ Present; tạo đúng 2 Absent; session closed | Phụ thuộc fix TC03 và dữ liệu enrollment chuẩn |
| TC13 | Đồng bộ session realtime | Session đang open trên app; backend/admin đóng đúng quyền | Giữ màn Live QR; cập nhật session từ luồng hợp lệ khác | UI tự chuyển trạng thái, không cần force-stop | Cần cơ chế cập nhật backend thứ hai |
| TC14 | Giảng viên sửa điểm danh thủ công | Session thuộc GV, có SV Absent | Đổi Absent sang Present và nhập ghi chú | Record cập nhật đúng; lịch sử phản ánh thay đổi | Cần xác nhận UI hiện có |
| TC15 | Cách ly dữ liệu giữa giảng viên | Hai GV có lớp riêng | GV A mở lớp/lịch sử; tìm dữ liệu GV B | Không đọc hoặc sửa được lớp, session, record của GV B | Cần hai staff account và seed đối chứng |
| TC16 | Từ chối QR hết hạn | Có QR cũ của session vẫn open | Chờ QR secret/chu kỳ đổi; SV dùng QR cũ | Không tạo attendance record; thông báo QR hết hạn | Cần thiết bị hoặc web check-in SV |
| TC17 | Từ chối QR bị chỉnh sửa | Session open; có URL QR hợp lệ | Sửa `sessionId`, secret hoặc tham số IP rồi mở URL | Rules từ chối; không tạo record giả | Cần web check-in và dữ liệu test riêng |
| TC18 | Check-in idempotent | SV đã Present trong session | Quét lại cùng QR nhiều lần | Không tạo record trùng; trạng thái vẫn Present | Cần tài khoản SV và QR hợp lệ |
| TC19 | Mất mạng khi mở/đóng phiên | GV đăng nhập; có lớp hợp lệ | Tắt mạng trước khi submit; bật lại và retry | Không báo thành công giả; không tạo dữ liệu trùng; retry an toàn | Phù hợp ARTEMIS + điều khiển network/ADB |
| TC20 | Lọc lịch sử theo trạng thái | Lịch sử có Present và Absent | Chọn Tất cả, Có mặt, Vắng | Số lượng và danh sách đúng từng bộ lọc | Có thể chạy ngay khi có seed |
| TC21 | Export khi không có dữ liệu | Lớp/session không có record | Chọn xuất báo cáo | Hiển thị empty/validation phù hợp; không tạo file sai | Có thể tự động hóa sau khi xác nhận UI |
| TC22 | Chia sẻ/mở file export | Export đã tạo thành công | Mở share sheet; chọn app/file manager thử nghiệm | URI ngoài app-private; app nhận file; không lộ file lớp khác | Phụ thuộc fix TC07 |
| TC23 | Đăng ký FCM token | Android 13+, app cài mới, staff active | Allow notification; bật reminder; mở lại app | Quyền granted; device token lưu đúng UID; switch giữ trạng thái | Phụ thuộc Rules `device_tokens`/preferences |
| TC24 | Lưu preferences | Staff đăng nhập | Đổi theme/ngôn ngữ/reminder; force-stop; mở lại | Giá trị được khôi phục đúng; không ghi vào UID khác | Cần dữ liệu preferences sạch |
| TC25 | Cập nhật hồ sơ và validation | Staff active | Sửa tên/điện thoại/ngày sinh; thử dữ liệu sai | Dữ liệu hợp lệ được lưu; dữ liệu sai bị chặn; session không mất | Có thể chạy khi profile UI ổn định |
| TC26 | Đăng xuất và khôi phục phiên | Staff đã đăng nhập | Force-stop/mở lại; sau đó logout; mở lại lần nữa | Trước logout tự khôi phục; sau logout quay về login; Google session được dọn | Phù hợp ARTEMIS; chú ý không lộ email |
| TC27 | OCR ảnh thời khóa biểu hợp lệ | Staff, ảnh lịch rõ và dưới giới hạn | Chọn ảnh; chạy OCR; xem kết quả; xác nhận import | OCR trả dữ liệu có cấu trúc; chỉ import lớp được chọn | Phụ thuộc Cloud Vision/Functions và dữ liệu lớp |
| TC28 | OCR file không hợp lệ/quá lớn | File không phải ảnh và ảnh vượt 10 MB | Lần lượt upload từng file | Từ chối an toàn; không crash; không gọi OCR cho file sai | Có regression backend; bổ sung Android E2E |
| TC29 | Remote Config fallback | Có thể đổi cấu hình test và mô phỏng fetch lỗi | Chạy với giá trị remote; sau đó offline/fetch lỗi | Dùng remote khi hợp lệ; dùng default an toàn khi lỗi | Có unit test; E2E cần môi trường Remote Config test |
| TC30 | Điều hướng và lifecycle | Staff ở Dashboard, Live QR và chi tiết lớp | Back, rotate, background/resume, quay về app | Màn con về route cha; route gốc mới thoát; state hợp lệ | Exploratory từng phát hiện lỗi Back; phù hợp ARTEMIS Pro |

## Nhóm ưu tiên khi chuyển sang ARTEMIS

1. Smoke và native UI: TC10, TC26, TC30.
2. Luồng đọc ít rủi ro: TC01, TC05, TC06, TC20, TC24, TC25.
3. Luồng ghi cần dữ liệu seed: TC03, TC11–TC14, TC19, TC23.
4. Luồng cần tài khoản/thiết bị thứ hai: TC04, TC15–TC18.
5. Luồng đang bị chặn hoặc phụ thuộc tính năng: TC07, TC08, TC22, TC27–TC29.

Kết quả Appium cũ không được đổi tên thành ARTEMIS. Một case chỉ được ghi nhận là ARTEMIS Pass khi có execution/trace thực tế, assertion cuối và evidence đã loại thông tin cá nhân.
