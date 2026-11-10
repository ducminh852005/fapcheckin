[← Tài liệu môn học](README.md) · [Mục lục kỹ thuật](../README.md)

# Gap review — khoảng cách giữa Lab 2/3 và bản Final

Đánh giá tại **28/10/2026**, nhánh `architecture-be`. Cột "Trạng thái" lấy từ việc đọc mã nguồn và `pubspec.yaml`, không phải từ lần chạy thử thiết bị thật.

## 1. Đã đạt

| Hạng mục | Lab 2/3 | Bản hiện tại |
|---|---|---|
| Backend | Google Apps Script + Google Sheet | Cloud Firestore, app và web đọc/ghi trực tiếp bằng Firebase SDK |
| Xác thực | Tự quản lý | Firebase Auth (Google), role `user`/`staff`/`admin` ở `users/{uid}.role` |
| Phân quyền | Kiểm tra ở script | Security Rules deny-by-default, 12 collection, có test trên Emulator ([08](../08-security-rules.md)) |
| Cấu trúc mã | Một app | Monorepo `mobile/`, `packages/core/`, `web/`, `firebase/`, `e2e_test/`, `docs/` ([04](../04-kien-truc-app-va-web.md)) |
| Cấu hình Firebase | — | `firebase.json` có Firestore, Hosting, Storage, Remote Config, Functions, Emulators |
| Schema | Bảng Sheet | 12 collection, có index, seed script và script migrate dữ liệu cũ ([data-model](../data-model.md), [03](../03-du-lieu-firestore.md)) |
| Cross-role | — | Collection `requests` và `announcements` đã có schema, Rules và test |
| CI | — | `.github/workflows/ci.yml` chạy Rules, Functions, e2e trên Emulator |

## 2. Còn thiếu hoặc lệch so với yêu cầu Final

| # | Khoảng cách | Mức | Ghi chú |
|---|---|---|---|
| 1 | **Web Admin mới là UI prototype dùng dữ liệu mẫu**, viết bằng React + Vite, chưa nối Firebase Auth/Firestore | Cao | Đề bài mô tả Flutter Web dùng chung `packages/core` (`docs/text.md`). Cần quyết định giữ React hay đổi, rồi nối `requests`, `announcements`, `classes`. |
| 2 | **Firebase App Check chưa tích hợp** | Trung bình | Không thấy `firebase_app_check` trong `pubspec.yaml` và không có mã App Check ở web. Nằm trong phạm vi vai trò Lead Backend. |
| 3 | **FCM / Inbox chưa có** | Trung bình | Không có `firebase_messaging`. `announcements` đã có sẵn Rules, chưa có màn hình Inbox phía mobile. |
| 4 | **Tính năng Gemini (Structured Output) chưa có** | Trung bình | Không thấy `firebase_ai`/`google_generative_ai`. Remote Config đã có trong `mobile/pubspec.yaml` để gắn cờ bật/tắt. |
| 5 | Đồng bộ FAP chỉ là stub | Thấp | `teacher_repository.dart` chỉ đặt `syncedToFap = true`; chờ API từ nhà trường ([06](../06-rui-ro-va-mo-rong.md)). |
| 6 | Cấu hình Firebase cho iOS chưa có | Thấp | Chưa có `GoogleService-Info.plist`; FlutterFire hiện chỉ có Android và web. |
| 7 | Kiểm tra IP do client gửi lên nên có thể bị khai giả | Thấp | Giới hạn đã chấp nhận, hướng xử lý (callable function) ở [06](../06-rui-ro-va-mo-rong.md#hướng-mở-rộng). |
| 8 | Báo cáo/thống kê tính ở client | Thấp | Đủ cho quy mô đồ án; Dashboard Admin cần truy vấn aggregation. |
| 9 | `UserModel` (Dart) chưa có `active`/`createdAt` dù `toFirestore()` ghi hai trường này | Thấp | Đã bổ sung cùng đợt cập nhật tài liệu này. |
| 10 | Tên role trong Dart là chuỗi tự do (`isTeacher` chấp nhận nhiều biến thể) | Thấp | Rules chỉ nhận `user`/`staff`/`admin`; có thể chuẩn hóa thành enum sau. |

## 3. Việc cần người phụ trách xác nhận

- Email admin đầu tiên trong [README](../../README.md#tài-khoản-admin-đầu-tiên) còn để trống.
- Hướng công nghệ cho Web Admin (xem mục 1 ở bảng trên).

## 4. Ghi chú

- Thang điểm và phân công nằm ở [`text.md`](text.md). Các mục 3 và 4 ở bảng trên thuộc phần việc của thành viên khác, được ghi lại ở đây để theo dõi, không thuộc phạm vi Lead Backend.
- Số lượng test (77) lấy từ tài liệu hiện có; chạy `cd firebase && npm test` để xác nhận lại.
