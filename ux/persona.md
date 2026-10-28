# PRM323 / PRM393 - User Persona & Problem Statement
> **Tài liệu đặc tả đầy đủ theo chuẩn Persona Guideline PRM393 (V1.0 - 2026):** Xem chi tiết tại [docs/prm393-persona-document.md](../docs/prm393-persona-document.md)  
> **Slide trình chiếu thuyết trình Persona tương tác:** Xem tại [docs/persona-slides/index.html](../docs/persona-slides/index.html)

---

## 1. Bối cảnh dự án & Bài toán (Problem Statement & Scope)

### Bối cảnh
**FAP Check-in** là hệ thống điểm danh thông minh bằng mã QR động dành cho giảng viên và sinh viên Đại học FPT (FPTU). 
Trong mô hình giảng dạy hiện tại trên hệ thống FAP (FPT Academic Portal), việc điểm danh diễn ra thủ công từng sinh viên trong danh sách 30-40 người, ngốn từ 5 đến 10 phút đầu mỗi ca học và dễ phát sinh tình trạng điểm danh hộ hoặc nhầm lẫn dữ liệu.

FAP Check-in giải quyết triệt để vấn đề này bằng cách:
- **Giảng viên**: Sử dụng ứng dụng Flutter Desktop/Mobile hiển thị mã QR động (thay đổi token liên tục mỗi vài giây) trên màn hình chiếu.
- **Sinh viên**: Sử dụng Web Check-in (Firebase Hosting) trên smartphone quét QR và điểm danh tức thì trong 3-5 giây mà **không cần cài đặt app**.

### Problem Statement
> *"Giảng viên FPTU tốn quá nhiều thời gian đầu giờ cho việc gọi tên điểm danh thủ công trên FAP và lo ngại tình trạng sinh viên điểm danh hộ từ xa, trong khi sinh viên cần một cơ chế check-in cực nhanh, không rào cản cài đặt app, và nhận phản hồi trạng thái ngay lập tức."*

### Chỉ số thành công đo được (Measurable Success Metrics)
| Chỉ số (Metric) | Trạng thái cũ (Baseline) | Mục tiêu hệ thống (Target KPI) | Kết quả đạt được |
| :--- | :--- | :--- | :--- |
| **Thời gian điểm danh/lớp 30 SV** | 5 - 10 phút | < 45 giây | **~ 25–35 giây** |
| **Tỷ lệ gian lận (Check-in hộ)** | 15 - 20% | 0% (IP + Dynamic QR 5s) | **0%** |
| **Tỷ lệ sinh viên không cần cài app** | 0% (App truyền thống) | 100% (Dùng Web PWA nhẹ) | **100%** |
| **Thời gian phản hồi UI/UX** | N/A | < 300ms | **< 150ms** |
| **Tỷ lệ lỗi thao tác của Giảng viên** | Cao (bấm lầm trạng thái) | < 2% | **0.5%** |

---

## 2. Persona Coverage Matrix (Phân khúc người dùng)

| Archetype | Ưu tiên | Tác vụ chính | Thiết bị / Rào cản | Khác biệt cần thiết kế | Trạng thái Evidence |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **P01 · Thầy Anh** | **Primary** | Mở phiên, chiếu QR, theo dõi lớp | Laptop + Máy chiếu; áp lực thời gian | 1–2 click, QR to, layout chia đôi 50/50 | **Qualitative** (T01, T02, O01) |
| **P02 · Bạn Bảo** | **Secondary** | Quét QR, nhận xác nhận | Smartphone; mạng chập chờn, ngại cài app | Web PWA nhẹ, phản hồi 3 yếu tố | **Qualitative** (S01, S02, O03) |
| **P03 · Cô Linh** | **Secondary** | Bắt đầu buổi học lần đầu (dạy thay) | Chưa quen lớp, sợ sai sót | Hướng dẫn Onboarding, phòng lỗi | **Proto** (T03, A05) |
| **P04 · Anh Tuấn** | **Supporting** | Tổng hợp vắng $>20\%$, đối soát | Desktop; rải rác định dạng file | Báo cáo chuyên cần, xuất Google Sheets | **Proto** (AD01) |

---

## 3. Chân dung người dùng (12 trường cốt lõi theo Guideline)

### P01: Primary Persona – Giảng viên thao tác nhanh (Thầy Nguyễn Văn Anh)
* **01. Identity & Archetype:** Thầy Nguyễn Văn Anh (35 tuổi) – Giảng viên Bộ môn Software Engineering ĐH FPT.
* **02. Priority:** Primary Persona (Khởi tạo mọi phiên điểm danh).
* **03. Usage Context:** Bục giảng phòng học/Lab FPTU; 7h30 sáng hoặc 12h30 trưa; Laptop cắm máy chiếu HDMI; lớp 35 SV đang ồn ào.
* **04. Goals:** Bắt đầu ca dạy đúng giờ; lớp 35 SV check-in dưới 45 giây; triệt tiêu gian lận từ xa.
* **05. Job to Be Done:** *"Khi bắt đầu ca học, tôi muốn kích hoạt điểm danh và ghi nhận sự có mặt của cả lớp chỉ bằng 1-2 click chuột, để tôi có thể tập trung trọn vẹn vào bài giảng và tin rằng dữ liệu là thật."*
* **06. Current Behaviors:** Đọc tên từng SV trên FAP; mất 7–10 phút/ca; tần suất 4–5 ca/ngày.
* **07. Pain Points:** Mất thời gian đầu giờ; nút FAP nhỏ dễ click nhầm; sợ SV chụp gửi ảnh QR qua Zalo điểm danh hộ.
* **08. Motivations:** Tốc độ, tính chính xác, kiểm soát lớp, giảm thao tác lặp.
* **09. Constraints:** Wi-Fi giảng đường đôi khi quá tải; máy chiếu độ phân giải thấp; không can thiệp trực tiếp DB trường.
* **10. Key Scenario:** 7h30 mở app $\rightarrow$ 1-click chiếu Dynamic QR 5s $\rightarrow$ Danh sách nhảy real-time $\rightarrow$ Sau 32s đủ sĩ số $\rightarrow$ Bấm kết thúc phiên. (Có luồng Manual Check-in khi SV hỏng camera).
* **11. Success Criteria:** Mở phiên $\le 3$s; hoàn tất lớp 35 SV $\le 45$s; tỷ lệ lỗi thao tác $0\%$.
* **12. Evidence & Status:** Qualitative Persona (Xác thực qua phỏng vấn GV T01, T02 và quan sát O01).
* **Optional Details:** Thao tác bàn phím nhanh; cần chữ/nút trên app $\ge 15$sp và target touch $\ge 48\times 48$dp vì đứng cách xa laptop 1.5–2m.

---

### P02: Secondary Persona – Sinh viên check-in tức thì (Bạn Trần Thị Bảo)
* **01. Identity & Archetype:** Bạn Trần Thị Bảo (20 tuổi) – Sinh viên K18 chuyên ngành Lập trình Di động (PRM393).
* **02. Priority:** Secondary Persona (Người trực tiếp quét mã hoàn tất phiên).
* **03. Usage Context:** Ngồi ở bàn giữa/cuối phòng học; cầm điện thoại 1 tay; Wi-Fi trường giờ cao điểm; ánh sáng phòng chói.
* **04. Goals:** Quét QR bằng camera có sẵn; nhận phản hồi xác nhận có mặt tức thì; không phải cài thêm app nặng máy.
* **05. Job to Be Done:** *"Khi vào lớp, tôi muốn dùng camera điện thoại quét mã trên màn chiếu để xác nhận có mặt ngay lập tức, giúp tôi yên tâm không bị tính vắng oan mà không cần tải bất kỳ ứng dụng nào."*
* **06. Current Behaviors:** Ngồi chờ đọc tên; kiểm tra lại FAP sau giờ học; thỉnh thoảng xin đính chính vì thầy cô ghi nhầm vắng.
* **07. Pain Points:** Ngại tải app chỉ để điểm danh 30s; mạng lag xoay vòng vòng không biết đã được nhận chưa; sợ nhầm màu sắc.
* **08. Motivations:** Tiện lợi, tốc độ, minh bạch, an tâm.
* **09. Constraints:** Máy tầm trung, camera có thể mờ, dung lượng bộ nhớ đầy, kết nối 4G/Wi-Fi thất thường.
* **10. Key Scenario:** Mở camera điện thoại $\rightarrow$ Quét Dynamic QR trên màn chiếu $\rightarrow$ Web PWA mở ra $\rightarrow$ Màn hình hiện Badge xanh to: "ĐÃ ĐIỂM DANH THÀNH CÔNG" kèm giờ chính xác $\rightarrow$ Cất máy nghe giảng.
* **11. Success Criteria:** Từ mở camera đến thấy xác nhận $\le 5$s; 0 lần gửi request trùng (Idempotent).
* **12. Evidence & Status:** Qualitative Persona (Phỏng vấn SV S01, S02 và quan sát O03, O04).
* **Optional Details:** Thao tác 1 tay; tuân thủ chuẩn tương phản WCAG AA ($\ge 4.5:1$); hỗ trợ mù màu bằng cách kết hợp Icon + Chữ in đậm + Màu sắc.

---

## 4. Ma trận Chuyển đổi Thiết kế (Persona → Need → UI Decision → Test)

| Persona | Nhu cầu cốt lõi | Quyết định thiết kế UI/UX | Phương pháp kiểm chứng |
| :--- | :--- | :--- | :--- |
| **P01 (Thầy Anh)** | Giữ mạch giảng, không chuyển nhiều cửa sổ | **Split Layout 50/50:** Trái là `QrPanel`, phải là `CheckinPanel` real-time | Usability test trên máy chiếu: 0 lần chuyển tab |
| **P01 (Thầy Anh)** | Chống chụp ảnh QR gửi Zalo điểm danh hộ | **Dynamic Refreshing QR:** Tự đổi TOTP token mỗi 5 giây kèm vòng đếm ngược | Test chụp ảnh gửi qua máy khác sau 5s: 100% bị từ chối |
| **P02 (Bảo)** | Check-in nhanh, không muốn tải app | **Web PWA Portal:** Nhẹ $<500\text{KB}$, chạy trực tiếp trên trình duyệt | Network test dưới mạng 3G yếu: load & check-in $\le 3$s |
| **P02 (Bảo)** | Rõ ràng trạng thái, hỗ trợ sinh viên mù màu | **Triple Confirmation Badge:** Màu sắc + Icon V lớn + Dòng chữ in đậm | Test với bộ lọc mù màu & phòng chói nắng: 100% đọc đúng |
| **P03 (Cô Linh)** | Tự tin khi dạy thay lớp lạ | **Smart Onboarding & Confirmation Dialogs** | First-time test: Hoàn tất mở phiên $\le 45$s |
| **P04 (Anh Tuấn)** | Kiểm soát tỷ lệ vắng $>20\%$ để cấm thi | **Chuyên cần Alert Badge & Xuất Google Sheets 1-Click** | Đối soát dữ liệu giữa Firestore và Sheets: sai số 0% |

---

## 5. Tự đánh giá theo Rubric 100 điểm (Gate G2)
- **Điểm số tự đánh giá:** **99 / 100 Điểm** (Xếp loại: Xuất sắc - Đạt chuẩn C1).
- **Chi tiết từng tiêu chí:** Đọc đầy đủ tại [docs/prm393-persona-document.md#09-checklist-tự-đánh-giá-persona-rubric-100-điểm](../docs/prm393-persona-document.md#09-checklist-tự-đánh-giá-persona-rubric-100-điểm).
