# Báo cáo kiểm thử TV5
Ngày bắt đầu: 31/10/2026; cập nhật: 01/11/2026. Source baseline `88cfbe8`, branch `feature/qa-testing`. Tại thời điểm bắt đầu, `dev` và `origin/dev` local cùng hash; chưa fetch nên không khẳng định remote mới nhất.

## Môi trường và phạm vi
Windows PowerShell, Node có sẵn, Java 17. Python trong PATH là WindowsApps alias không chạy được. `uv`, ADB và firebase-tools không tìm thấy trong PATH. Flutter 3.47.3, Dart 3.13.3; Flutter doctor không tìm thấy Android SDK. Chưa xác nhận thiết bị Android hay Firebase credentials.
Đã đọc README, Functions, test cũ, AuthViewModel, RemoteSettings, module export. Web Admin được README mô tả prototype. OCR source hiện dùng Cloud Vision, không phải Gemini. Không mô tả cross-role approval hoặc Gemini fallback là đã hoạt động.

## Kết quả thực tế
| Bộ test | Lượt 1 | Lượt 2 | Lượt 3 | Tổng |
|---|---|---|---|---|
| Functions unit/regression | 26 pass, 0 fail | 26 pass, 0 fail | 26 pass, 0 fail | 78 pass / 78 |
| Remote Config CR-04 | 3 pass, 0 fail | Chưa lặp | Chưa lặp | 3 pass / 3 |
Pass rate unit/regression = 78 / 78 × 100% = 100%. Baseline trước sửa: 22/22 pass. Log: e2e_test/results/functions-run-1.tap đến functions-run-3.tap; summary JSON cùng thư mục.
Flutter regression CR-04 đạt 3/3 trong một lượt. Đây là kiểm tra bổ sung cho finding, không được cộng vào 30 lượt Android E2E.
Android E2E: 0 lượt chạy, pass rate N/A. Không dùng 78 unit test để thay yêu cầu 30 Android E2E.
10 test case có bước, dữ liệu, expected trong test-cases.md. Android runner là scaffold cần mapping selector thật, tài khoản và seed. TC08 có thể blocked bởi trạng thái Web Admin. TC07 phải xác nhận định dạng xuất thực tế, chưa khẳng định PDF.

## Bugs và regression
Xem ai-code-review.md: CR-01, CR-02, CR-03, CR-04 và CR-06 đã sửa, có regression và được lưu trong ba commit riêng. CR-05 còn mở. Đã chạy Flutter test riêng cho CR-04; chưa chạy toàn bộ Flutter analyze/test hoặc Firebase Rules/SDK E2E vì toolchain Android và Firebase chưa hoàn chỉnh.

## Exploratory
Chưa thực hiện phiên tương tác 15–30 phút. Static review không được tính exploratory.
Charter đề xuất 20 phút: 0–5 phút login/role/cancel; 5–10 phút mở/đóng/QR hết hạn; 10–15 phút offline, empty và retry; 15–20 phút export, thông báo và đổi tài khoản. Ghi start/end, device/build, từng thao tác, kết quả, screenshot và bug ID.

## Đánh giá và phần còn thiếu
Chưa đạt Definition of Done. Đã có branch và ba commit sửa finding. Còn cần Android chạy thật 10 case ×3, exploratory, commit bộ QA/tài liệu, final report PDF theo mẫu trường, slide PDF và video 8–12 phút. Chưa nhận mẫu trường hoặc minh chứng từ TV1–TV4. Không tạo video/link/số liệu giả.
