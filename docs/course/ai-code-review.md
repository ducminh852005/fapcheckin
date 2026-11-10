# AI-assisted code review — TV5
Ngày review: 31/10/2026; cập nhật kết quả: 02/11/2026. Công cụ: Codex, đọc source và viết regression test. Baseline: 88cfbe8 (dev). Branch sửa lỗi: `feature/qa-testing`. Không chạy Copilot/CodeRabbit/SonarCloud, không giả định các công cụ đó đã xác nhận.

| ID | Vị trí | Nhóm / mức độ | Phát hiện và tác động | Quyết định / lý do |
|---|---|---|---|---|
| CR-01 | firebase/functions/src/notify.js: STALE_TOKEN_CODES | Bug / Medium | invalid-argument có thể do payload, xóa token làm thiết bị mất push | Accept, đã bỏ mã lỗi chung khỏi danh sách xóa. Test payload lỗi vẫn giữ token |
| CR-02 | firebase/functions/src/notify.js: pushToUser | Bug / Medium | Gửi toàn bộ token một lần vượt giới hạn multicast 500, làm hỏng cả lượt gửi | Accept, đã chia chunk 500, test 501 token và ánh xạ token stale ở chunk thứ hai |
| CR-03 | firebase/functions/src/scan.js: runScan | Security / Medium | Metadata size không hợp lệ vượt qua so sánh; buffer tải xuống chưa kiểm tra giới hạn trước OCR | Accept, đã kiểm tra size là số nguyên dương ≤10 MB; đọc stream và hủy khi vượt giới hạn trước OCR. Đọc/xóa đúng generation đã kiểm tra, không tác động file thay thế; từ chối metadata thiếu generation hợp lệ |
| CR-04 | mobile/lib/core/services/remote_settings.dart: load | Bug / Medium | Getter nằm ngoài try, lỗi SDK khi setDefaults thất bại vẫn có thể thoát ra thay vì dùng default | Accept, đã đưa cả khởi tạo FirebaseRemoteConfig.instance, cấu hình, fetch và đọc giá trị vào vùng fallback; regression xác nhận các nhánh lỗi đều trả mặc định an toàn |
| CR-05 | firebase/functions/src/fap_sync.js: fetchImpl | Reliability / Medium | HTTP không có timeout, gateway treo giữ callable đến timeout nền tảng | Accept, đã thêm AbortController/AbortSignal hủy request sau 15 giây, trả deadline-exceeded / UPSTREAM_TIMEOUT và không đánh dấu đã đồng bộ khi timeout; timer được dọn khi request kết thúc |
| CR-06 | firebase/functions/src/notify.js: token cleanup | Bug / Low | removed tăng dù delete thất bại, số liệu giám sát sai | Accept, đã tăng sau delete thành công và log lỗi. Regression mô phỏng delete offline |

## Minh chứng
- firebase/functions/test/notify-review.test.js: token invalid-argument, 501 token, delete failure.
- firebase/functions/test/timetable.test.js: metadata lỗi, stream vượt giới hạn bị hủy sớm, đúng ngưỡng 10 MB, stream rỗng/lỗi, generation không hợp lệ và file bị thay thế; xác nhận OCR không được gọi khi dữ liệu lỗi và cleanup chỉ xóa phiên bản đã kiểm tra.
- mobile/test/core/services/remote_settings_test.dart: giá trị remote thành công và các nhánh fallback CR-04 (Firebase chưa khởi tạo, setDefaults, setConfigSettings, fetch và getter).
- e2e_test/results/functions-run-{1,2,3}.tap: kết quả thực.
- Ba lượt regression sau sửa: 26/26 mỗi lượt. Không phải Android E2E.
- Flutter regression CR-04: 3/3 pass ngày 01/11/2026.
- firebase/functions/test/fap_sync.test.js: gateway treo bị hủy đúng hạn, không ghi trạng thái đồng bộ khi thất bại, giữ nguyên lỗi HTTP/network và dọn timer cả khi thành công lẫn thất bại.
- Ngày 02/11/2026: `npm.cmd test` tại `firebase/functions` đạt 28/28 trên Node v24.11.1; chưa chạy lại Flutter hoặc Android E2E trong lượt sửa CR-05.
- Kiểm tra lại toàn bộ review ngày 02/11/2026: Functions đạt 32/32; Flutter Remote Config đạt 6/6 bằng `flutter_tools.snapshot test --no-pub test/core/services/remote_settings_test.dart` (gọi trực tiếp SDK do launcher bị chặn quyền cache). Chưa chạy Android E2E hoặc kiểm thử tích hợp trên Cloud Storage thật.

## Commits sửa finding
1. `4b73278` — `fix(review): resolve CR-03 OCR image size validation`.
2. `6c5cf6c` — `fix(review): resolve CR-01 CR-02 CR-06 notification reliability`.
3. `9e0c46a` — `fix(review): resolve CR-04 Remote Config fallback`.

Đã đối chiếu CR-01 đến CR-06 với code hiện tại và kiểm chứng bằng regression test. Đã bổ sung phần hardening CR-03 và fallback khởi tạo SDK của CR-04; không còn mục review mở trong phạm vi tài liệu này. Các thay đổi mới chưa tạo commit.
