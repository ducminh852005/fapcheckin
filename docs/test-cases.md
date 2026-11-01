# Test cases Android — kế hoạch, chưa chạy

Mỗi case cần reset dữ liệu và trạng thái app trước mỗi lượt, thực hiện 3 lượt độc lập. Dùng project test riêng, tránh dữ liệu thật.

| ID | Luồng | Dữ liệu / tiền điều kiện | Bước | Expected |
|---|---|---|---|---|
| TC01 | Google Sign-In | GV staff active có invite | Mở app; chọn Google; chọn tài khoản GV | Vào dashboard, đúng GV; Firebase có phiên |
| TC02 | Role không hợp lệ | SV user và tài khoản inactive | Đăng nhập từng tài khoản | Từ chối dashboard; không giữ phiên staff |
| TC03 | Tạo phiên | GV001, lớp được phân công, slot hợp lệ | Chọn lớp; mở phiên | sessions có trạng thái open và đúng teacherMemberCode |
| TC04 | QR | Phiên open, thiết bị SV | Mở QR; chờ xoay; thử QR cũ và mới | QR hiển thị; QR cũ bị chặn, QR mới điểm danh được |
| TC05 | Lịch sử | Lớp có Present/Absent | Đóng phiên; mở lịch sử | Đúng lớp, SV và trạng thái; không lộ lớp GV khác |
| TC06 | Lọc môn | Hai lớp khác môn có dữ liệu | Mở lịch sử; chọn từng môn | Chỉ hiện dữ liệu thuộc môn đã chọn |
| TC07 | Xuất báo cáo | Lớp có dữ liệu | Chọn xuất; mở file thực tế | File có dữ liệu đúng và mở được; xác nhận PDF hay XLSX theo tính năng triển khai |
| TC08 | Yêu cầu sửa điểm danh | SV absent, admin test | Gửi đơn; xem pending; admin xử lý | pending được lưu; mobile nhận trạng thái mới. Blocked nếu UI chưa triển khai |
| TC09 | Empty/error | Lớp rỗng; chế độ offline | Mở lịch sử trống; tắt mạng; tải lại | Có thông báo phù hợp; không crash; retry khôi phục được |
| TC10 | Popup native | Android mới cài, chưa cấp thông báo | Mở app; từ chối/cho phép notification; hủy chọn tài khoản | Không crash, hủy đăng nhập trả về login, quyền phản ánh lựa chọn |
