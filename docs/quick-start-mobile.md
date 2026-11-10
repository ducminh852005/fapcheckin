[← Mục lục](README.md)

# Quick Start — Chạy & build app GV trên mobile (Android / iOS)

Tài liệu này giúp một dev mới chạy được app giảng viên (thư mục [`mobile/`](../mobile)) trên điện thoại hoặc emulator trong khoảng 15 phút. Pattern code (MVVM + Repository trên Firebase) nằm ở [quick-start.md](quick-start.md). **Mọi lệnh `flutter` chạy trong thư mục `mobile/`.**

## 1. Chuẩn bị

| Cần có | Ghi chú |
|---|---|
| Flutter SDK | Dart `^3.13.2` (xem `mobile/pubspec.yaml`). Kiểm tra bằng `flutter doctor`. |
| Android Studio + Android SDK | Cần cho cả emulator lẫn build APK. |
| JDK 17+ | Đi kèm Android Studio (đã thử với JDK 21). |
| Node.js 22 + Java 21 + `firebase-tools` | Chỉ khi chạy Firebase Emulator / test Rules. |
| Xcode (chỉ macOS) | Chỉ khi build iOS. |
| Tài khoản Google | Có trong `user_invites` với role `staff` (admin cấp — xem [05](05-xac-thuc-va-phan-quyen.md)). |

```bash
git clone <repo> && cd fapcheckin/mobile
flutter pub get          # kéo cả ../packages/core (path dependency)
```

## 2. Cấu hình Firebase cho app (một lần)

`mobile/lib/firebase_options.dart` trong repo là bản giữ chỗ (ném lỗi có hướng dẫn). Sinh bản thật:

```bash
dart pub global activate flutterfire_cli
cd mobile
flutterfire configure --project=fapcheckin-3bn2di
```

Lệnh này ghi đè `lib/firebase_options.dart` và tạo `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist` (khóa client của Firebase không phải bí mật — bảo vệ dữ liệu bằng Security Rules). Commit các file này để cả nhóm dùng chung.

Trong Firebase Console cần bật: **Authentication → Sign-in method → Google**, **Firestore**, và với import thời khóa biểu: **Storage**, **Functions** (gói Blaze). Chi tiết: [deploy-firebase.md](deploy-firebase.md).

## 3. Chạy trên emulator hoặc máy thật

```bash
flutter emulators                      # liệt kê emulator
flutter emulators --launch <id>        # bật emulator (chọn image có Google Play)
flutter devices                        # xác nhận thiết bị đã thấy
flutter run -d <device-id>
```

Máy thật Android: bật Developer options → USB debugging, cắm cáp. Lần build đầu mất 3–5 phút do Gradle tải dependency. Trong lúc `flutter run`: `r` hot reload, `R` hot restart, `q` thoát.

### Cấu hình qua `--dart-define`

Mọi giá trị đều có mặc định trong code, chỉ override khi cần.

| Biến | Mặc định | Dùng để |
|---|---|---|
| `CHECKIN_BASE_URL` | `https://fapcheckin-3bn2di.web.app` | Trang check-in của SV nhúng trong mã QR. |
| `GOOGLE_CLIENT_ID` | Web client của project | Client ID truyền cho Google Sign-In. |
| `GOOGLE_SERVER_CLIENT_ID` | Web client của project | Audience của `idToken` đổi lấy phiên Firebase. |
| `GOOGLE_HOSTED_DOMAIN` | rỗng | Giới hạn domain email (ví dụ `fpt.edu.vn`). |

`GOOGLE_DESKTOP_CLIENT_*` chỉ dùng cho Windows/Linux ([google-oauth-setup.md](google-oauth-setup.md)).

### Chạy với Firebase Emulator thay vì project thật

Mặc định app nói chuyện với project `fapcheckin-3bn2di`. Để thử Rules/dữ liệu giả, chạy `firebase emulators:start` ở thư mục gốc rồi gọi `FirebaseFirestore.instance.useFirestoreEmulator('10.0.2.2', 8085)` và `FirebaseAuth.instance.useAuthEmulator('10.0.2.2', 9099)` (địa chỉ máy host từ emulator Android) trong `main.dart` ở nhánh làm việc cục bộ của bạn — không commit thay đổi này.

## 4. Giao diện responsive

App chọn bố cục theo chiều rộng màn hình (`packages/core/lib/responsive/breakpoints.dart`):

| Chiều rộng | Bố cục |
|---|---|
| < 600 dp (điện thoại) | Thanh điều hướng dưới; popup lớn mở full-screen; bảng chuyển thành danh sách thẻ. |
| 600–767 dp | Menu Drawer. |
| ≥ 768 dp | Sidebar cố định (desktop / tablet ngang). |

Khi viết UI mới, dùng `context.isMobile`, `context.pagePadding` và `ResponsiveDialogFrame` thay vì tự kiểm tra `MediaQuery`. Kiểm tra nhanh không cần thiết bị: `flutter run -d chrome` rồi thu nhỏ cửa sổ.

## 5. Đăng nhập Google trên Android

Bản debug ký bằng **debug keystore mặc định của từng máy** (`~/.android/debug.keystore`), nên mỗi người có SHA-1 riêng và phải khai báo nó trong Firebase một lần.

1. Lấy SHA-1 của máy bạn:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
   (hoặc `cd mobile/android && ./gradlew signingReport`, mục `Variant: debug`). Keystore chưa có thì chạy app một lần (`flutter run`) để Gradle tạo.
2. Firebase Console → **Project settings → Your apps → Android** (`com.example.fapcheckin`) → **Add fingerprint** → dán SHA-1. Mỗi thành viên thêm SHA-1 của mình (một app chứa được nhiều SHA-1).
3. Tải lại `mobile/android/app/google-services.json` (hoặc chạy lại `flutterfire configure`) để file có OAuth client Android tương ứng.
4. Bật Google ở **Authentication → Sign-in method**. `GOOGLE_SERVER_CLIENT_ID` mặc định đã là Web client của project Firebase (`161196189514-jtodr…`), nên `idToken` có đúng audience, không cần safelist.
5. **OAuth consent screen**: nếu app ở chế độ Testing, thêm email thành viên vào **Test users**.

Lưu ý: một cặp (package name + SHA-1) chỉ thuộc được **một** OAuth client Android trên toàn Google Cloud. Nếu Firebase hiện cảnh báo "Another project contains an OAuth 2.0 client that uses this same SHA-1 fingerprint and package name combination", cặp đó đang bị project khác giữ: xóa client Android ở project kia, hoặc dùng keystore/SHA-1 khác.

### SHA-1 là gì và khi nào đổi

- SHA-1 là vân tay của chứng chỉ ký APK; Google dùng cặp (package name + SHA-1) để biết app nào được phép đăng nhập. Sai/thiếu SHA-1 → `DEVELOPER_ERROR` / `clientConfigurationError`.
- SHA-1 không phải bí mật (bí mật là file keystore và mật khẩu).
- Cần khai báo thêm khi: đổi máy hoặc xóa `~/.android/debug.keystore`; build **release** (keystore release khác); phát hành qua Google Play (khóa Play App Signing, lấy ở Play Console → App integrity).

Setup cho web và desktop: [google-oauth-setup.md](google-oauth-setup.md).

iOS: `ios/Runner/Info.plist` chưa có `GIDClientID` và URL scheme (`CFBundleURLTypes`) nên đăng nhập Google trên iOS chưa chạy được; cần OAuth client loại iOS (do `flutterfire configure` tạo trong `GoogleService-Info.plist`) rồi thêm hai khóa này.

## 6. Build

```bash
flutter build apk --debug          # APK debug
flutter build apk --release        # APK release (cần keystore để phát hành)
flutter build appbundle --release  # AAB để đưa lên Google Play
```

File ra tại `mobile/build/app/outputs/flutter-apk/`. Quyền `INTERNET` đã có trong `AndroidManifest.xml` chính. Bản release hiện vẫn ký bằng debug key (mặc định của template): trước khi phát hành, tạo keystore riêng và cấu hình `signingConfigs` trong `android/app/build.gradle.kts`.

Crashlytics: để báo cáo sự cố có stack trace dễ đọc cần thêm plugin Gradle `com.google.firebase.crashlytics` theo hướng dẫn của FlutterFire; thiếu plugin thì app vẫn chạy bình thường. Crashlytics và Analytics chỉ bật trên Android/iOS (bản release; bị tắt ở chế độ debug).

## Trợ lý AI & giọng nói (tab AI)

Tab **AI** gọi Cloud Function `aiAssistant` (Gemini; có thể tự chuyển sang Ollama local khi Gemini quá tải). Cần trước khi dùng: secret `GEMINI_API_KEY` đã đặt và hàm đã deploy — xem [deploy-firebase.md](deploy-firebase.md) và [ai-assistant.md](ai-assistant.md).

- **Chạy web để thử nhanh**: `flutter run -d chrome --web-port=5000 --web-hostname=localhost` (cổng cố định để đăng nhập Google không báo `origin_mismatch`; thêm `http://localhost:5000` vào *Authorized JavaScript origins* của OAuth client). Chrome cần cho phép micro; chỉ phát âm sau khi bạn bấm một nút.
- **Điện thoại Android**: cắm máy bật USB debugging (`flutter devices`), `flutter run -d <id>`. Cần quyền micro (hỏi lúc bấm mic/Live) và nên cài gói giọng nói **Tiếng Việt** (Cài đặt → Text-to-speech) cùng Google Speech Services.
- **Lần đầu thêm plugin giọng nói** (`speech_to_text`, `flutter_tts`) hoặc sau khi sửa `AndroidManifest.xml`/`Info.plist`: phải **dừng và chạy lại** `flutter run` (hot reload không nạp plugin native). Triệu chứng nếu quên: nghe được nhưng không có tiếng đọc, kèm toast "Giọng đọc chưa được nạp".
- **Dùng**: mic = nói một câu (gửi sau khi im lặng ~2 giây, hoặc bấm mic lần nữa để gửi ngay); **Live** = hội thoại liên tục, AI đọc to phần tóm tắt rồi tự nghe tiếp; nút **Dừng** ngắt AI đang đọc/xử lý. Lệnh ghi điểm danh luôn hiện thẻ xác nhận (bấm hoặc nói "xác nhận"/"huỷ").
- **Giọng đọc**: mặc định dùng Google Cloud Text-to-Speech (giọng Việt `vi-VN`) qua hàm `aiSpeak`, tự chuyển sang giọng của máy khi hàm lỗi. Cần bật `texttospeech.googleapis.com` và deploy `aiSpeak` ([deploy-firebase.md](deploy-firebase.md)). Muốn chỉ dùng giọng của máy: `flutter run ... --dart-define=AI_TTS_DEVICE_ONLY=true`.
- **Demo khi Gemini quá tải**: `./scripts/ai-fallback.ps1 up` rồi `switch ollama` (một lệnh, không cần deploy) — xem [ai-assistant.md §G](ai-assistant.md).

## 7. Kiểm tra

```bash
cd packages/core && flutter analyze && flutter test     # Repository (fake_cloud_firestore)
cd mobile && flutter analyze && flutter test            # model, ViewModel, widget
flutter test test/responsive_layout_test.dart           # bố cục 320/360/412 dp và 1280 dp
cd firebase && npm test                                 # Security Rules trên Emulator
cd e2e_test && npm test                                 # luồng admin → GV → SV
cd e2e_test && npm run test:ai                          # trợ lý AI: Functions + Rules trên Emulator (Gemini giả)
```

`responsive_layout_test.dart` fail khi có `RenderFlex overflow`; test dùng font Ahem (rộng hơn font thật) nên có thể báo overflow mà máy thật không bị.

**Ba test của `mobile/` đang thất bại sẵn** (đã kiểm chứng trên cây chưa có tính năng AI): `create_class_dialog_test.dart › real options, required fields and idempotent timeout retry`, `create_schedule_bottom_sheet_test.dart › CreateScheduleBottomSheet selects options and submits to backend` và `requests_test.dart › TC08: submit request and display subsequent approval/rejection from stream` (lỗi `RangeError`/layout trong test, chưa điều tra). Job `flutter-mobile` trong CI đặt `continue-on-error` cho tới khi sửa.

Trợ lý AI: `test/ai_assistant_flow_test.dart` (36 test: luồng chat/xác nhận, Live, câu dài, ngắt AI, lỗi giọng đọc; Gemini, Firestore, micro và loa giả) và `test/voice_vietnamese_test.dart` (20 test: locale tiếng Việt cho nhận dạng/đọc, hàm xử lý chữ) — xem [ai-assistant.md](ai-assistant.md). Nhận dạng và giọng đọc tiếng Việt thật cần thử tay trên thiết bị có gói giọng `vi-VN` và đã cấp quyền micro.

## 8. Lỗi thường gặp

| Triệu chứng | Nguyên nhân & cách xử lý |
|---|---|
| Mở app báo "Chưa cấu hình Firebase" | Chưa chạy `flutterfire configure` (mục 2). |
| `settings.gradle.kts: Unresolved reference 'run' / 'plugins'` | Gradle 9.3.1 compile script lỗi trên một số máy. Đổi `distributionUrl` trong `android/gradle/wrapper/gradle-wrapper.properties` sang Gradle 9.5.1. |
| `Could not close incremental caches ... compileDebugKotlin` | Project và pub cache khác ổ đĩa. Đã tắt bằng `kotlin.incremental=false` trong `android/gradle.properties`; chạy `flutter clean` rồi build lại. |
| Build treo / "busy daemon" | `cd android && ./gradlew --stop`, rồi build lại. |
| Đăng nhập báo `DEVELOPER_ERROR` / `clientConfigurationError` | Thiếu SHA-1 trong Firebase hoặc `google-services.json` cũ (mục 5). |
| "Tài khoản không thuộc hệ thống nhà trường hoặc chưa được phân quyền" | Email chưa có `user_invites` — nhờ admin cấp (hoặc `seed-admin` cho tài khoản admin đầu tiên). |
| "Tài khoản này không có quyền giảng viên" | Hồ sơ có `role` không phải `staff`. |
| Thao tác báo `FORBIDDEN` bất ngờ | Rules từ chối: kiểm tra lớp có đúng `teacherMemberCode` của bạn không ([08](08-security-rules.md)). |
| Truy vấn lỗi "The query requires an index" | Deploy `firebase/firestore.indexes.json` (`./scripts/deploy.ps1 -Only firestore`). |
| Emulator không có nút đăng nhập Google hoạt động | Dùng image **có Google Play** và đăng nhập một tài khoản Google trong Settings của emulator. |

## 9. Giới hạn đã biết trên mobile

- Xuất Excel trong màn hình lịch sử chỉ ghi file vào thư mục tạm, người dùng không mở được; cần thêm chia sẻ file (share sheet).
- Đăng nhập Google trên iOS chưa cấu hình (mục 5).
- Lịch tuần trên điện thoại vẫn cuộn ngang; chế độ xem theo ngày sẽ dễ dùng hơn.
- Màn Cài đặt chỉ thích ứng một phần và hiện chưa có mục menu dẫn tới.

[← Mục lục](README.md)
