[← Mục lục](README.md)

# Quick Start — Chạy & build app GV trên mobile (Android / iOS)

Tài liệu này giúp một dev mới chạy được app giảng viên trên điện thoại hoặc emulator trong khoảng 15 phút. Pattern code (MVVM, `action` + envelope) nằm ở [quick-start.md](quick-start.md), không lặp lại ở đây.

## 1. Chuẩn bị

| Cần có | Ghi chú |
|---|---|
| Flutter SDK | Dart `^3.13.2` (xem `pubspec.yaml`). Kiểm tra bằng `flutter doctor`. |
| Android Studio + Android SDK | Cần cho cả emulator lẫn build APK. |
| JDK 17+ | Đi kèm Android Studio, hoặc cài riêng (đã thử với JDK 21). |
| Xcode (chỉ macOS) | Chỉ khi build iOS. |
| Tài khoản Google | Dùng để đăng nhập; phải nằm trong danh sách Test users của OAuth consent screen (mục 4). |

```bash
git clone <repo> && cd fapcheckin
flutter pub get
```

## 2. Chạy trên emulator hoặc máy thật

```bash
flutter emulators                      # liệt kê emulator
flutter emulators --launch <id>        # bật emulator (chọn image có Google Play)
flutter devices                        # xác nhận thiết bị đã thấy
flutter run -d <device-id>
```

Máy thật Android: bật Developer options → USB debugging, cắm cáp, chạy `flutter devices`.

Lần build đầu mất 3–5 phút do Gradle tải dependency; các lần sau nhanh hơn. Trong lúc `flutter run`: `r` hot reload, `R` hot restart, `q` thoát.

### Cấu hình qua `--dart-define`

Mọi giá trị đều có mặc định trong code, chỉ override khi cần.

| Biến | Mặc định | Dùng để |
|---|---|---|
| `API_BASE_URL` | URL Apps Script hiện tại (`lib/core/network/api_service.dart`) | Trỏ sang deployment khác của backend. |
| `GOOGLE_CLIENT_ID` | Web client của project | Client ID truyền cho Google Sign-In. |
| `GOOGLE_SERVER_CLIENT_ID` | Web client của project | Audience của `idToken` gửi lên backend. |
| `GOOGLE_HOSTED_DOMAIN` | rỗng | Giới hạn domain email (ví dụ `fpt.edu.vn`). |

```bash
flutter run -d <device-id> \
  --dart-define=API_BASE_URL=https://script.google.com/macros/s/<DEPLOYMENT_ID>/exec
```

`GOOGLE_DESKTOP_CLIENT_*` chỉ dùng cho Windows/Linux, mobile không cần.

## 3. Giao diện responsive

App chọn bố cục theo chiều rộng màn hình (`lib/core/responsive/breakpoints.dart`):

| Chiều rộng | Bố cục |
|---|---|
| < 600 dp (điện thoại) | Thanh điều hướng dưới (Tổng quan / Lịch học / Tiết học / Khóa học); popup lớn mở full-screen; bảng chuyển thành danh sách thẻ. |
| 600–767 dp | Menu Drawer. |
| ≥ 768 dp | Sidebar cố định (desktop / tablet ngang). |

Khi viết UI mới, dùng `context.isMobile`, `context.pagePadding` và `ResponsiveDialogFrame` thay vì tự kiểm tra `MediaQuery`. Đừng hard-code `width` lớn (> 300); dùng `ConstrainedBox(maxWidth)`, `Flexible` hoặc `Wrap`.

Kiểm tra nhanh mà không cần thiết bị: `flutter run -d chrome` rồi thu nhỏ cửa sổ, hoặc dùng chế độ giả lập thiết bị trong DevTools của trình duyệt.

## 4. Đăng nhập Google trên Android

Đăng nhập chỉ chạy được sau khi cấu hình OAuth. Làm một lần cho mỗi máy dev:

1. Lấy SHA-1 của debug keystore trên máy bạn:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore \
     -alias androiddebugkey -storepass android -keypass android
   ```
   Trên Windows `~` là `C:\Users\<tên>`. Mỗi máy dev có SHA-1 riêng.
2. Vào Google Cloud Console → project của app → **APIs & Services → Credentials → Create credentials → OAuth client ID** → loại **Android**:
   - Package name: `com.example.fapcheckin`
   - SHA-1: giá trị ở bước 1.
   Mỗi SHA-1 một client Android; nhóm có nhiều dev thì tạo nhiều client hoặc dùng chung một debug keystore.
3. **OAuth consent screen**: nếu app đang ở chế độ Testing, thêm email của bạn vào **Test users**.
4. Chờ vài phút cho Google áp dụng, rồi bấm "Tiếp tục với Google" trong app.

### SHA-1 của máy là gì và vì sao mỗi máy khác nhau

- **SHA-1 là vân tay (fingerprint) của chứng chỉ dùng để ký APK.** Khi bạn chạy `flutter run`, Gradle ký bản debug bằng file `~/.android/debug.keystore`. File này **tự sinh ra trên từng máy** ở lần build Android đầu tiên, với khóa ngẫu nhiên, nên SHA-1 của mỗi máy dev khác nhau. Dev A và dev B dùng cùng mã nguồn nhưng có hai SHA-1 khác nhau.
- **Google dùng cặp (package name + SHA-1) để kiểm tra app nào được phép đăng nhập.** OAuth client loại Android chỉ chấp nhận APK có đúng package `com.example.fapcheckin` và được ký bằng chứng chỉ có SHA-1 đã khai báo. Nếu SHA-1 của APK không nằm trong client nào, Google trả `DEVELOPER_ERROR` / `clientConfigurationError` dù mọi thứ khác đều đúng.
- **SHA-1 không phải bí mật.** Nó chỉ là dấu vân tay công khai nên có thể dán vào chat, issue hay doc. Bí mật là file keystore và mật khẩu của nó.
- **Có thể lấy SHA-1 bằng một trong hai cách:**
  - `keytool` như ở bước 1 ở trên (dòng `SHA1:` trong kết quả).
  - `cd android && ./gradlew signingReport`, xem mục `Variant: debug`. Cách này in đúng SHA-1 mà Gradle dùng để ký, tiện khi project cấu hình `signingConfigs` riêng.

**Nhóm nhiều dev nên làm thế nào.** Chọn một trong hai:

| Cách | Làm gì | Ưu / nhược |
|---|---|---|
| Mỗi dev một client (khuyến nghị) | Mỗi người lấy SHA-1 của máy mình và tạo thêm một OAuth client Android, cùng package name, khác SHA-1. | Không chia sẻ khóa. Phải có quyền tạo client trong project Google Cloud, và mỗi dev mới cần thêm một client. |
| Dùng chung một debug keystore | Một người gửi file `debug.keystore` cho cả nhóm (qua kênh riêng), mọi người chép vào `~/.android/`. Khi đó cả nhóm có cùng một SHA-1, chỉ cần một client. | Đơn giản hơn. Chỉ dùng cho debug; **không** commit file này lên git. |

**Các trường hợp SHA-1 đổi, cần khai báo lại:**
- Máy mới, cài lại hệ điều hành, hoặc xóa `~/.android/debug.keystore` (Gradle sinh khóa mới nên SHA-1 đổi).
- Chạy trong CI (mỗi runner có debug keystore riêng nếu không được cấu hình).
- Build **release**: ký bằng keystore release, có SHA-1 khác hẳn debug. Phải thêm SHA-1 này vào một client Android.
- Phát hành qua Google Play: Google ký lại app bằng khóa của Play App Signing, SHA-1 lấy ở Play Console → App integrity. Cũng phải khai báo.

Dấu hiệu nhận biết nhầm SHA-1: đăng nhập báo `DEVELOPER_ERROR` / `clientConfigurationError` dù package name đã đúng và client đã tạo. Lấy lại SHA-1 bằng lệnh trên, đối chiếu với SHA-1 trong client rồi chỉnh. Sau khi sửa, chờ vài phút cho Google áp dụng.

Không cần sửa code: app đã dùng Web client làm `serverClientId`, nên `idToken` có đúng audience cho backend (xem [05](05-xac-thuc-va-phan-quyen.md)). Backend Apps Script phải cho phép email đó với vai trò giảng viên.

Với bản **release**, thêm SHA-1 của keystore release vào client Android. Nếu phát hành qua Google Play, thêm cả SHA-1 của Play App Signing.

Setup cho web và desktop: [google-oauth-setup.md](google-oauth-setup.md).

iOS: `ios/Runner/Info.plist` chưa có `GIDClientID` và URL scheme (`CFBundleURLTypes`) nên đăng nhập Google trên iOS chưa chạy được. Cần tạo OAuth client loại iOS rồi thêm hai khóa này.

## 5. Build

```bash
flutter build apk --debug          # APK debug
flutter build apk --release        # APK release (cần keystore để phát hành)
flutter build appbundle --release  # AAB để đưa lên Google Play
```

File ra tại `build/app/outputs/flutter-apk/`. Quyền `INTERNET` đã có trong `AndroidManifest.xml` chính, nên bản release gọi được API.

Hiện bản release vẫn ký bằng debug key (mặc định của template). Trước khi phát hành, tạo keystore riêng và cấu hình `signingConfigs` trong `android/app/build.gradle.kts`.

## 6. Kiểm tra

```bash
flutter analyze
flutter test
flutter test test/responsive_layout_test.dart   # test bố cục 320/360/412 dp và 1280 dp
```

`responsive_layout_test.dart` fail khi có `RenderFlex overflow`, nên chạy nó sau mỗi lần sửa UI. Lưu ý test dùng font Ahem (rộng hơn font thật), vì vậy test có thể báo overflow mà máy thật không bị; vẫn nên sửa cho an toàn.

## 7. Lỗi thường gặp

| Triệu chứng | Nguyên nhân & cách xử lý |
|---|---|
| `settings.gradle.kts: Unresolved reference 'run' / 'plugins'` | Gradle 9.3.1 compile script lỗi trên một số máy. Đổi `distributionUrl` trong `android/gradle/wrapper/gradle-wrapper.properties` sang Gradle 9.5.1. |
| `Could not close incremental caches ... compileDebugKotlin` | Project và pub cache nằm khác ổ đĩa (ví dụ project ở `D:`, pub cache ở `C:`). Đã tắt bằng `kotlin.incremental=false` trong `android/gradle.properties`. Sau khi sửa, chạy `flutter clean` rồi build lại. |
| Build treo hoặc báo "busy daemon" | `cd android && ./gradlew --stop`, rồi build lại. |
| Đăng nhập báo `DEVELOPER_ERROR` / `clientConfigurationError` | Chưa có OAuth client Android khớp package name và SHA-1 (mục 4), hoặc Google chưa áp dụng xong. |
| Đăng nhập báo email không được phép | Email chưa vào Test users, hoặc không đúng `GOOGLE_HOSTED_DOMAIN`, hoặc backend chưa cấp quyền giảng viên. |
| Màn hình trắng sau khi mở app | Mở `flutter run` xem log; thường do `API_BASE_URL` sai hoặc không có mạng. |
| Emulator không có nút đăng nhập Google hoạt động | Dùng image **có Google Play** và đăng nhập một tài khoản Google trong Settings của emulator. |

## 8. Giới hạn đã biết trên mobile

- Xuất Excel trong màn hình lịch sử chỉ ghi file vào thư mục tạm, người dùng không mở được; cần thêm chia sẻ file (share sheet).
- Đăng nhập Google trên iOS chưa cấu hình (mục 4).
- Lịch tuần trên điện thoại vẫn cuộn ngang; một chế độ xem theo ngày sẽ dễ dùng hơn.
- Màn Cài đặt chỉ thích ứng một phần và hiện chưa có mục menu dẫn tới.

[← Mục lục](README.md)
