[← Mục lục](README.md)

# 12 · Security Rules & kiểm thử

Nguồn chuẩn: [`firebase/firestore.rules`](../firebase/firestore.rules) và [`firebase/storage.rules`](../firebase/storage.rules). Nguyên tắc:

- **Deny by default**: khối `match /{document=**}` cuối cùng từ chối tất cả; không có `allow …: if true`.
- Mọi quyền đều yêu cầu `request.auth != null` và `email_verified == true`, rồi kiểm tra role/`active` của `users/{uid}`.
- Sở hữu dữ liệu của GV: `resource.data.teacherMemberCode == users/{uid}.memberCode`.
- Mọi `create`/`update` của client đều giới hạn tập khóa (`hasOnly`) và giá trị hợp lệ (trạng thái, kiểu, độ dài).

## Ma trận quyền

Ký hiệu: ✔ được · ✘ bị từ chối · "own" = chỉ tài liệu của chính mình/lớp mình phụ trách.

| Collection | Thao tác | `user` (SV) | `staff` (GV) | `admin` | Chưa đăng nhập |
|---|---|---|---|---|---|
| `users` | get | own | own | ✔ | ✘ |
| | list | ✘ | ✘ | ✔ | ✘ |
| | create | chỉ khi khớp `user_invites` (role/memberCode/rollNumber/email) | như SV | như SV (hoặc bootstrap bằng Admin SDK) | ✘ |
| | update | chỉ `fullName` của mình | chỉ `fullName` của mình | ✔ | ✘ |
| | delete | ✘ | ✘ | ✔ | ✘ |
| `user_invites` | get | invite của email mình | invite của email mình | ✔ | ✘ |
| | list / write | ✘ | ✘ | ✔ | ✘ |
| `subjects`, `timeSlots`, `slots` | read | ✔ | ✔ | ✔ | ✘ |
| | write | ✘ | ✘ | ✔ | ✘ |
| `classes` | read | ✘ | own + lớp chưa có GV | ✔ | ✘ |
| | create / delete | ✘ | ✘ | ✔ | ✘ |
| | update | ✘ | chỉ nhận lớp chưa có GV (`teacherMemberCode: '' → memberCode`, không đổi trường khác) | ✔ | ✘ |
| `enrollments` | read | own (`rollNumber`) | own + lớp chưa có GV | ✔ | ✘ |
| | create / delete | ✘ | ✘ | ✔ | ✘ |
| | update | ✘ | chỉ nhận ghi danh của lớp chưa có GV | ✔ | ✘ |
| `class_schedules` | read / update / delete | ✘ | own (không đổi `classCode`, `teacherMemberCode`) | ✔ | ✘ |
| | create | ✘ | cho lớp mình phụ trách | ✔ | ✘ |
| `sessions` | read | ✘ (tránh lộ `qrSecret`) | own | ✔ | ✘ |
| | create | ✘ | lớp mình phụ trách, `open`, `qrSecret` ≥ 16 ký tự, `ipCheck` boolean | ✘ | ✘ |
| | update | ✘ | own (không đổi `classCode`, `teacherMemberCode`, `sessionDate`) | ✔ | ✘ |
| | delete | ✘ | ✘ | ✔ | ✘ |
| `attendance_records` | read | bản ghi của mình | own | ✔ | ✘ |
| | create | **check-in** hợp lệ (xem [02](02-luong-diem-danh-qr.md#rules-quyết-định-gì-khi-sv-tạo-bản-ghi)) | phiên của mình, SV thuộc lớp, trạng thái hợp lệ, tập khóa cố định | ✘ | ✘ |
| | update | ✘ | own, chỉ các trường `status`, `checkinTime`, `networkVerificationResult`, `ipAddress`, `note`, `updatedAt`, `updatedBy`, `syncedToFap` | ✔ | ✘ |
| | delete | ✘ | ✘ | ✔ | ✘ |
| `requests` | read | đơn của mình | đơn của mình | ✔ | ✘ |
| | create | `authorUid` = mình, `status = pending`, `reason` 1..2000 ký tự, `type` ∈ {`attendance_fix`, `leave`} | như SV | ✘ | ✘ |
| | update | ✘ | ✘ | duyệt đơn `pending` → `approved`/`rejected`, chỉ `status`, `resolvedBy`, `resolvedAt`, `adminNote` | ✘ |
| | delete | rút đơn `pending` của mình | như SV | ✘ | ✘ |
| `announcements` | read | `audience` ∈ {`all`, `user`} | `audience` ∈ {`all`, `staff`} | ✔ | ✘ |
| | write | ✘ | ✘ | ✔ | ✘ |
| Mọi collection khác | — | ✘ | ✘ | ✘ | ✘ |

Storage (`storage.rules`): `timetable_scans/{uid}/{file}` — `staff` tạo file ảnh (`image/*`, < 10 MB, chỉ đường dẫn của mình, không ghi đè), chủ file và `admin` đọc; mọi đường dẫn khác bị từ chối.

## Test

Bộ test nằm ở [`firebase/tests/`](../firebase/tests) (`@firebase/rules-unit-testing` + `node:test`), chạy trên **Firebase Local Emulator**; mỗi collection có đủ trường hợp được phép và bị từ chối cho từng role:

| File | Nội dung |
|---|---|
| `firestore.rules.test.mjs` | `deny by default`; `users` (tự tạo hồ sơ khớp invite, không tự nâng role, mạo danh, đổi role); `user_invites`; dữ liệu tham chiếu; `classes` (nhận lớp, cướp lớp, đổi trường khác); `enrollments`; `class_schedules`; `sessions` (mở phiên, lớp người khác, secret yếu, SV không đọc); **`attendance_records` — check-in**: đúng QR, sai QR, phiên đã đóng, chưa ghi danh, điểm danh hộ, trùng, sai id, giả mạo trạng thái/giờ/lớp, IP khớp/lệch/thiếu, tài khoản bị khóa/chưa có hồ sơ/GV; GV chấm tay và sửa; `requests` (tạo, mạo danh, tự duyệt, admin duyệt, duyệt lại); `announcements` theo `audience`. |
| `storage.rules.test.mjs` | GV tải ảnh vào thư mục của mình, bị chặn khi ghi vào thư mục người khác / SV tải / không phải ảnh / sửa-xóa / đường dẫn lạ. |

Chạy: `cd firebase && npm ci && npm test` (cần Java 21 và `firebase-tools`; lệnh tự khởi động Emulator rồi tắt). CI chạy bộ này mỗi lần push ([`.github/workflows/ci.yml`](../.github/workflows/ci.yml)). Kịch bản end-to-end (`e2e_test/`) kiểm tra cả chuỗi admin → GV → SV bằng SDK client thật.

## Quy trình khi thêm/đổi Rules

1. Viết test (allowed **và** denied) trong `firebase/tests/` trước hoặc cùng lúc.
2. `npm test`; chỉ merge khi xanh.
3. Deploy: `./scripts/deploy.ps1 -Only firestore` (script chạy lại test trước khi deploy).

## Ghi chú kỹ thuật

- Test file chạy **tuần tự** (`--test-concurrency=1`) vì dùng chung một Emulator và xóa dữ liệu giữa các test.
- Cổng Firestore Emulator là **8085** (8080 hay bị chiếm); đổi ở `firebase.json` và `firebase/tests/helpers.mjs` nếu cần.
- Rules giới hạn 10 lần truy cập tài liệu (`get`/`exists`) mỗi request; check-in dùng 3 (`users`, `sessions`, `enrollments`).
