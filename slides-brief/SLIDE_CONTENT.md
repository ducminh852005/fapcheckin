# SLIDE_CONTENT — FAP Check-in · Nội dung chi tiết từng slide

> **Dành cho:** bên dựng slide (không phải viết lại nội dung). Khung: *Software Project Presentation Guideline V11* (24 slide nội dung + phụ lục).
> **Sản phẩm:** FAP Check-in — điểm danh bằng mã QR (Flutter mobile cho giảng viên + web check-in cho sinh viên + Firebase, có trợ lý AI).
> **Thời lượng:** 18–20′ (tổng ngân sách các slide dưới đây ≈ 18,8′). **Ngôn ngữ:** Tiếng Việt, giữ thuật ngữ Anh.
> **Chỉ mục "TEXT TRÊN SLIDE" và "HÌNH / BẢNG / BỐ CỤC" được đưa lên slide.** Các mục còn lại (câu hỏi hội đồng, tránh, thuyết minh, nguồn…) là công cụ cho nhóm.

**Nhãn dùng trong file**
- `[THIẾU: …]` — thông tin không có trong dự án, cần thu thập.
- `[SUY RA TỪ CODE: file]` — suy từ mã nguồn, nhóm cần xác nhận.
- `[CẦN NHÓM XÁC NHẬN]` — quyết định / lý do / số liệu mà repo không khẳng định.
- `[MÃ MỚI — ĐỀ XUẤT]` — repo chưa có mã FR / BR / WF; UI-xx tái dùng số trong `ux/user-flow.md`, TC01–TC30 lấy nguyên từ `docs/course/test-cases.md`.

**Workflow lõi (xem `WORKFLOW_SPECS.md` cho đặc tả 9 trường):**
`WF-01` Mở phiên điểm danh QR → `WF-02` Điểm danh bằng mã QR → `WF-03` Đóng phiên và chốt vắng mặt.

**Điều chỉnh so với khung:** giữ đủ 24 slide; Slide 12 (Sequence) và 14 (ERD khái niệm) đánh dấu TÙY CHỌN — nếu chỉ có 15′: gộp 02 vào 03, gộp 14 vào 15, đưa 12 vào phụ lục, demo 2 WF (WF-01 + WF-02). Có đúng 3 WF nên giữ 3 slide Demo (18–20), không phải đánh số lại.

**Cảnh báo quan trọng trước khi dựng slide** (chi tiết ở Phụ lục C):
1. Tài liệu `ux/*.md` và persona ghi "QR 5 giây, JWT/TOTP, gian lận 0%, 25–35 giây" — **mã nguồn thật: QR xoay 60 giây, bí mật ngẫu nhiên `qrSecret`, không có JWT/TOTP, các số KPI không có nguồn đo.** Slide dưới đây dùng số **60 giây** và **không** dùng các KPI đó.
2. Tên project Firebase / URL demo mâu thuẫn giữa các tài liệu (G-06). Cần nhóm chốt trước khi in link lên slide 24.

---

# P1 · PROBLEM

## Slide 01 — Overview · P1 · 30 s

**Câu hỏi hội đồng:** Đây là sản phẩm gì, cho ai, và đã chạy được chưa?
**Tiêu đề trên slide:** FAP Check-in: giảng viên mở QR, sinh viên quét là xong điểm danh
**Phụ đề:** Hệ thống điểm danh lớp học bằng mã QR xoay, không bắt sinh viên cài app.

### TEXT TRÊN SLIDE
1. **FAP Check-in** — hệ thống điểm danh bằng mã QR cho lớp học đại học.
2. Giảng viên mở phiên trên app Flutter; sinh viên quét QR bằng camera và điểm danh trên trang web.
3. **Users:** Giảng viên · Sinh viên · Quản trị viên. **Value:** nhanh hơn gọi tên · chống điểm danh hộ · kết quả rõ ràng. **Platform:** Mobile (Flutter) + Web + Firebase, có trợ lý AI.
4. Nhóm [THIẾU: tên/số nhóm] · môn PRM393 · GVHD [THIẾU: họ tên].

### HÌNH / BẢNG / BỐ CỤC
Mẫu bố cục khung: khối PROJECT NAME (tên + 1 câu) · 3 ô USERS / VALUE / PLATFORM · ô ảnh/GIF bên phải (≥ 50 % diện tích).
- Ảnh/GIF: **màn Live QR** của app giảng viên (QR + danh sách sinh viên nhảy lên) đặt cạnh **màn "Điểm danh thành công!"** trên điện thoại sinh viên.
- Tên file đề xuất: `s01_live_qr_and_success.gif`.

### MINH CHỨNG BẮT BUỘC → minh chứng thật của dự án
GIF 8–10 s quay từ bản đang chạy: GV mở phiên → QR hiện → điện thoại SV quét → trang báo thành công → tên SV xuất hiện trong danh sách bên GV.

### TRÁNH (áp vào dự án này)
Ghi "Flutter + Firebase + Gemini" làm tiêu đề; hoặc nói "hệ thống quản lý chuyên cần" quá chung. Giữ đúng thông điệp *điểm danh bằng QR*.

### LỜI THUYẾT MINH
"Chúng em làm FAP Check-in. Giảng viên mở một phiên điểm danh trên app, màn hình chiếu mã QR; sinh viên quét bằng camera điện thoại là điểm danh xong, không cần cài thêm app. Đây là bản đang chạy."

### ASSET CẦN CHUẨN BỊ
- `s01_live_qr_and_success.gif` (quay emulator/thiết bị thật, xóa tên/email thật).
- Logo nhóm / tên nhóm.

### NGUỒN & TRUY VẾT
README.md (dòng đầu); `docs/README.md`; `mobile/lib/views/teacher/live_session/`; `web/checkin/index.html:306` ("Điểm danh thành công!").

### THIẾU / GIẢ ĐỊNH
`[THIẾU: tên nhóm, thành viên, GVHD — final-report-source.md vẫn còn placeholder]`. Môn **PRM393** lấy từ docs/course.

---

## Slide 02 — Context · P1 · 30 s · (GỘP VÀO 03 nếu chỉ có 15′)

**Câu hỏi hội đồng:** Đề tài ra đời trong bối cảnh nào, công việc hiện được thực hiện ra sao?
**Tiêu đề trên slide:** Mỗi ca học, giảng viên đại học đọc tên cả lớp 30–40 sinh viên để điểm danh
**Phụ đề:** Bối cảnh Đại học FPT: điểm danh thủ công trên cổng FAP, nhiều ca mỗi ngày.

### TEXT TRÊN SLIDE
1. **Môi trường:** Đại học FPT, lớp 30–40 sinh viên, giảng viên dạy 4–5 ca/ngày.
2. **Người liên quan:** giảng viên, sinh viên, phòng đào tạo / khảo thí.
3. **Công cụ hiện tại:** cổng FAP (nhập tay từng sinh viên).
4. **Hiện trạng:** quan sát 1 lớp 32 sinh viên: giảng viên mất **8 phút 40 giây** để gọi tên.

### HÌNH / BẢNG / BỐ CỤC
3 thẻ ngang: MÔI TRƯỜNG · NGƯỜI LIÊN QUAN · CÔNG CỤ HIỆN TẠI. Dưới là dải QUY TRÌNH HIỆN TẠI 4 ô: ① Mở danh sách lớp trên FAP → ② Đọc tên từng sinh viên → ③ Bấm trạng thái Present/Absent → ④ Lưu. Dải cuối HIỆN TRẠNG: "32 SV · 8′40″ (quan sát O-01)".

### MINH CHỨNG BẮT BUỘC → minh chứng thật của dự án
Một con số quy mô: **O-01** (quan sát lớp PRM393, 32 SV, 8 phút 40 giây) — `docs/course/prm393-persona-document.md` §06. Ảnh màn danh sách điểm danh FAP: `[THIẾU: ảnh chụp màn FAP hiện tại, che dữ liệu cá nhân]`.

### TRÁNH (áp vào dự án này)
Nói trước về QR hay Firebase ở slide này; kể cả quy trình FAP quá dài. Chỉ mô tả hiện trạng, vấn đề để slide 03.

### LỜI THUYẾT MINH
"Hiện nay giảng viên điểm danh bằng cách đọc tên từng sinh viên rồi bấm trạng thái trên FAP. Nhóm quan sát một lớp 32 sinh viên: riêng việc gọi tên mất gần chín phút."

### ASSET CẦN CHUẨN BỊ
- Ảnh màn FAP (che thông tin cá nhân) — `s02_fap_current.png` `[THIẾU]`.

### NGUỒN & TRUY VẾT
`ux/persona.md` §1 (bối cảnh); `docs/course/prm393-persona-document.md` §06 Evidence O-01.

### THIẾU / GIẢ ĐỊNH
`[CẦN NHÓM XÁC NHẬN]`: O-01 do nhóm tự ghi trong tài liệu persona, không có dữ liệu thô (ghi chú quan sát, thời gian). "4–5 ca/ngày" lấy từ persona P01 (giả định).

---

## Slide 03 — Problem · P1 · 40 s

**Câu hỏi hội đồng:** Vấn đề có thật không, và gây hậu quả gì?
**Tiêu đề trên slide:** Điểm danh thủ công vừa tốn thời gian, vừa dễ điểm danh hộ và dễ sai
**Phụ đề:** Ba điểm nghẽn, mỗi điểm có nguyên nhân và bằng chứng đã ghi nhận.

### TEXT TRÊN SLIDE
Bảng 3 hàng (PAIN POINT · NGUYÊN NHÂN · IMPACT):
1. **PP1 Mất thời gian đầu ca** · phải đọc tên từng người · 8′40″ cho lớp 32 SV (O-01).
2. **PP2 Điểm danh hộ** · QR/danh sách có thể chuyển cho người vắng mặt · GV từng thấy "cả nhóm ở nhà vẫn điểm danh đều" (R-03).
3. **PP3 Kết quả sai, khó đối soát** · bấm nhầm trạng thái; SV không biết đã được ghi nhận chưa · bị cấm thi oan, khiếu nại (R-01); SV phải hỏi lại thầy (R-05).

### HÌNH / BẢNG / BỐ CỤC
Bảng 3 cột × 3 hàng như trên. Dưới cùng: khung MINH CHỨNG gồm 4 chip: `O-01 quan sát` · `R-01 phỏng vấn GV` · `R-03 phỏng vấn GV` · `R-05 phỏng vấn SV`, kèm ghi chú nguồn "kế hoạch n = 8 người, 08–14/10/2026".

### MINH CHỨNG BẮT BUỘC → minh chứng thật của dự án
Evidence log trong `docs/course/prm393-persona-document.md` §06: O-01 (quan sát), R-01, R-03, R-05 (trích dẫn phỏng vấn đã ẩn danh). Trích nguyên văn 1 câu trên slide, ví dụ R-03: *"Tôi từng chiếu QR cố định, hôm sau phát hiện cả nhóm KTX ở nhà vẫn điểm danh đều đều qua ảnh chụp gửi Zalo."*

### TRÁNH (áp vào dự án này)
(1) Chèn các KPI nền "gian lận 15–20 %", "lỗi thao tác cao" từ `ux/persona.md` — **không có nguồn đo**. (2) Biến slide thành mô tả giải pháp QR.

### LỜI THUYẾT MINH
"Có ba điểm nghẽn. Thứ nhất, thời gian: gần chín phút cho một lớp 32 người. Thứ hai, điểm danh hộ — một giảng viên kể ảnh QR cố định bị gửi qua Zalo. Thứ ba, dữ liệu sai hoặc không minh bạch: bấm nhầm trạng thái có thể dẫn đến cấm thi oan, và sinh viên không biết mình đã được ghi nhận chưa."

### ASSET CẦN CHUẨN BỊ
Không cần ảnh; cần bảng 3×3 và 1 trích dẫn in nghiêng.

### NGUỒN & TRUY VẾT
`prm393-persona-document.md` §06 (O-01, O-03, R-01, R-03, R-05).

### THIẾU / GIẢ ĐỊNH
`[THIẾU: dữ liệu thô khảo sát/phỏng vấn; cỡ mẫu thực tế]` — kế hoạch ghi n = 8 (3 GV, 4 SV, 1 khảo thí) nhưng evidence log chỉ có 6 mục và ký hiệu không nhất quán (T-01 vs R-01). `[CẦN NHÓM XÁC NHẬN]` khi hội đồng hỏi nguồn. Cách thu thập nhanh nhất: đo thời gian gọi tên 3 lớp khác nhau bằng đồng hồ bấm giờ và ghi vào bảng.

---

## Slide 04 — Proposed Solution · P1 · 40 s

**Câu hỏi hội đồng:** Giải pháp có trúng vấn đề không, phạm vi làm tới đâu?
**Tiêu đề trên slide:** QR xoay + kiểm tra ở tầng dữ liệu giải quyết cả ba điểm nghẽn
**Phụ đề:** Mỗi pain point có đúng một câu trả lời, gắn với workflow sẽ demo.

### TEXT TRÊN SLIDE
Bảng (PAIN POINT · SOLUTION · EXPECTED VALUE · DEMO):
1. PP1 Mất thời gian → GV mở phiên, SV tự quét → **WF-01** · điểm danh song song, không đọc tên.
2. PP2 Điểm danh hộ → QR đổi mỗi 60 s; mỗi SV một bản ghi; phải thuộc lớp; có thể bật kiểm tra IP → **WF-02** · khó chuyển tiếp mã.
3. PP3 Sai / khó đối soát → đóng phiên tự ghi Absent; lịch sử; điểm danh tay có hạn trong ngày → **WF-03** · kết quả rõ, truy vết được.
- **In-scope (MVP):** 3 workflow trên + đăng nhập Google, phân quyền.
- **Out-of-scope:** đồng bộ FAP thật (chưa có API), duyệt yêu cầu trên Web Admin (chưa chạy thật).

### HÌNH / BẢNG / BỐ CỤC
Bảng 4 cột × 3 hàng; hai ô dưới: IN-SCOPE (xanh) / OUT-OF-SCOPE (xám) kèm lý do ngắn.

### MINH CHỨNG BẮT BUỘC → minh chứng thật của dự án
Bảng ánh xạ pain point ↔ solution (chính là nội dung slide). Mỗi hàng liên kết tới 1 WF khớp slide 18–20.

### TRÁNH (áp vào dự án này)
Gọi "AI" là giá trị cốt lõi ở đây: AI là tính năng hỗ trợ (slide 06), không trả lời pain point nào trong 3 điểm trên. Không ghi "chống gian lận 100 %".

### LỜI THUYẾT MINH
"Mỗi điểm nghẽn có một câu trả lời: sinh viên tự quét thay vì gọi tên; mã QR đổi liên tục kèm kiểm tra quyền ở tầng dữ liệu để khó điểm danh hộ; và đóng phiên tự động ghi vắng để kết quả rõ ràng. Ba phần này là ba workflow sẽ demo."

### ASSET CẦN CHUẨN BỊ
Không cần ảnh.

### NGUỒN & TRUY VẾT
`docs/01-kien-truc-tong-the.md`, `docs/02-luong-diem-danh-qr.md`, `docs/06-rui-ro-va-mo-rong.md`; WF-01..03 (`WORKFLOW_SPECS.md`).

### THIẾU / GIẢ ĐỊNH
"Mục tiêu đo được" chưa có: chỉ tiêu "< 45 giây cả lớp" trong persona chưa được đo trên hệ thống thật `[THIẾU: đo thời gian điểm danh 1 lớp thật ≥ 20 SV]`.

---

## Slide 05 — Main Actors · P1 · 30 s

**Câu hỏi hội đồng:** Ai dùng hệ thống, họ là ai, và mỗi vai trò được làm gì?
**Tiêu đề trên slide:** Ba vai trò người dùng, mỗi vai trò bị giới hạn bằng Security Rules
**Phụ đề:** Quyền hạn được thi hành ở tầng dữ liệu, không chỉ ở giao diện.

### TEXT TRÊN SLIDE
Bảng ACTOR · MÔ TẢ · QUYỀN HẠN CHÍNH (7 hàng tối đa):
1. **Giảng viên** (`staff`) · dùng app Flutter · quản lý lớp mình phụ trách: mở/đóng phiên, điểm danh tay, lịch sử, báo cáo, tab AI.
2. **Sinh viên** (`user`) · dùng trang web, không cài app · tạo bản ghi điểm danh của chính mình; xem dữ liệu của mình; gửi yêu cầu.
3. **Quản trị viên** (`admin`) · dùng Web Admin / script · cấp lời mời tài khoản, quản lý lớp & ghi danh, duyệt yêu cầu, phát thông báo.
4. **Google Sign-In / Firebase Auth** · hệ thống ngoài · xác thực danh tính.
5. **Gemini API** · hệ thống ngoài · trợ lý AI của giảng viên (qua Cloud Function).
6. **API FAP** · hệ thống ngoài · chưa có — đồng bộ chỉ là điểm tích hợp giữ chỗ.

### HÌNH / BẢNG / BỐ CỤC
Bảng 3 cột × 6 hàng; cột đầu có chip màu (người dùng = xanh dương, hệ thống ngoài = xám). Cột phải: thêm biểu tượng nhỏ nền tảng (📱 / 🌐).

### MINH CHỨNG BẮT BUỘC → minh chứng thật của dự án
Bảng khớp ma trận quyền trong `docs/data-model.md` §4 và `firebase/firestore.rules`. Có thể chèn thêm 1 dòng chú thích: "106 test Security Rules đạt trên Emulator (chạy 11/11/2026)".

### TRÁNH (áp vào dự án này)
Ghi "Admin duyệt đơn" như đã chạy end-to-end — Review Queue còn dữ liệu mẫu. Ghi "Sinh viên dùng app" — sinh viên dùng web.

### LỜI THUYẾT MINH
"Có ba vai trò. Giảng viên dùng app Flutter, sinh viên chỉ cần trình duyệt, quản trị viên cấp tài khoản. Quyền được thi hành bằng Firestore Security Rules nên dù ai gọi trực tiếp vào dữ liệu cũng bị chặn nếu sai vai trò."

### ASSET CẦN CHUẨN BỊ
Icon 3 vai trò (tự vẽ đơn giản hoặc Material icons).

### NGUỒN & TRUY VẾT
`docs/data-model.md` §1, §4; `docs/05-xac-thuc-va-phan-quyen.md`; `firebase/firestore.rules` (users: dòng 73–114).

### THIẾU / GIẢ ĐỊNH
Không có.

---

## Slide 06 — Main Features · P1 · 45 s

**Câu hỏi hội đồng:** Hệ thống làm được gì, và đâu là các workflow quan trọng nhất?
**Tiêu đề trên slide:** Năm nhóm tính năng; ba workflow xuyên suốt một phiên điểm danh
**Phụ đề:** Từ lúc mở phiên đến khi chốt kết quả.

### TEXT TRÊN SLIDE
**5 nhóm tính năng** (mỗi nhóm ≤ 1 dòng):
- **F1 Tài khoản & quản trị** — Google Sign-In, lời mời, 3 vai trò.
- **F2 Phiên điểm danh QR** — mở phiên, QR xoay 60 s, kiểm tra IP tùy chọn, đóng phiên.
- **F3 Check-in sinh viên** — quét QR, điểm danh trên web, báo rõ lý do bị từ chối.
- **F4 Điều chỉnh, lịch sử & báo cáo** — điểm danh tay, lịch sử, xuất Excel, yêu cầu sửa.
- **F5 Trợ lý AI & tiện ích** — chat/giọng nói, import thời khóa biểu bằng ảnh, nhắc lịch.

**3 workflow lõi** (thẻ): 
- **WF-01 Mở phiên điểm danh QR** · Actor: Giảng viên · Trigger: bắt đầu ca · Kết quả: phiên `open` + QR · Slide 18.
- **WF-02 Điểm danh bằng mã QR** · Sinh viên · quét QR · bản ghi `Present` · Slide 19.
- **WF-03 Đóng phiên và chốt vắng mặt** · Giảng viên · hết ca / bấm đóng · `Absent` cho người chưa quét · Slide 20.

### HÌNH / BẢNG / BỐ CỤC
Hàng trên: 5 thẻ F1–F5 (thẻ F2, F3, F4 gắn chấm xanh dương = chứa WF). Hàng dưới: 3 thẻ WF theo layout khung (Actor / Trigger / Kết quả / Tính năng). Dòng cuối: "Ngoài MVP: duyệt yêu cầu trên Web Admin, đồng bộ FAP — xem Slide 23."

### MINH CHỨNG BẮT BUỘC → minh chứng thật của dự án
Nhóm tính năng + 2–4 workflow sẽ demo (3 thẻ WF). Mã khớp `WORKFLOW_SPECS.md`.

### TRÁNH (áp vào dự án này)
Liệt kê toàn bộ menu app (Tổng quan, Lớp học, Lịch dạy, Lịch sử, Yêu cầu, AI, Cài đặt…). Chỉ giữ 5 nhóm.

### LỜI THUYẾT MINH
"Hệ thống có năm nhóm tính năng. Ba workflow nối với nhau thành một câu chuyện: giảng viên mở phiên, sinh viên quét để điểm danh, rồi giảng viên đóng phiên và hệ thống chốt vắng. Ba workflow này sẽ được demo ở slide 18 đến 20."

### ASSET CẦN CHUẨN BỊ
Không cần ảnh.

### NGUỒN & TRUY VẾT
`README.md` (bảng vai trò); `mobile/lib/views/main_screen.dart` (route); FR-01…FR-17 (Phụ lục B); WF-01..03.

### THIẾU / GIẢ ĐỊNH
FR-xx là `[MÃ MỚI — ĐỀ XUẤT]`.

---

# P2 · DESIGN (toàn hệ thống)

## Slide 07 — Business Flow · P2 · 60 s

**Câu hỏi hội đồng:** Nghiệp vụ của hệ thống vận hành thế nào, ai làm gì ở đâu?
**Tiêu đề trên slide:** Một phiên điểm danh đi qua bốn bên và bốn điểm rẽ theo quy tắc nghiệp vụ
**Phụ đề:** Từ lời mời tài khoản đến khi chốt kết quả và xử lý ngoại lệ.

### TEXT TRÊN SLIDE
1. Bốn lane: **Quản trị viên · Giảng viên · Hệ thống · Sinh viên**.
2. Bốn điểm rẽ: **BR-02/03** mở phiên · **BR-05…08** check-in · **BR-09** chốt vắng · **BR-10/11** sửa kết quả.
3. Ngoại lệ: ngoài giờ ca; QR hết hạn / không thuộc lớp; quá hạn sửa tay → gửi yêu cầu.
4. Chi tiết từng workflow xem khi demo (Slide 18–20).

### HÌNH / BẢNG / BỐ CỤC
**Sơ đồ activity swimlane:** `diagrams/07_business_flow.mmd` (xuất PNG; hoặc dựng lại bằng shape trong PowerPoint theo cùng cấu trúc). Màu: xanh dương = luồng chính; đỏ = nhánh ngoại lệ (2 khối đỏ: "Báo lỗi, không tạo phiên", "Thấy lý do bị từ chối"). Gắn nhãn WF-01/02/03 lên khối bắt đầu của từng workflow.

### MINH CHỨNG BẮT BUỘC → minh chứng thật của dự án
Một activity tổng thể có swimlane, mã BR tại điểm rẽ; các BR dẫn về luật thật trong `firestore.rules` (bảng ở Phụ lục B §1).

### TRÁNH (áp vào dự án này)
Vẽ thêm sơ đồ riêng cho từng màn hình; thay bằng danh sách "bấm nút A → nút B".

### LỜI THUYẾT MINH
"Quản trị viên cấp lời mời tài khoản. Giảng viên mở phiên — hệ thống kiểm tra lớp có thuộc giảng viên và có đang trong giờ ca không. Sinh viên quét QR; Firestore Rules kiểm tra mã QR, phiên còn mở, sinh viên thuộc lớp và chưa điểm danh. Khi đóng phiên, hệ thống ghi vắng cho người chưa quét. Nếu cần sửa sau đó: còn trong ngày thì điểm danh tay, quá hạn thì gửi yêu cầu cho quản trị viên."

### ASSET CẦN CHUẨN BỊ
`s07_business_flow.png` (render từ `diagrams/07_business_flow.mmd`; chưa kiểm tra render).

### NGUỒN & TRUY VẾT
`diagrams/07_business_flow.mmd`; `docs/02-luong-diem-danh-qr.md`; `docs/cross-role-flow.md`; BR-01…BR-13.

### THIẾU / GIẢ ĐỊNH
Mã BR là `[MÃ MỚI — ĐỀ XUẤT]`. Nhánh "duyệt yêu cầu" vẽ theo Rules/thiết kế, UI duyệt chưa chạy thật (ghi chú nhỏ trên sơ đồ: "đang phát triển").

---

## Slide 08 — State Machine · P2 · 40 s

**Câu hỏi hội đồng:** Đối tượng chính đi qua những trạng thái nào, chuyển nào bị cấm?
**Tiêu đề trên slide:** Phiên và bản ghi điểm danh chỉ đổi trạng thái theo luật; ba chuyển bị cấm đều có test
**Phụ đề:** Trạng thái nghiệp vụ lưu trong Firestore, không phải trạng thái giao diện.

### TEXT TRÊN SLIDE
1. **Session:** `open` → `closed` (đóng bởi GV hoặc hết ca); `expired` là trạng thái suy ra khi quá giờ mà chưa đóng.
2. **AttendanceRecord:** → `Present` (check-in) hoặc `Absent` (đóng phiên); `Absent` → `ManualByGV` (điểm danh tay, BR-10).
3. Transition = **Event [Guard] / Action**, ví dụ `checkin [QR đúng ∧ phiên open ∧ đã ghi danh ∧ chưa có bản ghi] / create Present`.
4. **Cấm:** quét lần hai / sửa / xóa bản ghi · check-in khi phiên `closed` · điểm danh tay sau 00:00 ngày kế tiếp.

### HÌNH / BẢNG / BỐ CỤC
Sơ đồ `diagrams/08_state_machine.mmd` — hai khối cạnh nhau (Session | AttendanceRecord) trong **một** sơ đồ. Màu: xám = trạng thái; mũi tên xanh = chuyển hợp lệ; đỏ = chuyển bị cấm (3 mũi tên đỏ có nhãn "TEST"). Chân slide: *Transition = Event [Guard] / Action*.

### MINH CHỨNG BẮT BUỘC → minh chứng thật của dự án
3 chuyển cấm + test: 
- "điểm danh lần hai (trùng) → bị chặn" & "SV không sửa / xóa bản ghi của mình sau khi điểm danh" (`firebase/tests/firestore.rules.test.mjs`);
- "phiên đã đóng → bị chặn";
- "GV không được điểm danh tay sau deadline của ngày học".

### TRÁNH (áp vào dự án này)
Vẽ state cho từng màn hình (loading/empty…) — đó là trạng thái UI. Và **không** tuyên bố "closed → open bị cấm": Rules hiện không chặn (G-12).

### LỜI THUYẾT MINH
"Phiên có hai trạng thái lưu thật là mở và đóng. Bản ghi điểm danh bắt đầu bằng Present khi sinh viên quét, hoặc Absent khi đóng phiên. Ba chuyển bị cấm đều có test: không quét lần hai hoặc sửa bản ghi, không check-in khi phiên đã đóng, và điểm danh tay chỉ được trong ngày."

### ASSET CẦN CHUẨN BỊ
`s08_state_machine.png` (từ `diagrams/08_state_machine.mmd`).

### NGUỒN & TRUY VẾT
`firebase/firestore.rules:189–296` (sessions, attendance_records); `teacher_repository.dart:338` (`closeSession`); `teacher_data.dart:160,168` (`effectiveSessionStatusAt`, `canManuallyAttendOn`); BR-05…BR-10.

### THIẾU / GIẢ ĐỊNH
`[SUY RA TỪ CODE: teacher_data.dart]` — `expired` là giá trị suy ra khi đọc, không lưu. ERD cũ ghi thêm `cancelled`, mã không dùng → bỏ. Chưa có test cho chuyển `closed → open` (G-12).

---

## Slide 09 — System Architecture · P2 · 50 s

**Câu hỏi hội đồng:** Hệ thống gồm những khối nào, chạy ở đâu, vì sao thiết kế như vậy?
**Tiêu đề trên slide:** Không có máy chủ riêng: ứng dụng nói thẳng với Firebase, Rules làm hàng rào
**Phụ đề:** Ba client, một backend Firebase, các dịch vụ ngoài phục vụ AI/OCR.

### TEXT TRÊN SLIDE
1. **Client:** app giảng viên (Flutter) · trang check-in sinh viên (HTML + Firebase JS SDK) · Web Admin (React).
2. **Firebase:** Auth · Firestore + Security Rules · Storage · Remote Config · Hosting · Cloud Functions.
3. **Ngoài:** Gemini API (AI), Cloud Vision (OCR), Cloud Text-to-Speech, Ollama (AI dự phòng), API FAP (chưa có).
4. **Triển khai:** Firebase Hosting + Functions (asia-southeast1) · GitHub Actions: CI → preview → deploy.
5. **Quyết định:** *Chọn "Rules-first, không backend riêng" để ít thành phần vận hành và chống trùng ngay tại CSDL — đánh đổi:* Rules chỉ trả `permission-denied`; báo cáo tính ở client.

### HÌNH / BẢNG / BỐ CỤC
Sơ đồ container: `diagrams/09_architecture.mmd` — 3 cột CLIENT · FIREBASE · HỆ THỐNG NGOÀI. Nét liền = đồng bộ; nét đứt = không đồng bộ / chưa nối (Ollama fallback, đồng bộ FAP). Dải dưới: DEPLOYMENT + QUYẾT ĐỊNH theo khung.

### MINH CHỨNG BẮT BUỘC → minh chứng thật của dự án
Sơ đồ container + 1 quyết định kiến trúc có trong `docs/01-kien-truc-tong-the.md` ("Vì sao Rules-first…").

### TRÁNH (áp vào dự án này)
Chèn đủ 9 Cloud Function thành 9 hộp — nhóm lại trong một khối. Không nói "microservices".

### LỜI THUYẾT MINH
"Hệ thống không có máy chủ trung gian: app giảng viên và trang sinh viên nói trực tiếp với Firestore, còn Security Rules quyết định ai được đọc ghi gì. Những việc cần máy chủ như OCR, nhắc lịch, trợ lý AI chạy trong Cloud Functions. Đánh đổi là Rules chỉ trả permission-denied nên trang sinh viên phải tự chẩn đoán lý do."

### ASSET CẦN CHUẨN BỊ
`s09_architecture.png` (từ `diagrams/09_architecture.mmd`).

### NGUỒN & TRUY VẾT
`docs/01-kien-truc-tong-the.md`; `firebase.json`; `firebase/functions/index.js`; `.github/workflows/ci.yml`, `deploy.yml`.

### THIẾU / GIẢ ĐỊNH
`[CẦN NHÓM XÁC NHẬN]` project Firebase production (`ducminh-41459` trong `.firebaserc`/deploy.yml, `fapcheckin-3bn2di` trong README) — G-06. `[CẦN NHÓM XÁC NHẬN]` lý do chọn Flutter/React/Gemini ngoài 2 quyết định đã có trong docs.

---

## Slide 10 — Technology Stack · P2 · 40 s

**Câu hỏi hội đồng:** Hệ thống dùng những công nghệ nào, mỗi thứ để làm gì?
**Tiêu đề trên slide:** Flutter cho giảng viên, Firebase cho toàn bộ backend, Gemini cho trợ lý
**Phụ đề:** Chỉ liệt kê công nghệ có trong manifest và cấu hình.

### TEXT TRÊN SLIDE
Bảng NHÓM · CÔNG NGHỆ · DÙNG ĐỂ LÀM GÌ (7 hàng):
1. **Mobile** · Flutter (Dart), Provider (MVVM), go_router, qr_flutter · app giảng viên, hiển thị QR.
2. **Web** · HTML + Firebase JS SDK; React 19 + Vite + TypeScript + Tailwind · trang SV; Web Admin.
3. **Backend** · Firebase Auth, Cloud Firestore + Rules, Storage, Remote Config, Hosting, Cloud Functions (Node 22) · dữ liệu, quyền, tác vụ nền.
4. **AI** · Gemini API qua Cloud Function; Ollama (dự phòng); Cloud TTS; speech_to_text · trợ lý, giọng nói tiếng Việt.
5. **Dev & Test** · Git/GitHub; `flutter_test`; `node:test`, `@firebase/rules-unit-testing`; Appium (QA) · kiểm thử.
6. **DevOps** · GitHub Actions (ci / deploy / mobile-build), firebase-tools 15 · test & deploy tự động.
7. **Ops** · Firebase Crashlytics, Analytics · theo dõi lỗi.
- Lý do chọn (3): **Firebase** — bỏ máy chủ, Rules chống trùng ở CSDL; **Web cho SV** — không bắt cài app; **Gemini qua proxy** — giấu API key, vẫn chịu Rules.

### HÌNH / BẢNG / BỐ CỤC
Bảng 3 cột × 7 hàng. Cột "Công nghệ" dùng chip chữ (không bức tường logo). Dải cuối "VÌ SAO" 3 chip.

### MINH CHỨNG BẮT BUỘC → minh chứng thật của dự án
Mỗi dòng có file nguồn: `mobile/pubspec.yaml`, `packages/core/pubspec.yaml`, `web/admin/package.json`, `firebase/functions/package.json`, `.github/workflows/*.yml`.

### TRÁNH (áp vào dự án này)
Ghi Grafana/Sentry/PostgreSQL/Docker (không dùng). Ghi "Gemini OCR" — OCR hiện là **Cloud Vision**.

### LỜI THUYẾT MINH
"Mobile là Flutter theo MVVM; backend hoàn toàn là Firebase. Trợ lý AI gọi Gemini qua Cloud Function để giấu khóa API. Kiểm thử dùng Flutter test, node test và Rules unit test trên Emulator; CI chạy bằng GitHub Actions."

### ASSET CẦN CHUẨN BỊ
Không cần logo; nếu dùng, tối đa 6 logo nhỏ.

### NGUỒN & TRUY VẾT
`mobile/pubspec.yaml` (provider, go_router, qr_flutter, speech_to_text, flutter_tts, firebase_*); `packages/core/pubspec.yaml` (cloud_firestore ^7.1.0, firebase_auth, cloud_functions); `web/admin/package.json` (react ^19, vite ^8, tailwindcss ^4, firebase ^12); `firebase/functions/package.json` (node 22, @google-cloud/vision, text-to-speech); `.github/workflows/`.

### THIẾU / GIẢ ĐỊNH
`[CẦN NHÓM XÁC NHẬN]` lý do chọn Flutter và React cho Web Admin (docs gốc dự định Flutter Web nhưng mã dùng React — `docs/course/gap-review.md` mục 1). Figma có dùng nhưng không có link (G-05).

---

## Slide 11 — UI/UX Design · P2 · 40 s

**Câu hỏi hội đồng:** Giao diện được tổ chức thế nào và có nhất quán, dễ dùng không?
**Tiêu đề trên slide:** Giao diện xoay quanh một màn hình chiếu: QR bên trái, danh sách sinh viên bên phải
**Phụ đề:** Điều hướng 1 cấp, thiết kế sửa theo phản hồi của giảng viên và sinh viên.

### TEXT TRÊN SLIDE
1. **Sitemap app GV:** Tổng quan (UI-02, gồm báo cáo) · Điểm danh QR (UI-03) · Lớp học (UI-04) · Lịch sử (UI-05) · Lịch dạy (UI-07) · Yêu cầu (UI-10) · Trợ lý AI (UI-11) · Cài đặt/Hồ sơ (UI-08). Web SV = UI-09.
2. **Wireframe → Mockup → Final (Figma):** `[THIẾU: link Figma]`.
3. **4 trạng thái:** empty · loading · error · success (ví dụ web SV: "Điểm danh thành công!", "Mã QR đã hết hạn").
4. **Sau góp ý:** SV không biết đã được ghi nhận chưa (R-05) → trang báo thành công rõ + "Đã ghi nhận" khi quét lại; GV sợ bấm nhầm (R-01) → thẻ xác nhận ở trợ lý AI.

### HÌNH / BẢNG / BỐ CỤC
Cột trái: sitemap (1 hàng 8 hộp nhỏ). Giữa: 3 ảnh tiến hóa **Wireframe / Mockup / Final** của màn Điểm danh QR. Phải: 4 thumbnail trạng thái của trang web SV (loading, success, "Đã ghi nhận", lỗi QR hết hạn). Dải dưới: "SAU GÓP Ý" 2 mũi tên.

### MINH CHỨNG BẮT BUỘC → minh chứng thật của dự án
Sitemap + UI cuối: ảnh chụp thật các màn (UI-03, UI-09). Link Figma `[THIẾU]`.

### TRÁNH (áp vào dự án này)
Chiếu cả 12 màn. Nói "đạt WCAG AA, phản hồi < 150 ms" — các số này nằm trong `ux/design-decisions.md` nhưng **không có bằng chứng đo trong repo**.

### LỜI THUYẾT MINH
"App giảng viên có tám mục điều hướng, nhưng trọng tâm là màn Điểm danh QR: mã QR một bên, danh sách sinh viên cập nhật bên kia để không phải chuyển tab. Trang sinh viên chỉ có bốn trạng thái. Hai phản hồi từ phỏng vấn đã đổi thiết kế: báo thành công rõ ràng cho sinh viên và thẻ xác nhận trước khi AI ghi dữ liệu."

### ASSET CẦN CHUẨN BỊ
- `s11_wireframe.png`, `s11_mockup.png`, `s11_final_live_qr.png` `[THIẾU: export từ Figma]`.
- 4 ảnh `s11_web_*.png` chụp từ `web/checkin` (chạy ở Emulator, che tên thật).
- Link Figma `[THIẾU]`.

### NGUỒN & TRUY VẾT
`mobile/lib/views/main_screen.dart` (route); `ux/user-flow.md` (sitemap); `ux/design-decisions.md`; `web/checkin/app.js` (ERROR_MAP); `index.html:306,328`; `docs/ai-assistant.md` (thẻ xác nhận).

### THIẾU / GIẢ ĐỊNH
`[THIẾU: Figma, ảnh wireframe/mockup]`. Mã UI-06 (Báo cáo) bị gộp vào Tổng quan (route `bao-cao` → `tong-quan`, `main_screen.dart`). UI-10, UI-11, UI-12 là `[MÃ MỚI — ĐỀ XUẤT]`.

---

## Slide 12 — Sequence Diagram · P2 · 35 s · TÙY CHỌN (đưa vào phụ lục nếu ≤ 15′)

**Câu hỏi hội đồng:** Khi người dùng bấm nút, bên trong hệ thống diễn ra những gì?
**Tiêu đề trên slide:** Khi sinh viên quét QR, Rules quyết định cho ghi hay từ chối
**Phụ đề:** Một tương tác điển hình: lifeline và message trùng tên hàm thật.

### TEXT TRÊN SLIDE
1. Tương tác: sinh viên điểm danh trên `web/checkin`.
2. Lifeline: Sinh viên · `app.js` · Firebase Auth · Firestore + Rules.
3. Khối **alt**: không có lời mời (BR-01) · không ghi danh (BR-06) · Rules đạt (BR-05…08) · `permission-denied` → `diagnoseDenied`.
4. Message là hàm thật: `loadProfile`, `checkin`, `fetchPublicIp`, `diagnoseDenied`.

### HÌNH / BẢNG / BỐ CỤC
Sequence `diagrams/12_sequence.mmd` — 4 lifeline, 1 khối `alt` lồng `opt` (khi `ic = 1`), mũi tên đỏ cho nhánh từ chối.

### MINH CHỨNG BẮT BUỘC → minh chứng thật của dự án
Message khớp `web/checkin/app.js` (dòng 139, 165, 178, 190) và `studentCheckin()` (`firestore.rules:235`).

### TRÁNH (áp vào dự án này)
Vẽ sequence cho cả mở phiên, đóng phiên, AI. Chỉ 1 sơ đồ.

### LỜI THUYẾT MINH
"Sinh viên đăng nhập, trang đọc ghi danh của sinh viên rồi gửi một lệnh tạo bản ghi điểm danh. Rules kiểm tra mã QR, phiên, ghi danh và IP. Nếu bị từ chối, trang đọc thêm bản ghi của chính sinh viên để chọn thông báo phù hợp."

### ASSET CẦN CHUẨN BỊ
`s12_sequence.png` (từ `diagrams/12_sequence.mmd`).

### NGUỒN & TRUY VẾT
`web/checkin/app.js:139–232`; `firebase/firestore.rules:235–261`; BR-01, 05, 06, 07, 08.

### THIẾU / GIẢ ĐỊNH
Không có.

---

## Slide 13 — Class Design · P2 · 30 s

**Câu hỏi hội đồng:** Code chia trách nhiệm ra sao, business rule nằm ở đâu?
**Tiêu đề trên slide:** View chỉ hiển thị; luật nghiệp vụ nằm ở Repository và Security Rules
**Phụ đề:** MVVM + Repository dùng chung giữa mobile và web admin qua `packages/core`.

### TEXT TRÊN SLIDE
1. Tầng: **View** (`LiveSessionBody`) → **ViewModel** (`LiveSessionViewModel`) → **Repository** (`TeacherRepository`, `RequestRepository`) → Firestore.
2. Luật: `createSession` (BR-02/03/04), `closeSession` (BR-09), `canManuallyAttendOn` (BR-10) trong `packages/core`.
3. `AutoSessionManager` mở/đóng phiên theo giờ ca; `AiToolExecutor` gọi lại cùng Repository sau thẻ xác nhận.
4. Rules vẫn kiểm lại mọi lệnh ghi: model Dart (`SessionModel`) ≠ collection `sessions`.

### HÌNH / BẢNG / BỐ CỤC
Class diagram `diagrams/13_class_design.mmd` (10 hộp, không thêm getter/setter). Chú thích góc: "Business rule không nằm trong UI." "Domain model ≠ bảng DB."

### MINH CHỨNG BẮT BUỘC → minh chứng thật của dự án
Tên class/hàm khớp mã: `mobile/lib/viewmodels/live_session_viewmodel.dart` (`startSession:316`, `closeCurrentSession:686`); `packages/core/lib/repositories/teacher_repository.dart` (`startSession:201`, `closeSession:338`, `rotateQr:394`, `manualCheckin:603`); `internal/session_ops.dart` (`createSession`).

### TRÁNH (áp vào dự án này)
Vẽ lại 18 model thành 18 class. Giữ 10 class cốt lõi.

### LỜI THUYẾT MINH
"Giao diện chỉ gọi ViewModel; ViewModel gọi Repository; luật mở phiên, đóng phiên, hạn điểm danh tay nằm trong Repository và được Security Rules kiểm lại. Trợ lý AI không có đường tắt: nó dùng cùng Repository."

### ASSET CẦN CHUẨN BỊ
`s13_class_design.png` (từ `diagrams/13_class_design.mmd`).

### NGUỒN & TRUY VẾT
Các file nêu trên; `docs/09-repository-api.md`; `docs/04-kien-truc-app-va-web.md`.

### THIẾU / GIẢ ĐỊNH
Số dòng có thể lệch sau khi nhóm sửa mã — kiểm lại trước khi in.

---

## Slide 14 — Database Conceptual · P2 · 25 s · TÙY CHỌN (GỘP VÀO 15)

**Câu hỏi hội đồng:** Dữ liệu nghiệp vụ gồm những thực thể nào, quan hệ ra sao?
**Tiêu đề trên slide:** Mỗi sinh viên chỉ có tối đa một bản ghi điểm danh trong mỗi phiên
**Phụ đề:** Tám thực thể nghiệp vụ và quy tắc chi phối quan hệ.

### TEXT TRÊN SLIDE
1. Thực thể: Người dùng · Lời mời · Lớp học · Ghi danh · Phiên điểm danh · Bản ghi điểm danh · Yêu cầu.
2. Một lớp có nhiều phiên; **tối đa 1 phiên đang mở** (BR-04).
3. Một phiên có nhiều bản ghi; **mỗi SV tối đa 1 bản ghi / phiên** (BR-07).
4. Lời mời tạo hồ sơ ở lần đăng nhập đầu (BR-01); giảng viên chỉ thấy lớp mình (BR-13).

### HÌNH / BẢNG / BỐ CỤC
ERD khái niệm `diagrams/14_er_conceptual.mmd`: 7–8 hộp, cardinality, **không** kiểu dữ liệu. Danh sách BR bên phải (BR-01, 04, 07, 11, 13).

### MINH CHỨNG BẮT BUỘC → minh chứng thật của dự án
ERD có cardinality + BR, đối chiếu `docs/db-erd.mermaid` (bản vật lý).

### TRÁNH (áp vào dự án này)
Thêm `string`, `timestamp`, `PK` vào ERD này.

### LỜI THUYẾT MINH
"Khái niệm trung tâm là phiên điểm danh và bản ghi điểm danh: một phiên có nhiều bản ghi, mỗi sinh viên chỉ một bản ghi cho mỗi phiên — đó là luật chống điểm danh trùng."

### ASSET CẦN CHUẨN BỊ
`s14_erd_conceptual.png`.

### NGUỒN & TRUY VẾT
`docs/db-erd.mermaid`; `docs/data-model.md` §2–3.

### THIẾU / GIẢ ĐỊNH
Tên thực thể tiếng Việt do tôi đặt cho slide; tên vật lý ở slide 15.

---

## Slide 15 — Database Logical → Physical · P2 · 30 s

**Câu hỏi hội đồng:** Dữ liệu được hiện thực đúng và có ràng buộc bảo vệ chưa?
**Tiêu đề trên slide:** Ràng buộc nằm trong Firestore Rules, không phải trong khóa ngoại SQL
**Phụ đề:** Bản ghi điểm danh: logic → collection thật với điều kiện bắt buộc.

### TEXT TRÊN SLIDE
Bảng `attendance_records` (Cloud Firestore — NoSQL):
1. **ID tài liệu:** `{sessionId}_{rollNumber}` — xác định → không thể trùng.
2. **Trường chính:** `sessionId`, `rollNumber`, `classCode`, `teacherMemberCode`, `qrToken`, `status`, `checkinTime`, `networkVerificationResult`, `ipAddress`, `syncedToFap`.
3. **Ràng buộc (Rules):** `status in [Present, Late, Absent, ManualByGV, Unchecked]`; `checkinTime == request.time`; tập khóa cố định (`hasOnly`); chỉ `create` với SV; phải có `enrollments/{classCode}_{rollNumber}`.
4. **Index / seed:** truy vấn điều kiện bằng; 6 composite index ở `firestore.indexes.json` (sessions, class_schedules, requests, announcements); seed `seed-reference.mjs`.

### HÌNH / BẢNG / BỐ CỤC
Trái: hộp LOGICAL `AttendanceRecord` (Session, Student, Status, CheckinTime, Source). Phải: bảng PHYSICAL 3 cột TRƯỜNG · KIỂU · RÀNG BUỘC (10 dòng ngắn; kiểu = string / timestamp / bool). Dải dưới: "Nguồn: `firestore.rules:217–296`".

### MINH CHỨNG BẮT BUỘC → minh chứng thật của dự án
Rules + schema export: ảnh chụp đoạn `studentCheckin()` (`firebase/firestore.rules:235–261`) và `firebase/firestore.indexes.json`. **Không có migration SQL**; ràng buộc kiểm chứng bằng 106 test Rules.

### TRÁNH (áp vào dự án này)
Dùng mẫu khung PostgreSQL (BIGINT, FK) cho Firestore; chụp màn Firebase Console làm "thiết kế vật lý".

### LỜI THUYẾT MINH
"Cơ sở dữ liệu là Firestore, nên ràng buộc nằm trong Security Rules. Ví dụ bản ghi điểm danh: mã tài liệu ghép từ phiên và mã sinh viên nên không thể trùng; giờ điểm danh bắt buộc bằng giờ máy chủ; sinh viên chỉ được tạo, không được sửa."

### ASSET CẦN CHUẨN BỊ
`s15_rules_snippet.png` (trích 15 dòng của `studentCheckin`).

### NGUỒN & TRUY VẾT
`firebase/firestore.rules:217–296`; `docs/data-model.md` §3.4; `firebase/firestore.indexes.json`.

### THIẾU / GIẢ ĐỊNH
`[SUY RA TỪ CODE]` "PK" ở đây = ID tài liệu. Dữ liệu cũ từ Google Sheet có script `firebase/scripts/migrate-legacy.mjs` (không đưa lên slide).

---

## Slide 16 — Traceability · P2 · 30 s

**Câu hỏi hội đồng:** Các bản thiết kế có khớp nhau và có được dùng thật không?
**Tiêu đề trên slide:** Mỗi nhóm tính năng truy được từ màn hình đến class, dữ liệu và test
**Phụ đề:** Ba workflow demo đi qua đúng các hàng này.

### TEXT TRÊN SLIDE
Bảng FEATURE · SCREEN · CLASS/SERVICE · ENTITY · TESTS:
1. **F2 Phiên QR** (WF-01, WF-03) · UI-03, 04, 05 · `LiveSessionViewModel`, `TeacherRepository` · `sessions`, `attendance_records` · TC03, TC04, TC11, TC12 + 7 rules test (sessions) + `teacher_repository_test`.
2. **F3 Check-in SV** (WF-02) · UI-09 · `web/checkin/app.js`, rule `studentCheckin` · `attendance_records` · TC16–TC18 (chưa chạy) + 11 rules test.
3. **F4 Điều chỉnh & báo cáo** · UI-02, 05, 10 · `manualCheckin`, `RequestRepository`, `ReportRepository` · `attendance_records`, `requests` · TC05–TC09, TC14, TC20–TC22.
4. **F5 Trợ lý AI** · UI-11 · `AiChatViewModel`, `AiToolExecutor` · `attendance_records` · 52 + 28 test AI.
5. **F1 Tài khoản** · UI-01 · `AuthRepository`, rule `users` · `users`, `user_invites` · TC01, TC02 + rules test.

### HÌNH / BẢNG / BỐ CỤC
Bảng 5 cột × 5 hàng; hai hàng đầu tô nhạt = các hàng của WF demo. Cột cuối có chip trạng thái: xanh (đã chạy) / vàng (partial) / xám (chưa chạy). Dải dưới: *Feature → Screen → Class → DB → Test*. Cuối: "Phát hiện: UI-06 (Báo cáo) đã gộp vào UI-02; Web Admin UI-12 chưa nối đủ".

### MINH CHỨNG BẮT BUỘC → minh chứng thật của dự án
Ma trận đầy đủ ở **Phụ lục B**; mọi ô đã đối chiếu có thật trong repo (tên file, hàm, test).

### TRÁNH (áp vào dự án này)
Ép 1 class / 1 bảng / 1 màn hình mỗi tính năng — ví dụ F2 và F3 cùng ghi `attendance_records`.

### LỜI THUYẾT MINH
"Đọc một hàng từ trái sang phải: nhóm Phiên QR được dùng ở ba màn hình, đi qua LiveSessionViewModel và TeacherRepository, ghi vào hai collection, và được phủ bởi test Rules, test Repository và test Android. Hai workflow đầu của demo nằm trong hai hàng tô nhạt."

### ASSET CẦN CHUẨN BỊ
Không cần ảnh.

### NGUỒN & TRUY VẾT
Phụ lục B của file này.

### THIẾU / GIẢ ĐỊNH
Test case TC16–TC18 đã mô tả nhưng **chưa chạy** (nhãn xám).

---

# P3 · DEMO

## Slide 17 — Demo Plan · P3 · 30 s

**Câu hỏi hội đồng:** Hội đồng sắp xem những workflow nào, theo thứ tự nào, vì sao?
**Tiêu đề trên slide:** Một lớp, một phiên, ba workflow nối tiếp: mở → điểm danh → chốt
**Phụ đề:** Kết quả của workflow trước là dữ liệu của workflow sau.

### TEXT TRÊN SLIDE
Storyboard 3 cột (ACTOR · TÀI KHOẢN · KẾT QUẢ):
1. **WF-01 Mở phiên** · Giảng viên · GV demo `[CẦN NHÓM XÁC NHẬN: tài khoản]` · lớp `PRN232_SE1917` có phiên **open** + QR.
2. **WF-02 Điểm danh** · Sinh viên SE1001, SE1002 · SV demo · 2 bản ghi **Present** của phiên đó.
3. **WF-03 Đóng phiên** · Giảng viên · GV demo · SE1003 (chưa quét) → **Absent (AutoAbsent)**; tổng 2 có mặt / 1 vắng.
- **CHUẨN BỊ:** seed lớp + 3 SV ghi danh · 1 GV + 3 SV có lời mời · demo trong khung giờ ca · người thao tác ≠ người thuyết minh · video dự phòng.

### HÌNH / BẢNG / BỐ CỤC
3 cột như mẫu khung (số 01/02/03, tên WF, actor, ô KẾT QUẢ); dải CHUẨN BỊ dưới cùng gồm 5 chip.

### MINH CHỨNG BẮT BUỘC → minh chứng thật của dự án
Storyboard + dữ liệu demo cố định. Bộ dữ liệu 3 SV (SE1001–SE1003) và lớp `PRN232_SE1917` lấy từ fixture `e2e_test/e2e.test.mjs`. **Chưa có script seed/reset riêng cho demo** (G-13).

### TRÁNH (áp vào dự án này)
Tạo dữ liệu ngẫu nhiên tại chỗ; demo ngoài khung giờ ca (BR-03 sẽ chặn mở phiên). Tên/email thật của SV.

### LỜI THUYẾT MINH
"Demo là một câu chuyện: giảng viên mở phiên cho lớp PRN232; hai sinh viên quét QR đó; giảng viên đóng phiên và sinh viên chưa quét tự động bị ghi vắng. Mọi bước dùng dữ liệu đã chuẩn bị sẵn."

### ASSET CẦN CHUẨN BỊ
- Script seed + reset `[THIẾU]` (đề xuất: kế thừa `seed-reference.mjs`, `seed-admin.mjs`, thêm bước tạo lời mời + lớp + 3 ghi danh; xóa `sessions` + `attendance_records` của lớp demo).
- 4 tài khoản Google demo `[THIẾU]`; video dự phòng `s17_backup.mp4` `[THIẾU]`.

### NGUỒN & TRUY VẾT
`e2e_test/e2e.test.mjs:100–131`; `firebase/scripts/` (`seed-reference`, `seed-admin`, `prepare-live-demo-slot` — **hard-code GV và ngày 2026-11-04**); `docs/qa-handoff.md`.

### THIẾU / GIẢ ĐỊNH
Xem G-13. Giả định giờ demo nằm trong khung ca của lớp (A1 07:00–09:15, A2 09:30–11:45, P1 12:30–14:45, P2 15:00–17:15 theo `seed-reference.mjs`).

---

## Slide 18 — Demo WF-01 · Mở phiên điểm danh QR · P3 · ≈ 2′

**Câu hỏi hội đồng:** WF-01 có chạy thật, đúng nghiệp vụ, và xử lý lỗi đúng không?
**Tiêu đề trên slide:** WF-01 — Giảng viên mở phiên và QR xuất hiện, xoay mỗi 60 giây
**Phụ đề:** Giảng viên · khởi tạo nghiệp vụ.

### TEXT TRÊN SLIDE
1. **Scenario:** Giảng viên bắt đầu ca học lớp PRN232_SE1917.
2. Chuỗi 5 chip: **Trigger** *bắt đầu ca* → **Chọn lớp** *UI-04* → **Mở phiên** *UI-03a · BR-02/03* → **QR hiện** *UI-03* → **Kết quả** *phiên `open`*.
3. **TRẠNG THÁI:** (chưa có) → `open`.
4. **EXCEPTION:** đang có phiên mở, thử "Mở phiên mới" từ Lịch sử → bị chặn *(BR-04)*.
5. **EVIDENCE:** `sessions/{id}` = open · QR đổi sau 60 s · khớp TC03, TC11.

### HÌNH / BẢNG / BỐ CỤC
Layout dùng chung cho 3 slide demo (cố định): hàng chip nằm ngang 5 ô xanh dương; dưới là 3 dải: TRẠNG THÁI (xám) · EXCEPTION (đỏ) · EVIDENCE (xanh lá). Bên phải: ảnh màn Live QR đang chạy (UI-03).

### MINH CHỨNG BẮT BUỘC → minh chứng thật của dự án
Chạy trực tiếp; ghi lại **sessionId** (hiển thị trong Firebase Emulator UI / Console) và trạng thái `open`. Test: TC03 (ARTEMIS 10/11/2026: 1 lượt PASS, 9/9 assertion — chưa đủ 3 lượt), `teacher_repository_test.dart:124` (BR-03).

### TRÁNH (áp vào dự án này)
Chiếu video thay cho chạy thật. Mở phiên ngoài giờ ca khiến demo báo `SESSION_OUTSIDE_SLOT_TIME` ngoài kịch bản.

### LỜI THUYẾT MINH (kịch bản demo — không đưa lên slide)
1. (Người thao tác) Đăng nhập tài khoản GV demo trên app; vào lớp PRN232_SE1917.
2. Bấm "Bắt đầu điểm danh", để mặc định *không* bật kiểm tra IP, xác nhận.
3. QR hiện cùng đồng hồ đếm ngược; chỉ vào số giây và mô tả "mã đổi mỗi 60 giây".
4. Mở Lịch sử, bấm "Mở phiên điểm danh mới" → thông báo "đang có phiên điểm danh mở" (BR-04).
5. Mở Emulator UI/Console cho thấy `sessions/{id}` có `sessionStatus = open`.
6. Giữ nguyên màn QR để chuyển sang WF-02.
(Thuyết minh song song: "Hệ thống đã kiểm tra lớp thuộc giảng viên và đang trong giờ ca trước khi tạo phiên.")

### ASSET CẦN CHUẨN BỊ
`s18_live_qr.png` (ảnh dự phòng); `s18_backup.mp4` `[THIẾU]`.

### NGUỒN & TRUY VẾT
`session_ops.dart:18–` (`createSession`); `live_session_viewmodel.dart:316`; `start_session_dialog.dart`; FR-04/05/06; BR-02/03/04/05; TC03, TC04, TC11.

### THIẾU / GIẢ ĐỊNH
`[CẦN NHÓM XÁC NHẬN]` nút/nhãn UI chính xác ("Bắt đầu điểm danh", "Mở phiên điểm danh mới" lấy từ docs và thông báo trong code; kiểm lại trên bản build).

---

## Slide 19 — Demo WF-02 · Điểm danh bằng mã QR · P3 · ≈ 2′

**Câu hỏi hội đồng:** WF-02 có chạy thật, đúng nghiệp vụ, và xử lý lỗi đúng không?
**Tiêu đề trên slide:** WF-02 — Sinh viên quét QR, 5 bước, bản ghi Present được tạo
**Phụ đề:** Sinh viên · xử lý nghiệp vụ.

### TEXT TRÊN SLIDE
1. **Scenario:** hai sinh viên SE1001, SE1002 điểm danh bằng QR vừa hiển thị.
2. Chuỗi 5 chip: **Trigger** *quét QR* → **Đăng nhập Google** *BR-01* → **Kiểm tra** *BR-05·06·07* → **Ghi bản ghi** *studentCheckin* → **Kết quả** *Present*.
3. **TRẠNG THÁI:** (chưa có bản ghi) → `Present`.
4. **EXCEPTION:** quét lần hai → **"Đã ghi nhận"**, không tạo bản ghi mới *(BR-07)*; SV không thuộc lớp → **"Không thuộc lớp học này"** *(BR-06)*.
5. **EVIDENCE:** `attendance_records/{sessionId}_SE1001` = Present · khớp rules test + TC04.

### HÌNH / BẢNG / BỐ CỤC
Cùng layout slide 18. Ảnh bên phải: màn điện thoại SV "Điểm danh thành công!" + giờ. Ảnh nhỏ: màn "Đã ghi nhận".

### MINH CHỨNG BẮT BUỘC → minh chứng thật của dự án
Record ID `<sessionId>_SE1001` hiển thị trong Emulator UI; danh sách bên GV nhảy lên 2 SV. Test: 11 rules test (sai QR, phiên đóng, chưa ghi danh, điểm danh hộ, trùng…), `e2e` bước "SV đăng nhập lần đầu và điểm danh thành công" (xem lưu ý G-08).

### TRÁNH (áp vào dự án này)
Quét bằng tài khoản GV → ra `WRONG_ROLE` ngoài kịch bản. Chiếu QR đã xoay → "Mã QR đã hết hạn".

### LỜI THUYẾT MINH (kịch bản demo)
1. (Người thao tác ở điện thoại SV) Quét QR đang chiếu; đăng nhập tài khoản SE1001 (lần đầu).
2. Trang báo "Điểm danh thành công!" kèm giờ; GV thấy SE1001 xuất hiện trong danh sách.
3. Lặp lại với SE1002.
4. Quét lại bằng SE1001 → "Đã ghi nhận" (chỉ vào: không tạo bản ghi thứ hai).
5. Đăng nhập một tài khoản SV **không ghi danh** lớp → "Không thuộc lớp học này".
6. Mở Emulator UI: hai bản ghi `…_SE1001`, `…_SE1002`, `status = Present`, `networkVerificationResult = Skipped`.
(Thuyết minh: "Việc kiểm tra mã QR, ghi danh và chống trùng không nằm ở trang web mà ở Security Rules.")

### ASSET CẦN CHUẨN BỊ
`s19_success.png`, `s19_already.png`, `s19_not_enrolled.png` (chụp trên điện thoại/Emulator); `s19_backup.mp4` `[THIẾU]`.

### NGUỒN & TRUY VẾT
`web/checkin/app.js:139–232`; `firestore.rules:235–261`; `index.html:306,328`; FR-08/09; BR-01/05/06/07/08; TC04, TC16–TC18.

### THIẾU / GIẢ ĐỊNH
Kiểm tra IP (BR-08) **không** nằm trong kịch bản demo (mặc định tắt); nếu hội đồng hỏi, mở phụ lục. TC16–TC18 chưa chạy trên thiết bị thật.

---

## Slide 20 — Demo WF-03 · Đóng phiên và chốt vắng mặt · P3 · ≈ 2′

**Câu hỏi hội đồng:** WF-03 có chạy thật, đúng nghiệp vụ, và xử lý lỗi đúng không?
**Tiêu đề trên slide:** WF-03 — Đóng phiên, sinh viên chưa quét tự động thành Absent
**Phụ đề:** Giảng viên · tổng hợp kết quả.

### TEXT TRÊN SLIDE
1. **Scenario:** hết giờ điểm danh, giảng viên đóng phiên.
2. Chuỗi 5 chip: **Trigger** *bấm đóng / hết ca* → **Đọc ghi danh** *lớp* → **Batch** *BR-09* → **Cập nhật** *UI-02·05* → **Kết quả** *closed + Absent*.
3. **TRẠNG THÁI:** `open` → `closed`; SE1003: (chưa có) → `Absent (AutoAbsent)`.
4. **EXCEPTION:** SV quét QR **sau khi đóng** → "Mã QR đã hết hạn" *(BR-06)*; sửa tay sau 00:00 hôm sau → `MANUAL_ATTENDANCE_EXPIRED` → gửi yêu cầu *(BR-10/11)*.
5. **EVIDENCE:** 2 Present + 1 Absent · `…_SE1003` AutoAbsent · TC03, TC12; `teacher_repository_test` (autoAbsentCount = 2).

### HÌNH / BẢNG / BỐ CỤC
Cùng layout slide 18. Ảnh phải: màn Lịch sử / chi tiết buổi với thẻ "Có mặt 2 · Vắng 1".

### MINH CHỨNG BẮT BUỘC → minh chứng thật của dự án
Record `<sessionId>_SE1003` với `networkVerificationResult = AutoAbsent`; session `closed` mà không phải restart app. ARTEMIS 10/11/2026 TC03: Closed đồng bộ, Absent được tạo (1 lượt). Lưu ý: ngày 01/11 lỗi `PERMISSION_DENIED` khi đóng phiên (DEF-TC03-01) — cần nhóm xác nhận đã sửa (G-11).

### TRÁNH (áp vào dự án này)
Demo ngay sau khi sửa dữ liệu trực tiếp trong Console (từng làm UI giữ trạng thái cũ — DEF-TC03-02). Không chạm Console trong lúc demo.

### LỜI THUYẾT MINH (kịch bản demo)
1. (Người thao tác) Trên app GV, bấm "Đóng phiên điểm danh".
2. Phiên chuyển sang đã đóng; Tổng quan và Lịch sử cập nhật không cần mở lại app.
3. Mở chi tiết buổi: SE1001, SE1002 Có mặt; SE1003 Vắng (ghi chú nguồn: tự động).
4. Dùng điện thoại SV quét lại QR → "Mã QR đã hết hạn".
5. Mở Emulator UI: ba bản ghi, `SE1003` có `AutoAbsent`.
6. (Nói, không cần chạy) "Nếu cần sửa sau hôm đó thì phải gửi yêu cầu cho quản trị viên."

### ASSET CẦN CHUẨN BỊ
`s20_history_detail.png`; `s20_backup.mp4` `[THIẾU]`.

### NGUỒN & TRUY VẾT
`teacher_repository.dart:338–392` (`closeSession`); `auto_session_manager.dart:89`; `teacher_data.dart:168`; FR-07/10/11; BR-06/09/10/11; TC03, TC05, TC12, TC14.

### THIẾU / GIẢ ĐỊNH
`[CẦN NHÓM XÁC NHẬN]` UI ghi chú "tự động" cho Absent AutoAbsent. Bước 6 chỉ nói, không demo vì Review Queue chưa chạy thật (Slide 23).

---

# P4 · PROOF

## Slide 21 — Testing · P4 · 50 s

**Câu hỏi hội đồng:** Làm sao nhóm biết hệ thống chạy đúng?
**Tiêu đề trên slide:** 483/491 test tự động đạt; chưa đạt: 5 kịch bản E2E cũ và 3 test giao diện
**Phụ đề:** Số đo ngày 11/11/2026 trên máy nhóm; Android E2E đã chạy 25/30 lượt.

### TEXT TRÊN SLIDE
Ba số lớn: **491** test tự động · **98,4 %** đạt (483) · **8** test đỏ (5 E2E luồng + 3 giao diện mobile).
Bảng LEVEL · EVIDENCE · RESULT:
1. **Unit** · Functions 74 · packages/core 67 · web check-in 2 · mobile 206 · **Pass 74/74 · 67/67 · 2/2 · 203/206**.
2. **Integration** · Security Rules trên Emulator (Firestore + Storage) **106/106** · AI end-to-end (Gemini giả) **28/28**.
3. **E2E (Emulator)** · luồng GV→SV→GV **3/8** (kịch bản cũ thiếu `manualAttendanceDeadline`).
4. **E2E (Android)** · 25/30 lượt: 17 đạt, 8 hỏng (01/11); ARTEMIS 10/11: TC03 PASS.
5. **UAT** · `[THIẾU]`.
- Mapping: BR-02…BR-13 → test (xem Phụ lục B §3); chuyển cấm → 3 rules test.

### HÌNH / BẢNG / BỐ CỤC
Hàng trên: 3 ô số lớn. Dưới: bảng 3 cột × 5 hàng. Dải cuối: "Lệnh chạy ở Phụ lục C". Màu: đạt xanh lá, hỏng đỏ.

### MINH CHỨNG BẮT BUỘC → minh chứng thật của dự án
- Chạy 11/11/2026: `firebase && npm test` → **106/106** (2 lần đạt; 1 lần thoát code 1 ở hook `after`, chưa điều tra); `firebase/functions && npm test` → **74/74**; `packages/core && flutter test` → **67/67**; `mobile && flutter test` → **203 đạt / 3 hỏng**; `e2e_test && npm test` → **3/8**; `e2e_test && npm run test:ai` → **28/28**; `web/checkin: node --test profile.test.mjs` → **2/2**.
- Báo cáo QA: `docs/course/test-report.md`, `docs/artemis-report.md`, `e2e_test/results/android-summary.json`.
- CI: `.github/workflows/ci.yml` — `[THIẾU: link lần chạy CI]`.

### TRÁNH (áp vào dự án này)
Cộng các level thành "100 % pass". Tính 78 unit test vào 30 lượt Android E2E (báo cáo QA đã cấm). Nói "bug còn mở = 0" — chưa có bảng theo dõi.

### LỜI THUYẾT MINH
"Hôm qua nhóm chạy lại toàn bộ test: 483 trên 491 đạt. Tám test chưa đạt đều đã biết nguyên nhân: năm bước end-to-end dùng kịch bản cũ chưa cập nhật hạn điểm danh tay, và ba test giao diện hỏng sẵn. Các luật nghiệp vụ quan trọng đều có test Security Rules; Android E2E đã chạy 25 trên 30 lượt, còn thiếu các case cần thiết bị thứ hai."

### ASSET CẦN CHUẨN BỊ
Ảnh terminal 4 lệnh (hoặc bảng) — `s21_test_run_2026-11-11.png`.

### NGUỒN & TRUY VẾT
`firebase/tests/*.test.mjs`; `firebase/functions/test/`; `packages/core/test/`; `mobile/test/`; `e2e_test/`; `docs/course/test-report.md`; `docs/artemis-report.md`.

### THIẾU / GIẢ ĐỊNH
Tổng 491 = 106 + 74 + 67 + 206 + 8 + 28 + 2. `[CẦN NHÓM XÁC NHẬN]` số bug còn mở và trạng thái DEF-TC07/TC09/TC10/EXP-01 sau mã mới (G-11). Số 17/8 (Android) là của đợt 01/11, **trước** các thay đổi sau đó.

---

## Slide 22 — Achievements · P4 · 40 s

**Câu hỏi hội đồng:** Nhóm đã đạt được những gì đã cam kết ở phần đầu?
**Tiêu đề trên slide:** Ba workflow lõi chạy được và có test; một số chỉ tiêu chưa đạt
**Phụ đề:** Đối chiếu mục tiêu — đã làm — đã kiểm chứng, kèm chỗ chưa đạt.

### TEXT TRÊN SLIDE
Bảng OBJECTIVE · IMPLEMENTED · VALIDATED (6 hàng):
1. Đăng nhập Google + phân quyền · `staff/user/admin` · Rules 106/106; Android TC01, TC02: 3/3 (01/11).
2. Mở phiên + QR xoay · WF-01 · TC03 ARTEMIS PASS (1 lượt); `teacher_repository_test`.
3. SV điểm danh không cài app · WF-02 · 11 rules test; web `profile.test.mjs` 2/2.
4. Đóng phiên + chốt vắng · WF-03 · test `autoAbsentCount`; TC03.
5. Lịch sử, lọc, xuất Excel · FR-11/12 · TC05, TC06: 3/3 (01/11); TC07 partial (10/11).
6. Trợ lý AI giọng nói · FR-14/15 · 28/28 E2E AI + 52 test luồng.
- **CHƯA ĐẠT:** thời gian cả lớp < 45 giây chưa đo · duyệt yêu cầu trên Web Admin chưa chạy · đồng bộ FAP chưa có API · Android E2E 25/30 → *Slide 23*.

### HÌNH / BẢNG / BỐ CỤC
Bảng 3 cột × 6 hàng với dấu ✓ (xanh) / ◐ (vàng cho partial); khung đỏ CHƯA ĐẠT dưới cùng. Cột VALIDATED chứa link rút gọn tới file báo cáo.

### MINH CHỨNG BẮT BUỘC → minh chứng thật của dự án
Mỗi hàng có link: `docs/course/test-report.md`, `docs/artemis-report.md`, `e2e_test/ai_assistant.e2e.test.mjs`, `firebase/tests/`. Repo: `https://github.com/ducminh852005/fapcheckin`.

### TRÁNH (áp vào dự án này)
Lấy "Kết quả đạt được" trong `ux/persona.md` (~25–35 s, 0 % gian lận, 0,5 % lỗi, < 150 ms, 99/100 điểm) làm thành tích — chưa có phép đo. Không dùng "100 %", "hoàn hảo".

### LỜI THUYẾT MINH
"Sáu mục tiêu: bốn mục đã có kiểm chứng rõ, hai mục partial. Nhóm cũng nêu thẳng những gì chưa đạt: chưa đo thời gian cả lớp trên lớp thật, duyệt yêu cầu và đồng bộ FAP chưa chạy."

### ASSET CẦN CHUẨN BỊ
Không cần ảnh.

### NGUỒN & TRUY VẾT
`docs/course/final-report-source.md` §1.2 (mục tiêu); test-report; artemis-report; `docs/ai-assistant.md`.

### THIẾU / GIẢ ĐỊNH
`[THIẾU: live demo URL]` (G-06). `[CẦN NHÓM XÁC NHẬN]` mục tiêu chính thức đã cam kết với giảng viên (final-report dùng 6 mục tiêu ở §1.2 — slide dùng lại, có tách nhỏ).

---

## Slide 23 — Limitations · P4 · 25 s

**Câu hỏi hội đồng:** Sản phẩm chưa làm được gì, và ảnh hưởng thế nào?
**Tiêu đề trên slide:** Ba giới hạn chính: duyệt yêu cầu, chống điểm danh hộ tuyệt đối, và độ phủ test
**Phụ đề:** Mỗi giới hạn có tác động, mức ưu tiên và bước tiếp theo.

### TEXT TRÊN SLIDE
Bảng GIỚI HẠN · TÁC ĐỘNG · ƯU TIÊN · NEXT STEP:
1. **[Product]** Duyệt yêu cầu sửa điểm danh chưa chạy thật (Review Queue còn dữ liệu mẫu) · quá hạn điểm danh tay không có đường sửa · **Cao** · nối `RequestsPage` với `requests`, chạy TC08.
2. **[Technology]** Kiểm tra IP mặc định tắt; IP do client gửi · chuyển tiếp QR trong cửa sổ 60 s vẫn có thể · **Trung bình** · check-in qua Cloud Function đọc IP thật.
3. **[Testing]** Thiếu: cách ly 2 giảng viên, QR cũ/mới trên thiết bị SV, kịch bản E2E cũ, 3 test mobile đỏ, chưa stress test · **Cao** · cập nhật e2e, chạy TC15–TC18, benchmark.

### HÌNH / BẢNG / BỐ CỤC
Bảng 4 cột × 3 hàng; cột ƯU TIÊN dùng chip màu. Chân slide: liên kết "→ Slide 21 (số đo) · Slide 22 (CHƯA ĐẠT)".

### MINH CHỨNG BẮT BUỘC → minh chứng thật của dự án
`docs/06-rui-ro-va-mo-rong.md` (IP, NAT); `docs/course/final-report-source.md` §9; `web/admin/src/pages/RequestsPage.tsx` (`requestRows` từ `mock-data`); kết quả test Slide 21.

### TRÁNH (áp vào dự án này)
Viết "thiếu thời gian". Giấu giới hạn IP: hội đồng rất dễ hỏi.

### LỜI THUYẾT MINH
"Ba giới hạn: một, quá hạn điểm danh tay thì cần gửi yêu cầu nhưng phía quản trị chưa duyệt được thật; hai, kiểm tra IP là tùy chọn nên vẫn có khe hở trong 60 giây; ba, một số kịch bản test chưa được chạy hoặc đang lỗi thời. Mỗi mục có bước tiếp theo cụ thể."

### ASSET CẦN CHUẨN BỊ
Không cần ảnh.

### NGUỒN & TRUY VẾT
Như trên; Phụ lục C (G-07, G-08, G-14, G-15).

### THIẾU / GIẢ ĐỊNH
Giới hạn #2 là đánh đổi có chủ ý (đã nêu trong docs/06).

---

## Slide 24 — Conclusion · P4 · 30 s

**Câu hỏi hội đồng:** Hội đồng nên nhớ điều gì sau buổi bảo vệ?
**Tiêu đề trên slide:** Điểm danh QR chạy được từ mở phiên đến chốt kết quả, có test chứng minh
**Phụ đề:** Ba thông điệp và đường dẫn minh chứng.

### TEXT TRÊN SLIDE
1. **PROBLEM SOLVED** — thay việc gọi tên (8′40″/32 SV) bằng sinh viên tự quét QR.
2. **WORKING PRODUCT** — WF-01, WF-02, WF-03 chạy trực tiếp trong demo.
3. **VERIFIED RESULT** — 483/491 test tự động đạt; luật nghiệp vụ được Rules kiểm tra (106/106).
- **Demo URL** `[THIẾU: chốt URL production — G-06]` · **Git repo** `github.com/ducminh852005/fapcheckin` · **Final Figma** `[THIẾU]`.

### HÌNH / BẢNG / BỐ CỤC
3 thẻ đánh số 1–3 như khung; hàng dưới 3 ô link (có QR code cho Demo URL và Repo). Giữ slide trên màn hình suốt Q&A.

### MINH CHỨNG BẮT BUỘC → minh chứng thật của dự án
Link demo, repo, Figma (hai link còn thiếu — xem trên).

### TRÁNH (áp vào dự án này)
Nhắc lại cả roadmap; tuyên bố "chống gian lận hoàn toàn".

### LỜI THUYẾT MINH
"Tóm lại: vấn đề là điểm danh thủ công mất thời gian và dễ sai; sản phẩm là hệ thống QR đã chạy trong ba workflow vừa demo; kết quả đã được kiểm chứng bằng test, và chúng em đã nêu các giới hạn còn lại. Xin cảm ơn hội đồng, mời quý thầy cô đặt câu hỏi."

### ASSET CẦN CHUẨN BỊ
QR code tới repo và demo URL (tạo sau khi chốt link).

### NGUỒN & TRUY VẾT
Slide 03, 18–22.

### THIẾU / GIẢ ĐỊNH
`[THIẾU: Demo URL, Figma]`.

---

# PHỤ LỤC (không chiếu) — Slide 25

Mỗi slide gắn một câu hỏi dự kiến; `[phân công người trả lời]` nhóm điền.

## A1 · Trợ lý AI & WF-04 Điểm danh bằng AI
- **Câu hỏi dự kiến:** "AI có tự ý ghi điểm danh không? Nhận nhầm MSSV thì sao?"
- **Nội dung sơ bộ:** sơ đồ `docs/ai-assistant.md` (§A–B): Cloud Function chỉ là proxy tới Gemini; app thực thi tool dưới quyền GV; lệnh ghi **luôn qua thẻ xác nhận** lấy MSSV/họ tên từ dữ liệu thật; lỗi: `NO_SESSION_TODAY`, `STUDENT_NOT_ENROLLED`, `MANUAL_ATTENDANCE_EXPIRED`; rate-limit 60 lượt/10 phút/người; AI dự phòng Ollama. Test: 28/28 E2E AI + 52 test luồng.
- **[phân công người trả lời]:** TV4 (theo `docs/course/text.md`) `[CẦN NHÓM XÁC NHẬN]`.

## A2 · Đặc tả 3 workflow
- **Câu hỏi:** "Nếu sai quy tắc thì sao?" — dán 3 bảng 9 trường từ `WORKFLOW_SPECS.md` §4 (WF-01/02/03).
- **[phân công]:** …

## A3 · Test case & báo cáo
- **Câu hỏi:** "Cho xem danh sách test và kết quả." — TC01–TC30 (`docs/course/test-cases.md`), bảng 25/30 lượt, báo cáo ARTEMIS, 6 finding AI code review (CR-01…CR-06; 3 commit sửa: `4b73278`, `6c5cf6c`, `9e0c46a`), lệnh chạy ở Phụ lục C.
- **[phân công]:** TV5.

## A4 · Schema vật lý & Security Rules
- **Câu hỏi:** "Tại sao SV không đọc được `sessions`? Ai chặn điểm danh trùng?" — trích `firestore.rules` (sessions, attendance_records), ma trận quyền `docs/data-model.md` §4, 6 composite index.
- **[phân công]:** TV1.

## A5 · Application design
- **Câu hỏi:** "Code tổ chức thế nào, thêm một role mới ra sao?" — layer MVVM, `packages/core`, route trong `main_screen.dart`, `AutoSessionManager`, Remote Config.
- **[phân công]:** TV2.

## A6 · Video demo dự phòng + kiểm tra IP (BR-08)
- **Câu hỏi:** "Nếu mạng lỗi thì sao? Kiểm tra IP hoạt động ra sao?" — video `[THIẾU]`; luồng bật `ipCheck`, `teacherIp`, trạng thái `Match/Skipped`, giới hạn NAT/VPN.
- **[phân công]:** …

## Câu hỏi khó nhất hội đồng có thể hỏi (8–10) và gợi ý trả lời

| # | Câu hỏi | Gợi ý trả lời (dựa trên sự thật) | Phụ lục |
|---|---|---|---|
| 1 | Sinh viên chụp ảnh QR gửi cho bạn ở nhà thì sao? | QR xoay 60 s; với phiên bật kiểm tra IP thì IP phải trùng GV; mặc định tắt là đánh đổi nêu ở Slide 23. Không nói "0 %". | A6 |
| 2 | Tài liệu ghi QR 5 giây và JWT/TOTP, code lại 60 giây? | Nhận: tài liệu UX là thiết kế ban đầu; hệ thống thật dùng `qrSecret` ngẫu nhiên xoay theo Remote Config (mặc định 60 s). | A5 |
| 3 | Con số "< 45 giây cả lớp" lấy ở đâu? | Là chỉ tiêu, chưa đo trên lớp thật; số quan sát duy nhất là 8′40″ của cách cũ (O-01). | — |
| 4 | Tại sao e2e chỉ 3/8? CI có xanh không? | Kịch bản e2e tạo phiên thiếu `manualAttendanceDeadline` (Rules yêu cầu); lỗi ở test, đã biết cách sửa; CI step e2e sẽ đỏ nếu push lên main trước khi sửa. | A3 |
| 5 | Đóng phiên từng bị `PERMISSION_DENIED`, đã sửa chưa? | QA 01/11 báo lỗi; ARTEMIS 10/11 TC03 đạt 1 lượt, chưa đủ 3 lượt → cần chạy lại. | A3 |
| 6 | GV có mở lại phiên đã đóng được không? | Rules không chặn closed → open (không có test) — hạn chế thật, đề xuất thêm rule + test. | A4 |
| 7 | Web Admin đã dùng được chưa? | Nhiều trang nối Firestore, riêng Duyệt yêu cầu còn dữ liệu mẫu; TC08 Blocked. | A1/A4 |
| 8 | Dữ liệu cá nhân (PII) và gửi lên Gemini? | Xem `docs/pii-review.md`; Cloud Function chỉ proxy, app thực thi tool; kết quả tool ≤ 24 000 ký tự. `[CẦN NHÓM XÁC NHẬN: dữ liệu nào được gửi lên Gemini]` | A1 |
| 9 | Đồng bộ lên FAP thế nào? | Chưa có API FAP; `syncToFap` là điểm tích hợp giữ chỗ, bản production trả 404 ngày 10/11. | — |
| 10 | Vì sao Web Admin dùng React thay vì Flutter Web như đề bài? | `[CẦN NHÓM XÁC NHẬN]` (gap-review ghi nhận lệch này). | A5 |

---

# PHỤ LỤC B — ID registry & truy vết (thay cho TRACEABILITY.md)

## B.1 Business rule (BR) — `[MÃ MỚI — ĐỀ XUẤT]`

| BR | Quy tắc | Nơi thi hành |
|---|---|---|
| BR-01 | Chỉ email có lời mời `user_invites` mới tạo được hồ sơ; role/memberCode/rollNumber phải khớp lời mời | `firestore.rules:73–93` (users create) |
| BR-02 | Chỉ GV phụ trách lớp mới mở/đóng phiên của lớp | `session_ops.dart` (`FORBIDDEN`); `firestore.rules:189–210`; `teacher_repository.dart` `_session` |
| BR-03 | Chỉ mở phiên trong khung giờ của ca (`SESSION_OUTSIDE_SLOT_TIME`) | `session_ops.dart` |
| BR-04 | Mỗi lớp tối đa một phiên mở: mở mới từ Lịch sử bị chặn (`SESSION_ALREADY_OPEN`); từ màn QR thì phiên cũ bị đóng | `session_ops.dart`, `attendance_history_repository.dart:315` |
| BR-05 | `qrToken` phải bằng `qrSecret` hiện tại; secret xoay mỗi `qr_refresh_seconds` (60) | `studentCheckin()` `firestore.rules:235`; `rotateQr` |
| BR-06 | Phiên phải `open` và SV phải có ghi danh lớp | `studentCheckin()` |
| BR-07 | Mỗi SV một bản ghi mỗi phiên; id = `{sessionId}_{rollNumber}`; SV chỉ `create` | `attendance_records` rules |
| BR-08 | Phiên bật `ipCheck`: IP SV phải bằng `teacherIp` (`Match`); tắt: `Skipped` | `studentCheckin()` |
| BR-09 | Đóng phiên: SV chưa có bản ghi → `Absent`/`AutoAbsent` | `teacher_repository.dart:338` |
| BR-10 | Điểm danh tay chỉ đến hết ngày VN của phiên; SV phải thuộc lớp | `teacher_data.dart:168`, `teacher_repository.dart:659–705`, `manualAttendanceWithinDeadline` |
| BR-11 | Yêu cầu tạo ở `pending`; chỉ admin chuyển `approved/rejected`, không duyệt lại | `firestore.rules:298–325` |
| BR-12 | Lệnh ghi của AI phải qua thẻ xác nhận, MSSV thuộc lớp, phiên hôm nay phải tồn tại | `ai_tool_executor.dart`, `docs/ai-assistant.md` §D |
| BR-13 | GV chỉ đọc/ghi dữ liệu lớp của mình (`teacherMemberCode`) | `ownsDoc()` `firestore.rules:49` |
| BR-14 | Ảnh TKB: chỉ ảnh, < 10 MB, thư mục của chính GV | `storage.rules:13–22` |

## B.2 Feature / FR / UI / WF

| Feature | FR | Screen | Workflow |
|---|---|---|---|
| F1 Tài khoản & quản trị | FR-01 Đăng nhập Google · FR-02 Lời mời · FR-03 Phân quyền | UI-01, UI-12 | — |
| F2 Phiên QR | FR-04 Mở phiên (tay/tự động) · FR-05 QR xoay · FR-06 Kiểm tra IP · FR-07 Đóng phiên & Absent | UI-03 (03a Mở phiên, 03b Điểm danh tay), UI-04, UI-05 | WF-01, WF-03 |
| F3 Check-in SV | FR-08 Quét & điểm danh · FR-09 Báo lý do từ chối | UI-09 | WF-02 |
| F4 Điều chỉnh & báo cáo | FR-10 Điểm danh tay · FR-11 Lịch sử/lọc · FR-12 Báo cáo/XLSX · FR-13 Yêu cầu | UI-02, UI-05, UI-10 | (nhánh WF-03) |
| F5 AI & tiện ích | FR-14 AI tra cứu · FR-15 AI điểm danh · FR-16 OCR TKB · FR-17 Nhắc lịch | UI-11, UI-07 | WF-04 (dự phòng) |

UI: UI-01 Đăng nhập · 02 Tổng quan (gồm báo cáo) · 03 Điểm danh QR · 04 Quản lý lớp · 05 Lịch sử · 07 Lịch dạy · 08 Cài đặt/Hồ sơ · 09 Web check-in SV *(01–09 theo `ux/user-flow.md`)* · 10 Yêu cầu · 11 Trợ lý AI · 12 Web Admin *(mới)*.

## B.3 Ma trận WF → bước → trạng thái → BR → test

| WF | Bước | Chuyển trạng thái | BR | Test |
|---|---|---|---|---|
| WF-01 | Kiểm tra lớp | — | BR-02 | rules "GV không mở phiên lớp người khác / mạo danh…"; TC03 |
| WF-01 | Kiểm tra giờ ca | — | BR-03 | `teacher_repository_test.dart:124` |
| WF-01 | Đóng phiên cũ / chặn mở trùng | `open` → `closed` (cũ) | BR-04 | `history_report_schedule_test.dart:329`; TC11 |
| WF-01 | Tạo phiên | → `open` | BR-02 | rules "GV mở phiên cho lớp của mình"; TC03 |
| WF-01 | Xoay QR | `open` → `open` | BR-05 | rules "GV chủ xoay QR…"; e2e "QR mới sau khi GV xoay"; `qr_refresh_interval_test.dart`; TC04 |
| WF-02 | Có lời mời | — | BR-01 | rules ×3 "tạo hồ sơ…invite"; TC01/TC02 |
| WF-02 | QR đúng | → `Present` | BR-05 | rules "sai QR token → bị chặn"; TC16, TC17 (chưa chạy) |
| WF-02 | Phiên mở + ghi danh | → `Present` | BR-06 | rules "phiên đã đóng", "chưa ghi danh" |
| WF-02 | Không trùng / không hộ | → `Present` | BR-07 | rules "điểm danh hộ", "lần hai", "không sửa/xóa"; TC18 (chưa chạy) |
| WF-02 | IP | → `Present` | BR-08 | rules "phiên kiểm tra IP…"; **chưa có E2E** |
| WF-03 | Chốt vắng | `open` → `closed`; → `Absent` | BR-09 | `teacher_repository_test.dart:213`; e2e "GV đóng phiên và sinh Absent" (đang đỏ — G-08); TC03, TC12 |
| WF-03 | Sửa tay trong ngày | `Absent` → `ManualByGV` | BR-10 | rules "sau deadline", "legacy"; `teacher_repository_test.dart:348`; TC14 |
| WF-03 | Quá hạn → yêu cầu | → `pending` | BR-11 | rules ×5 (requests); TC08 Blocked |

**Ô "có hình nhưng không dùng":** `UI-06 Báo cáo` (route cũ, nay hợp vào UI-02); `sessionStatus = cancelled` trong ERD cũ (mã không dùng); `Mismatch` trong `networkVerificationResult` (dữ liệu cũ, không tạo mới).

---

# PHỤ LỤC C — Gaps, giả định, lệnh đã chạy, asset (thay cho ASSETS_AND_GAPS.md)

## C.1 Danh sách khoảng trống (xếp theo mức ưu tiên)

| ID | Mức | Vấn đề | Slide | Nhãn |
|---|---|---|---|---|
| G-06 | **Cao** | Project Firebase / URL demo mâu thuẫn: `.firebaserc` & `deploy.yml` = `ducminh-41459`; README & `quick-start-mobile.md` = `fapcheckin-3bn2di`; `desktop-api-status` = `ducminh-41459`. Chưa biết Demo URL | 22, 24 | [CẦN NHÓM XÁC NHẬN] |
| G-13 | **Cao** | Chưa có script seed/reset cho demo; `prepare-live-demo-slot.mjs` hard-code GV và ngày 2026-11-04; demo phải trong khung giờ ca (BR-03); chưa có tài khoản demo & video dự phòng | 17–20 | [THIẾU] |
| G-08 | **Cao** | `e2e_test/e2e.test.mjs` **3/8**: tạo phiên không có `manualAttendanceDeadline` mà Rules (`firestore.rules:191–197`) bắt buộc → CI (`ci.yml` step "End-to-end flow") sẽ đỏ khi push `main` | 21 | [SUY RA TỪ CODE] |
| G-01 | **Cao** | Số liệu vấn đề (O-01, R-01, R-03, R-05) do nhóm tự ghi trong persona doc, không có dữ liệu thô; kế hoạch n = 8 nhưng log 6 mục; ký hiệu ID không nhất quán. KPI "25–35 s, 0 % gian lận, 0,5 % lỗi, < 150 ms, 99/100" không có phép đo → **không dùng** | 02, 03, 22 | [CẦN NHÓM XÁC NHẬN] |
| G-02 | **Cao** | `ux/*.md` & persona ghi QR 5 s, JWT/TOTP; mã thật: 60 s, `qrSecret` ngẫu nhiên (`remote_settings.dart:8`, `remoteconfig.template.json`) | 04, 11, Q&A | [SUY RA TỪ CODE] |
| G-11 | **Cao** | Không có bảng bug còn mở. Trạng thái DEF-TC03-01/02, TC07, TC09, TC10, EXP-01 sau mã mới: có `PopScope` (`main_screen.dart:142`), có `saveFile` (`history_download_io.dart:20`), ARTEMIS 10/11 TC03 đạt 1 lượt; UI offline chưa thấy trong mã | 20, 21 | [CẦN NHÓM XÁC NHẬN] |
| G-04 | Trung bình | Tên nhóm, thành viên, GVHD còn placeholder | 01 | [THIẾU] |
| G-05 | Trung bình | Không có link Figma; không có ảnh wireframe/mockup | 11, 24 | [THIẾU] |
| G-07 | Trung bình | Web Admin: nhiều trang nối Firestore nhưng Duyệt yêu cầu dùng mock; docs (`01`, `README`) ghi "chưa nối/prototype" — tài liệu lỗi thời | 05, 23 | [SUY RA TỪ CODE] |
| G-12 | Trung bình | Rules `sessions` update chỉ giữ 3 trường → không chặn `closed → open`; không có test | 08 | [SUY RA TỪ CODE] |
| G-14 | Trung bình | Test thiếu: BR-08 E2E; TC04 (thiết bị SV), TC15–TC18, TC13; không có UAT; chưa có link CI | 21 | [THIẾU] |
| G-09 | Trung bình | Mobile: 3 test đỏ (`create_class_dialog`, `create_schedule_bottom_sheet`, `requests`); CI `flutter-mobile` đặt `continue-on-error` | 21 | đã biết trong docs |
| G-03 | Trung bình | Mã FR/BR/WF/UI-10..12 là đề xuất mới | toàn bộ | [MÃ MỚI — ĐỀ XUẤT] |
| G-10 | Thấp | `npm test` Rules: lần chạy đầu thoát code 1 ở hook `after` (không xem được lỗi đầy đủ), 2 lần sau 106/106 | 21 | [CẦN NHÓM XÁC NHẬN] |
| G-15 | Thấp | Kiểm tra IP mặc định tắt, IP client tự gửi → điểm danh hộ trong 60 s còn khả thi | 23 | đã nêu `docs/06` |
| G-16 | Thấp | `syncToFap` production 404 (10/11); bản Windows chưa có cấu hình Firebase | 04, 23 | đã nêu `desktop-api-status` |
| G-17 | Thấp | Docs lỗi thời: README "77 test" (đo 106); `desktop-api-status` "Functions 35" (đo 74); số dòng trong docs có thể lệch | 21 | [SUY RA TỪ CODE] |
| G-18 | Thấp | `AutoSessionManager` fallback 6 ca (đến 22:15) khác `seed-reference.mjs` 4 khung (đến 17:15) | 17 | [SUY RA TỪ CODE] |
| G-19 | Thấp | Lý do chọn Flutter/React/Gemini không có trong repo; chỉ "Rules-first" và "web cho SV" có căn cứ | 09, 10 | [CẦN NHÓM XÁC NHẬN] |

**Tổng nhãn:** `[THIẾU]` 6 (G-04, G-05, G-13, G-14 + Demo URL, video dự phòng) · `[SUY RA TỪ CODE]` 6 · `[CẦN NHÓM XÁC NHẬN]` 8 · `[MÃ MỚI]` toàn bộ FR/BR/WF.

## C.2 Việc nhóm nên làm đầu tiên
1. Chốt Firebase project + Demo URL, deploy lại trang check-in (G-06).
2. Viết script seed/reset demo và chạy thử đúng giờ ca (G-13).
3. Sửa `e2e.test.mjs` (thêm `manualAttendanceDeadline`) để CI xanh (G-08).
4. Chạy lại TC03 đủ 3 lượt và lập bảng bug còn mở (G-11).
5. Điền tên nhóm/GVHD, export Figma, thu dữ liệu thô khảo sát (G-04, G-05, G-01).

## C.3 Lệnh đã chạy (11/11/2026, chỉ đọc/test; không sửa mã)

| Lệnh | Kết quả |
|---|---|
| `cd firebase/functions && npm test` | 74/74 pass |
| `cd firebase && npm test` (Rules, Emulator) | 106/106 pass (lần 2, 3); lần 1 thoát code 1 ở hook `after` |
| `cd packages/core && flutter test` | 67 pass |
| `cd mobile && flutter test` | 203 pass, 3 fail |
| `cd e2e_test && npm test` | 3/8 pass (5 fail do thiếu `manualAttendanceDeadline`) |
| `cd e2e_test && npm run test:ai` | 28/28 pass |
| `cd web/checkin && node --test profile.test.mjs` | 2/2 pass |

Không chạy: Android E2E (Appium/ARTEMIS), Web Admin build, `flutter analyze`. Không render được ảnh PPTX (thiếu `soffice`); Mermaid trong `diagrams/` chưa được render thử.

## C.4 Danh sách asset cần chuẩn bị

| Asset | Tên đề xuất | Nguồn | Trạng thái |
|---|---|---|---|
| GIF tổng quan | `s01_live_qr_and_success.gif` | Quay emulator + điện thoại | [THIẾU] |
| Ảnh FAP hiện tại | `s02_fap_current.png` | Chụp cổng FAP (che PII) | [THIẾU] |
| Sơ đồ 07, 08, 09, 12, 13, 14 | `s07…s14_*.png` | Render `diagrams/*.mmd` | có nguồn |
| Wireframe / Mockup / Final | `s11_*.png` + link Figma | Figma | [THIẾU] |
| Ảnh trang SV | `s19_success/already/not_enrolled.png` | Chụp `web/checkin` | [THIẾU] |
| Ảnh lịch sử buổi | `s20_history_detail.png` | Chụp app | [THIẾU] |
| Ảnh chạy test | `s21_test_run_2026-11-11.png` | Terminal | [THIẾU] |
| Video dự phòng ×3 | `s18/19/20_backup.mp4` | Quay trước buổi bảo vệ | [THIẾU] |
| Tài khoản demo (1 GV + 3 SV) | — | Tạo `user_invites` + enrollments | [THIẾU] |

---

# PHỤ LỤC D — Tự rà soát theo Quality Gate (slide 30) và checklist W14

| Mục | Kết quả | Lý do / bằng chứng |
|---|---|---|
| PROBLEM — vấn đề có minh chứng, user rõ? | **Chưa đạt hoàn toàn** | Có O-01/R-01/R-03/R-05, nhưng không có dữ liệu thô (G-01) |
| FEATURES — nhóm theo nghiệp vụ, gắn vấn đề? | **Đạt** | Slide 04, 06: PP1–PP3 ↔ WF-01..03 |
| DESIGN — business flow, state, UI, class, DB khớp nhau và khớp code? | **Đạt một phần** | BR/WF/state/class khớp mã đã đối chiếu; UI chưa có Figma (G-05); ERD cũ có `cancelled` không dùng |
| TRACEABILITY — Feature → Screen → Class → DB → Test? | **Đạt** | Phụ lục B; TC16–TC18 chưa chạy ghi rõ |
| DEMO WORKFLOW — 2–4 WF có trigger, kết quả, chạy thật, có ngoại lệ? | **Đạt (thiết kế)** | 3 WF, mỗi WF có exception demo được; **chưa diễn tập** trên bản build thật |
| DEMO DATA — seed, tài khoản theo actor, reset, video dự phòng? | **Chưa đạt** | G-13 |
| TESTS — theo tính năng/BR/state, có report? | **Đạt một phần** | Có số liệu 11/11; BR-08 chưa E2E; e2e luồng 3/8; chưa có link CI |
| OUTCOME — kết quả và giới hạn có cơ sở? | **Đạt** | Slide 22–23 dùng số đo thật; KPI không có nguồn bị loại |

**Rà soát phụ:** 
- Mỗi slide có đủ các trường theo mẫu Mục 5 — **đạt** (24 slide + A1–A6).
- Tổng thời lượng: P1 3,6′ · P2 6,3′ · P3 6,5′ · P4 2,4′ = **≈ 18,8′** — **đạt** (ngân sách 18–20′).
- WF trong Business flow (07) = Traceability (16) = Demo (17–20) = Test (21) = WF-01/02/03 — **đạt**.
- Mã BR ở điểm rẽ (07) = state machine (08) = test (21, Phụ lục B.3) — **đạt**; BR-08 chỉ có rules test.
- Không còn dữ liệu ví dụ của khung/PDF (mua hàng, `#R-102`, TC01–14 mẫu…) — **đạt** (TC01–TC30 là của dự án).
- Mọi `[THIẾU]` / `[CẦN NHÓM XÁC NHẬN]` đã gom ở Phụ lục C.1 — **đạt**.
- Checklist W14 (8 mục) đã chạy trong `WORKFLOW_SPECS.md` §6: 7 đạt, 1 chưa đạt hoàn toàn (mục 6: nhánh rẽ chưa đủ test).
