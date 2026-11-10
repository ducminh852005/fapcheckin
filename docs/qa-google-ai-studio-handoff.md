# QA handoff – tiếp tục kiểm thử bằng Google AI Studio

Ngày cập nhật: **09/11/2026**  
Repository: `D:\ki8\PRM\Lab1\fapcheckin`  
Branch hiện tại: **`feature/qa-testing`**  
HEAD đã kiểm tra: **`41d7413` – `docs(qa): expand Firebase setup and Android test coverage`**

## 1. Câu lệnh bắt đầu ở cửa sổ mới

> Đọc `docs/qa-google-ai-studio-handoff.md`, kiểm tra Git status, sau đó tiếp tục QA từ mục 8. Ưu tiên kiểm tra model và phân tích evidence trong Google AI Studio trước khi gọi API/ARTEMIS. Không chạy lặp ARTEMIS khi model đang trả 429, 503 hoặc 504. Không sửa code Mobile/Firebase vì phần đó thuộc thành viên khác.

## 2. Phạm vi công việc của TV5

- Thiết kế và quản lý test case.
- Chạy Android E2E/regression và lưu evidence.
- Tổng hợp defect để gửi thành viên phụ trách sửa.
- Cập nhật test report, handoff và Final Report.
- Không tự sửa nghiệp vụ Mobile, Firebase Rules hoặc Web Admin nếu chưa được nhóm giao.
- Khi code mới được merge từ `dev`, chỉ rerun các case liên quan tới phần sửa.

## 3. Trạng thái repository cần giữ nguyên

Tại thời điểm tạo file này, working tree có các thay đổi local sau:

```text
M mobile/android/app/google-services.json
M mobile/linux/flutter/generated_plugin_registrant.cc
M mobile/linux/flutter/generated_plugin_registrant.h
M mobile/linux/flutter/generated_plugins.cmake
M mobile/macos/Flutter/GeneratedPluginRegistrant.swift
M mobile/windows/flutter/generated_plugin_registrant.cc
M mobile/windows/flutter/generated_plugin_registrant.h
M mobile/windows/flutter/generated_plugins.cmake
```

Không stage hoặc commit các file trên nếu chưa xác định chúng là thay đổi chủ đích. Đặc biệt, `google-services.json` có thể là cấu hình Firebase local.

Trước mọi commit:

```bat
git status --short
git diff --cached --name-only
git diff --cached --check
```

## 4. Kết quả QA đã có

### Android/Appium

- Đã thực thi **25/30 lượt** trong phạm vi TC01–TC10.
- Kết quả đã chạy: **17 pass, 8 fail – 68%**.
- TC01 Google Sign-In: 3/3 pass.
- TC02 role không hợp lệ: 3/3 pass.
- TC03 tạo/đóng phiên: tạo và hiển thị QR được; đóng phiên fail do Firestore `PERMISSION_DENIED` và stale session state.
- TC04 hiển thị QR: 3/3 UI pass; còn thiếu thiết bị/tài khoản sinh viên để kiểm QR cũ/mới.
- TC05 lịch sử cơ bản: 3/3 pass; còn thiếu kiểm isolation giữa giảng viên.
- TC06 lọc môn/lớp: 3/3 pass.
- TC07 export XLSX: 0/3; file nằm trong app-private `code_cache`.
- TC08 request pending: blocked vì chưa có flow Mobile + Web Admin thật.
- TC09 empty/offline: empty pass, offline feedback/retry fail 3/3.
- TC10 native popup: 2/3 pass; notification allow bị lỗi quyền backend.

### Backend/regression

- Functions regression: **78/78 pass** qua ba lượt.
- Remote Config regression: **3/3 pass**.
- Exploratory: **15,1 phút**, 14 chu kỳ, không crash.
- Bộ test đã mở rộng thành **30 Test Case** trong `docs/test-cases.md`.
- TC11–TC30 mới là thiết kế coverage; chưa được đánh dấu Pass nếu chưa chạy thực tế.

### Báo cáo/evidence chính

- `docs/test-cases.md`
- `docs/test-report.md`
- `docs/ai-code-review.md`
- `docs/defect-fix-request.md`
- `docs/qa-handoff.md`
- `docs/final-report-source.md`
- `docs/final-report.pdf`
- `e2e_test/results/android-summary.json`
- `e2e_test/results/regression-summary.json`

## 5. Defect còn phụ thuộc thành viên khác

| Test Case | Defect/trạng thái | Cần thành viên khác xử lý |
|---|---|---|
| TC03 | Đóng phiên bị `PERMISSION_DENIED`; UI giữ session open cũ | Firebase Rules/dữ liệu enrollment và Mobile state sync |
| TC07 | XLSX chỉ nằm trong private cache | Mobile share sheet/SAF/MediaStore |
| TC08 | Chưa có flow request pending end-to-end | Mobile request UI + Web Admin Review Queue + Firebase |
| TC09 | Offline không có banner/error/retry | Mobile error/offline state |
| TC10 | Allow notification nhưng đăng ký token/preferences bị từ chối | Firebase Rules/device token flow |
| TC30 / DEF-EXP-01 | Back từ màn con thoát thẳng Launcher | Mobile navigation/PopScope |

Không tính thao tác sửa trực tiếp trên Firebase Console là một lượt E2E pass.

## 6. Trạng thái thiết bị và công cụ

- Thiết bị thật: `2dd833e1` – Xiaomi `2312DRA50I`, Android 14 API 34.
- Package: `com.example.fapcheckin`.
- Flutter 3.47.3; Dart 3.13.3; Android SDK 36.
- Appium 3.9.0; UiAutomator2 8.7.3.
- ARTEMIS tại `D:\tools\artemis`.
- ARTEMIS Accessibility Helper: v1.2.0/code 6; Xiaomi có thể tạm suppress service hoặc làm mất session token, khi đó ARTEMIS fallback sang UIAutomator2.
- Gemini key không được lưu trong repository hoặc đưa vào chat/video.

## 7. Kết quả thử ARTEMIS và nguyên nhân chưa hoàn thành

ARTEMIS đã kết nối MCP, mở được app, đọc được Dashboard và từng phát action tap `Quản lý lớp`. Tuy nhiên chưa có một lượt ARTEMIS hoàn chỉnh vì dịch vụ Gemini không ổn định.

| Trace | Model/kết quả chính |
|---|---|
| `823638f2-b777-453a-9ccf-15b137bddfd7` | `gemini-3.8-flash`; quota 429, không hoàn thành |
| `e4526e76-bdac-4934-8c88-c30fdf76a9b2` | Có Step 1 tap `Quản lý lớp`; sau đó 503/504, kết quả partial |
| `027f7ef6-4dae-4b8e-98b9-f8b125b8a533` | 503/504 ngay lượt đầu |
| `a5b3e058-a219-4458-a344-99c5bf244e65` | 429 free-tier 20 request/ngày |
| `23824d7b-158e-46d4-87eb-60e0a3ccca6d` | Key khác nhưng vẫn dùng quota/project đã cạn; 429 |
| `1cd2d7d3-a495-490a-8295-1af214fac246` | LLM timeout, không có action |
| `32341f65-c253-4077-b3aa-4efef66177ff` | `gemini-2.5-flash` trả 404, không còn dành cho user mới |
| `6fac98a8-8793-44df-9bc1-90c75c71d438` | `gemini-3.7-flash` trả 503 high demand |

Các lỗi trên là lỗi tầng model/API, không phải bằng chứng app fail. Không ghi các trace này thành test case Pass/Fail nghiệp vụ; ghi là **Blocked/Inconclusive – external AI service**.

ARTEMIS config hiện đã được đổi sang:

```json
"model": "gemini-3.7-flash",
"fallback": {
  "provider": "google",
  "model": "gemini-3.8-flash"
}
```

Nếu tiếp tục dùng ARTEMIS, phải kiểm tra quota và model trong Google AI Studio trước. Không tiếp tục đổi key liên tục nếu các key thuộc cùng Google Cloud project vì quota tính theo project và model.

## 8. Hướng tiếp tục ưu tiên: kiểm thử trong Google AI Studio

Mục tiêu của bước này là dùng **Google AI Studio** để kiểm tra model và phân tích evidence trước, tránh để ARTEMIS gọi API lặp rồi hết quota/timeout.

### 8.1. Preflight model trong Google AI Studio

1. Mở Google AI Studio bằng đúng tài khoản/project chứa API key dự định dùng.
2. Kiểm tra trang quota/rate limit của project.
3. Chọn model còn khả dụng; không chọn model đang báo unavailable/high demand.
4. Gửi một prompt văn bản rất ngắn để xác nhận model trả lời bình thường.
5. Tải một screenshot Dashboard đã loại PII và hỏi model nhận diện các nhãn UI.
6. Chỉ coi preflight đạt khi model trả lời cả prompt text và prompt ảnh mà không có 404, 429, 503 hoặc 504.
7. Không đưa API key, email thật, mã sinh viên hoặc dữ liệu lớp nhạy cảm vào prompt.

Prompt kiểm tra ảnh đề xuất:

```text
Đây là ảnh màn hình Android của ứng dụng kiểm thử. Chỉ phân tích nội dung nhìn thấy, không suy đoán.
Hãy trả JSON gồm:
- screen_name
- visible_labels
- target_label cho nút "Quản lý lớp"
- expected_next_screen
Nếu không đủ bằng chứng, trả status = "inconclusive".
```

### 8.2. Cách dùng Google AI Studio cho QA

- Chạy thao tác thực tế thủ công trên thiết bị hoặc bằng Appium.
- Chụp screenshot/quay video từng checkpoint.
- Đưa evidence đã che PII vào Google AI Studio để:
  - nhận diện màn hình và nhãn;
  - so sánh Expected/Actual;
  - phát hiện thông báo lỗi hiển thị;
  - tạo bản nháp observation/test report.
- Người kiểm thử phải đối chiếu lại kết quả AI với UI và log thật trước khi ghi Pass/Fail.
- Google AI Studio **không thay thế** thao tác E2E trên điện thoại; không ghi là “AI tự động điều khiển app” nếu chỉ phân tích ảnh/video.

### 8.3. Case nên chạy trước

Ưu tiên case đọc, ít rủi ro và có thể kiểm bằng screenshot:

1. TC05 – Lịch sử cơ bản.
2. TC06 – Lọc môn/lớp.
3. TC20 – Lọc Present/Absent.
4. TC24 – Hiển thị/lưu preferences, chỉ đổi dữ liệu test an toàn.
5. TC30 – Điều hướng Back/lifecycle; không mở hoặc đóng phiên.

Không chạy TC03, TC07, TC08, TC09 hoặc TC10 như regression pass trước khi thành viên phụ trách báo đã sửa đúng defect.

## 9. Quy trình một lượt test mới

1. Ghi commit hash đang test:

```bat
cd /d D:\ki8\PRM\Lab1\fapcheckin
git branch --show-current
git log -1 --oneline
git status --short
```

2. Xác nhận thiết bị:

```bat
"C:\Users\ASUS\AppData\Local\Android\Sdk\platform-tools\adb.exe" devices -l
```

3. Mở app mà không xóa phiên đăng nhập:

```bat
"C:\Users\ASUS\AppData\Local\Android\Sdk\platform-tools\adb.exe" -s 2dd833e1 shell monkey -p com.example.fapcheckin -c android.intent.category.LAUNCHER 1
```

4. Bắt đầu quay màn hình trước thao tác test.
5. Thực hiện đúng bước trong `docs/test-cases.md`.
6. Lưu screenshot/XML/logcat raw vào thư mục Git-ignore; che PII trước khi tải lên Google AI Studio.
7. Dùng Google AI Studio phân tích evidence và tạo observation nháp.
8. Người kiểm thử tự xác nhận Expected/Actual và kết luận Pass/Fail/Blocked/Inconclusive.
9. Cập nhật:
   - `e2e_test/results/android-summary.json`;
   - `docs/test-report.md`;
   - `docs/final-report-source.md` nếu kết quả ảnh hưởng báo cáo cuối.
10. Chạy một case tối thiểu ba lượt độc lập nếu mục tiêu là đóng regression.

## 10. Nếu vẫn muốn thử ARTEMIS sau preflight

Chỉ chạy ARTEMIS khi Google AI Studio đã trả lời ổn định với cùng project/model.

1. Dừng Appium để tránh xung đột UIAutomator2.
2. Bật Artemis Accessibility Helper.
3. Khởi động daemon bằng `D:\tools\artemis\start.bat`.
4. Chỉ chạy một task ngắn, read-only.
5. Theo dõi task mỗi phút.
6. Dừng ngay khi có 404, 429, 503, 504 hoặc vòng lặp không tạo action.
7. Không chạy nhiều task song song trên `2dd833e1`.
8. Không coi task bị lỗi API là lỗi app.

Nếu mục tiêu là hoàn thành regression đúng hạn, ưu tiên **Appium/manual + Google AI Studio phân tích evidence** thay vì tiếp tục tiêu thời gian vào lỗi hạ tầng ARTEMIS.

## 11. Việc còn lại để hoàn thành TV5

- Chờ thành viên khác sửa TC03, TC07, TC08, TC09, TC10 và DEF-EXP-01.
- Khi nhận commit sửa, merge/fetch theo quy trình nhóm và ghi hash.
- Chạy regression ba lượt cho case liên quan.
- Hoàn thành 5 lượt Android còn thiếu của phạm vi ban đầu nếu dependency đã có: 2 lượt TC03 và 3 lượt TC08.
- Cập nhật test report và Final Report theo kết quả mới.
- Điền placeholder bìa Final Report: trường, nhóm, lớp, giảng viên, thành viên.
- Slide làm sau khi kết quả regression cuối đã ổn định.
- Tạo PR `feature/qa-testing` → `dev` sau khi review.

## 12. Tiêu chí không được báo cáo quá mức

- Không ghi ARTEMIS pass khi trace chưa hoàn thành.
- Không dùng kết quả Google AI Studio phân tích ảnh để thay thế thao tác E2E thực tế.
- Không tính unit test backend vào 30 lượt Android.
- Không ghi TC08 pass nếu request được tạo bằng Firebase Console.
- Không ghi TC03 pass nếu phải force-stop/restart mới đồng bộ trạng thái.
- Không commit raw evidence chứa email, tên hoặc mã sinh viên.

