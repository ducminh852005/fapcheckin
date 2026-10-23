# fapcheckin_core

Mã dùng chung của FAP Check-in (Dart/Flutter): dùng bởi app giảng viên [`mobile/`](../../mobile) và sắp tới bởi Web Admin ([`web/admin/`](../../web/admin)).

| Thư mục `lib/` | Nội dung |
|---|---|
| `models/` | Model dữ liệu (`UserModel`, `SessionModel`, `ClassSectionModel`, …) — `fromJson` và `fromFirestore` |
| `repositories/` | Repository đọc/ghi Cloud Firestore (+ Auth, Storage, Functions); trả `ApiResult<T>` |
| `result/` | `ApiResult` / `ApiSuccess` / `ApiFailure`, `guardApi`, `ApiException` |
| `session/` | `CurrentUser` — hồ sơ đang đăng nhập (cung cấp `memberCode` cho Repository) |
| `firebase/` | Đổi `Timestamp` ↔ JSON, ngày giờ theo giờ Việt Nam |
| `theme/`, `constants/`, `responsive/` | Design system (màu, typography, breakpoint, khung dialog) |
| `utils/` | Chuẩn hóa JSON, xuất `.xlsx` |

Import bằng `package:fapcheckin_core/<đường dẫn dưới lib/>`. Mô tả Repository: [docs/09](../../docs/09-repository-api.md).

```bash
flutter pub get
flutter analyze
flutter test        # fake_cloud_firestore — không cần Emulator
```

> `pubspec.yaml` ghim `cloud_firestore` 7.0.0 trong `dependency_overrides` chỉ để `fake_cloud_firestore` 4.4.0 biên dịch được; override không ảnh hưởng app `mobile/`. Bỏ khi `fake_cloud_firestore` hỗ trợ `cloud_firestore_platform_interface` 8.1.
