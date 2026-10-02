# Lịch sử điểm danh — API và triển khai

Trang `Lịch sử điểm danh` đọc dữ liệu thật qua các action dưới đây (Google Sheet hoặc Firestore, tùy cờ `DB_BACKEND` — xem [03](03-du-lieu-firestore.md)); không có dữ liệu dự phòng giả. Các ghi chú về "tab"/"cột" bên dưới mô tả chế độ Google Sheet; ở chế độ Firestore các trường `note`, `updatedAt`, `updatedBy`, `syncedToFap` là trường chính thức của `attendanceRecords` và không cần bổ sung cột.
Request gửi POST JSON với `Content-Type: text/plain;charset=utf-8` tới URL `/exec` đang cấu hình trong `ApiService`.
Response giữ envelope `{success, data, error}`.

## Triển khai

### Nguồn dữ liệu sinh viên

- `SheetDB.gs` mở đúng `SPREADSHEET_ID` đã cấu hình bằng `openById`, không tự chuyển sang Sheet đang gắn với Apps Script. Tài khoản triển khai phải có quyền truy cập file đó.
- Danh sách điểm danh trực tiếp dùng `Users.fullName` ghép theo `Enrollment.rollNumber`, không dùng phần tên email làm họ tên.
- Bảng cảnh báo ở trang Báo cáo dùng `getHistoryClasses` và `getHistoryDetail`; không còn tên/MSSV mẫu. Tỷ lệ vắng tính trên phiên đã đóng; lỗi API được hiển thị, không thay bằng dữ liệu giả. Các KPI và biểu đồ báo cáo khác vẫn là minh họa và được ghi rõ trên trang.
- Bảng chính của trang Lịch sử điểm danh dùng `getHistorySummary` để hiển thị **tổng hợp cả lớp từ buổi đầu đến nay** (1 dòng/sinh viên: số buổi có mặt/đi trễ/vắng trên các phiên đã đóng), không còn phụ thuộc 1 buổi cụ thể. `getHistoryDetail` (theo 1 buổi, có `revision` để sửa) chỉ còn dùng nội bộ khi sửa 1 ô trong dialog Ma trận.
- Sau khi thay đổi `SheetDB.gs`, cần triển khai phiên bản Apps Script mới theo các bước dưới đây; sửa file trong repo chưa cập nhật Web App đang chạy.

1. Cập nhật `AuthService.gs`, `SheetDB.gs`, `Router.gs` trong dự án Apps Script hiện tại.
2. Thêm **hai file mới**: `AttendanceHistoryService.gs` và `HistoryExcel.gs`.
3. Deploy phiên bản Web App mới vào deployment đang dùng (giữ nguyên URL `/exec`).
4. Hot restart Flutter, đăng xuất rồi đăng nhập lại. Token đăng nhập cũ chưa được lưu trong cache server nên không dùng được cho các API lịch sử mới.

Không cần tạo tab mới. Khi lưu chỉnh sửa lần đầu, backend tự bổ sung các cột còn thiếu `note`, `updatedAt`, `updatedBy`, `syncedToFap` ở cuối `Attendance_Record`; không sửa các header/dữ liệu cũ.
Cache đăng nhập có thời hạn tối đa 6 giờ, có thể bị Google thu hồi sớm. Khi gặp `UNAUTHORIZED`, đăng nhập lại.

## Action

Mọi action dưới đây yêu cầu `sessionToken` nhận từ `login`. Giảng viên được xác định từ token, không tin `teacherMemberCode` do client gửi.

| Action | Tham số ngoài action/token | Data trả về |
|---|---|---|
| `getHistoryClasses` | Không | Danh sách lớp của giảng viên, sĩ số từ Enrollment, số phiên, tỷ lệ có mặt/đi trễ, số SV vắng >20%, phiên gần nhất |
| `getHistorySummary` | `classCode` | `classInfo`, `teacherName`, `sessions`, `slots`, `students[]` — mỗi sinh viên có `presentCount/lateCount/absentCount/closedSessions/totalSessions` tính trên toàn bộ phiên đã đóng của lớp (dùng cho bảng chính) |
| `getHistoryDetail` | `classCode`, `sessionId` tùy chọn | `classInfo`, `teacherName`, `sessions`, `selectedSession`, `slots`, `students` (trạng thái theo 1 buổi, có `revision` để sửa) — chỉ dùng nội bộ khi sửa 1 ô trong Ma trận |
| `saveAttendanceChanges` | `classCode`, `sessionId`, `changes[]` | Chi tiết mới sau khi ghi (theo 1 buổi) |
| `getAttendanceMatrix` | `classCode` | Danh sách `sessions` và `students`; mỗi sinh viên có `cells[]` (`sessionId, status, note, checkinTime, revision`) cùng thứ tự với sessions — `revision` dùng để sửa trực tiếp trong dialog Ma trận |
| `exportAttendanceHistory` | `classCode`, `sessionId` tùy chọn | Có `sessionId`: XLSX danh sách 1 buổi (như cũ). Không có `sessionId`: XLSX tổng hợp cả lớp, 1 dòng/sinh viên với số buổi có mặt/trễ/vắng và tỷ lệ — dùng cho nút xuất trên bảng chính |
| `startHistorySession` | `classCode`, `slotCode`, `ipCheck` (mặc định `false`), `teacherIp` (bắt buộc khi `ipCheck = true`) | `session`, `qrToken`; kiểm tra ca học, quyền phụ trách và phiên đang mở |
| `getReport` | Không | Tổng hợp KPI, xu hướng theo tuần, tỷ lệ theo lớp, phương thức điểm danh và danh sách cảnh báo của toàn bộ lớp giảng viên phụ trách |

Các API cũ vẫn tồn tại để các trang khác tiếp tục hoạt động. Trang lịch sử không gọi `getAttendanceHistory` cũ.

### Lưu thay đổi

```json
{
  "action": "saveAttendanceChanges",
  "sessionToken": "TOKEN_FROM_LOGIN",
  "classCode": "CLASS_FROM_API",
  "sessionId": "SESSION_FROM_API",
  "changes": [{
    "rollNumber": "STUDENT_FROM_API",
    "status": "ManualByGV",
    "note": "Giảng viên xác nhận tại lớp",
    "revision": "EXACT_REVISION_FROM_STUDENT_RESPONSE"
  }]
}
```

- Trạng thái: `Present`, `Late`, `Absent`, `ManualByGV`, `Unchecked`.
- `revision` phải giữ nguyên từ response, kể cả chuỗi rỗng. Nếu bản ghi đã đổi, server trả `CONFLICT` và không bắt đầu ghi batch đó.
- Giới hạn 500 thay đổi/lần, ghi chú tối đa 2000 ký tự; toàn bộ sinh viên/trạng thái/revision được kiểm tra trước khi ghi.
- Dùng script lock để tuần tự hóa các batch từ API lịch sử. Các API cũ chưa cùng sử dụng lock này; đây không phải transaction cơ sở dữ liệu. Nếu Sheets lỗi giữa các thao tác ghi, tải lại trước khi sửa tiếp để kiểm tra phần đã được lưu.
- Lưu sẽ đặt `syncedToFap=false`; không tự đồng bộ lên FAP và không tạo thời gian quét QR giả cho thay đổi thủ công.

## Quy tắc dữ liệu giao diện

- Danh sách sinh viên lấy từ Enrollment, ghép tên/email bằng rollNumber trong Users; trùng Enrollment cùng lớp/MSSV được gộp.
- Chưa có phiên: vẫn hiện sinh viên đã ghi danh, trạng thái `Unchecked`, không cho sửa điểm danh.
- Phiên mở thiếu bản ghi: `Unchecked`. Phiên đã đóng thiếu bản ghi: `Absent`.
- Tỷ lệ lũy kế chỉ tính trên phiên `closed` và danh sách ghi danh hiện tại. `Present`, `Late`, `ManualByGV` được tính có tham dự. Tỷ lệ vắng >20% chỉ là cảnh báo, không phải quyết định cấm thi.
- Trang Báo cáo dùng `getReport`; toàn bộ KPI, biểu đồ và cảnh báo đều tính từ `Attendance_Session` có `sessionStatus=closed`, `Enrollment`, `Users` và `Attendance_Record`. Nếu chưa có phiên đã đóng, API trả các giá trị 0 và danh sách rỗng, không tạo dữ liệu minh họa.
- `getReport` chỉ trả phương thức QR khi bản ghi có `networkVerificationResult` là `Match` hoặc `Skipped` (phiên không kiểm tra IP), xác nhận thủ công khi có trạng thái/bằng chứng `Manual`; các bản ghi còn lại được phân loại `Khác / chưa xác định` để không suy đoán nguồn dữ liệu.
- Không giả định 30 buổi/kỳ; tổng buổi là số phiên thực có trong Sheet. Không hiển thị học kỳ, số phút đi trễ hay thông tin BSSID giả khi backend chưa có dữ liệu.
- Khi có thay đổi chưa lưu, khóa đổi lớp/buổi/xuất Excel cho đến khi lưu hoặc hủy. Lỗi lưu giữ lại nội dung đang sửa.
- Tệp Excel xuất toàn bộ danh sách của buổi đang chọn, không chỉ các hàng đang lọc. Dùng XLSX chuẩn với chuỗi inline (không thực thi công thức từ tên/ghi chú). Đây không phải mẫu import FAP được chứng nhận.
- Web tải file qua trình duyệt; bản desktop lưu file vào thư mục tạm và hiển thị đường dẫn.

## Kiểm tra

```text
node --test apps-script/tests/api.test.cjs apps-script/tests/history.test.cjs
flutter test test/attendance_history_test.dart test/api_models_test.dart
flutter build web --debug
```

Các bài kiểm thử dùng fixture cục bộ, không ghi vào dữ liệu điểm danh thật.
