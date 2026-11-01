# AI-assisted code review — TV5
Ngày review: 31/10/2026; cập nhật kết quả: 01/11/2026. Công cụ: Codex, đọc source và viết regression test. Baseline: 88cfbe8 (dev). Branch sửa lỗi: `feature/qa-testing`. Không chạy Copilot/CodeRabbit/SonarCloud, không giả định các công cụ đó đã xác nhận.

| ID | Vị trí | Nhóm / mức độ | Phát hiện và tác động | Quyết định / lý do |
|---|---|---|---|---|
| CR-01 | firebase/functions/src/notify.js: STALE_TOKEN_CODES | Bug / Medium | invalid-argument có thể do payload, xóa token làm thiết bị mất push | Accept, đã bỏ mã lỗi chung khỏi danh sách xóa. Test payload lỗi vẫn giữ token |
| CR-02 | firebase/functions/src/notify.js: pushToUser | Bug / Medium | Gửi toàn bộ token một lần vượt giới hạn multicast 500, làm hỏng cả lượt gửi | Accept, đã chia chunk 500, test 501 token và ánh xạ token stale ở chunk thứ hai |
| CR-03 | firebase/functions/src/scan.js: runScan | Security / Medium | Metadata size không hợp lệ vượt qua so sánh; buffer tải xuống chưa kiểm tra giới hạn trước OCR | Modify, đã chặn metadata không hữu hạn/không dương và buffer >10 MB. Chưa giải quyết bộ nhớ tải ảnh bằng stream; cần generation precondition/stream limit cho hardening |
| CR-04 | mobile/lib/core/services/remote_settings.dart: load | Bug / Medium | Getter nằm ngoài try, lỗi SDK khi setDefaults thất bại vẫn có thể thoát ra thay vì dùng default | Accept, đã đưa toàn bộ cấu hình, fetch và đọc giá trị vào vùng fallback; test Flutter xác nhận lỗi cấu hình hoặc getter đều trả về mặc định an toàn |
| CR-05 | firebase/functions/src/fap_sync.js: fetchImpl | Reliability / Medium | HTTP không có timeout, gateway treo giữ callable đến timeout nền tảng | Accept / chưa sửa, cần AbortSignal và test gateway timeout |
| CR-06 | firebase/functions/src/notify.js: token cleanup | Bug / Low | removed tăng dù delete thất bại, số liệu giám sát sai | Accept, đã tăng sau delete thành công và log lỗi. Regression mô phỏng delete offline |

## Minh chứng
- firebase/functions/test/notify-review.test.js: token invalid-argument, 501 token, delete failure.
- firebase/functions/test/timetable.test.js: metadata lỗi và buffer lớn, xác nhận OCR không được gọi và file tạm được dọn.
- mobile/test/core/services/remote_settings_test.dart: giá trị remote thành công và hai nhánh fallback CR-04.
- e2e_test/results/functions-run-{1,2,3}.tap: kết quả thực.
- Ba lượt regression sau sửa: 26/26 mỗi lượt. Không phải Android E2E.
- Flutter regression CR-04: 3/3 pass ngày 01/11/2026.

## Commits sửa finding
1. `4b73278` — `fix(review): resolve CR-03 OCR image size validation`.
2. `6c5cf6c` — `fix(review): resolve CR-01 CR-02 CR-06 notification reliability`.
3. `9e0c46a` — `fix(review): resolve CR-04 Remote Config fallback`.

CR-05 vẫn mở. Cần bổ sung timeout bằng `AbortSignal` và regression test trước khi chấp nhận bản sửa.
