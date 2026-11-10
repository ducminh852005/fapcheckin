# Thiết lập QA với Firebase project mới

Tài liệu này dành cho TV5 khi nhóm chuyển sang Firebase project mới. Quyền truy cập Firebase Console (IAM) không đồng nghĩa tài khoản Google đã có quyền `staff` trong ứng dụng.

## 1. Thông tin cần lấy từ thành viên quản lý Firebase

- Firebase project ID mới.
- Xác nhận Android app có package `com.example.fapcheckin`.
- `google-services.json` được tải sau khi thêm SHA-1/SHA-256 của máy build.
- Xác nhận Authentication > Google đã bật.
- Xác nhận Firestore Rules, Indexes, Storage Rules và Functions đã deploy đúng project.
- Tài khoản test/invite: một `staff`, một `user`, và nếu có thể một tài khoản inactive.
- Dữ liệu seed không chứa dữ liệu thật: lớp, enrollment, session và attendance records.

Không cần tải service-account JSON cho kiểm thử mobile thông thường. Không commit API key riêng, credential, file `.env.local`, log hoặc screenshot chứa PII.

## 2. Thêm fingerprint Android

Tại `mobile/android` chạy:

```bat
gradlew signingReport
```

Gửi SHA-1 và SHA-256 của variant `debug` cho người quản lý Firebase. Họ thêm tại Project settings > Your apps > Android app > SHA certificate fingerprints, sau đó tải lại `google-services.json`.

## 3. Cập nhật cả hai cấu hình Flutter/Firebase

Project hiện khởi tạo Firebase bằng `DefaultFirebaseOptions.currentPlatform`, vì vậy phải cập nhật đồng thời:

1. `mobile/android/app/google-services.json`.
2. `mobile/lib/firebase_options.dart`.

Chỉ thay `google-services.json` là chưa đủ.

Từ thư mục `mobile`:

```bat
firebase login
firebase projects:list
dart pub global activate flutterfire_cli
flutterfire configure
```

Trong wizard, chọn Firebase project mới và các platform mà nhóm thực sự hỗ trợ. Với source hiện tại, tối thiểu cần Android; nếu giữ cấu hình Web trong `firebase_options.dart` thì chọn cả Web. FlutterFire CLI sẽ tạo/cập nhật `lib/firebase_options.dart` theo project đã chọn.

Sau đó kiểm tra:

```powershell
$j = Get-Content android\app\google-services.json -Raw | ConvertFrom-Json
$j.project_info.project_id
Select-String -Path lib\firebase_options.dart -Pattern "projectId:"
```

Project ID trong hai nguồn phải cùng project mới. Firebase khuyến nghị chạy lại `flutterfire configure` khi đổi project hoặc thêm dịch vụ Firebase.

## 4. Cấp quyền ứng dụng cho tài khoản QA

Tài khoản IAM trên Console và tài khoản ứng dụng là hai lớp khác nhau. Trước lần đăng nhập đầu, admin tạo:

```text
user_invites/{email viết thường}
```

Tài liệu staff tối thiểu:

```text
role: "staff"
memberCode: "GV_QA_01"
fullName: "QA Teacher"
```

Khi người dùng đăng nhập Google lần đầu, app tạo `users/{firebaseAuthUid}` khớp invite, với `active = true`. Không dùng UID hoặc hồ sơ copy từ Firebase project cũ.

Để chạy TC02, chuẩn bị thêm invite `role = "user"` và một hồ sơ `active = false`. Không dùng tài khoản thật của sinh viên.

## 5. Dữ liệu seed tối thiểu cho 30 Test Case

- Hai staff account và hai lớp thuộc hai `teacherMemberCode` khác nhau để kiểm isolation.
- Ít nhất một user/SV có `rollNumber` và enrollment đúng convention của Rules.
- Một lớp rỗng, một lớp có Present/Absent, một lớp có session open.
- Không để session test cũ open ngoài ý muốn trước mỗi lượt.
- Request test, notification token và preferences phải dùng UID của project mới.

## 6. Build sạch sau khi đổi project

Gỡ app cũ để xóa Firebase Auth/cache của project trước:

```bat
adb -s 2dd833e1 uninstall com.example.fapcheckin
```

Build và cài lại:

```bat
cd /d D:\ki8\PRM\Lab1\fapcheckin\mobile
flutter clean
flutter pub get
flutter build apk --debug
flutter install --debug -d 2dd833e1
```

Smoke thủ công trước ARTEMIS: đăng nhập staff, vào Dashboard, tải lớp/lịch sử và kiểm tra không có `permission-denied`.

## 7. Git và dữ liệu nhạy cảm

- Nếu nhóm đã commit cấu hình Firebase mới vào `dev`, ưu tiên merge commit đó thay vì chép file thủ công.
- Không `stash pop` một stash chứa `google-services.json` của project cũ.
- Chỉ commit cấu hình Firebase theo chính sách của nhóm; không commit service account hoặc file local chứa tài khoản.
- Trước commit chạy `git diff --cached --name-only` và `git diff --cached --check`.

## 8. ARTEMIS và video minh chứng

Chỉ quay sau khi Firebase smoke thủ công đã ổn. Không quay Firebase Console, API key hoặc account chooser chứa email cá nhân. Video nên bắt đầu tại `adb devices`, `artemis doctor`, prompt chạy Test Case, màn hình thiết bị và trace/result cuối.
