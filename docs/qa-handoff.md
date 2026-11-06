# QA handoff – tiếp tục công việc TV5

Ngày chốt trạng thái: **01/11/2026**
Branch: **`feature/qa-testing`**
Remote: **`origin/feature/qa-testing`**
HEAD khi tạo handoff: **`f1355e8`** – `test(qa): finalize Android E2E runner configuration`

Tài liệu này là điểm bắt đầu khi tiếp tục QA sau khi TV1–TV4 sửa Mobile/Firebase/Web. Không dùng nội dung trò chuyện cũ làm nguồn duy nhất; ưu tiên source, Git history và các file kết quả được liệt kê bên dưới.

## 1. Trạng thái ngắn gọn

- Android E2E đã thực thi: **25/30 lượt**.
- Kết quả trên số lượt đã chạy: **17 pass, 8 fail – 68%**.
- Functions regression: **78/78 pass** qua ba lượt.
- Remote Config regression: **3/3 pass**.
- Exploratory: **15,1 phút**, 14 chu kỳ, không crash.
- AI code review: **6 findings**; CR-01, CR-02, CR-03, CR-04, CR-06 đã sửa; CR-05 chưa sửa.
- Final Report: **12 trang**, đã commit; còn placeholder bìa và cần cập nhật sau regression cuối.
- Slide: **chưa làm**.
- Video: đã loại khỏi phạm vi TV5 theo quyết định hiện tại; cần xác nhận lại với rubric/nhóm.

## 2. Các phần đã hoàn thành

### Toolchain và test assets

- Python 3.12.16 qua `uv`.
- Flutter 3.47.3, Dart 3.13.3, Android SDK 36.
- Emulator `emulator-5554`, Android 16 API 36.
- Appium 3.9.0, UiAutomator2 8.7.3.
- `e2e_test/` có runner, README, config mẫu, test cases và summary.
- Tài khoản staff và role không hợp lệ đã từng được cấu hình local; không lưu email trong repository.

### Tài liệu và báo cáo

- `docs/test-cases.md` – 10 test case.
- `docs/test-report.md` – kết quả, defects, exploratory.
- `docs/ai-code-review.md` – 6 findings và quyết định kỹ thuật.
- `e2e_test/results/android-summary.json` – dữ liệu tổng hợp 25 lượt.
- `docs/final-report-source.md` – nguồn báo cáo.
- `docs/final-report.pdf` – Final Report 12 trang.
- `scripts/generate_final_report.py` – tạo lại PDF.

### Commit quan trọng

- `4b73278` – sửa CR-03 OCR image size validation.
- `6c5cf6c` – sửa CR-01, CR-02, CR-06 notification reliability.
- `9e0c46a` – sửa CR-04 Remote Config fallback.
- `88f3348` – Android E2E scaffold và regression evidence.
- `d9cae28` – AI review, test plan và tài liệu ban đầu.
- `a18bbb8` – kết quả Android E2E.
- `e9741f9` – exploratory testing.
- `ca609e0` – Final Report PDF.
- `f1355e8` – hoàn thiện Android E2E runner configuration.

## 3. Ma trận Android hiện tại

| Case | Kết quả hiện tại | Việc còn lại |
|---|---|---|
| TC01 Google Sign-In | 3/3 pass | Chỉ rerun nếu auth bị sửa |
| TC02 role không hợp lệ | 3/3 pass | Chỉ rerun nếu auth/RBAC bị sửa |
| TC03 tạo/đóng phiên | 0/1, fail | Cần thêm 2 lượt sau khi TV1/TV2 sửa; nên chạy lại đủ 3 lượt nếu logic thay đổi lớn |
| TC04 hiển thị QR | 3/3 UI pass, overall partial | Thiếu student device/account để kiểm QR cũ bị từ chối và QR mới được chấp nhận |
| TC05 lịch sử | 3/3 basic pass, partial | Thiếu lớp của giảng viên khác để kiểm isolation |
| TC06 lọc môn/lớp | 3/3 pass | Rerun nếu lịch sử/repository bị sửa |
| TC07 export XLSX | 0/3, fail | Rerun sau khi TV2 chuyển sang share sheet/SAF/MediaStore |
| TC08 request pending | 0 lượt, blocked | Cần mobile request UI + Web Admin Review Queue nối Firebase; sau đó chạy 3 lượt |
| TC09 empty/offline | 0/3, fail | Empty state pass; offline feedback/retry fail. Rerun sau khi TV2 sửa |
| TC10 native popup | 2/3 pass | Rerun allow notification sau khi Rules/device registration được sửa |

Năm lượt còn thiếu để đạt 30 là **2 lượt TC03** và **3 lượt TC08**. Không tạo request trực tiếp bằng Firebase Console rồi tính là E2E pass.

## 4. Defects cần thành viên khác xử lý

### TV1 – Firebase / Security Rules / dữ liệu

1. **DEF-TC03-01 – High:** đóng phiên bị `PERMISSION_DENIED` khi ghi `attendance_records/{sessionId}_{rollNumber}`.
   - Kiểm tra document ID thực tế của `enrollments/{classCode}_{rollNumber}`.
   - Kiểm tra profile staff đang active và Rules đang deploy có khớp repository.
   - Batch đóng session + tạo Absent bị rollback toàn bộ khi một record bị từ chối.
2. **DEF-TC10-01 – Medium:** Android đã cấp `POST_NOTIFICATIONS`, nhưng ghi `device_tokens/{uid}/tokens/{id}` hoặc preferences trả lỗi quyền.
   - Đối chiếu Rules deploy cho `device_tokens` và `user_preferences`.

### TV2 – Flutter Mobile

1. **DEF-TC03-02 – High:** `LiveSessionViewModel.session` giữ trạng thái open cũ sau khi Firestore thay đổi; chỉ hết sau restart.
2. **DEF-TC07-01 – Medium:** XLSX nằm trong app-private `code_cache`; cần URI người dùng có thể mở/chia sẻ.
3. **DEF-TC09-01 – Medium:** offline không có banner/error/retry; cần phân biệt empty thật với lỗi mạng.
4. **DEF-EXP-01 – Medium:** Back hệ thống từ Live QR hoặc chi tiết lớp thoát thẳng ra Launcher; cần `PopScope`/route cha.

### TV3 – Web Admin / cross-role

- TC08 cần form/listener mobile cho `attendance_fix`/`leave` và Review Queue approve/reject kết nối Firebase.
- Web Admin hiện là prototype; không ghi nhận cross-role là đã hoàn thành trước khi có UI và dữ liệu realtime thật.

### TV4 – OCR / AI / Remote Config

- Remote Config fallback đã có regression.
- Implementation OCR hiện dùng Cloud Vision, chưa phải Gemini. Cần thống nhất cách mô tả và minh chứng trước khi nộp.
- CR-05 trong `firebase/functions/src/fap_sync.js` còn thiếu HTTP timeout và regression gateway chậm.

## 5. Khởi động lại môi trường trong lần làm tiếp theo

### Terminal 1 – Appium

```bat
set ANDROID_HOME=C:\Users\ASUS\AppData\Local\Android\Sdk
set JAVA_HOME=C:\Program Files\Android\Android Studio\jbr
appium
```

### Terminal 2 – xác minh emulator và server

```bat
"C:\Users\ASUS\AppData\Local\Android\Sdk\platform-tools\adb.exe" devices
curl http://127.0.0.1:4723/status
```

Kết quả cần có `emulator-5554 device` và Appium `"ready": true`.

Mở ứng dụng mà không xóa đăng nhập:

```bat
"C:\Users\ASUS\AppData\Local\Android\Sdk\platform-tools\adb.exe" shell monkey -p com.example.fapcheckin -c android.intent.category.LAUNCHER 1
```

Không chạy `pm clear` trừ TC01, TC02 hoặc test popup cần trạng thái cài mới.

### Biến môi trường E2E

```bat
cd /d D:\ki8\PRM\Lab1\fapcheckin
set ANDROID_E2E_CONFIG=D:\ki8\PRM\Lab1\fapcheckin\e2e_test\config.local.json
set E2E_RUN_ID=local-regression
```

Email test nằm trong `e2e_test/.env.local` và không được commit.

Smoke kiểm tra runner:

```bat
e2e_test\.venv\Scripts\python.exe -m pytest -c e2e_test\pytest.ini --collect-only -q
```

## 6. Quy trình sau khi nhận bản sửa

1. Ghi hash/branch của bản sửa từ thành viên phụ trách.
2. Đồng bộ code theo quy trình Git của nhóm; không rebase branch đã chia sẻ nếu chưa thống nhất.
3. Xác nhận emulator online và app đăng nhập được.
4. Dọn session test đang open trên Firebase nếu cần; ghi rõ ai dọn và document nào.
5. Chạy case liên quan tối thiểu ba lượt độc lập sau bản sửa.
6. Lưu screenshot/XML/logcat raw vào thư mục Git-ignore; summary không chứa PII.
7. Cập nhật:
   - `e2e_test/results/android-summary.json`;
   - `docs/test-report.md`;
   - `docs/final-report-source.md`, đặc biệt trang kết quả và hạn chế.
8. Tạo lại PDF:

```bat
uv run --with reportlab python scripts\generate_final_report.py
```

9. Kiểm tra PDF vẫn 10–15 trang và không bị cắt bảng/chữ.
10. Commit regression riêng, có bug ID hoặc case ID trong message.

## 7. Tiêu chí đóng các case phụ thuộc

### TC03

- Giảng viên tạo được phiên.
- Live QR hiển thị.
- Đóng phiên không bị `PERMISSION_DENIED`.
- Absent records được tạo đúng và session chuyển `closed`.
- Dashboard, lịch sử và màn quản lý đồng bộ mà không force-stop.
- Đạt ba lượt liên tiếp trên dữ liệu seed rõ ràng.

### TC08

- Tài khoản có quyền tạo request từ UI.
- Document được tạo với `status = pending` và đúng author.
- Admin thấy request bằng Review Queue thật.
- Approve/Reject cập nhật Firestore đúng quyền.
- Mobile nhận trạng thái mới mà không cần sửa Console.
- Đạt ba lượt độc lập.

### TC07 / TC09 / TC10 / DEF-EXP-01

- TC07: file xuất mở hoặc chia sẻ được bằng URI ngoài app-private storage.
- TC09: offline có thông báo và retry; bật mạng khôi phục được.
- TC10: Allow notification làm reminder bật và đăng ký token thành công.
- Back: màn con quay về route cha; chỉ route gốc mới thoát app.

## 8. Công việc TV5 còn lại

- Điền 5 placeholder bìa trong `docs/final-report-source.md`: trường, nhóm, lớp, giảng viên, thành viên.
- Nhận screenshot/nội dung đã loại PII từ TV1–TV4 và bổ sung vào Final Report nếu rubric yêu cầu.
- Làm slide PDF 12–15 trang sau khi nội dung cuối ổn định.
- Chạy regression sau bản sửa và đóng đủ 30 lượt nếu dependency được cung cấp.
- Xác nhận chính thức việc bỏ video với nhóm/giảng viên.
- Tạo Pull Request `feature/qa-testing` → `dev` và chỉ merge sau review.

## 9. File không được commit nhầm

- `mobile/android/app/google-services.json` nếu chỉ là cấu hình Firebase local đã thay đổi.
- `e2e_test/config.local.json`.
- `e2e_test/.env.local`.
- Raw XML/screenshot/logcat chứa email, tên hoặc mã sinh viên.
- Generated plugin files do `flutter pub get` tạo lại nếu không có thay đổi dependency chủ đích.

Trước mỗi commit, luôn chạy:

```bat
git status --short
git diff --cached --name-only
git diff --cached --check
```

## 10. Điểm tiếp tục nhanh

Khi nhóm báo đã sửa, bắt đầu bằng câu:

> Đọc `docs/qa-handoff.md`, kiểm tra commit mới của TV1–TV4, rồi chạy regression cho defect/case tương ứng. Không chạy lại toàn bộ nếu code không liên quan; ưu tiên TC03 và TC08 để hoàn thành 30 lượt.
