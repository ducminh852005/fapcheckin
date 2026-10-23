[← Mục lục](README.md)

# 13 · Repository (thay cho "API" của Apps Script)

Không còn endpoint HTTP hay envelope `{success, data, error}`. App gọi các Repository trong [`packages/core/lib/repositories`](../packages/core/lib/repositories); mỗi phương thức đọc/ghi Firestore trực tiếp và trả `ApiResult<T>`:

```dart
sealed-like:  ApiSuccess<T>(data)  |  ApiFailure<T>(ApiError(code, message))
```

Repository **không bao giờ ném** lỗi ra ngoài: `guardApi` đổi mọi ngoại lệ thành `ApiFailure`. Lỗi nghiệp vụ dùng `ApiException(code, message)`; lỗi Firebase được ánh xạ (`permission-denied` → `FORBIDDEN`, `unavailable` → `NETWORK_ERROR`, …).

Mọi Repository nhận `CurrentUser` (hồ sơ đang đăng nhập, do `AuthRepository` ghi) để biết `memberCode` của giảng viên, và nhận `FirebaseFirestore` tùy chọn (để test bằng `fake_cloud_firestore`).

## Mã lỗi

| Mã | Khi nào |
|---|---|
| `UNAUTHORIZED` | Chưa đăng nhập / phiên hết hạn |
| `FORBIDDEN` | Lớp/phiên không thuộc giảng viên, hoặc Rules từ chối |
| `VALIDATION_ERROR` | Thiếu hoặc sai dữ liệu đầu vào |
| `SESSION_NOT_FOUND`, `CLASS_NOT_FOUND` | Không tồn tại / phiên đã đóng |
| `SESSION_ALREADY_OPEN` | Mở phiên từ trang lịch sử khi lớp đang có phiên mở |
| `CONFLICT` | `revision` không còn khớp khi lưu chỉnh sửa; `requestId` dùng cho lịch khác |
| `SCHEDULE_CONFLICT` | Trùng khung giờ trong lịch của giảng viên |
| `NOT_SUPPORTED` | Tính năng chưa có (QR tự động, email, đồng bộ FAP) |
| `DOMAIN_NOT_ALLOWED`, `INVALID_TOKEN` | Đăng nhập: email không có invite / token không hợp lệ |
| `SCAN_EXPIRED`, `ASSIGNMENT_CONFLICT` | Import TKB |
| `NETWORK_ERROR`, `DB_ERROR`, `NOT_FOUND` | Lỗi hạ tầng Firebase |

## AuthRepository

| Phương thức | Việc làm |
|---|---|
| `loginWithGoogleIdToken(idToken)` | `signInWithCredential` → nạp/tạo `users/{uid}` từ `user_invites` → `AuthSessionModel(token = uid, user)` |
| `restoreSession()` | Nạp lại hồ sơ khi mở app nếu Firebase Auth còn phiên |
| `signOut()` | Xóa `CurrentUser` và đăng xuất Firebase |

## TeacherRepository

| Phương thức | Truy vấn / ghi |
|---|---|
| `getClasses(teacherMemberCode)` | `classes`, `sessions`, `class_schedules` của GV + `count()` bản ghi có mặt theo lớp; thêm thẻ riêng cho buổi học bù hôm nay |
| `startSession(classCode, slotCode, teacherIp, ipCheck)` | Batch: đóng phiên `open` cũ của lớp + tạo `sessions` mới (`qrSecret` ngẫu nhiên 128 bit) |
| `rotateQr(sessionId)` / `syncSessionTeacherIp` | Cập nhật `qrSecret` / `teacherIp` của phiên đang mở |
| `closeSession(sessionId)` | Batch: `sessionStatus = closed` + `Absent`/`AutoAbsent` cho SV chưa có bản ghi |
| `getSessions(classCode)` | Phiên thật + lịch kế hoạch chưa mở (trạng thái `planned`) |
| `getRoster(sessionId)` | `enrollments` ghép `attendance_records` của phiên |
| `getAttendanceHistory`, `getStats` | Tổng hợp theo lớp từ `attendance_records` |
| `manualCheckin`, `manualCheckinBulk` | Tạo/cập nhật bản ghi `Manual`, `syncedToFap = false` |
| `syncToFap(classCode?)` | Bản giữ chỗ: đánh dấu `syncedToFap = true` (chưa có API FAP) |

## AttendanceHistoryRepository

Dùng cho trang **Lịch sử điểm danh** (dữ liệu thật, không có dữ liệu giả):

| Phương thức | Ghi chú |
|---|---|
| `getClasses()` | Danh sách lớp: sĩ số, số phiên, tỷ lệ có mặt/đi trễ, số SV vắng > 20%, phiên gần nhất |
| `getSummary(classCode)` | Bảng chính: 1 dòng/SV, số buổi có mặt/trễ/vắng trên các **phiên đã đóng** |
| `getDetail(classCode, sessionId?)` | Trạng thái theo 1 buổi, có `revision` để chống ghi đè |
| `save(classCode, sessionId, changes)` | **Transaction**: đọc lại từng bản ghi, so `revision`, rồi ghi; lỗi `CONFLICT` nếu đã đổi. Tối đa 500 thay đổi, ghi chú ≤ 2000 ký tự, trạng thái ∈ {`Present`,`Late`,`Absent`,`ManualByGV`,`Unchecked`} |
| `getMatrix(classCode)` | Ma trận SV × buổi (mỗi ô có `revision`) |
| `export(classCode, sessionId?)` | Tạo `.xlsx` phía client (chuỗi inline — không thực thi công thức); có `sessionId` = 1 buổi, không có = tổng hợp cả lớp |
| `startSession(...)` | Như `TeacherRepository.startSession` nhưng kiểm tra slot hợp lệ và trả `SESSION_ALREADY_OPEN` thay vì tự đóng phiên cũ |

Quy tắc hiển thị: phiên mở thiếu bản ghi → `Unchecked`; phiên đã đóng thiếu bản ghi → `Absent`; `Present`, `Late`, `ManualByGV` đều tính là có tham dự; tỷ lệ chỉ tính trên phiên `closed`; tổng buổi là số phiên thực có.

## ReportRepository

`getReport()` — KPI, xu hướng theo tuần, tỷ lệ theo lớp, phương thức điểm danh (QR = `Match`/`Skipped`, thủ công = `ManualByGV`/`Manual`, còn lại "Khác") và danh sách cảnh báo (vắng > 15%, tối đa 50) từ toàn bộ lớp của GV; chưa có phiên đóng → giá trị 0, danh sách rỗng. Hàm thuần `ReportRepository.buildReport` có test riêng.

## ScheduleRepository

Kế hoạch buổi ngoài lịch (`class_schedules`); không tự mở phiên.

| Phương thức | Ghi chú |
|---|---|
| `options()` | `teacherName`, `today` (giờ Việt Nam), `classes`, `slots`, `rooms`, `capabilities`, `schedules` |
| `list()` | Lịch đã tạo của GV, sắp xếp theo ngày/giờ |
| `create(input)` | Kiểm tra lớp thuộc GV, `requestId` (`^[a-zA-Z0-9_-]{8,100}$`), slot hợp lệ, ngày hợp lệ, ca chưa bắt đầu, phòng thuộc lớp của GV, ghi chú ≤ 2000, không trùng khung giờ. **Idempotent**: id tài liệu `{memberCode}_{requestId}`; cùng `requestId` + cùng nội dung trả bản ghi cũ, khác nội dung → `CONFLICT` |

`lessonType`: `makeup`, `workshop`, `review`; `teachingMethod`: `onCampus`. Giờ lấy từ slot (`slotCode`), không lưu trong bản ghi lịch. QR tự động, email và đồng bộ FAP chưa được tích hợp (`NOT_SUPPORTED`).

## TimetableRepository

`scanImage(bytes, fileName, mimeType)` (Storage + Cloud Function) và `importAssignments(scanToken, classCodes)` (nhận lớp) — xem [07](07-timetable-ocr.md).

## Kiểm thử

```bash
cd packages/core && flutter test        # 38 test: Teacher, History, Report, Schedule (fake_cloud_firestore)
cd mobile && flutter test               # model, ViewModel, widget
```

Các test dùng `fake_cloud_firestore` (không có Security Rules); phần phân quyền được kiểm bằng test Rules trên Emulator ([08](08-security-rules.md)).
