<!-- PAGE: COVER -->
# [TÊN TRƯỜNG / CƠ SỞ]
## MÔN PRM393 – MOBILE PROGRAMMING

# FAP CHECK-IN
## Hệ thống điểm danh bằng mã QR và quản lý chuyên cần

**BÁO CÁO DỰ ÁN CUỐI KỲ**

| Thông tin | Nội dung |
|---|---|
| Nhóm | [TÊN / SỐ NHÓM] |
| Lớp | [MÃ LỚP] |
| Giảng viên | [HỌ TÊN GIẢNG VIÊN] |
| Thành viên | [DANH SÁCH TV1–TV5 VÀ MÃ SINH VIÊN] |
| Phiên bản báo cáo | 1.0 – 01/11/2026 |

**Hà Nội, 2026**

<!-- PAGE -->
# TÓM TẮT VÀ MỤC LỤC

## Tóm tắt điều hành

FAP Check-in là hệ thống hỗ trợ giảng viên mở phiên điểm danh, phát mã QR thay đổi theo chu kỳ, theo dõi tình trạng chuyên cần và xuất báo cáo. Ứng dụng mobile được xây dựng bằng Flutter; xác thực, dữ liệu thời gian thực và các tác vụ nền sử dụng Firebase. Dự án hướng tới giảm thao tác thủ công, hạn chế điểm danh hộ và tạo lịch sử có thể kiểm tra.

Báo cáo phản ánh đúng trạng thái source tại nhánh `feature/qa-testing`. Mobile và các dịch vụ Firebase là phần đã được tích hợp sâu nhất. Web Admin hiện mới ở mức prototype, chưa nối đầy đủ Firebase. Luồng yêu cầu sửa điểm danh cross-role và Gemini OCR chưa hoàn chỉnh; OCR hiện dùng Google Cloud Vision. Các khoảng trống này được ghi nhận là hạn chế, không mô tả như tính năng đã hoàn thành.

## Mục lục

| Trang | Nội dung |
|---:|---|
| 3 | Bối cảnh, vấn đề và phạm vi |
| 4 | Kiến trúc tổng thể |
| 5 | Dữ liệu Firestore và phân quyền |
| 6 | Các luồng chức năng chính |
| 7 | OCR, Remote Config và Cloud Functions |
| 8 | Chiến lược đảm bảo chất lượng |
| 9 | Kết quả kiểm thử |
| 10 | AI-assisted code review và sửa lỗi |
| 11 | Lỗi tồn tại, hạn chế và rủi ro |
| 12 | Kết luận, lộ trình và minh chứng |

<!-- PAGE -->
# 1. BỐI CẢNH, VẤN ĐỀ VÀ PHẠM VI

## 1.1. Bối cảnh

Điểm danh lớp học thường tốn thời gian, dễ sai lệch khi nhập tay và khó tổng hợp khi dữ liệu nằm rải rác. Với lớp đông, giảng viên cần một công cụ thao tác nhanh trên điện thoại, đồng thời vẫn bảo đảm dữ liệu gắn với đúng lớp, đúng phiên và đúng người dùng.

## 1.2. Mục tiêu

- Đăng nhập bằng Google và phân quyền theo hồ sơ người dùng.
- Cho phép giảng viên quản lý lớp, tạo phiên và hiển thị Live QR.
- Ghi nhận trạng thái Present/Absent và cung cấp lịch sử theo lớp, môn học.
- Hỗ trợ nhập thời khóa biểu bằng OCR, thông báo và cấu hình từ xa.
- Lưu dữ liệu trên Firestore với Security Rules kiểm soát quyền truy cập.
- Cung cấp minh chứng kiểm thử, code review và các giới hạn còn tồn tại.

## 1.3. Phạm vi thực tế

| Hạng mục | Trạng thái |
|---|---|
| Flutter Mobile cho giảng viên | Đã tích hợp; được kiểm thử trên Android emulator |
| Google Sign-In và RBAC | Hoạt động cho tài khoản staff; role user bị từ chối trên app giảng viên |
| Phiên điểm danh và Live QR | Tạo/hiển thị được; đóng phiên đang gặp lỗi quyền dữ liệu |
| Lịch sử, lọc và xuất XLSX | Hiển thị/lọc được; file xuất nằm trong private cache |
| Web Admin / Review Queue | Prototype, chưa nối Firebase đầy đủ |
| Request sửa điểm danh | Có schema/Rules, chưa có flow UI end-to-end |
| OCR thời khóa biểu | Cloud Vision; chưa phải Gemini như mục tiêu ban đầu |
| Video demo | Đã loại khỏi phạm vi TV5 theo quyết định hiện tại của nhóm |

## 1.4. Đối tượng sử dụng

Giảng viên là người dùng chính của mobile. Sinh viên và quản trị viên xuất hiện trong mô hình dữ liệu và định hướng cross-role, nhưng trải nghiệm hoàn chỉnh cho hai vai trò này chưa được triển khai đồng đều.

<!-- PAGE -->
# 2. KIẾN TRÚC TỔNG THỂ

[[ARCH_DIAGRAM]]

## 2.1. Mobile Flutter

Ứng dụng tổ chức theo hướng MVVM: View hiển thị giao diện, ViewModel giữ trạng thái và điều phối nghiệp vụ, Repository làm việc với Firebase. `packages/core` chứa model và repository dùng chung. Điều hướng mobile hiện dựa trên `DashboardViewModel.currentRoute`, thuận tiện cho sidebar/bottom navigation nhưng chưa quản lý đầy đủ lịch sử Back hệ thống.

## 2.2. Firebase backend

- **Firebase Authentication:** nhận Google credential và tạo phiên đăng nhập.
- **Cloud Firestore:** lưu người dùng, lớp, lịch, phiên, điểm danh, preferences và notification.
- **Cloud Functions:** xử lý notification, nhắc lịch, OCR và các tác vụ tin cậy phía server.
- **Firebase Storage:** lưu tài nguyên như avatar hoặc file ảnh liên quan.
- **Remote Config:** cung cấp chu kỳ QR và giá trị cấu hình; client có fallback an toàn.

## 2.3. Web Admin

Thư mục Web Admin thể hiện thiết kế dashboard và Review Queue, nhưng tài liệu kiến trúc xác nhận UI vẫn là prototype dùng dữ liệu mẫu. Vì chưa nối Auth/Firestore đầy đủ, báo cáo không tính luồng approve/reject là tính năng end-to-end đã hoàn thành.

## 2.4. Đặc điểm thiết kế

Kiến trúc tách giao diện khỏi truy cập dữ liệu, dùng realtime stream tại các màn cần cập nhật. Security Rules là lớp bảo vệ bắt buộc; client-side validation chỉ cải thiện trải nghiệm và không thay thế kiểm soát phía server.

<!-- PAGE -->
# 3. DỮ LIỆU FIRESTORE VÀ PHÂN QUYỀN

## 3.1. Các collection chính

| Collection | Mục đích | Chủ thể chính |
|---|---|---|
| `users` | Hồ sơ, role, trạng thái tài khoản | User/Admin |
| `classes` | Thông tin lớp và giảng viên phụ trách | Staff/Admin |
| `enrollments` | Liên kết lớp – sinh viên | Admin/đồng bộ |
| `class_schedules` | Lịch học, slot, phòng | Staff/Admin |
| `sessions` | Phiên điểm danh, secret, trạng thái | Staff |
| `attendance_records` | Present/Absent và nguồn ghi nhận | User/Staff |
| `requests` | Đơn attendance_fix/leave | User/Staff/Admin |
| `user_preferences` | Theme, ngôn ngữ, reminder | Chính chủ |
| `device_tokens` | Token FCM theo thiết bị | Chính chủ/Functions |

## 3.2. RBAC

Ba role chính là `user`, `staff` và `admin`. Security Rules kết hợp kiểm tra xác thực, hồ sơ tồn tại, trạng thái active, quyền sở hữu và schema field. Session secret không được mở cho sinh viên; bản ghi điểm danh phải khớp lớp, phiên, enrollment và quy tắc ID.

## 3.3. Quy tắc đáng chú ý

- Người dùng không được tự nâng role hoặc sửa dữ liệu của người khác.
- Giảng viên chỉ thao tác trên lớp/phiên thuộc quyền phụ trách.
- Yêu cầu sửa điểm danh được tạo ở trạng thái `pending`; chỉ admin có quyền duyệt.
- Notification do worker tin cậy tạo; người dùng chỉ đánh dấu đã đọc.
- Preferences và device token phải thuộc đúng Firebase UID.

## 3.4. Vấn đề dữ liệu đã phát hiện

Khi đóng phiên, client tạo các bản ghi Absent trong cùng batch. Firestore trả `PERMISSION_DENIED` tại `attendance_records/{sessionId}_{rollNumber}`, làm toàn bộ batch rollback. Điều kiện `enrollments/{classCode}_{rollNumber}` là điểm cần TV1 đối chiếu với dữ liệu thật và Rules đang deploy.

<!-- PAGE -->
# 4. CÁC LUỒNG CHỨC NĂNG CHÍNH

## 4.1. Đăng nhập Google

Người dùng chọn tài khoản Google, ứng dụng nhận token, đăng nhập Firebase và tải hồ sơ `users/{uid}`. Tài khoản staff hợp lệ vào Dashboard; tài khoản role user được từ chối ở ứng dụng giảng viên. Hủy popup chọn tài khoản quay về màn login mà không crash.

## 4.2. Tạo phiên và Live QR

Giảng viên chọn lớp, mở phiên và hiển thị QR. QR chứa thông tin cần thiết để check-in và được làm mới theo chu kỳ cấu hình. Trạng thái `ĐANG MỞ ĐIỂM DANH` hiển thị ổn định trong ba lượt kiểm thử. Tuy nhiên, đóng phiên thất bại do quyền ghi Absent và trạng thái ViewModel có thể giữ cache cũ khi dữ liệu bị sửa ngoài ứng dụng.

## 4.3. Lịch sử và lọc

Màn lịch sử hiển thị các buổi theo lớp, trạng thái Present/Absent và cho phép chuyển giữa các môn/lớp. Kiểm thử PRN232 và PRM392 cho thấy tiêu đề và số phiên đổi đúng. Kiểm tra cách ly dữ liệu giữa hai giảng viên còn thiếu dữ liệu đối chứng.

## 4.4. Xuất báo cáo

Core tạo được workbook XLSX hợp lệ. Trên Android, file hiện được ghi vào `/data/user/0/<package>/code_cache`, là vùng riêng tư của ứng dụng; người dùng không thể mở bằng trình quản lý tệp. Cần chuyển sang Android share sheet, Storage Access Framework hoặc MediaStore.

## 4.5. Yêu cầu sửa điểm danh

Schema và Rules cho `attendance_fix`/`leave` đã tồn tại, nhưng mobile chưa có form/listener và Web Admin chưa có Review Queue kết nối Firebase. Do đó TC08 được đánh dấu Blocked thay vì tạo dữ liệu trực tiếp trên Console rồi ghi nhận sai là E2E pass.

<!-- PAGE -->
# 5. OCR, REMOTE CONFIG VÀ CLOUD FUNCTIONS

## 5.1. OCR thời khóa biểu

Luồng OCR nhận ảnh lịch học, kiểm tra metadata và kích thước trước khi gửi tới dịch vụ nhận dạng. Finding CR-03 chỉ ra rằng metadata không hợp lệ hoặc buffer tải xuống quá lớn có thể vượt kiểm soát. Bản sửa đã chặn kích thước không hữu hạn/không dương và buffer lớn hơn 10 MB.

Implementation hiện dùng Google Cloud Vision. Gemini OCR và tự động trích xuất minh chứng xin nghỉ là định hướng trong đề bài, chưa phải chức năng production; đây là khoảng cách cần nêu rõ khi demo và báo cáo.

## 5.2. Remote Config fallback

Các giá trị như chu kỳ refresh QR và kiểm tra IP có default cục bộ. CR-04 phát hiện getter nằm ngoài vùng `try`, khiến lỗi SDK có thể thoát ra thay vì dùng default. Bản sửa đưa cả setDefaults, fetch và đọc getter vào cùng vùng fallback. Flutter regression đạt 3/3.

## 5.3. Notification và reminder

Cloud Functions gửi FCM theo token người dùng. CR-01, CR-02 và CR-06 lần lượt xử lý xóa nhầm token khi payload lỗi, giới hạn multicast 500 token và số liệu cleanup sai khi delete thất bại. Bản sửa chia chunk 500, chỉ xóa token stale xác định và chỉ tăng bộ đếm sau delete thành công.

Trên Android, cấp `POST_NOTIFICATIONS` thành công nhưng đăng ký reminder vẫn bị backend từ chối. Cần đối chiếu Rules deploy cho `device_tokens`/`user_preferences` và trạng thái active của hồ sơ.

## 5.4. Reliability còn mở

CR-05 ghi nhận HTTP call trong `fap_sync.js` chưa có timeout. Nếu gateway treo, callable có thể giữ tài nguyên đến timeout của nền tảng. Hướng xử lý là `AbortSignal.timeout` hoặc `AbortController`, kèm regression test cho gateway chậm.

<!-- PAGE -->
# 6. CHIẾN LƯỢC ĐẢM BẢO CHẤT LƯỢNG

## 6.1. Môi trường

| Thành phần | Cấu hình |
|---|---|
| Hệ điều hành | Windows 10 22H2 |
| Flutter / Dart | Flutter 3.47.3 / Dart 3.13.3 |
| Android | Emulator Android 16, API 36, `emulator-5554` |
| Automation | Appium 3.9.0, UiAutomator2 8.7.3 |
| Python | 3.12.16, `uv`, `pytest` |
| Backend | Firebase project thật với cấu hình Android local |

## 6.2. Phương pháp

- 10 test case bao phủ authentication, phiên, QR, lịch sử, lọc, export, request, empty/offline và popup native.
- Mục tiêu ba lượt độc lập cho mỗi case; raw screenshot/XML/logcat được giữ local vì có thể chứa dữ liệu tài khoản.
- Unit/regression cho Cloud Functions chạy ba lượt.
- Flutter regression tập trung vào Remote Config fallback.
- Exploratory 15,1 phút kiểm tra điều hướng, rotation, background/resume, modal và mất mạng giữa phiên.
- AI code review ghi nhận finding, quyết định Accept/Modify/Reject và liên kết commit sửa lỗi.

## 6.3. Nguyên tắc báo cáo

Một case chỉ Pass khi toàn bộ expected result đạt. Luồng thiếu UI được ghi Blocked, không tạo dữ liệu bằng Console để thay thế thao tác người dùng. Test bị giới hạn dữ liệu được ghi Partial/Coverage gap. Unit test không được cộng vào 30 lượt Android E2E.

## 6.4. Quản lý minh chứng

Kết quả tổng hợp nằm trong `e2e_test/results/android-summary.json` và `docs/course/test-report.md`. Log TAP của Functions được commit. Evidence có PII nằm trong thư mục Git-ignore và không đưa vào repository công khai.

<!-- PAGE -->
# 7. KẾT QUẢ KIỂM THỬ

[[RESULTS_CHART]]

## 7.1. Tổng hợp

| Nhóm kiểm thử | Kết quả |
|---|---:|
| Android E2E đã thực thi | 25/30 lượt |
| Android Pass / Fail | 17 / 8 |
| Pass rate trên lượt đã chạy | 68,0% |
| Functions regression | 78/78 pass – 100% |
| Remote Config regression | 3/3 pass |
| Exploratory | 15,1 phút – 14 chu kỳ |

## 7.2. Kết quả theo case

| Case | Trạng thái | Ghi chú |
|---|---|---|
| TC01 | 3/3 Pass | Google Sign-In staff |
| TC02 | 3/3 Pass | Từ chối role user |
| TC03 | 0/1, Fail | Tạo/QR pass; đóng phiên bị từ chối |
| TC04 | 3/3 UI Pass, Partial | Thiếu thiết bị sinh viên kiểm QR cũ/mới |
| TC05 | 3/3 Basic Pass, Partial | Thiếu lớp đối chứng giảng viên khác |
| TC06 | 3/3 Pass | Lọc PRN232/PRM392 đúng |
| TC07 | 0/3, Fail | XLSX ở private cache |
| TC08 | Blocked | Flow mobile/admin chưa triển khai |
| TC09 | 0/3, Fail | Empty pass; offline feedback fail |
| TC10 | 2/3 Pass | Allow notification không bật reminder |

Năm lượt còn thiếu gồm hai lượt TC03 sau khi sửa Rules/dữ liệu và ba lượt TC08 sau khi có UI cross-role.

<!-- PAGE -->
# 8. AI-ASSISTED CODE REVIEW VÀ SỬA LỖI

## 8.1. Findings

| ID | Nhóm | Mức độ | Quyết định / trạng thái |
|---|---|---|---|
| CR-01 | Notification bug | Medium | Accept – đã sửa xóa nhầm token |
| CR-02 | Performance/reliability | Medium | Accept – chia multicast 500 token |
| CR-03 | Security | Medium | Modify – kiểm metadata và buffer OCR |
| CR-04 | Reliability | Medium | Accept – fallback Remote Config an toàn |
| CR-05 | Reliability | Medium | Accept – chưa sửa HTTP timeout |
| CR-06 | Monitoring correctness | Low | Accept – sửa bộ đếm cleanup |

## 8.2. Commit sửa finding

- `4b73278` – `fix(review): resolve CR-03 OCR image size validation`.
- `6c5cf6c` – `fix(review): resolve CR-01 CR-02 CR-06 notification reliability`.
- `9e0c46a` – `fix(review): resolve CR-04 Remote Config fallback`.

Ba commit tách theo nhóm vấn đề thực tế, có regression đi kèm; không tạo commit giả để tăng số lượng.

## 8.3. Regression

Functions tăng từ baseline 22 test lên 26 test và chạy ba lượt liên tiếp, tổng 78/78 pass. Flutter test cho Remote Config kiểm tra giá trị remote thành công cùng hai nhánh fallback và đạt 3/3. Việc này xác nhận bản sửa không phá các hành vi đã được bao phủ, nhưng không thay thế Android E2E hoặc Firebase Rules emulator test.

## 8.4. Đánh giá

AI review hữu ích nhất khi finding được kiểm tra lại bằng source, test và bối cảnh nghiệp vụ. CR-03 được chọn Modify vì bản sửa giảm rủi ro nhưng chưa giải quyết hoàn toàn giới hạn bộ nhớ bằng streaming. CR-05 được giữ mở thay vì ghi nhận hoàn thành khi chưa có timeout test.

<!-- PAGE -->
# 9. LỖI TỒN TẠI, HẠN CHẾ VÀ RỦI RO

## 9.1. Defects chính

| ID | Mức độ | Tác động |
|---|---|---|
| DEF-TC03-01 | High | Không đóng được phiên; batch Absent rollback |
| DEF-TC03-02 | High | Trạng thái phiên cache cũ, cần restart |
| DEF-TC07-01 | Medium | Người dùng không mở/chia sẻ được XLSX |
| DEF-TC09-01 | Medium | Không có offline feedback hoặc retry |
| DEF-TC10-01 | Medium | Cấp notification nhưng reminder không bật |
| DEF-EXP-01 | Medium | Back hệ thống từ màn con thoát app |

## 9.2. Hạn chế chức năng

- Web Admin và Review Queue chưa kết nối Firebase đầy đủ.
- Cross-role request chưa có E2E; TC08 bị Blocked.
- Gemini OCR chưa triển khai; Cloud Vision là implementation hiện tại.
- Chưa kiểm QR cũ/mới bằng thiết bị sinh viên và chưa kiểm isolation bằng giảng viên thứ hai.
- Chưa chạy toàn bộ Flutter analyze/test và Firebase Rules emulator E2E.
- Video demo đã loại khỏi phạm vi TV5 hiện tại; nhóm cần đối chiếu rubric chính thức.

## 9.3. Rủi ro phát hành

| Rủi ro | Khả năng | Ảnh hưởng | Giảm thiểu |
|---|---|---|---|
| Rules deploy lệch source | Trung bình | Cao | Kiểm version/deploy và rules emulator |
| Dữ liệu enrollment sai convention | Trung bình | Cao | Migration và validation script |
| Người dùng hiểu nhầm cache là dữ liệu mới | Cao | Trung bình | Offline banner, timestamp, retry |
| File export không truy cập được | Cao | Trung bình | SAF/MediaStore/share sheet |
| HTTP gateway treo | Trung bình | Trung bình | Timeout + retry có giới hạn |

Ưu tiên trước demo/phát hành là xử lý hai lỗi High, xác minh Rules thật và đóng đủ 30 lượt E2E.

<!-- PAGE -->
# 10. KẾT LUẬN, LỘ TRÌNH VÀ MINH CHỨNG

## 10.1. Kết luận

FAP Check-in đã hình thành nền tảng mobile–Firebase có khả năng đăng nhập staff, quản lý lớp, mở Live QR, xem lịch sử và áp dụng Rules theo vai trò. QA đã thiết lập toolchain Android thật, chạy 25/30 lượt, hoàn thành regression, exploratory và AI code review có sửa lỗi. Kết quả cho thấy phần hiển thị và điều hướng chính tương đối ổn định, nhưng các luồng ghi dữ liệu nhạy cảm và cross-role chưa đủ điều kiện phát hành.

## 10.2. Lộ trình đề xuất

1. TV1 đối chiếu `enrollments`, `device_tokens`, profile active và Rules đang deploy.
2. TV2 sửa đóng phiên, đồng bộ LiveSessionViewModel, export Android, offline state và Back handling.
3. TV3 nối Web Admin Review Queue với Firebase để mở khóa TC08.
4. TV4 thống nhất Cloud Vision/Gemini, bổ sung fallback và minh chứng đúng implementation.
5. TV5 formalize cấu hình tự động TC03–TC10, chạy lại đủ 30 lượt và cập nhật pass rate.
6. Cả nhóm bổ sung thông tin bìa, ảnh minh chứng và xác nhận yêu cầu video theo rubric.

## 10.3. Minh chứng và Git history

- `docs/course/test-report.md`, `docs/course/test-cases.md`, `docs/course/ai-code-review.md`.
- `e2e_test/README.md`, `e2e_test/results/android-summary.json` và TAP regression.
- Commit QA: `88f3348`, `d9cae28`, `a18bbb8`, `e9741f9`.
- Commit sửa finding: `4b73278`, `6c5cf6c`, `9e0c46a`.

## 10.4. Thông tin cần hoàn thiện trước khi nộp

- Thay toàn bộ placeholder ở bìa bằng thông tin chính thức.
- Chèn ảnh Mobile, Web Admin, Firebase Console và test evidence đã loại PII.
- Cập nhật kết quả sau khi sửa TC03/TC08 và chạy đủ 30 lượt.
- Đối chiếu mẫu trường, rubric và yêu cầu chữ ký/xác nhận nếu có.

**Tài liệu nội bộ dùng làm nguồn:** README, tài liệu kiến trúc/dữ liệu/RBAC trong `docs/`, source Flutter/Firebase và báo cáo QA ngày 01/11/2026.
