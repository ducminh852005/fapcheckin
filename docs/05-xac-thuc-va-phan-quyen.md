[← Mục lục](README.md)

# 05 · Xác thực & phân quyền

Không tự làm hệ thống mật khẩu — tận dụng tài khoản Google theo domain trường mà GV/SV đã có sẵn, dù một bên là app, một bên là web.

## Phía Giảng viên (app Flutter)

1. **Đăng nhập bằng Google** (`google_sign_in`) — App lấy `idToken`; gửi kèm request đầu tiên tới Backend.
2. **Backend xác minh domain email** — Chỉ chấp nhận email đúng domain trường; tra collection `users` (trước đây là tab `Users`) theo email — chưa có trong `users` thì từ chối (`DOMAIN_NOT_ALLOWED`), có rồi thì lấy `role` đã lưu.
3. **Cấp session token nội bộ** — Token ngắn hạn ký HMAC (không phải mật khẩu Google) lưu ở `flutter_secure_storage`; mọi request sau đính token này.

## Phân quyền dữ liệu

Không client nào đọc/ghi Firestore trực tiếp: `firestore.rules` từ chối mọi truy cập ([03](03-du-lieu-firestore.md#4-firestore-rules--indexes)). Quyền nằm ở Backend — mỗi action giảng viên gọi `AuthService.requireTeacher` và kiểm tra lớp thuộc đúng giảng viên; Backend truy cập Firestore bằng quyền IAM của chủ script (scope `datastore`), không có khóa dịch vụ nào trong app hay repo. Firebase Auth chưa được dùng (`users.authUid` là trường dành sẵn).

## Phía Sinh viên (trang web)

1. **Mở trang qua QR lần đầu** — Trình duyệt chưa có session → trang hiện nút "Đăng nhập bằng Google" (Google Identity Services), giới hạn domain trường giống hệt phía app. Trang chạy ở origin Firebase Hosting (`https://<project>.web.app`), origin này phải nằm trong *Authorized JavaScript origins* của OAuth Web client ([google-oauth-setup.md](google-oauth-setup.md)).
2. **Backend cấp session token, trang lưu vào `localStorage`** — Thay cho `flutter_secure_storage` bên app; token gắn với trình duyệt/thiết bị đó.
3. **Các lần quét sau: tự động, không hỏi lại** — Trang phát hiện đã có token hợp lệ trong `localStorage` → tự lấy IP và POST `/checkin` ngay khi tải xong, không cần SV bấm thêm gì — đúng yêu cầu "đã đăng nhập thì tự điểm danh".

[→ 06 Tính năng đề xuất thêm](06-tinh-nang-de-xuat-them.md)
