# Ghi chú đối chiếu Firestore cho Admin Web

> Tài liệu làm việc tạm thời, ghi nhận từ ảnh Firebase Console ngày 29/10/2026.
> Giá trị nhạy cảm như QR secret, IP, email và thông tin cá nhân không được chép vào đây.

## Mục tiêu

- Xác định collection thực tế đang có trên Firebase.
- Phân biệt dữ liệu legacy (camelCase) và schema mới (snake_case).
- Đối chiếu dữ liệu thật với các chức năng hiện tại của `web/admin`.
- Xác định chức năng nào có thể nối trực tiếp, chức năng nào còn thiếu schema/backend.

## Collection đã ghi nhận

### `attendanceRecords` (legacy)

Document ID quan sát được có dạng `{sessionId}_{rollNumber}`.

Các field xuất hiện trong ảnh:

| Field | Kiểu quan sát | Ghi chú |
|---|---|---|
| `_row` | number | Dấu vết dữ liệu import/migrate |
| `checkinTime` | string | Có mẫu là chuỗi rỗng |
| `ipAddress` | string | Có thể rỗng |
| `networkVerificationResult` | string | Ví dụ `AutoAbsent` |
| `recordId` | string | UUID riêng, không trùng document ID |
| `rollNumber` | string | Mã sinh viên |
| `sessionId` | string | Liên kết phiên điểm danh |
| `status` | string | Ví dụ `Absent` |
| `syncedToFap` | boolean | Trạng thái đồng bộ |
| `updatedAt` | string | Có mẫu là chuỗi rỗng |

Nhận xét ban đầu:

- Mẫu này không có `classCode` và `teacherMemberCode`.
- Thời gian đang lưu dưới dạng string, không phải Firestore Timestamp.
- Cần kiểm tra app còn đọc collection này hay chỉ giữ làm dữ liệu legacy.

### `attendanceSessions` (legacy)

Document ID là UUID và trùng với giá trị `sessionId` trong document mẫu.

| Field | Kiểu quan sát | Ghi chú |
|---|---|---|
| `_row` | number | Dấu vết dữ liệu import/migrate |
| `classCode` | string | Liên kết lớp |
| `qrSecret` | string | Dữ liệu nhạy cảm, không được trả về sinh viên |
| `sessionDate` | string | Định dạng quan sát `yyyy-MM-dd` |
| `sessionId` | string | UUID |
| `sessionStatus` | string | Ví dụ `open` |
| `slotCode` | string | Ví dụ `P4` |
| `teacherIp` | string | IP của giảng viên |

Nhận xét ban đầu:

- Mẫu không có `teacherMemberCode` và `ipCheck` như schema `sessions` mới.
- `sessionDate` đang là string.
- Có phiên `open`; admin tương lai nên có màn hình phát hiện phiên mở quá lâu.

### `attendance_records` (schema mới)

Document ID quan sát được có dạng `{sessionId}_{rollNumber}`.

| Field | Kiểu quan sát | Ghi chú |
|---|---|---|
| `classCode` | string | Đã denormalize |
| `ipAddress` | string | Có thể rỗng |
| `networkVerificationResult` | string | Ví dụ `AutoAbsent` |
| `recordId` | string | UUID legacy vẫn còn được giữ |
| `rollNumber` | string | Mã sinh viên |
| `sessionId` | string | Liên kết phiên |
| `status` | string | Ví dụ `Absent` |
| `syncedToFap` | boolean | Trạng thái đồng bộ |
| `teacherMemberCode` | string | Đã denormalize |

Nhận xét ban đầu:

- Collection mới đã bổ sung `classCode` và `teacherMemberCode`, phù hợp hơn với Security Rules hiện tại.
- Document mẫu `Absent` không có `checkinTime` và `updatedAt`; code đọc dữ liệu cần chấp nhận field tùy chọn.
- Vẫn còn `recordId` từ schema cũ dù document ID đã đủ định danh.

### `classSchedules` (legacy)

Document ID là UUID và trùng với `scheduleId` trong mẫu.

| Field | Kiểu quan sát | Ghi chú |
|---|---|---|
| `_row` | number | Dấu vết import/migrate |
| `classCode` | string | Liên kết lớp |
| `createdAt` | string | ISO-8601 string, chưa phải Timestamp |
| `lessonType` | string | Ví dụ `makeup` |
| `note` | string | Ghi chú lịch |
| `requestId` | string | ID yêu cầu tạo lịch |
| `room` | string | Phòng học |
| `scheduleDate` | string | `yyyy-MM-dd` |
| `scheduleId` | string | UUID |
| `slotCode` | string | Liên kết slot |
| `status` | string | Ví dụ `scheduled` |
| `teacherMemberCode` | string | Mã giảng viên |
| `teachingMethod` | string | Ví dụ `onCampus` |

Nhận xét ban đầu:

- Đây là lịch học bổ sung/ngoài lịch, không phải request duyệt điểm danh của Admin Web.
- `createdAt` là string trong dữ liệu legacy.

### `classSections` (legacy)

Document ID quan sát được trùng với `classCode`.

| Field | Kiểu quan sát | Ghi chú |
|---|---|---|
| `_row` | number | Dấu vết import/migrate |
| `classCode` | string | Mã lớp, cũng là document ID |
| `room` | string | Phòng mặc định |
| `slotCode` | string | Slot mặc định |
| `studentCount` | number | Sĩ số |
| `subjectCode` | string | Liên kết môn học |
| `teacherMemberCode` | string | Mã giảng viên |

Nhận xét ban đầu:

- Không thấy `subjectName`, `credits`, `status` hoặc `semester`.
- UI Admin hiện có trạng thái `Đang học / Sắp mở / Lưu trữ` và bộ lọc học kỳ nhưng dữ liệu này chưa hỗ trợ.
- Muốn hiện tên giảng viên phải join với `users` bằng `teacherMemberCode`.
- Muốn hiện tên môn phải join với `subjects` bằng `subjectCode`.

### `class_schedules` (schema mới)

Document ID là UUID và trùng với `scheduleId` trong document mẫu.

| Field | Kiểu quan sát | Ghi chú |
|---|---|---|
| `classCode` | string | Liên kết lớp |
| `createdAt` | timestamp | Đã chuyển từ ISO string ở legacy sang Firestore Timestamp |
| `lessonType` | string | Ví dụ `makeup` |
| `note` | string | Ghi chú lịch |
| `requestId` | string | ID yêu cầu tạo lịch |
| `room` | string | Phòng học |
| `scheduleDate` | string | `yyyy-MM-dd` |
| `scheduleId` | string | UUID |
| `slotCode` | string | Liên kết slot |
| `status` | string | Ví dụ `scheduled` |
| `teacherMemberCode` | string | Mã giảng viên |
| `teachingMethod` | string | Ví dụ `onCampus` |

Nhận xét ban đầu:

- Nội dung gần như tương ứng `classSchedules`, nhưng `_row` đã được bỏ và `createdAt` đã đúng kiểu Timestamp.
- Collection này phù hợp với repository và Security Rules hiện tại hơn bản legacy.
- `requestId` ở đây là yêu cầu/lịch bổ sung của giảng viên; không chứng minh có collection duyệt đơn `requests` dành cho admin.

### `classes` (schema mới)

Document ID trùng với `classCode`.

| Field | Kiểu quan sát | Ghi chú |
|---|---|---|
| `classCode` | string | Mã lớp, cũng là document ID |
| `credits` | number | Số tín chỉ được denormalize từ môn học |
| `room` | string | Phòng mặc định |
| `slotCode` | string | Slot mặc định |
| `studentCount` | number | Sĩ số |
| `subjectCode` | string | Liên kết môn học |
| `subjectName` | string | Tên môn đã denormalize |
| `teacherMemberCode` | string | Mã giảng viên |

Nhận xét ban đầu:

- So với `classSections`, schema mới đã bỏ `_row`, bổ sung `credits` và `subjectName`.
- Admin có thể hiển thị tên môn trực tiếp từ `classes`; tên giảng viên vẫn cần tra `users` bằng `teacherMemberCode`.
- Vẫn không có `status`, `semester`, `active` hoặc `archivedAt`. UI hiện tại chưa thể lọc học kỳ hay lưu trữ lớp đúng nghĩa.
- Mã lớp là document ID; không nên cho sửa mã lớp sau khi tạo.

### `enrollments`

Document ID quan sát được có dạng `{classCode}_{rollNumber}`.

| Field | Kiểu quan sát | Ghi chú |
|---|---|---|
| `classCode` | string | Liên kết lớp |
| `email` | string | Email sinh viên |
| `fullName` | string | Họ tên sinh viên |
| `rollNumber` | string | Mã sinh viên |
| `teacherMemberCode` | string | Mã giảng viên được denormalize |

Nhận xét ban đầu:

- Schema phù hợp với Security Rules và repository hiện tại.
- Có thể dùng trực tiếp cho màn hình danh sách sinh viên theo lớp.
- Khi admin đổi giảng viên của lớp, phải cập nhật đồng bộ `teacherMemberCode` cho toàn bộ enrollment liên quan; update một document `classes` là chưa đủ.
- Email/họ tên là dữ liệu cá nhân, UI admin cần giới hạn quyền và tránh ghi log giá trị đầy đủ.

### `sessions` (schema mới)

Document ID là UUID và trùng với `sessionId` trong document mẫu.

| Field | Kiểu quan sát | Ghi chú |
|---|---|---|
| `classCode` | string | Liên kết lớp |
| `ipCheck` | boolean | Bật/tắt xác minh IP |
| `qrSecret` | string | Dữ liệu nhạy cảm |
| `sessionDate` | string | `yyyy-MM-dd` |
| `sessionId` | string | UUID |
| `sessionStatus` | string | Ví dụ `open` |
| `slotCode` | string | Liên kết slot |
| `teacherIp` | string | IP giảng viên |
| `teacherMemberCode` | string | Mã giảng viên được denormalize |

Nhận xét ban đầu:

- So với `attendanceSessions`, schema mới đã bổ sung `ipCheck` và `teacherMemberCode`, phù hợp với Rules hiện tại.
- Admin có đủ dữ liệu để lọc phiên theo lớp, giảng viên, ngày và trạng thái.
- `qrSecret` không được đưa vào bảng, log, export hoặc response không cần thiết của admin web.
- Có thể triển khai cảnh báo phiên `open` quá lâu, nhưng cần định nghĩa ngưỡng và cách suy ra thời gian bắt đầu; document mẫu chưa có `createdAt`/`openedAt`.

### `slots`

Document ID trùng với `slotCode` (ví dụ `A1`).

| Field | Kiểu quan sát | Ghi chú |
|---|---|---|
| `slotCode` | string | Mã slot |
| `timeSlotId` | string | Liên kết `timeSlots` |
| `weekdays` | array<number> | Các thứ áp dụng; ví dụ `[2, 5]` |

Nhận xét ban đầu:

- Dữ liệu đúng với seed/reference và tài liệu hiện tại.
- Muốn hiện giờ bắt đầu/kết thúc phải join `timeSlots` bằng `timeSlotId`.
- Collection chỉ có 12 mã slot cố định; CRUD slot trên Admin Web không phải ưu tiên và có thể gây hỏng quy ước lịch nếu sửa tùy ý.

### `subjects`

Document ID trùng với `subjectCode`.

| Field | Kiểu quan sát | Ghi chú |
|---|---|---|
| `credits` | number | Số tín chỉ |
| `subjectCode` | string | Mã môn, cũng là document ID |
| `subjectName` | string | Tên môn |

Nhận xét ban đầu:

- Schema gọn và phù hợp với tài liệu/repository hiện tại.
- Admin có thể CRUD môn học trực tiếp, nhưng không nên cho xóa môn đã được `classes` tham chiếu.
- Hiện có ít nhất bốn môn trong ảnh; số lượng `42 môn` trên UI Admin là mock.

### `timeSlots`

Document ID trùng với `timeSlotId` (ví dụ `A-1`).

| Field | Kiểu quan sát | Ghi chú |
|---|---|---|
| `daySlotNo` | number | Số thứ tự ca trong ngày |
| `endTime` | string | Giờ kết thúc `HH:mm` |
| `period` | string | Ví dụ `Morning` |
| `slotInPeriod` | number | Thứ tự ca trong buổi |
| `startTime` | string | Giờ bắt đầu `HH:mm` |
| `timeSlotId` | string | Mã khung giờ, cũng là document ID |

Nhận xét ban đầu:

- Có bốn khung giờ cố định: `A-1`, `A-2`, `P-1`, `P-2`.
- Dữ liệu khớp seed/reference hiện tại.
- Đây là cấu hình nền tảng; Admin Web nên mặc định chỉ xem. Nếu cho sửa phải kiểm tra `startTime < endTime` và ảnh hưởng đến toàn bộ slot/lớp.

### `user_invites`

Document ID quan sát được là email viết thường.

| Field | Kiểu quan sát | Ghi chú |
|---|---|---|
| `email` | string | Trùng với document ID trong mẫu |
| `fullName` | string | Họ tên người được mời |
| `memberCode` | string | Mã thành viên |
| `role` | string | Mẫu dùng enum mới `user` |
| `rollNumber` | string | Có với sinh viên |

Nhận xét ban đầu:

- Schema phù hợp với luồng tạo hồ sơ lần đăng nhập đầu và Security Rules hiện tại.
- Chưa thấy `createdAt`, `createdBy`, `usedAt` hoặc trạng thái invite; Admin khó biết invite nào đã dùng nếu chỉ dựa vào document này.
- Admin Web nên ưu tiên màn hình cấp tài khoản/invite, tìm kiếm và khóa/mở người dùng hơn các tính năng thông báo nâng cao.

### `users` (mẫu legacy quan sát được)

Document ID trong ảnh là `memberCode`, không phải Firebase Auth UID.

| Field | Kiểu quan sát | Ghi chú |
|---|---|---|
| `_row` | number | Dấu vết import/migrate |
| `email` | string | Email người dùng |
| `fullName` | string | Họ tên |
| `memberCode` | string | Trùng document ID trong mẫu |
| `role` | string | Mẫu dùng enum legacy `SV` |
| `rollNumber` | string | Mã sinh viên |

Nhận xét quan trọng:

- Mẫu này không phù hợp schema `users/{uid}` mà Security Rules hiện tại yêu cầu.
- Role `SV` không khớp enum mới `user | staff | admin`.
- Không có `active` và `createdAt`.
- Vì document ID không phải Auth UID, helper `profilePath()` trong Rules không tìm được hồ sơ sau khi đăng nhập nếu người dùng chỉ có document legacy này.
- Đây là lời giải thích hợp lý cho việc tài khoản có quyền Firebase Console nhưng client exporter vẫn nhận `permission-denied`.
- Cần kiểm tra xem collection có tồn tại song song các document mới dùng Auth UID hay chưa. Không nên tự động coi toàn bộ `users` là đã migrate chỉ từ một mẫu.

## Quan hệ legacy quan sát được

```text
classSections.classCode
  ├─ attendanceSessions.classCode
  │    └─ attendanceRecords.sessionId -> attendanceSessions.sessionId
  └─ classSchedules.classCode
```

Schema mới dự kiến tương ứng:

```text
classes
  ├─ enrollments.classCode
  ├─ sessions.classCode
  │    └─ attendance_records.sessionId -> sessions.sessionId
  └─ class_schedules.classCode
```

Hiện Firebase đang tồn tại song song cả hai nhóm. Nhóm snake_case/canonical có cấu trúc phù hợp hơn với code, tài liệu và Security Rules hiện tại. Cần tiếp tục xác nhận ứng dụng production đã chuyển hoàn toàn sang nhóm mới trước khi bỏ hoặc ngừng đọc legacy.

## Ảnh còn cần

- [x] `classes`
- [x] `sessions`
- [x] `class_schedules`
- [x] `enrollments`
- [x] `users` (đã thấy mẫu legacy; còn cần xác nhận document Auth UID/admin)
- [x] `subjects`
- [x] `slots`
- [x] `timeSlots`
- [x] `user_invites`
- [x] `requests` không xuất hiện trong danh sách root collection đã chụp
- [x] `announcements` không xuất hiện trong danh sách root collection đã chụp

## Kết luận tạm thời cho Admin Web

1. Trang quản lý lớp có thể lấy mã lớp, tên môn, tín chỉ, phòng, slot, sĩ số và mã giảng viên trực tiếp từ `classes`; chỉ tên giảng viên cần join `users`.
2. Bộ lọc học kỳ, trạng thái lớp và thao tác lưu trữ hiện chưa có dữ liệu hỗ trợ trong mẫu đã xem.
3. Dashboard và màn hình giám sát có thể đọc `sessions` + `attendance_records`; nhóm này phù hợp với schema hiện tại hơn legacy.
4. Chưa thấy `requests` và `announcements` trong danh sách collection trên ảnh; hai chức năng này có khả năng chưa có backend/dữ liệu thật.
5. Admin nên ưu tiên quản lý tài khoản, dữ liệu lớp, giám sát phiên và bản ghi điểm danh hơn các biểu đồ hoặc thông báo nâng cao.
6. Thay đổi giảng viên của lớp cần cập nhật đồng bộ `classes`, `enrollments` và các dữ liệu tương lai có `teacherMemberCode`; nên thực hiện bằng batch/transaction hoặc Cloud Function.
7. Quản lý tài khoản chưa thể nối an toàn cho tới khi chuẩn hóa `users`: document ID phải là Auth UID, role phải là `user | staff | admin`, đồng thời có `active`.
8. `subjects`, `slots` và `timeSlots` đã đủ dữ liệu cho danh mục cơ bản; các số lượng và học kỳ trên UI hiện tại vẫn là mock.

## Vấn đề ưu tiên cần xử lý trước Admin Web

1. **Migration tài khoản:** chuẩn hóa hoặc tạo hồ sơ `users/{authUid}` từ `user_invites`; không dùng document memberCode legacy làm hồ sơ đăng nhập.
2. **Chọn nguồn dữ liệu chuẩn:** Admin Web và mobile nên dùng `classes`, `sessions`, `attendance_records`, `class_schedules`; xác minh không còn luồng production ghi vào camelCase legacy.
3. **Bổ sung nghiệp vụ còn thiếu:** chưa có `requests`, `announcements` và `audit_logs` trong danh sách collection quan sát được.
4. **Thu gọn UI Admin:** bỏ các bộ lọc học kỳ, trạng thái lưu trữ, số liệu và hoạt động giả cho tới khi schema/backend tương ứng tồn tại.
