# Web Admin (chưa triển khai)

Thư mục giữ chỗ cho **Web Admin** — ứng dụng web (Flutter Web, dùng chung `packages/core`) dành cho
vai trò `admin`. Hiện chỉ có **thiết kế và dữ liệu nền**: schema Firestore, Security Rules và script khởi tạo
đã sẵn sàng để Web Admin ghi trực tiếp lên Firestore (không cần backend riêng).

> Trang điểm danh của sinh viên nằm ở [`../checkin/`](../checkin/) (Firebase Hosting).
> App giảng viên (staff) nằm ở [`../../mobile/`](../../mobile/).

## Vai trò & chức năng dự kiến

| Chức năng | Collection | Quyền (xem `firebase/firestore.rules`) |
|---|---|---|
| Cấp tài khoản GV/SV trước khi họ đăng nhập | `user_invites/{email}` | chỉ admin ghi |
| Khóa/mở tài khoản, đổi vai trò | `users/{uid}` (`active`, `role`) | chỉ admin sửa |
| Quản lý môn, lớp, ghi danh, phân công GV | `subjects`, `classes`, `enrollments` | chỉ admin tạo/xóa |
| Slot / khung giờ | `slots`, `timeSlots` | chỉ admin ghi |
| Duyệt đơn sửa điểm danh / nghỉ phép | `requests/{id}` (`pending → approved\|rejected`) | admin đổi `status`, `resolvedBy`, `resolvedAt`, `adminNote` |
| Gửi thông báo về app | `announcements/{id}` (`audience: all\|staff\|user`) | chỉ admin ghi |
| Xem điểm danh toàn trường | `sessions`, `attendance_records` | admin đọc/sửa/xóa |

## Việc cần làm khi triển khai

1. Tạo project Flutter Web tại thư mục này, phụ thuộc `fapcheckin_core` (`path: ../../packages/core`) để dùng lại
   theme, model và repository.
2. Đăng nhập Google → `AuthRepository` → chỉ cho phép `role == 'admin'`.
3. Thêm một **site Hosting thứ hai** (vd. `fapcheckin-admin`): `firebase hosting:sites:create fapcheckin-admin`,
   gán target (`firebase target:apply hosting admin fapcheckin-admin`) và chuyển `hosting` trong `firebase.json`
   thành mảng hai phần tử (`checkin` → `web/checkin`, `admin` → `web/admin/build/web`).
4. Thêm test Security Rules cho từng thao tác admin mới vào `firebase/tests/`.

## Khởi tạo admin đầu tiên

Xem mục "Tài khoản Admin đầu tiên" trong [README gốc](../../README.md#tài-khoản-admin-đầu-tiên).
