[← Mục lục](README.md)

# Thiết lập đăng nhập Google (Firebase Authentication)

Cả app GV, trang SV và (sau này) Web Admin đều đăng nhập bằng **Firebase Authentication — nhà cung cấp Google**. Không còn luồng Google Identity Services + backend tự xác minh `idToken` như thời Apps Script.

## 1. Bật nhà cung cấp Google

Firebase Console → **Authentication → Sign-in method → Google → Enable**, chọn email hỗ trợ dự án. Firebase tự tạo một **Web client** trong project Google Cloud tương ứng.

## 2. Trang SV (Hosting) — không cần cấu hình OAuth thủ công

Trang `web/checkin` dùng `signInWithPopup` của Firebase Auth trên origin `https://<project-id>.web.app`. Origin này đã nằm trong **Authentication → Settings → Authorized domains** mặc định; thêm `localhost` để thử cục bộ. Không cần khai báo Authorized JavaScript origins / redirect URI trong Google Cloud Console (Firebase tự lo handler `/__/auth/handler`).

## 3. App Android

1. Thêm SHA-1 của máy bạn vào app Android trong Firebase (*Project settings → Your apps*) và chạy lại `flutterfire configure` để tải `google-services.json` — chi tiết: [quick-start-mobile.md §5](quick-start-mobile.md#5-đăng-nhập-google-trên-android).
2. `GOOGLE_SERVER_CLIENT_ID` mặc định (`mobile/lib/core/config/auth_config.dart`) là Web client của chính project Firebase (`161196189514-jtodr06udnlqeca7768qkqq5lrqn32qo.apps.googleusercontent.com`), nên không cần safelist. Nếu đổi sang client của project khác, thêm nó vào *Authentication → Sign-in method → Google → Safelist client IDs from external projects*.
3. Nếu OAuth consent screen đang ở chế độ **Testing**, thêm email thành viên vào **Test users**.

## 4. Desktop (Windows / Linux)

Bản desktop dùng luồng OAuth *installed app* (mở trình duyệt, nhận mã qua loopback) để lấy Google `idToken`, rồi đổi sang phiên Firebase giống mobile. Cần **Desktop OAuth client** của project và client secret của nó:

- Client ID mặc định: `222111384223-bpv1gtbt3kqs8401b6ethio1gi69ahl1.apps.googleusercontent.com` (`AuthConfig.googleDesktopClientId`).
- Client secret **không** nằm trong repo. Tạo file `mobile/desktop_oauth.local.json` (đã được `.gitignore`) chứa `{"GOOGLE_DESKTOP_CLIENT_SECRET": "<secret thật từ Google Cloud Console>"}` rồi chạy:

```powershell
cd mobile
flutter run -d windows --dart-define-from-file=desktop_oauth.local.json
```

Nếu file vẫn là giá trị mẫu, Google từ chối đổi mã với `invalid_client`.

> Hỗ trợ Windows/Linux của các plugin Firebase còn hạn chế (xem [06](06-rui-ro-va-mo-rong.md)). Nếu `signInWithCredential` lỗi trên desktop, dùng Android hoặc web.

## 5. Cấp quyền truy cập

Đăng nhập Google thành công **chưa** có nghĩa được vào hệ thống: email phải có bản ghi `user_invites/{email}` (admin cấp) thì mới tạo được hồ sơ `users/{uid}`. Xem [05](05-xac-thuc-va-phan-quyen.md).

## Chẩn đoán nhanh

| Triệu chứng | Nguyên nhân thường gặp |
|---|---|
| `DEVELOPER_ERROR` / `clientConfigurationError` (Android) | SHA-1 chưa khai báo trong Firebase, hoặc `google-services.json` cũ. |
| `auth/invalid-credential` / audience không hợp lệ | `GOOGLE_SERVER_CLIENT_ID` không thuộc project Firebase và chưa được safelist. |
| `auth/unauthorized-domain` (web) | Thêm domain vào *Authorized domains*. |
| "Tài khoản không thuộc hệ thống…" | Email chưa có `user_invites`. |
| `access_denied` khi đăng nhập | Consent screen ở chế độ Testing và email chưa vào Test users. |
