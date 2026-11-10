# Báo cáo tình trạng API ứng dụng desktop FAP Check-in

**Ngày kiểm tra:** 10/11/2026  
**Phạm vi:** Target Windows của ứng dụng Flutter trong thư mục `mobile/`  
**Dự án:** `D:\ki8\PRM\Lab1\fapcheckin`

## Mẫu tin nhắn gửi thành viên nhóm

Chào mọi người,

Mình đã rà soát và kiểm tra các API/dịch vụ mà bản desktop Windows của FAP Check-in sử dụng. Kết quả hiện tại như sau:

- Firebase Hosting và Firestore vẫn đang hoạt động bình thường. Firestore Security Rules cũng chặn truy cập chưa đăng nhập đúng như thiết kế.
- Google OAuth và bộ client credentials hiện tại còn hợp lệ.
- Hai API lấy IP chính (`api.ipify.org`, `api64.ipify.org`) và API dự phòng `icanhazip.com` vẫn hoạt động. Riêng `api.ip.sb/json` hiện trả về HTML thay vì JSON nên cần thay hoặc loại bỏ.
- Cloud Function `syncToFap`, là Function mà app desktop thực sự gọi, hiện trả HTTP 404, tức chưa được deploy hoặc đã bị gỡ khỏi project production.
- Cloudinary với cấu hình mặc định trả HTTP 401. Tuy nhiên code hiện tại bỏ qua Cloudinary mặc định và dùng Base64 làm phương án dự phòng.
- Vấn đề lớn nhất là bản Windows chưa được cấu hình trong `firebase_options.dart`. Khi khởi động, app sẽ dừng ở bước `Firebase.initializeApp`, nên chưa thể sử dụng Auth, Firestore, Storage hoặc Remote Config từ giao diện desktop.
- Firebase Messaging và OCR thời khóa biểu không hỗ trợ Windows trong cấu hình hiện tại.

Kết quả test cục bộ:

- Core repository: 49/49 test pass.
- Nhóm test API/model/Cloudinary/Remote Config: 16/16 test pass.
- Firebase Functions: 35/35 test pass. Điều này cho thấy code Function ổn, lỗi chính nằm ở deployment/configuration.
- Toàn bộ Flutter test: 103 test pass, 3 test UI fail do finder dùng index không tồn tại; không liên quan đến API.
- Chưa build được Windows vì máy kiểm tra thiếu CMake C++ compiler.

Đề xuất ưu tiên xử lý:

1. Chạy FlutterFire CLI để bổ sung cấu hình Firebase cho Windows.
2. Deploy lại Function `syncToFap` tại region `asia-southeast1` và cấu hình `FAP_SYNC_URL`, kèm `FAP_SYNC_TOKEN` nếu gateway yêu cầu.
3. Truyền đúng file OAuth bằng `--dart-define-from-file`; hiện file local nằm ở root nhưng tài liệu hướng dẫn chạy từ thư mục `mobile/`.
4. Thay `api.ip.sb/json` bằng một endpoint JSON ổn định hơn.
5. Thêm điều kiện platform để bỏ qua Firebase Messaging trên Windows.

Tóm lại: các dịch vụ Firebase nền tảng và Google OAuth còn hoạt động, nhưng bản desktop hiện chưa chạy được luồng API thực tế do thiếu Firebase Windows configuration; ngoài ra `syncToFap` đang chưa được deploy.

## Bảng kết quả chi tiết

| API/dịch vụ | Trạng thái | Kết quả kiểm tra |
|---|---|---|
| Firebase initialization trên Windows | Không sử dụng được | `firebase_options.dart` ném `UnsupportedError` cho Windows |
| Firebase Hosting/check-in | Hoạt động | HTTP 200, đúng project `ducminh-41459` |
| Firestore | Hoạt động | Endpoint phản hồi; truy cập chưa đăng nhập bị chặn HTTP 403 |
| Firebase Auth qua Google OAuth | Hoạt động có điều kiện | Google endpoints hoạt động; client credentials được chấp nhận |
| Firebase Storage | Chưa kiểm tra E2E | Bị chặn bởi lỗi khởi tạo Firebase desktop và cần phiên đăng nhập |
| Firebase Remote Config | Chưa kiểm tra E2E | Có fallback mặc định; bị chặn bởi cấu hình Firebase Windows |
| Cloud Function `syncToFap` | Không hoạt động | HTTP 404, Function chưa được deploy hoặc không còn tồn tại |
| IP `api.ipify.org` | Hoạt động | HTTP 200, trả JSON hợp lệ |
| IP `api64.ipify.org` | Hoạt động | HTTP 200, trả JSON hợp lệ |
| IP `api.ip.sb/json` | Không tương thích | HTTP 200 nhưng trả HTML thay vì JSON |
| IP `icanhazip.com` | Hoạt động | HTTP 200, trả IP dạng text |
| Cloudinary mặc định | Không hoạt động | HTTP 401 `Unknown API key`; app đang bỏ qua cấu hình mặc định này |
| Firebase Messaging trên Windows | Không hỗ trợ | Không có Windows plugin trong generated registrant |
| OCR thời khóa biểu desktop | Không hỗ trợ | Code chỉ cho phép Android |

## Các Cloud Function không thuộc luồng desktop hiện tại

- `scanTimetable`: trả HTTP 404, nhưng ứng dụng hiện dùng OCR local và OCR chỉ hỗ trợ Android.
- `resolveFeedback`: trả HTTP 404; đây là chức năng dành cho luồng quản trị.
- `getCrashlyticsDashboard`: vẫn được deploy; trả HTTP 401 khi gọi chưa đăng nhập, đúng yêu cầu bảo mật.
- `sendTeachingReminders`: Function chạy theo lịch, không phải API được desktop gọi trực tiếp.

## Vị trí mã nguồn liên quan

- Khởi tạo Firebase: `mobile/lib/main.dart`
- Cấu hình Firebase theo nền tảng: `mobile/lib/firebase_options.dart`
- Google OAuth desktop: `mobile/lib/core/services/desktop_google_auth_io.dart`
- Cấu hình Google OAuth: `mobile/lib/core/config/auth_config.dart`
- Danh sách API lấy IP: `mobile/lib/core/services/ip_service.dart`
- Lời gọi `syncToFap`: `packages/core/lib/repositories/teacher_repository.dart`
- Cloud Functions: `firebase/functions/index.js`
- Cổng đồng bộ FAP: `firebase/functions/src/fap_sync.js`
- Firebase Messaging: `mobile/lib/core/services/push_notification_service.dart`
- OCR theo nền tảng: `mobile/lib/core/services/timetable_ocr_service.dart`

## Lưu ý

- Không có mã nguồn nào của dự án được chỉnh sửa trong quá trình kiểm tra.
- Các file đang thay đổi hoặc chưa commit của thành viên nhóm được giữ nguyên.
- Các request production được giới hạn ở kiểm tra không xác thực hoặc không làm thay đổi dữ liệu.
