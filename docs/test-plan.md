# Kế hoạch kiểm thử — FAP Check-in

## 1. Mục đích và phạm vi

Tài liệu này xác định 10 kịch bản kiểm thử ưu tiên cho bản MVP. Phạm vi gồm ứng dụng giảng viên Flutter, trang check-in sinh viên, Firebase Authentication, Firestore Security Rules, Cloud Storage, Remote Config và Cloud Function OCR.

Môi trường kiểm thử chính là **Firebase Emulator Suite**; các chức năng Google Sign-In thật, Remote Config production và Cloud Vision cần được xác nhận thêm trên dự án Firebase đã cấu hình.

## 2. Điều kiện chung

- Khởi động Emulator: `firebase emulators:start --project demo-fapcheckin` tại thư mục gốc.
- Nạp dữ liệu mẫu theo [quick-start.md](quick-start.md).
- Có tối thiểu một tài khoản `staff`, một tài khoản `user` đã ghi danh, một `admin` và một sinh viên không thuộc lớp.
- Với ca OCR, cần ảnh PNG/JPEG thời khóa biểu có cặp mã lớp–môn hợp lệ.

## 3. Kịch bản kiểm thử

| ID | Kịch bản | Bước thực hiện | Kết quả mong đợi | Mức độ | Bằng chứng tự động hiện có |
|---|---|---|---|---|---|
| TC-01 | Đăng nhập Google của giảng viên | Đăng nhập bằng Google với tài khoản có hồ sơ `staff` đang hoạt động. | Firebase Auth tạo/khôi phục phiên; app vào màn hình giảng viên và nạp lớp được phân công. | Critical | `AuthRepository` và test repository Flutter. |
| TC-02 | Tạo phiên điểm danh và QR | Giảng viên chọn lớp, mở phiên, chọn bật hoặc tắt kiểm tra IP. | Tạo `sessions` trạng thái `open`; QR chứa `s`, `t`, `ic`; mã QR tự làm mới theo `qr_refresh_seconds`. | Critical | `teacher_repository_test.dart`, `qr_refresh_interval_test.dart`. |
| TC-03 | Sinh viên check-in hợp lệ | Sinh viên đã ghi danh quét QR mới, đăng nhập Google, gửi bản ghi check-in. | Tạo đúng một `attendance_records/{sessionId}_{rollNumber}` có `Present` và thời gian máy chủ. | Critical | `e2e_test/e2e.test.mjs`, Firestore Rules tests. |
| TC-04 | Chống điểm danh trùng | Dùng cùng sinh viên gửi check-in lần thứ hai cho cùng phiên. | Rules từ chối lần ghi thứ hai; trang hiển thị trạng thái đã điểm danh. | High | `firestore.rules.test.mjs`. |
| TC-05 | Từ chối sinh viên không ghi danh | Đăng nhập bằng tài khoản `user` không có enrollment cho lớp rồi quét QR. | Không tạo attendance record; UI báo không thuộc lớp. | High | `firestore.rules.test.mjs`, `web/checkin/app.js`. |
| TC-06 | Kiểm tra IP tùy chọn | Mở phiên bật kiểm tra IP; thử check-in với IP không khớp và IP khớp. | IP không khớp bị từ chối; IP khớp được ghi `Match`. Khi tắt kiểm tra IP, bản ghi có `Skipped`. | High | `firestore.rules.test.mjs`, [02-luong-diem-danh-qr.md](02-luong-diem-danh-qr.md). |
| TC-07 | Kết thúc phiên và chốt vắng mặt | Có SV đã/không check-in, giảng viên kết thúc phiên. | Session chuyển `closed`; SV chưa check-in nhận trạng thái vắng mặt tự động; không thể check-in sau đó. | Critical | `teacher_repository_test.dart`, `e2e_test/e2e.test.mjs`. |
| TC-08 | Phân quyền và bảo vệ dữ liệu | Thử đọc/ghi collection không thuộc vai trò hiện tại: user, staff, admin và anonymous. | Security Rules áp dụng deny-by-default; chỉ thao tác được cấp quyền mới thành công. | Critical | `firebase/tests/firestore.rules.test.mjs`, `storage.rules.test.mjs`. |
| TC-09 | Remote Config và fallback | Cấu hình `qr_refresh_seconds`, `ip_check_default`, `maintenance_mode`; sau đó mô phỏng Remote Config lỗi/mất mạng. | App dùng giá trị remote sau khi fetch thành công; khi lỗi vẫn khởi động bằng default an toàn. | Medium | `remote_settings.dart`; cần kiểm thử tích hợp thủ công trên Firebase project. |
| TC-10 | Import thời khóa biểu bằng OCR | Giảng viên upload ảnh hợp lệ; gọi `scanTimetable`; chọn lớp `available` để nhận lớp. Thử ảnh không hợp lệ/không có chữ. | Function chỉ xử lý ảnh của đúng giảng viên, trả dữ liệu lớp nhận diện; ảnh tạm bị xóa; lỗi OCR trả mã nghiệp vụ rõ ràng. | High | `firebase/functions/test/timetable.test.js`. |

## 4. Quy trình ghi nhận kết quả

Mỗi test case chạy tối thiểu 3 lần trên môi trường được chỉ định. Ghi nhận vào bảng dưới đây; nếu có lỗi, đính kèm ảnh/video, thời điểm chạy, thiết bị/trình duyệt, tài khoản vai trò và log không chứa PII.

| Ngày chạy | ID test | Môi trường / thiết bị | Lần 1 | Lần 2 | Lần 3 | Kết quả | Ghi chú / Issue |
|---|---|---|---|---|---|---|---|
|  |  |  |  |  |  |  |  |

## 5. Lệnh kiểm thử tự động

```bash
cd firebase && npm test
cd firebase/functions && npm test
cd e2e_test && npm test
cd packages/core && flutter test
cd mobile && flutter test
```

Các test Rules và E2E phải chạy với Firebase Emulator. Chi tiết kiến trúc test nằm trong [README gốc](../README.md) và [08-security-rules.md](08-security-rules.md).

## 6. Tiêu chí chấp nhận

- 10/10 kịch bản được thực thi; các case Critical không có lỗi mở.
- Mọi vi phạm quyền truy cập phải bị chặn bởi Firestore/Storage Rules, không chỉ bởi UI.
- Lỗi phải có mã/ thông báo người dùng hiểu được và không ghi PII vào ảnh, log hoặc tài liệu nộp bài.
- Khi dịch vụ Remote Config/OCR không khả dụng, luồng điểm danh QR chính vẫn không bị chặn.
