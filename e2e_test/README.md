# TV5 QA
## Phần đã chạy được
Tại repo root: node e2e_test/run-regression.mjs
Chạy 3 lượt unit/regression Functions, ghi TAP và JSON vào results. Không cần network hay tài khoản thật. Bộ npm test cũ vẫn giữ nguyên, cần firebase-tools và emulator.

## Android scaffold (chưa đủ điều kiện nghiệm thu)
Có 10 case pytest tham số hóa, dùng Appium UiAutomator2. Đây là phương án tương đương đề xuất, CHƯA có xác nhận giảng viên. Chưa ghi selector thực tế, chưa chạy trên máy Android. Thiếu config sẽ SKIP, không được tính pass.
1. Cài Python 3.12+, uv, Android SDK platform-tools, Java theo phiên bản Firebase tools; cấu hình PATH và chạy adb devices.
2. uv venv --python 3.12; uv pip install -r e2e_test/requirements.txt
3. Cài Appium và driver UiAutomator2 theo tài liệu chính thức, khởi động server.
4. Seed project test, cài APK, xác định native accessibility ID / XPath bằng Appium Inspector. Flutter cần expose Semantics cho các widget quan trọng.
5. Tạo file JSON local theo config.example.json, khai báo đủ 10 flows, mỗi flow tự đưa app về tiền điều kiện và assertion nội dung sau thao tác.
6. PowerShell: $env:ANDROID_E2E_CONFIG='đường-dẫn-tuyệt-đối-config.json'; $env:E2E_RUN_ID='run-1'; uv run pytest -c e2e_test/pytest.ini --junitxml=e2e_test/results/android-run-1.xml
7. Lặp run-2/run-3, reset seed và app, lưu logcat: adb logcat -d > e2e_test/results/android-run-1.log
Screenshot và XML màn hình cuối được lưu theo run ID. Cần bổ sung screenshot ngay lúc fail nếu teardown không đọc được UI; không commit token, tài khoản thật hoặc dữ liệu cá nhân.

## ARTEMIS
Đã xác minh repo chính thức: https://github.com/google/artemis (31/10/2026). README mô tả Android automation và artemis-client qua uv. Chưa cài hoặc xác nhận tương thích Windows/thiết bị ở phiên này; không dựng API giả. Nếu giảng viên bắt buộc ARTEMIS, triển khai adapter theo SDK thực tế và chạy lại 30 lượt. Không tự coi Appium đã được chấp thuận.

## Trợ lý AI (tab AI)
Có thể chạy ngay, không cần thiết bị hay Gemini key: `npm run test:ai` (thư mục e2e_test). Script `run-ai-e2e.mjs` bật Auth+Firestore+Functions emulator, trỏ Cloud Function `aiAssistant` về Gemini giả (`support/fake_gemini.mjs`) rồi chạy `ai_assistant.e2e.test.mjs`: xác thực/phân quyền, kiểm tra đầu vào, định dạng tool_calls, lỗi upstream, rate-limit và Security Rules cho thao tác ghi. Luồng giao diện nằm ở `mobile/test/ai_assistant_flow_test.dart` (flutter test). Xem `docs/ai-assistant.md`.
