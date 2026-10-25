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

1. Nối Firebase JS SDK và đăng nhập Google; chỉ cho phép `role == 'admin'`.
2. Thay dữ liệu trong `src/data/mock-data.ts` bằng service/repository Firestore.
3. Thêm một **site Hosting thứ hai** (vd. `fapcheckin-admin`): `firebase hosting:sites:create fapcheckin-admin`,
   gán target (`firebase target:apply hosting admin fapcheckin-admin`) và chuyển `hosting` trong `firebase.json`
   thành mảng hai phần tử (`checkin` → `web/checkin`, `admin` → `web/admin/build/web`).
4. Thêm test Security Rules cho từng thao tác admin mới vào `firebase/tests/`.

## Khởi tạo admin đầu tiên

Xem mục "Tài khoản Admin đầu tiên" trong [README gốc](../../README.md#tài-khoản-admin-đầu-tiên).
