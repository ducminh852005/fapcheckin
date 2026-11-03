# Kết nối mobile với backend Firebase

Backend trong repository là Firebase Authentication, Firestore, Storage và các Cloud Functions (`scanTimetable`, `sendTeachingReminders`, `onFeedbackSaved`, `syncToFap` tại region `asia-southeast1`). Mobile gọi SDK thông qua `packages/core/lib/repositories`, không cần REST base URL. Firebase SDK quản lý phiên và ID token; trường `AuthSessionModel.token` hiện chứa UID, không phải bearer token.

## Đối chiếu màn hình và API

| Màn hình | Repository / thao tác | Nguồn dữ liệu |
|---|---|---|
| Đăng nhập | `AuthRepository.loginWithGoogleIdToken`, `restoreSession`, `signOut` | Firebase Auth, `users`, `user_invites` |
| Tổng quan, quản lý lớp | `TeacherRepository.getClasses` | `classes`, `enrollments`, `sessions`, `attendance_records`, `slots`, `timeSlots` |
| Lịch dạy | Lịch lặp từ slot của lớp; `ScheduleRepository.list` | `classes`, `class_schedules` |
| Tạo lịch bổ sung | `ScheduleRepository.options`, `create` | Lớp/phòng/slot được phép, `class_schedules`; giữ requestId khi retry |
| Nhập thời khóa biểu | `TimetableRepository.scanImage`, thao tác import của repository | Storage `timetable_scans/{uid}`, Cloud Function OCR, nhận lớp chưa có giảng viên |
| Điểm danh QR | `startSession`, `getSession`, `rotateQr`, `getRoster`, `syncSessionTeacherIp`, `closeSession` | `sessions`, `enrollments`, `attendance_records` |
| Điểm danh tay | `manualCheckin`, `manualCheckinBulk` | Ghi trạng thái thật; chỉ báo thành công sau phản hồi |
| Lịch sử & Đồng bộ FAP | `AttendanceHistoryRepository.getClasses`, `getSummary`, `getDetail`, `getMatrix`, `save`, `export`, `startSession`; `TeacherRepository.syncToFap` | Lớp/buổi/sinh viên thật; sửa ô qua bảng chi tiết, kiểm tra revision; xuất XLSX; đồng bộ trạng thái `syncedToFap` |
| Báo cáo | `ReportRepository.getReport` | Tổng hợp lượt đã ghi nhận; thống kê tuần từ phiên đầu tiên, tổng có mặt/vắng và mẫu số thật; xuất XLSX |
| Hồ sơ cá nhân & Ảnh đại diện | `AuthRepository.updateName` (`updateProfile`), `AccountFeaturesRepository.saveAvatar`, `removeAvatar`, `loadAvatar` | `users/{uid}` (`fullName`, `phone`, `birthDate`, `avatarPath`), Storage `avatars/{uid}/avatar` |
| Thông tin công tác | `AuthRepository.restoreSession` / `loginWithGoogleIdToken` | Đọc `department`, `division`, `jobTitle`, `employmentDate`, `contractType` từ `users/{uid}` (kết hợp `user_invites/{email}`) |
| Tài khoản & Bảo mật | `AccountFeaturesRepository.securitySummary` | Kiểm tra phương thức đăng nhập (`google.com` / `password`), trạng thái xác thực email và thông tin MFA từ `FirebaseAuth.currentUser` |
| Cài đặt & Nhắc lịch | `AccountFeaturesRepository.preferences`, `savePreferences` | `user_preferences/{uid}` (`teachingReminders`, `leadMinutes`, `themeMode`, `languageCode`), Cloud Function `sendTeachingReminders` |
| Thông báo | `AnnouncementRepository.watch`, `AccountFeaturesRepository.notifications`, `markRead` | Stream `announcements` + `user_notifications/{uid}/items` |
| Báo lỗi / Gửi góp ý | `AccountFeaturesRepository.submitFeedback`, `feedback` | `app_feedback/{id}` + trigger `onFeedbackSaved` gửi thông báo phản hồi |
| Liên hệ hỗ trợ | `AccountFeaturesRepository.support` | `support_config/public` (`hotline`, `email`, `zalo`, `officeHours`, `address`, `faqUrl`) |

Router yêu cầu đăng nhập. Dữ liệu ViewModel được xóa khi đổi UID/đăng xuất; phản hồi muộn của báo cáo, dashboard, lịch sử và các tác vụ live chính không được ghi đè tài khoản mới. Danh sách rỗng không sinh lớp/sinh viên/QR mẫu. Lỗi khởi tạo Firebase không đưa người dùng vào màn hình dữ liệu giả.

## Ghi chú kiến trúc & Bảo mật

- **Ảnh đại diện & Hồ sơ cá nhân:** Giảng viên có thể cập nhật `fullName`, `phone` (kiểm tra regex số điện thoại), `birthDate` (`YYYY-MM-DD`) và `avatarPath` (`avatars/{uid}/avatar` trên Firebase Storage, tối đa 5MB, định dạng ảnh).
- **Thông tin công tác:** Các trường `department`, `division`, `jobTitle`, `employmentDate`, `contractType` được bảo vệ bởi Firestore Security Rules (chỉ Admin được phép chỉnh sửa, giảng viên chỉ đọc).
- **Nhắc lịch trước giờ dạy:** Cấu hình lưu tại `user_preferences/{uid}`, Cloud Function định kỳ `sendTeachingReminders` quét lịch dạy và tạo thông báo vào `user_notifications/{uid}/items`.
- **Đồng bộ FAP:** `TeacherRepository.syncToFap` và callable Cloud Function `syncToFap` kiểm tra quyền sở hữu lớp của giảng viên, đồng bộ các bản ghi điểm danh chưa đồng bộ (`syncedToFap != true`) và cập nhật `syncedToFap = true`, `updatedAt`, `updatedBy`.

## Chạy với dữ liệu thật

1. Dùng cấu hình Firebase trong `mobile/lib/firebase_options.dart` và cấu hình nền tảng tương ứng. Xem `docs/quick-start-mobile.md` cho Google OAuth/SHA.
2. Admin tạo `user_invites/{email}` hoặc hồ sơ `users/{uid}` với `role=staff`, `active=true`, `memberCode` đúng. Phân công lớp/ghi danh với cùng `teacherMemberCode`.
3. Đăng nhập Google bằng tài khoản đã cấp quyền. Không có lớp được phân công sẽ hiển thị trạng thái rỗng.
4. Mở lớp → chọn kiểm tra IP → mở QR → sinh viên quét → kiểm tra danh sách → đóng phiên → xem lịch sử/báo cáo. Xuất file trên mobile hiện lưu vào thư mục tạm và trả đường dẫn; web tải xuống trực tiếp.
5. `CHECKIN_BASE_URL` phải trỏ đến trang sinh viên đã deploy cùng Firebase project. OCR thực cần Cloud Function đã deploy và Cloud Vision được cấu hình.
