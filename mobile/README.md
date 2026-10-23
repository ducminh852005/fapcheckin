# mobile — App Giảng viên

App Flutter (MVVM) dành cho giảng viên (`staff`): mở phiên điểm danh bằng QR xoay 60 giây, roster, lịch sử, báo cáo, lịch học bù, import thời khóa biểu. Dữ liệu và xác thực dùng thẳng Firebase qua [`packages/core`](../packages/core).

```bash
flutterfire configure --project=fapcheckin-3bn2di   # một lần: sinh lib/firebase_options.dart, google-services.json
flutter pub get
flutter run -d <device-id>
flutter test
```

Hướng dẫn đầy đủ (đăng nhập Google/SHA-1, build, lỗi thường gặp): [docs/quick-start-mobile.md](../docs/quick-start-mobile.md). Kiến trúc: [docs/04](../docs/04-kien-truc-app-va-web.md).
