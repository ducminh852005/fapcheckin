# FAP Check-in Admin Web

Ứng dụng quản trị viết bằng React 19, TypeScript, Vite và Tailwind CSS. UI hiện là prototype dùng dữ liệu
mẫu; bước tiếp theo là nối Firebase Authentication và các collection Firestore đã có trong monorepo.

## Chạy dự án

```bash
corepack pnpm install
corepack pnpm dev
corepack pnpm typecheck
corepack pnpm build
```

## Cấu trúc source

```text
src/
├── components/    # UI dùng chung, drawer và toast
├── data/          # Dữ liệu mẫu tạm thời
├── layouts/       # Khung sidebar/topbar của trang quản trị
├── pages/         # Login, Dashboard, Catalog và Requests
├── types/         # Kiểu dữ liệu dùng chung
├── App.tsx        # Điều phối trạng thái và trang hiện tại
└── index.css      # Design tokens và style toàn cục
```

> Trang điểm danh của sinh viên nằm ở [`../checkin/`](../checkin/) (Firebase Hosting).
> App giảng viên (staff) nằm ở [`../../mobile/`](../../mobile/).

## Phạm vi giao diện quản trị hiện tại

Admin Web tập trung vào bốn khu vực có dữ liệu và trách nhiệm quản trị rõ ràng:

1. **Tổng quan vận hành** — tài khoản hoạt động, lớp, phiên đang mở và bản ghi chưa đồng bộ.
2. **Tài khoản** — `users`, `user_invites`, vai trò và trạng thái hoạt động.
3. **Dữ liệu học vụ** — `classes`, `subjects`, `enrollments`, `slots`, `timeSlots`.
4. **Giám sát điểm danh** — `sessions`, `attendance_records`, tìm dữ liệu lỗi và chưa đồng bộ.

Các phần sau đã được bỏ khỏi navigation cho đến khi có schema/backend thật:

- Duyệt yêu cầu (`requests` chưa tồn tại trên project đã kiểm tra).
- Gửi/lên lịch thông báo (`announcements`, FCM và device token chưa tồn tại).
- Biểu đồ chuyên cần, top môn vắng, học kỳ và activity realtime dùng số liệu mẫu.
- Trạng thái/lưu trữ lớp vì `classes` chưa có `status`, `semester` hay `archivedAt`.

Giao diện mới không hiển thị số liệu giả và không giả lập thao tác ghi thành công. Cấu trúc dữ liệu thật: [`docs/03-du-lieu-firestore.md`](../../docs/03-du-lieu-firestore.md), [`docs/data-model.md`](../../docs/data-model.md).

### Kết nối Firestore đã triển khai

- Dashboard dùng aggregate count trực tiếp trên `users`, `classes`, `sessions`, `attendance_records`.
- Tài khoản đọc `users`/`user_invites`, cấp/thu hồi quyền đăng nhập, xem chi tiết, khóa/mở hồ sơ canonical và đổi role `user`/`staff` có kiểm soát.
- Hồ sơ legacy có thể tạo quyền đăng nhập từ dữ liệu sẵn có; không bị sửa trực tiếp trước migration.
- Học vụ đọc `classes`, `subjects`, `slots`, `timeSlots` và join tên giảng viên theo `memberCode`.
- Điểm danh đọc 100 phiên gần nhất, lọc phiên và tải bản ghi theo `sessionId`; không đưa `qrSecret` hay IP lên UI.
- Repository học vụ có batch đổi giảng viên để đồng bộ `classes` và `enrollments`; UI ghi học vụ chưa bật cho tới khi migration được xác nhận hoàn tất.

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

## Việc cần làm tiếp theo

1. Đăng nhập Google đã được nối; cần duy trì hồ sơ `users/{uid}` với `role == 'admin'` và `active == true`.
2. Nối repository Firestore cho bốn khu vực quản trị đang hiển thị.
3. Thêm một **site Hosting thứ hai** (vd. `fapcheckin-admin`): `firebase hosting:sites:create fapcheckin-admin`,
   gán target (`firebase target:apply hosting admin fapcheckin-admin`) và chuyển `hosting` trong `firebase.json`
   thành mảng hai phần tử (`checkin` → `web/checkin`, `admin` → `web/admin/build/web`).
4. Thêm test Security Rules cho từng thao tác admin mới vào `firebase/tests/`.

## Khởi tạo admin đầu tiên

Xem mục "Tài khoản Admin đầu tiên" trong [README gốc](../../README.md#tài-khoản-admin-đầu-tiên).
