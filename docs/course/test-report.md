# Báo cáo kiểm thử TV5
Ngày bắt đầu: 31/10/2026; cập nhật: 01/11/2026. Source baseline `88cfbe8`, branch `feature/qa-testing`. Tại thời điểm bắt đầu, `dev` và `origin/dev` local cùng hash; chưa fetch nên không khẳng định remote mới nhất.

## Môi trường và phạm vi
Windows 10, PowerShell, Flutter 3.47.3, Dart 3.13.3, Android SDK 36, emulator Android 16 API 36 (`emulator-5554`), Appium 3.9.0 với UiAutomator2 8.7.3. Python 3.12.16 được quản lý bằng `uv`; ứng dụng kết nối Firebase project thật qua cấu hình Android local. Appium doctor không có lỗi bắt buộc; các cảnh báo bundletool/ffmpeg/GStreamer là tùy chọn và quay video đã loại khỏi phạm vi.
Đã đọc README, Functions, test cũ, AuthViewModel, RemoteSettings, module export. Web Admin được README mô tả prototype. OCR source hiện dùng Cloud Vision, không phải Gemini. Không mô tả cross-role approval hoặc Gemini fallback là đã hoạt động.

## Kết quả thực tế
| Bộ test | Lượt 1 | Lượt 2 | Lượt 3 | Tổng |
|---|---|---|---|---|
| Functions unit/regression | 26 pass, 0 fail | 26 pass, 0 fail | 26 pass, 0 fail | 78 pass / 78 |
| Remote Config CR-04 | 3 pass, 0 fail | Chưa lặp | Chưa lặp | 3 pass / 3 |
| Android TC01 Google Sign-In | Pass (26,06 giây) | Pass (26,57 giây) | Pass (25,02 giây) | 3 pass / 3 |
| Android TC02 từ chối role `user` | Pass (31,01 giây) | Pass (25,91 giây) | Pass (26,26 giây) | 3 pass / 3 |
| Android TC03 tạo/đóng phiên | **Fail**: tạo phiên và QR thành công; đóng phiên bị Firestore từ chối | Chưa lặp | Chưa lặp | 0 pass / 1, 1 fail |
| Android TC04 hiển thị QR | Pass (3,18 giây) | Pass (3,14 giây) | Pass (3,19 giây) | 3 pass / 3; overall partial |
| Android TC05 lịch sử cơ bản | Pass (6,74 giây) | Pass (7,04 giây) | Pass (7,00 giây) | 3 pass / 3; isolation pending |
| Android TC06 lọc môn/lớp | Pass (10,72 giây) | Pass (11,16 giây) | Pass (11,16 giây) | 3 pass / 3 |
| Android TC07 xuất XLSX | **Fail** (4,58 giây) | **Fail** (5,02 giây) | **Fail** (4,98 giây) | 0 pass / 3, 3 fail |
| Android TC08 yêu cầu sửa điểm danh | **Blocked**: chưa có flow mobile | **Blocked** | **Blocked** | 0 lượt; feature chưa triển khai |
| Android TC09 empty/offline/retry | **Fail**: empty pass, offline feedback fail | **Fail**: empty pass, offline feedback fail | **Fail**: empty pass, offline feedback fail | 0 pass / 3, 3 fail |
| Android TC10 popup native | Pass: cancel Google + deny notification | **Fail**: Android allow nhưng app không bật reminder | Pass: cancel Google + deny notification | 2 pass / 3, 1 fail |
Pass rate unit/regression = 78 / 78 × 100% = 100%. Baseline trước sửa: 22/22 pass. Log: e2e_test/results/functions-run-1.tap đến functions-run-3.tap; summary JSON cùng thư mục.
Flutter regression CR-04 đạt 3/3 trong một lượt. Đây là kiểm tra bổ sung cho finding, không được cộng vào 30 lượt Android E2E.
Android E2E: TC01 đã chạy 3 lượt độc lập với precondition xóa dữ liệu app, chọn tài khoản trong popup Google và xác nhận dashboard. TC02 cũng chạy 3 lượt độc lập, đăng nhập bằng tài khoản `role = user`, xác nhận app từ chối quyền giảng viên và quay lại màn hình login. Pass rate của TC01 và TC02 đều là 3 / 3 × 100% = 100%. TC03 đã chạy một lượt: tạo phiên và hiển thị QR thành công, nhưng đóng phiên thất bại. TC04 chạy 3 Appium session độc lập trên precondition có phiên đang mở, mỗi lượt xác nhận đồng thời phần tử `qr code` và trạng thái `ĐANG MỞ ĐIỂM DANH`; phần hiển thị đạt 3/3 nhưng kiểm tra QR cũ/mới bằng thiết bị sinh viên còn thiếu nên overall vẫn partial. TC05 cơ bản chạy 3 lượt độc lập, xác nhận đúng lớp, có 3 buổi cùng bộ lọc `Tất cả`/`Vắng`; đạt 3/3, nhưng điều kiện không lộ dữ liệu giáo viên khác cần seed lớp đối chứng nên chưa đóng coverage isolation. TC06 chạy 3 lượt chuyển PRN232 → PRM392; tiêu đề và số buổi đổi đúng (1 so với 3), đạt 3/3. TC07 chạy 3 lượt và đều fail vì file XLSX chỉ được ghi vào private `code_cache`, không thể mở/chia sẻ từ UI. TC08 bị blocked qua cả static review và UI vì chưa có flow mobile gửi/xem yêu cầu sửa điểm danh hoặc nghỉ phép; không tạo kết quả giả bằng Firebase Console. TC09 chạy 3 lượt: empty-state `Có mặt (0)` hiển thị đúng thông báo trong cả 3 lượt; app không crash khi offline và phục hồi dashboard sau khi bật mạng, nhưng cả 3 lượt không có thông báo offline/error/retry nên overall fail. TC10 chạy 3 lượt; hủy popup Google đều quay lại login và app không crash, hai lượt deny phản ánh đúng, nhưng lượt allow cấp quyền Android thành công vẫn không bật được reminder do backend trả lỗi quyền. Toàn bộ kế hoạch Android hiện đã thực thi 25 / 30 lượt: 17 pass, 8 fail; TC08 blocked 3 lượt, TC03 còn thiếu 2 lượt. TC04–TC05 còn coverage gap. Không dùng 78 unit test để thay yêu cầu 30 Android E2E. Summary không chứa thông tin tài khoản nằm tại `e2e_test/results/android-summary.json`; ảnh, XML và logcat raw được giữ local vì có dữ liệu cá nhân.
10 test case có bước, dữ liệu, expected trong test-cases.md. Android runner là scaffold cần mapping selector thật, tài khoản và seed. TC08 có thể blocked bởi trạng thái Web Admin. TC07 phải xác nhận định dạng xuất thực tế, chưa khẳng định PDF.

## Bugs và regression
Xem ai-code-review.md: CR-01, CR-02, CR-03, CR-04 và CR-06 đã sửa, có regression và được lưu trong ba commit riêng. CR-05 còn mở. Đã chạy Flutter test riêng cho CR-04; chưa chạy toàn bộ Flutter analyze/test hoặc bộ Firebase Rules emulator E2E. Android/Appium toolchain đã hoạt động và đang được dùng cho TC01–TC03.

### DEF-TC03-01 — đóng phiên bị `PERMISSION_DENIED` (High)
Tái hiện ngày 01/11/2026 trên emulator API 36 bằng Appium. Ứng dụng tạo phiên mới và hiển thị `qr code`/`ĐANG MỞ ĐIỂM DANH`, sau đó thao tác `Đóng phiên điểm danh` trả về `Bạn không có quyền thực hiện thao tác này.` Logcat Firebase xác nhận:

```text
WriteStream: PERMISSION_DENIED — Missing or insufficient permissions.
Write failed at attendance_records/{sessionId}_{rollNumber}: PERMISSION_DENIED
```

`TeacherRepository.closeSession` đóng phiên và tạo các bản ghi `Absent` trong cùng batch. Lỗi xảy ra tại lần ghi `attendance_records` đầu tiên, nên toàn bộ batch bị rollback và phiên vẫn `open`. Firestore Rules chỉ cho phép bản ghi này khi `teacherCreatesRecord` đạt, bao gồm điều kiện tồn tại `enrollments/{classCode}_{rollNumber}`. Tạo phiên vừa thành công bằng cùng tài khoản, repository đã kiểm tra session thuộc đúng `teacherMemberCode`, record id/field/status do client sinh đúng schema; vì vậy điều kiện enrollment theo document ID là nguyên nhân dữ liệu có xác suất cao nhất nhưng cần đối chiếu ID document trực tiếp trên Firebase Console trước khi kết luận migration sai. Evidence local (bị Git ignore): `results/tc03-repro-2026-11-01/`.

### DEF-TC03-02 — trạng thái phiên trong bộ nhớ không đồng bộ (High)
Sau khi `sessionStatus` được sửa trực tiếp trên Firestore, Trang chủ tải lại và không hiển thị phiên hoạt động, nhưng màn Lịch sử vẫn chặn `Mở phiên điểm danh mới` với thông báo `Bạn đang có phiên điểm danh mở`. Mã nguồn chặn theo `LiveSessionViewModel.session?.isOpen`, không theo dữ liệu vừa tải từ Firestore; trạng thái chỉ hết sau khi force-stop/relaunch. Cần reset/reload LiveSessionViewModel khi app resume, khi quay lại màn hình hoặc khi session document thay đổi.

TC03 chỉ được chuyển sang Pass khi người tạo phiên đóng được phiên, các màn hình cập nhật mà không restart, và toàn bộ chuỗi đạt 3 lượt liên tiếp.

### DEF-TC07-01 — XLSX được lưu vào private cache, người dùng không thể mở (Medium)
Ba lượt Appium đều nhận thông báo `Đã lưu tại /data/user/0/com.example.fapcheckin/code_cache/.../Attendance_<class>.xlsx`. `history_download_io.dart` dùng `Directory.systemTemp.createTemp`, ghi bytes rồi chỉ trả chuỗi đường dẫn; không gọi Android share/save intent, không mở file và không lưu vào Downloads/MediaStore. Vì `/data/user/0/<package>` là vùng private, giảng viên không thể lấy file bằng trình quản lý tệp. Unit test core xác nhận workbook bytes là XLSX hợp lệ nhưng không đáp ứng tiêu chí Android E2E “mở file thực tế”. Cần dùng share sheet hoặc Storage Access Framework/MediaStore và chỉ báo thành công khi người dùng có URI truy cập được. Evidence local: `results/tc07-export-2026-11-01/`.

### DEF-TC09-01 — offline không có thông báo hoặc thao tác retry (Medium)
Ba lượt Appium tắt toàn bộ kết nối bằng API network của UiAutomator2 rồi cold-start ứng dụng. Ứng dụng vẫn sống, không crash và dashboard phục hồi sau khi kết nối được bật lại. Tuy nhiên cả ba lượt không hiển thị trạng thái offline, lỗi tải dữ liệu hoặc nút retry; ở hai lượt cold-start không có cache, người dùng chỉ thấy nội dung chưa sẵn sàng mà không biết nguyên nhân. Empty-state hợp lệ được kiểm riêng trên tab `Có mặt (0)` và đạt 3/3. Cần phân biệt empty thật với lỗi mạng, hiển thị trạng thái offline và cho phép retry. Evidence local: `results/tc09-empty-offline-2026-11-01/`.

### DEF-TC10-01 — cấp quyền notification nhưng đăng ký reminder bị từ chối (Medium)
Trong lượt allow, popup Android cấp `POST_NOTIFICATIONS` thành công và Appium xác nhận quyền nằm trong nhóm granted. Sau đó công tắc `Nhắc lịch dạy` vẫn trở về `false`, UI báo `Bạn không có quyền thực hiện thao tác này.`. Lượt chẩn đoán riêng tái hiện cùng kết quả. Luồng `PreferencesViewModel.save(newReminders: true)` đăng ký FCM token qua `device_tokens/{uid}/tokens/{id}` trước khi lưu `user_preferences`; vì vậy cần đối chiếu Firestore Rules đang deploy và profile active với rules trong repository. Hai lượt deny hoạt động đúng và hủy popup Google đều quay về login không crash. Evidence local: `results/tc10-native-popup-2026-11-01/`.

### DEF-EXP-01 — Back hệ thống thoát app từ màn con (Medium)
Trong exploratory, nút Back Android từ màn Live QR và từ chi tiết `Điểm danh sinh viên` đều đưa thẳng về Android Launcher thay vì quay về Dashboard hoặc danh sách lớp. Nút Back nằm trong giao diện của màn Cài đặt vẫn hoạt động và Back khi modal đang mở vẫn chỉ đóng modal. `MainScreen` chọn body theo `DashboardViewModel.currentRoute` nhưng không có `PopScope`/`WillPopScope` ánh xạ Back hệ thống về route cha, nên Android pop Activity. Cần định nghĩa lịch sử/route cha và chỉ cho thoát app khi người dùng đang ở route gốc.

## Exploratory
Đã chạy phiên exploratory 15,1 phút ngày 01/11/2026, từ 20:46:11 đến 21:01:17 (UTC+7), trên emulator API 36 và build debug hiện tại. Charter bao phủ Dashboard/Live QR, chi tiết lớp, Lịch dạy, Báo cáo, Hồ sơ, Cài đặt, notification/security modal, chuyển tab nhanh, xoay portrait–landscape, ngắt mạng giữa phiên và background/resume.

Kết quả: 14 chu kỳ endurance hoàn tất; không crash, phiên đăng nhập được giữ sau hai lần background/resume, nội dung chính vẫn hiển thị sau hai lần xoay màn hình, các modal đóng đúng bằng Back và dashboard được khôi phục cuối phiên với network mode `6`. Phát hiện mới `DEF-EXP-01`: Back hệ thống từ Live QR và chi tiết lớp thoát app. Hai lần ngắt mạng giữa phiên cũng tái hiện `DEF-TC09-01` vì không có offline feedback. Evidence local (Git ignore): `results/exploratory-2026-11-01/`, gồm mốc bắt đầu/kết thúc, 14 quan sát, screenshot và UI XML.

## Đánh giá và phần còn thiếu
Chưa đạt toàn bộ phạm vi TV5 đã thống nhất. Đã có branch và ba commit sửa finding; Android đã thực thi 25/30 lượt và exploratory 15,1 phút đã hoàn tất. Còn hai lượt TC03 sau khi sửa dữ liệu/rules, ba lượt TC08 sau khi có flow mobile, commit kết quả exploratory, final report PDF theo mẫu trường và slide PDF. Phần quay video đã được loại khỏi phạm vi theo quyết định ngày 01/11/2026. Chưa nhận mẫu trường hoặc minh chứng từ TV1–TV4.
