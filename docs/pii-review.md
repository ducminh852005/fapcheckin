# Rà soát PII — FAP Check-in

## Phạm vi rà soát

PII (Personally Identifiable Information) trong dự án gồm: họ tên, email trường, mã thành viên/mã sinh viên, ảnh thời khóa biểu có thể chứa dữ liệu nhận diện và địa chỉ IP công khai khi giảng viên bật kiểm tra mạng.

Tài liệu này là rà soát source và cấu hình repository; không thay thế đánh giá bảo mật hoặc pháp lý độc lập trước khi triển khai production.

## Bảng kiểm soát

| Dữ liệu | Nơi xử lý/lưu trữ | Kiểm soát hiện có | Trạng thái |
|---|---|---|---|
| Họ tên, email, mã thành viên, mã SV | `users`, `user_invites`, `enrollments`, attendance records trên Firestore | Firestore Rules kiểm tra đăng nhập/role; sinh viên chỉ đọc dữ liệu của chính mình; staff bị giới hạn vào lớp phụ trách. | Có |
| Bản ghi điểm danh | `attendance_records` | Record ID cố định theo phiên và MSSV; sinh viên chỉ tạo bản ghi của chính mình, không tự sửa/xóa sau khi gửi. | Có |
| QR secret | `sessions.qrSecret` | Sinh viên không được đọc session; secret chỉ có trong QR được giảng viên hiển thị và Rules đối chiếu lúc ghi nhận. | Có |
| Địa chỉ IP công khai | `sessions.teacherIp`, `attendance_records.ipAddress` | Chỉ thu khi phiên bật IP check; Rules xác thực giá trị trong luồng check-in. Đây là dữ liệu cá nhân/nhạy cảm cần tránh đưa vào ảnh chụp hoặc log. | Có kiểm soát, cần vận hành cẩn trọng |
| Ảnh thời khóa biểu | Cloud Storage `timetable_scans/{uid}/...` | Chỉ staff upload ảnh của mình; Function giới hạn dung lượng/loại ảnh và xóa ảnh tạm sau OCR. | Có |
| Kết quả OCR | Bộ nhớ Cloud Function và phản hồi callable | Không lưu văn bản OCR sau xử lý; chỉ trả dữ liệu lớp được trích xuất để giảng viên xác nhận. | Có |
| Log / Crashlytics / Analytics | Firebase telemetry trên Android/iOS | Có Crashlytics và Analytics; source không chủ động gửi PII vào event. Cần duy trì nguyên tắc không thêm email, MSSV, QR secret, IP vào event/log. | Cần kiểm tra khi mở rộng |
| Tài liệu, file nộp và dữ liệu test | Git repository / report | Tài liệu kiến trúc yêu cầu không commit XLSX/CSV chứa PII. Dữ liệu emulator dùng tài khoản mẫu. | Có quy định |

## Checklist trước khi demo hoặc nộp bài

- [ ] Không hiển thị email, MSSV, IP hoặc QR secret thật trong slide/video/public repository.
- [ ] Dùng tài khoản test và dữ liệu giả khi quay demo.
- [ ] Không commit service-account JSON, OAuth desktop secret hoặc file export `.xlsx`/`.csv` có dữ liệu thật.
- [ ] Không ghi PII vào `debugPrint`, Firebase Analytics event, Crashlytics custom key hoặc thông báo lỗi.
- [ ] Kiểm tra Rules bằng Emulator sau mỗi thay đổi collection hoặc quyền truy cập.
- [ ] Sau demo OCR, xác nhận ảnh tạm trong Storage đã bị xóa.
- [ ] Nếu cần export lịch sử điểm danh, chỉ chia sẻ qua kênh được cấp quyền và xóa file sau khi dùng.

## Các điểm cần theo dõi

1. Kiểm tra IP dùng IP công khai do client gửi nên phù hợp mục đích kiểm tra cùng mạng ở mức đồ án, không phải xác thực vị trí tuyệt đối.
2. Firebase client config không phải bí mật; trái lại service account và OAuth client secret phải được giữ ngoài repository.
3. Web Admin chưa kết nối Firebase thật. Khi triển khai, phải bổ sung Rules test cho tất cả màn có dữ liệu PII, đặc biệt là quản lý người dùng và yêu cầu chỉnh sửa điểm danh.

## Tài liệu liên quan

- [Rủi ro, giới hạn & hướng mở rộng](06-rui-ro-va-mo-rong.md)
- [Xác thực & phân quyền](05-xac-thuc-va-phan-quyen.md)
- [Security Rules & kiểm thử](08-security-rules.md)
- [Import thời khóa biểu bằng OCR](07-timetable-ocr.md)
