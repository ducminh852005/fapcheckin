# API tạo lịch học

Popup tạo lịch lấy dữ liệu thật, không thêm lớp hoặc Enrollment. Lịch mới được lưu riêng, không tự mở phiên điểm danh.

## Triển khai

1. Mở dự án Apps Script gắn với URL `/exec` trong `lib/core/network/api_service.dart`. Đồng bộ **toàn bộ các file `.gs` trong thư mục `apps-script/`** vào dự án. Không đưa thư mục `tests` vào Apps Script.
2. Đặc biệt phải có `ScheduleService.gs`, `AttendanceHistoryService.gs`, `HistoryExcel.gs`, và bản mới của `AuthService.gs`, `Router.gs`, `SheetDB.gs`. Chỉ chép Router/ScheduleService vào backend cũ sẽ thiếu các hàm phụ thuộc như `AuthService.requireTeacher`.
3. Deploy → Manage deployments → Edit → New version → Deploy. Giữ deployment hiện tại để URL `/exec` không thay đổi.
4. Chạy lại Flutter, đăng nhập tài khoản giảng viên và mở **Lớp học → Tạo lịch học mới**.

Backend tự tạo tab `Class_Schedule` khi lưu lịch đầu tiên. Không chạy lại seed, không thay đổi lớp/enrollment có sẵn. Source chưa được triển khai lên Apps Script bởi công cụ trong phiên làm việc này.

### Lỗi đã xác nhận trên deployment hiện tại

Kiểm tra trực tiếp ngày 21/09/2026: URL mặc định của Flutter trả `UNKNOWN_ACTION` cho cả `getScheduleOptions`, `getClassSchedules` và `getHistoryClasses`. Giao diện đã gọi API nhưng deployment vẫn là bản cũ. Lưu source trên máy hoặc bấm Save trong Apps Script chưa cập nhật bản `/exec` đang chạy; phải deploy **New version**.

Sau deploy, mở URL `/exec?action=getScheduleOptions` không kèm token. Kết quả đúng là `UNAUTHORIZED` (API đã tồn tại, yêu cầu đăng nhập). Nếu vẫn `UNKNOWN_ACTION`, bạn đang cập nhật sai deployment hoặc chưa chọn New version. Kiểm tra tương tự với `getClassSchedules` và `getHistoryClasses`.

Nếu tạo deployment mới có URL khác, chạy Flutter với URL mới:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=https://script.google.com/macros/s/DEPLOYMENT_ID/exec
```

Dừng rồi chạy lại Flutter hoàn toàn (không chỉ hot reload), vì provider API và cấu hình khởi tạo đã thay đổi. Đăng xuất/đăng nhập lại để có token do backend mới cấp.

## Request và response

POST JSON dưới dạng `text/plain;charset=utf-8`, sử dụng cùng URL và envelope `{success,data,error}` của ứng dụng. Mọi action yêu cầu `sessionToken` từ API login. Backend tự xác định giảng viên, không tin `teacherMemberCode` từ client.

- `getScheduleOptions`: trả `teacherName`, `today` theo giờ Việt Nam, `classes` thuộc giảng viên, `slots`, `rooms`, `capabilities`, `schedules`.
- `getClassSchedules`: trả danh sách lịch đã lưu của giảng viên, sắp xếp ngày/giờ.
- `createClassSchedule`: nhận ví dụ:

```json
{
  "action": "createClassSchedule",
  "sessionToken": "TOKEN_LOGIN",
  "requestId": "unique_request_123",
  "classCode": "MA_LOP_THUC",
  "scheduleDate": "2026-12-01",
  "slotCode": "A1",
  "room": "303",
  "lessonType": "makeup",
  "teachingMethod": "onCampus",
  "note": "Nội dung buổi học"
}
```

`lessonType`: `makeup`, `workshop`, `review`. Phòng phải tồn tại trong Class_Section. Sĩ số đếm rollNumber không trùng trong Enrollment. Slot lấy từ tab Slot, dùng giờ 24h; giờ kết thúc phải sau giờ bắt đầu. Ca có dữ liệu sai bị vô hiệu hóa, không tự suy đoán AM/PM. Ngày/giờ học theo Asia/Ho_Chi_Minh; ô giờ kiểu Date cũng chuẩn hóa theo múi giờ này, nên cấu hình múi giờ bảng tính cùng Việt Nam và kiểm tra Slot nếu bảng đang dùng múi giờ khác.

Response tạo lịch là bản ghi gồm `scheduleId`, dữ liệu request, `teacherMemberCode`, `startTime`, `endTime`, `status: scheduled`, `createdAt`. Không trả QR secret hoặc thông tin lịch của giáo viên khác.

Backend khóa ghi, kiểm tra quyền sở hữu, ngày/ca chưa bắt đầu, ghi chú tối đa 2000 ký tự và trùng khoảng giờ (kể cả khác mã ca) của giảng viên/lớp/phòng trong Class_Schedule và Attendance_Session. Chỉ kiểm tra lịch đã có trong ứng dụng; không biết lịch trên FAP bên ngoài. Cùng requestId + nội dung trả bản ghi cũ; đổi nội dung với requestId cũ báo CONFLICT. Sau lỗi mạng, popup khóa nội dung và cho gửi lại cùng request để tránh ghi trùng.

Các mã lỗi chính: UNAUTHORIZED, FORBIDDEN, VALIDATION_ERROR, SCHEDULE_CONFLICT, CONFLICT, NOT_SUPPORTED.

## Giới hạn được hiển thị trên giao diện

QR tự động/luân phiên 20 giây, email/thông báo và đồng bộ FAP chưa có triển khai thực tế trong backend. Các công tắc tắt và vô hiệu hóa kèm lý do; API từ chối yêu cầu bật chúng. Tạo lịch không gửi email, không đánh dấu đã đồng bộ và không tự mở phiên. Giáo viên mở phiên điểm danh thủ công qua chức năng hiện có khi bắt đầu buổi học.

Danh sách **Lịch học đã tạo** ở trang lớp học tải từ API và cập nhật sau khi lưu. Các thẻ dashboard/lớp cũ dùng getClasses không được chuyển thành lịch FAP bởi thay đổi này.

## Kiểm thử

`node --test apps-script/tests/api.test.cjs apps-script/tests/history.test.cjs apps-script/tests/schedule.test.cjs`

`flutter test --no-pub test/create_class_dialog_test.dart`

Kiểm thử dùng dữ liệu giả lập riêng trong test; không ghi lịch hay gửi thông báo cho sinh viên thật.
