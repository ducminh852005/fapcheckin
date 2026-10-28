[← Mục lục](README.md)

# 05 · Xác thực & phân quyền

Không tự làm hệ thống mật khẩu — dùng **Firebase Authentication với nhà cung cấp Google** cho cả app (GV) lẫn web (SV, admin). Quyền truy cập dữ liệu do **Security Rules** thi hành theo vai trò (RBAC).

## Vai trò (`users/{uid}.role`)

| Role | Là ai | Dùng gì | Quyền chính |
|---|---|---|---|
| `user` | Sinh viên | `web/checkin` | Tạo bản ghi điểm danh của chính mình; đọc bản ghi/ghi danh/đơn của mình; tạo đơn `requests`; đọc `announcements` cho `all`/`user`. |
| `staff` | Giảng viên | app `mobile/` | Quản lý **lớp mình phụ trách**: phiên, điểm danh, lịch ngoài lịch, ghi danh (đọc), nhận lớp chưa có GV; tạo đơn; đọc `announcements` cho `all`/`staff`. |
| `admin` | Quản trị | Web Admin (UI prototype, chưa nối Firebase) | Toàn quyền dữ liệu tham chiếu, `users`, `user_invites`, lớp/ghi danh; duyệt `requests`; phát `announcements`; đọc/sửa/xóa điểm danh. |

Ma trận đầy đủ role × collection × thao tác: [08](08-security-rules.md).

## Cấp tài khoản: `user_invites` → `users`

Người dùng **không thể tự đặt role**. Quy trình:

1. **Admin** tạo `user_invites/{email viết thường}` với `role`, `memberCode`, `fullName` (và `rollNumber` với SV).
2. Người dùng đăng nhập Google. Nếu chưa có `users/{uid}`, app/web đọc invite của **chính email đó** và tạo `users/{uid}`.
3. Rules chỉ chấp nhận khi dữ liệu tạo ra **khớp invite** (`role`, `memberCode`, `rollNumber`, `email` = email đã xác minh của token, `active = true`, `createdAt = request.time`).
4. Email không có invite → `DOMAIN_NOT_ALLOWED` ("Tài khoản không thuộc hệ thống nhà trường hoặc chưa được phân quyền").

`users.active = false` khóa tài khoản: mọi quyền theo role biến mất ngay (Rules kiểm tra `active` ở mỗi request).

## Phía Giảng viên (app Flutter)

1. **Đăng nhập Google** (`google_sign_in`; Windows/Linux dùng luồng OAuth installed-app) → lấy `idToken`.
2. **Đổi lấy phiên Firebase**: `FirebaseAuth.signInWithCredential(GoogleAuthProvider.credential(idToken: …))`.
3. **Nạp hồ sơ** `users/{uid}` (tạo từ invite nếu là lần đầu). Chỉ `role == staff` được vào app; `user`/`admin` bị đăng xuất kèm thông báo.
4. Firebase Auth giữ phiên trên thiết bị; mở lại app tự khôi phục (`AuthViewModel.restoreSession`). Không còn token HMAC tự cấp hay `flutter_secure_storage` cho token.

## Phía Sinh viên (trang web)

1. Mở trang qua QR; chưa đăng nhập → nút "Đăng nhập bằng Google" (Firebase Auth).
2. Tạo/nạp `users/{uid}`; yêu cầu `role == user` và có `rollNumber`.
3. Lần quét sau: phiên Firebase còn trong trình duyệt → tự điểm danh ngay.

## Nguyên tắc bảo mật áp dụng

- **Deny by default**: collection không khai báo bị từ chối; không có `allow …: if true`.
- Quyền dữ liệu của GV tính theo `memberCode` trong `users/{uid}` so với `teacherMemberCode` trên tài liệu.
- `email_verified == true` bắt buộc (token Google luôn thỏa).
- Khóa API của Firebase client (trong `firebase_options.dart`, `google-services.json`) không phải bí mật — bảo vệ dữ liệu bằng Rules, không bằng việc giấu khóa. Không commit khóa service account.

[→ 06 Rủi ro, giới hạn & hướng mở rộng](06-rui-ro-va-mo-rong.md)
