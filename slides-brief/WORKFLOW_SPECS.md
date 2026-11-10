# WORKFLOW_SPECS — Nhận diện và đặc tả workflow lõi (FAP Check-in)

> Phương pháp: PDF *Workflow là gì* (5 câu kiểm tra, cỡ vừa phải, đặt tên, mẫu 9 trường, checklist W14).
> Mọi mã **WF-xx / BR-xx / FR-xx** trong file này là `[MÃ MỚI — ĐỀ XUẤT]` (repo chưa có các mã đó). Mã **TC01–TC30** lấy nguyên từ `docs/course/test-cases.md`.
> Đối chiếu số slide: dùng số slide *nội dung* của PPTX V11 (01–24), không dùng số slide của bản V3 trong PDF.

---

## 1. Danh sách ứng viên và kết quả 5 câu kiểm tra

Năm câu: **Q1** trigger rõ · **Q2** kết thúc bằng kết quả nghiệp vụ có giá trị · **Q3** thay đổi dữ liệu/trạng thái hoặc có quyết định · **Q4** có rẽ nhánh theo BR hoặc ngoại lệ · **Q5** nói được bằng ngôn ngữ nghiệp vụ. Chỉ nhận khi 5/5.

| # | Ứng viên | Nguồn trong repo | Q1 | Q2 | Q3 | Q4 | Q5 | Kết luận |
|---|---|---|:-:|:-:|:-:|:-:|:-:|---|
| C1 | **Mở phiên điểm danh QR** | `session_ops.dart` `createSession`, `LiveSessionViewModel.startSession`, `AutoSessionManager` | ✔ | ✔ | ✔ | ✔ | ✔ | **NHẬN → WF-01** |
| C2 | **Điểm danh bằng mã QR** (sinh viên) | `web/checkin/app.js` `checkin`, rule `studentCheckin()` | ✔ | ✔ | ✔ | ✔ | ✔ | **NHẬN → WF-02** |
| C3 | **Đóng phiên và chốt vắng mặt** | `TeacherRepository.closeSession`, `AutoSessionManager` | ✔ | ✔ | ✔ | ✔ | ✔ | **NHẬN → WF-03** |
| C4 | Điểm danh tay cho sinh viên (sự cố camera/mạng) | `TeacherRepository.manualCheckin(Bulk)`, rule `teacherCreatesRecord()` | ✔ | ✔ | ✔ | ✔ | ✔ | Đạt 5/5. **Không demo riêng**: là nhánh ngoại lệ của WF-03 (BR-10) — xem §5 |
| C5 | Gửi và duyệt yêu cầu sửa điểm danh / nghỉ phép | `request_repository.dart`, rule `requests`, `web/admin/.../RequestsPage.tsx` | ✔ | ✔ | ✔ | ✔ | ✔ | Đạt 5/5 nhưng **chưa chạy thật end-to-end** (Review Queue còn dữ liệu mẫu, TC08 Blocked) → không đưa vào demo, ghi vào Limitations |
| C6 | Điểm danh bằng trợ lý AI (giọng nói / gõ, thẻ xác nhận) | `ai_chat_viewmodel.dart`, `ai_tool_executor.dart`, `functions/src/ai_assistant.js` | ✔ | ✔ | ✔ | ✔ | ✔ | Đạt 5/5. **Đề xuất WF-04 dự phòng** (§4); chỉ demo nếu còn thời gian |
| C7 | Nhập thời khóa biểu bằng ảnh (OCR) → nhận lớp | `scanTimetable`, `timetable_ocr_service.dart` | ✔ | ✔ | ✔ | ✔ | ✔ | Đạt 5/5 nhưng chỉ chạy trên Android, TC27/TC28 chưa chạy → không demo (backup) |
| C8 | Cấp tài khoản từ lời mời (`user_invites` → `users`) | rule `users` create | ✔ | ✘ | ✔ | ✔ | ✔ | Thiếu Q2 (không tạo giá trị nghiệp vụ riêng) → là **Precondition** của WF-01/02 |
| C9 | Nhắc lịch dạy (FCM theo lịch 5 phút) | `sendTeachingReminders` | ✔ | ✔ | ✘ | ✔ | ✔ | Thiếu Q3 (không đổi trạng thái nghiệp vụ) → nhóm tính năng Thông báo |
| C10 | Đồng bộ điểm danh lên FAP | `syncToFap`, `fap_sync.js` | ✔ | ✘ | ✔ | ✔ | ✔ | API FAP chưa tồn tại, function production trả 404 (10/11/2026) → không có kết quả thật |
| C11 | Gửi góp ý / xử lý góp ý | `functions/src/feedback.js` | ✔ | ✔ | ✔ | ? | ✔ | `[THIẾU]` chưa khảo sát đủ để chấm Q4 → để ngoài phạm vi slide |
| C12 | Xem báo cáo chuyên cần / xuất Excel | `report_repository.dart`, `history_download_io.dart` | ✔ | ✔ | ✘ | ✘ | ✔ | Chỉ đọc, không rẽ nhánh theo BR → **nhóm tính năng**, không phải workflow |

### Những thứ bị gọi nhầm là workflow và nên đặt ở đâu

| Bị gọi là | Thực chất | Đặt ở slide |
|---|---|---|
| "Màn hình Điểm danh QR", "Màn hình Lịch sử" | Màn hình (UI) | 11 UI/UX |
| "Quản lý lớp học" (tạo/sửa lớp, import) | CRUD + module | 06 (nhóm tính năng) |
| "Đăng nhập Google" | Chức năng hỗ trợ | Precondition của WF-01/02 |
| "Báo cáo chuyên cần / Xuất Excel" | Nhóm tính năng chỉ đọc | 06 |
| "Mở app → bấm Điểm danh → bấm Xác nhận" | Chuỗi click (user flow) | 11 UI/UX |
| "Module Web Admin" | Nhóm chức năng | 06 |

## 2. Kiểm tra cỡ

| WF | Số bước | Có rẽ nhánh | Gắn pain point (Slide 03) | Kết luận |
|---|:-:|:-:|---|---|
| WF-01 Mở phiên điểm danh QR | 5 | BR-02, BR-03, BR-04 | PP1 — điểm danh thủ công tốn thời gian đầu ca | Vừa |
| WF-02 Điểm danh bằng mã QR | 5 | BR-01, BR-05…BR-08 | PP2 — điểm danh hộ qua ảnh QR | Vừa |
| WF-03 Đóng phiên và chốt vắng mặt | 4 (+ nhánh sửa tay) | BR-09, BR-10, BR-11 | PP3 — kết quả sai, khó đối soát | Vừa |

## 3. Câu chuyện demo (kết quả WF trước = đầu vào WF sau)

`WF-01` GV mở phiên của lớp → tạo **session = open + QR** → `WF-02` SV dùng đúng QR đó để tạo **attendance_records = Present** → `WF-03` GV đóng phiên → SV chưa quét tự có **Absent (AutoAbsent)**, kết quả hiện trong Lịch sử. Cùng một lớp, một session, một bộ bản ghi xuyên suốt ba WF.

Ghép pain point: PP1→WF-01, PP2→WF-02, PP3→WF-03 (đúng 1–1, khớp Slide 03/04).

## 4. Đặc tả 9 trường

### WF-01 · Mở phiên điểm danh QR

| Trường | Nội dung |
|---|---|
| **Mã & tên** | WF-01 · Mở phiên điểm danh QR |
| **Actor** | Giảng viên (`staff`); Hệ thống (Firestore Rules, `AutoSessionManager`, Remote Config) |
| **Trigger** | Giảng viên bắt đầu ca học và bấm "Bắt đầu điểm danh" cho lớp có ca hôm nay (hoặc app tự mở khi tới giờ ca) |
| **Precondition** | GV đã đăng nhập, `role = staff`, `active = true` (BR-01) · lớp có `teacherMemberCode` = GV (BR-02) · thời điểm nằm trong khung giờ ca (BR-03) · nếu bật kiểm tra IP thì lấy được IP công khai |
| **Happy path** | 1. GV chọn lớp, mở hộp thoại **Mở phiên điểm danh** (`StartSessionDialog`), chọn bật/tắt "Kiểm tra IP mạng" (mặc định theo `ip_check_default` = false).<br>2. Hệ thống kiểm tra lớp thuộc GV (BR-02) và giờ ca (BR-03).<br>3. Hệ thống đóng phiên đang mở cũ của lớp (nếu có, BR-04) rồi tạo `sessions/{id}`: `sessionStatus = open`, `qrSecret` ngẫu nhiên, `ipCheck`, `manualAttendanceDeadline` = 00:00 giờ VN hôm sau.<br>4. App hiển thị QR (URL `?s=&t=&ic=`) và đồng hồ đếm ngược.<br>5. Mỗi `qr_refresh_seconds` (60 s) app đổi `qrSecret` (`rotateQr`) — mã cũ hết hiệu lực (BR-05). |
| **Điểm quyết định** | BR-02 lớp có thuộc GV? · BR-03 đang trong giờ ca? · BR-04 lớp đã có phiên mở? (từ màn Lịch sử → chặn; từ màn Điểm danh QR → đóng phiên cũ) · bật IP mà không lấy được IP → không mở |
| **Exception** | `FORBIDDEN` (lớp không thuộc GV) · `SESSION_OUTSIDE_SLOT_TIME` (ngoài giờ ca) · `SESSION_ALREADY_OPEN` (mở thêm từ Lịch sử) · `VALIDATION_ERROR` (bật IP nhưng thiếu IP) |
| **Postcondition** | `sessions/{id}.sessionStatus = open`; QR đang hiển thị và xoay; chưa có `attendance_records` nào của phiên |
| **Truy vết** | FR-04, FR-05, FR-06 → UI-03 (+ hộp thoại UI-03a) → `LiveSessionViewModel.startSession` → `TeacherRepository.startSession` → `createSession` → `Session` → TC03, TC04, TC11 · test: `teacher_repository_test.dart:124` (BR-03), `history_report_schedule_test.dart:329` (BR-04), rules test "GV mở phiên cho lớp của mình" |

### WF-02 · Điểm danh bằng mã QR

| Trường | Nội dung |
|---|---|
| **Mã & tên** | WF-02 · Điểm danh bằng mã QR |
| **Actor** | Sinh viên (`user`); Hệ thống (Firebase Auth, Firestore Rules) |
| **Trigger** | Sinh viên quét QR đang chiếu bằng camera điện thoại; trình duyệt mở trang web check-in |
| **Precondition** | Phiên đang `open` và QR chưa bị xoay (WF-01) · SV có lời mời, `role = user`, có `rollNumber`, `active` (BR-01) · SV có tên trong `enrollments` của lớp (BR-06) |
| **Happy path** | 1. SV quét QR; trang mở với `s`, `t`, `ic`.<br>2. SV đăng nhập Google (lần sau trình duyệt tự giữ phiên).<br>3. Trang `loadProfile` rồi đọc `enrollments` của chính SV; nếu `ic=1` thì `fetchPublicIp`.<br>4. Trang gửi `setDoc(attendance_records/{sessionId}_{rollNumber})`.<br>5. Rules `studentCheckin()` đối chiếu → ghi `Present`; trang hiện **"Điểm danh thành công!"** kèm giờ. |
| **Điểm quyết định** | BR-01 có lời mời? · BR-05 `qrToken == qrSecret` hiện tại? · BR-06 phiên còn `open` và SV có ghi danh? · BR-07 chưa có bản ghi của SV trong phiên? · BR-08 (nếu `ipCheck`) IP SV = `teacherIp`? |
| **Exception** | `DOMAIN_NOT_ALLOWED` · `WRONG_ROLE` · `NOT_ENROLLED` · `IP_MISMATCH` · `SESSION_NOT_FOUND` ("Mã QR đã hết hạn") · quét lần hai → **"Đã ghi nhận"** · `NETWORK_ERROR` + nút Thử lại |
| **Postcondition** | `attendance_records/{sessionId}_{rollNumber}`: `status = Present`, `checkinTime` = giờ máy chủ, `networkVerificationResult = Match` hoặc `Skipped`, `syncedToFap = false` |
| **Truy vết** | FR-08, FR-09 → UI-09 (web check-in) → `checkin()`/`diagnoseDenied()` trong `web/checkin/app.js` → rule `studentCheckin()` → `AttendanceRecord` → TC04 (Partial), TC16, TC17, TC18 (chưa chạy) · test: 11 rules test từ "SV đã ghi danh điểm danh thành công" đến "tài khoản bị khóa / chưa có hồ sơ / GV" |

### WF-03 · Đóng phiên và chốt vắng mặt

| Trường | Nội dung |
|---|---|
| **Mã & tên** | WF-03 · Đóng phiên và chốt vắng mặt |
| **Actor** | Giảng viên (`staff`); Hệ thống (`AutoSessionManager`, Firestore Rules) |
| **Trigger** | GV bấm "Đóng phiên điểm danh", hoặc ca học kết thúc (app tự đóng; kiểm tra mỗi 15 giây) |
| **Precondition** | Phiên thuộc GV và đang `open` (BR-02) |
| **Happy path** | 1. GV bấm đóng phiên (hoặc hết giờ ca).<br>2. App đọc danh sách `enrollments` của lớp và các `attendance_records` đã có của phiên.<br>3. Một batch: `sessions.sessionStatus = closed` + tạo `Absent` (`AutoAbsent`) cho SV chưa có bản ghi (BR-09).<br>4. Tổng quan và Lịch sử cập nhật; GV thấy số Có mặt / Vắng. |
| **Điểm quyết định** | BR-09 SV nào chưa có bản ghi? · BR-10 cần sửa sau đó: còn trong ngày VN → điểm danh tay; quá hạn → BR-11 gửi yêu cầu cho admin |
| **Exception** | `FORBIDDEN` / `SESSION_NOT_FOUND` · `MANUAL_ATTENDANCE_EXPIRED` (sửa tay sau 00:00 VN ngày kế tiếp) · `STUDENT_NOT_ENROLLED` (sửa tay SV ngoài lớp) · SV quét muộn sau khi đóng → bị chặn (BR-06) |
| **Postcondition** | Phiên `closed`; mỗi SV ghi danh có đúng một bản ghi (`Present` hoặc `Absent`/`AutoAbsent`); không ai điểm danh thêm bằng QR được nữa |
| **Truy vết** | FR-07, FR-10, FR-11 → UI-03, UI-05 → `LiveSessionViewModel.closeCurrentSession` → `TeacherRepository.closeSession` → `Session`, `AttendanceRecord` → TC03, TC05, TC12, TC14 · test: `teacher_repository_test.dart:213` (BR-09), `:348` (BR-10), rules test "GV không được điểm danh tay sau deadline của ngày học" |

### WF-04 (đề xuất, dự phòng) · Điểm danh bằng trợ lý AI

Không thuộc 3 WF demo chính (6,5′ chỉ đủ ba WF). Giữ làm slide phụ lục A1 và làm demo bổ sung **chỉ khi** thời lượng ≥ 18′ còn dư.

| Trường | Nội dung |
|---|---|
| **Mã & tên** | WF-04 · Điểm danh bằng trợ lý AI |
| **Actor** | Giảng viên; Hệ thống (Cloud Function `aiAssistant`, Gemini, Firestore Rules) |
| **Trigger** | GV nói hoặc gõ lệnh "Điểm danh SV … lớp … slot …" ở tab AI |
| **Precondition** | GV `staff` đang hoạt động · lớp thuộc GV · hôm nay lớp có phiên (cho điểm danh tay) |
| **Happy path** | 1. App gửi lịch sử hội thoại lên `aiAssistant`.<br>2. Gemini trả lệnh `mark_attendance`.<br>3. `AiToolExecutor` kiểm tra phiên hôm nay và MSSV thuộc lớp, dựng **thẻ xác nhận** từ dữ liệu thật.<br>4. GV bấm Xác nhận → `manualCheckinBulk`.<br>5. Rules cho ghi → AI báo kết quả. |
| **Điểm quyết định** | BR-12 mọi lệnh ghi phải qua thẻ xác nhận; BR-10 hạn trong ngày; BR-13 chỉ lớp của GV |
| **Exception** | `NO_SESSION_TODAY` · `AMBIGUOUS_SESSION` · `STUDENT_NOT_ENROLLED` · `MANUAL_ATTENDANCE_EXPIRED` · GV bấm Hủy · Gemini quá tải → tự chuyển Ollama |
| **Postcondition** | Bản ghi `ManualByGV`/trạng thái được chọn, `networkVerificationResult = Manual` |
| **Truy vết** | FR-14, FR-15 → UI-11 → `AiChatViewModel` → `AiToolExecutor` → `TeacherRepository.manualCheckinBulk` → `AttendanceRecord` · test: `ai_tool_executor_test.dart`, `ai_assistant_flow_test.dart` (52 test), `e2e_test/ai_assistant.e2e.test.mjs` (28/28 pass, chạy 11/11/2026) |

## 5. Những workflow đạt 5/5 nhưng không đưa vào demo

| WF | Lý do không demo | Đặt ở đâu |
|---|---|---|
| C4 Điểm danh tay | Là nhánh ngoại lệ của WF-03 (BR-10); chạy trong Exception của slide 20 | Slide 20 (EXCEPTION), phụ lục |
| C5 Yêu cầu sửa điểm danh | Review Queue của Web Admin vẫn dùng dữ liệu mẫu (`RequestsPage.tsx` dùng `requestRows` từ `mock-data`); TC08 Blocked | Slide 06 (mở rộng), Slide 23 (Limitations) |
| C6 AI | Hết thời lượng demo; có test riêng | Phụ lục A1; slide 06 là nhóm tính năng |
| C7 OCR TKB | Chỉ Android, TC27/TC28 chưa chạy | Slide 06 (nhóm tính năng) |

## 6. Checklist cuối PDF (W14)

| # | Mục kiểm tra | Kết quả | Ghi chú |
|---|---|---|---|
| 1 | Có 2–4 WF lõi, mỗi WF gắn một pain point | **Đạt** | 3 WF ↔ PP1–PP3. Pain point lấy từ `docs/course/prm393-persona-document.md` §06; số liệu cần nhóm xác nhận (SLIDE_CONTENT.md Phụ lục C, G-01) |
| 2 | Tên theo mẫu động từ + đối tượng nghiệp vụ | **Đạt** | "Mở phiên điểm danh QR", "Điểm danh bằng mã QR", "Đóng phiên và chốt vắng mặt" — không chứa "màn hình/module/quản lý/nút" |
| 3 | Đủ 7 thành phần, ≥ 1 exception | **Đạt** | Mỗi WF có ≥ 3 exception mang mã lỗi thật |
| 4 | Điểm quyết định ghi mã BR | **Đạt** | BR-xx là mã đề xuất → nhóm cần xác nhận mã (G-03) |
| 5 | Postcondition khớp state machine | **Đạt** | Khớp `diagrams/08_state_machine.mmd` (open/closed, Present/Absent) |
| 6 | Mỗi nhánh rẽ có test case tương ứng | **Chưa đạt hoàn toàn** | BR-04, BR-12 có test; **BR-08 chỉ có rules test, chưa có Android/web E2E**; TC16–TC18 chưa chạy. Chi tiết ở SLIDE_CONTENT.md Phụ lục B.3 |
| 7 | WF trong demo trùng WF trong thiết kế | **Đạt** | Cùng 3 WF ở slide 07 (nhãn lane), 16, 17–20, 21 |
| 8 | Mỗi WF đạt 5/5 câu kiểm tra | **Đạt** | Bảng §1 |
