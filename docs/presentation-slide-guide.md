# PRM323 Lab 2 - Slide Presentation & Live Demo Guide

Tài liệu hướng dẫn chi tiết chuẩn bị Slide Trình bày (12 Slides) và Kịch bản Demo trực tiếp dành cho Nhóm sinh viên bảo vệ bài báo cáo **Lab 2: Thiết kế UI/UX có hỗ trợ AI (Google Stitch -> Figma)**.

---

## 1. Cấu trúc Slide Báo cáo Chi tiết (12 Slides Detail & Script)

### Slide 01: Project Overview (Tổng quan Dự án)
- **Tiêu đề**: FAP Check-in – Hệ thống Điểm danh QR Thông minh cho FPTU
- **Thành viên & Vai trò**: 
  - UI/UX Lead & Prompt Engineer (Phụ trách AI Log & Figma)
  - Mobile/Flutter Architect (Phụ trách Design System & Flutter Handoff)
- **Vấn đề thực tế**: Điểm danh thủ công ngốn 10 phút/ca học, sinh viên dễ điểm danh hộ.
- **Minh chứng Artifacts**: 
  - GitHub Repository: [fapcheckin](file:///d:/FPTU/Semester%208/fapcheckin/README.md)
  - Figma Workspace: 6 Pages (`01 User Flow`, `02 Wireframe`, `03 Final UI`, `04 Design System`, `05 Components`, `06 Prototype`)
- **Kịch bản nói (Script 45s)**: *"Kính chào giảng viên và các bạn. Nhóm xin trình bày dự án FAP Check-in - giải pháp điểm danh QR động giúp tiết kiệm 90% thời gian đầu giờ học tại FPTU..."*

---

### Slide 02: Problem & Persona (Bài toán & Chân dung Người dùng)
- **Tiêu đề**: Khảo sát Bối cảnh & Xây dựng Persona
- **Nội dung chính**: 
  - *Primary Persona*: Thầy Nguyễn Văn Anh (35 tuổi - Giảng viên FPTU) -> Cần chiếu QR nhanh, quản lý danh sách real-time, cảnh báo cấm thi.
  - *Secondary Persona*: Sinh viên Trần Thị Bảo (20 tuổi) -> Cần quét QR tức thì qua Web PWA không phải cài app.
- **Chỉ số đo lường (KPIs)**: Giảm thời gian từ 10 phút xuống < 30 giây, 0% điểm danh hộ.
- **Minh chứng Artifact**: [ux/persona.md](file:///d:/FPTU/Semester%208/fapcheckin/ux/persona.md)
- **Kịch bản nói (Script 45s)**: *"Qua khảo sát thực tế tại trường, nhóm xây dựng 2 Persona chính. Điểm cốt lõi là Giảng viên cần thao tác 1-click trên máy chiếu, còn Sinh viên chỉ cần dùng Web điện thoại..."*

---

### Slide 03: Information Architecture (Kiến trúc Thông tin & Sitemap)
- **Tiêu đề**: Cấu trúc Điều hướng & Sơ đồ Trang (>= 8 Màn hình)
- **Nội dung chính**: Sơ đồ sitemap 8 màn hình chính (Login, Dashboard, Live QR Session, Class Management, History, Absence Report, Schedule, Settings) + Web Check-in Portal.
- **Minh chứng Artifact**: [ux/user-flow.md §1](file:///d:/FPTU/Semester%208/fapcheckin/ux/user-flow.md#L5-L25); Figma Page `01 User Flow`
- **Kịch bản nói (Script 45s)**: *"Hệ thống được tổ chức mạch lạc thành 8 màn hình cấp cao chuẩn Material 3. Các chức năng như Báo cáo cảnh báo hay Điểm danh thủ công được phân cấp hợp lý..."*

---

### Slide 04: Three User Flows ( Ba Luồng Người dùng Chi tiết)
- **Tiêu đề**: Happy Path, Alternate Path & Error/Recovery Path
- **Nội dung chính**:
  1. *Flow 1 (Happy)*: Đăng nhập -> Mở ca dạy -> Chiếu QR 5s -> Sinh viên quét Web -> Real-time update.
  2. *Flow 2 (Alternate)*: Sinh viên hỏng camera -> Mở `ManualAttendanceDialog` -> Đổi trạng thái -> Cập nhật badge `[Manual]`.
  3. *Flow 3 (Error/Recovery)*: Mất mạng Internet -> Báo lỗi Banner đỏ -> Bấm Retry -> Khôi phục Token & QR.
- **Minh chứng Artifact**: [ux/user-flow.md §2](file:///d:/FPTU/Semester%208/fapcheckin/ux/user-flow.md#L28-L70); Figma Page `01 User Flow`
- **Kịch bản nói (Script 60s)**: *"Chúng tôi không chỉ thiết kế luồng thuận lợi mà còn đặc biệt chú trọng luồng phụ khi sinh viên hỏng camera và luồng tự phục hồi khi mất kết nối mạng..."*

---

### Slide 05: AI UI Generation (Khởi tạo Giao diện bằng AI)
- **Tiêu đề**: Prompting với Google Stitch & Giao diện Ban đầu
- **Nội dung chính**:
  - Prompt nguyên văn chứa đầy đủ thông tin Persona, Mobile Platform, Material 3 style và Constraints.
  - Ảnh chụp UI ban đầu do Google Stitch tạo ra.
- **Minh chứng Artifact**: [ux/ai-design-log.md §1-2](file:///d:/FPTU/Semester%208/fapcheckin/ux/ai-design-log.md#L5-L35)
- **Kịch bản nói (Script 45s)**: *"Nhóm đã sử dụng Google Stitch với prompt có cấu trúc chặt chẽ. Tuy nhiên output ban đầu của AI vẫn chưa tối ưu cho màn hình máy chiếu phòng học..."*

---

### Slide 06: AI Iterations & Critique (3 Vòng lặp AI & Phản biện UX)
- **Tiêu đề**: Tinh chỉnh AI theo 3 Mục tiêu & Đánh giá Heuristics
- **Nội dung chính**:
  - *Vòng 1*: Tối ưu tầm nhìn QR máy chiếu (Projection Clarity).
  - *Vòng 2*: Bổ sung Modal điểm danh thủ công khẩn cấp (Fallback Handling).
  - *Vòng 3*: Nâng cao mật độ dữ liệu cảnh báo cấm thi (Absence Warning).
  - *5 Vấn đề UX Nielsen*: Phản hồi trạng thái (Countdown ring), Feedback sinh viên, Control freedom, Non-color reliance, Target size 48dp.
- **Minh chứng Artifact**: [ux/ai-design-log.md §3-4](file:///d:/FPTU/Semester%208/fapcheckin/ux/ai-design-log.md#L38-L90)
- **Kịch bản nói (Script 60s)**: *"Qua 3 vòng lặp với các mục tiêu hoàn toàn khác nhau, nhóm đã biến giao diện sơ khởi của AI thành một sản phẩm UI chỉn chu đạt chuẩn Nielsen..."*

---

### Slide 07: Design Decisions (Các Quyết định Thiết kế Cốt lõi)
- **Tiêu đề**: Accept / Modify / Reject Matrix
- **Nội dung chính**: 4 ví dụ điển hình về việc Chấp nhận, Sửa đổi hoặc Từ chối đề xuất của AI (Chuyển sang QR động 5s, Từ chối bắt cài app sinh viên, Thiết kế Split Canvas 50/50, Thêm luồng Manual override).
- **Minh chứng Artifact**: [ux/design-decisions.md §1](file:///d:/FPTU/Semester%208/fapcheckin/ux/design-decisions.md#L5-L45)
- **Kịch bản nói (Script 45s)**: *"AI đề xuất làm QR cố định và bắt sinh viên tải app, nhưng nhóm đã kiên quyết từ chối để chuyển sang QR động 5s và Web PWA nhằm đảm bảo tính bảo mật và giảm rào cản UX..."*

---

### Slide 08: Wireframe -> Final UI (Từ Wireframe đến Giao diện Hoàn chỉnh)
- **Tiêu đề**: Đối chiếu Low-Fi và Hi-Fi UI (>= 8 Screens)
- **Nội dung chính**: Trình bày sự tiến hóa từ cấu trúc Wireframe khung xương sang giao diện hoàn chỉnh có Hierarchy rõ ràng, khoảng thở Spacing hợp lý và đủ các trạng thái Loading / Empty / Error.
- **Minh chứng Artifact**: Figma Page `02 Wireframe` & Page `03 Final UI`
- **Kịch bản nói (Script 45s)**: *"Trên 8 màn hình hoàn chỉnh, nhóm giữ tính nhất quán cao về bố cục. Các trạng thái rỗng (Empty state) hay lỗi mạng đều có thông điệp hướng dẫn người dùng..."*

---

### Slide 09: Design System & Components (Hệ thống Thiết kế & Linh kiện)
- **Tiêu đề**: Design Tokens, Variables & 9 Nhóm Component
- **Nội dung chính**:
  - Color Tokens (`Primary Teal #087C87`, `Accent Orange #F2A51D`, `Status Colors`).
  - Typography Tokens (Inter font family, 12sp đến 28sp).
  - 9 Nhóm Component: Button, Text Field, Card, Navigation, App Bar, Dialog, Loading, Empty, Error. Tất cả dùng Auto Layout và Component Variants.
- **Minh chứng Artifact**: Figma Page `04 Design System` & Page `05 Components`; [lib/core/constants/app_colors.dart](file:///d:/FPTU/Semester%208/fapcheckin/lib/core/constants/app_colors.dart)
- **Kịch bản nói (Script 45s)**: *"Design System được xây dựng bằng Figma Variables. Chỉ cần đổi màu token Primary, toàn bộ giao diện và components sẽ lập tức tự động cập nhật..."*

---

### Slide 10: Accessibility & Responsiveness (Khả năng Truy cập & Đáp ứng)
- **Tiêu đề**: Kiểm thử WCAG 2.1 AA & Đa độ phân giải
- **Nội dung chính**:
  - Tỷ lệ tương phản chữ $\ge$ 4.5:1 (Text trắng trên Teal = 5.42:1).
  - Nút bấm $\ge$ 48x48 dp.
  - Không phụ thuộc duy nhất vào màu sắc (Kết hợp Color + Label + Icon).
  - Thử nghiệm trên kích thước 360dp, 412dp và 1200dp Desktop.
- **Minh chứng Artifact**: [ux/design-decisions.md §2-3](file:///d:/FPTU/Semester%208/fapcheckin/ux/design-decisions.md#L48-L95)
- **Kịch bản nói (Script 45s)**: *"Giao diện đạt chuẩn truy cập WCAG 2.1 AA. Người bị mù màu vẫn dễ dàng nhận biết trạng thái nhờ hệ thống icon đi kèm nhãn text..."*

---

### Slide 11: Live Prototype (Nguyên mẫu Tương tác Direct)
- **Tiêu đề**: Prototype Tương tác Không có Ngõ cụt (No Dead-ends)
- **Nội dung chính**:
  - Minh họa các Smart Animate transitions, Overlay dialogs, Loading -> Result transitions.
  - Đảm bảo tất cả các luồng đều có nút Back và nút Đóng rõ ràng.
- **Minh chứng Artifact**: Figma Page `06 Prototype`
- **Kịch bản nói (Script 30s)**: *"Sau đây nhóm xin kính mời giảng viên xem kịch bản demo trực tiếp nguyên mẫu tương tác trên Figma..."*

---

### Slide 12: Flutter Handoff & Summary (Bàn giao Lập trình & Tổng kết)
- **Tiêu đề**: Bán giao Kỹ thuật cho Lập trình viên Flutter
- **Nội dung chính**:
  - Quy chuẩn 6 mục cho 8 màn hình (Layout, Components, States, Interactions, Navigation, Constraints).
  - Bảng ánh xạ Token -> Flutter Code (`AppColors`, `AppTextStyles`).
  - Bảng ánh xạ Component -> Flutter Widgets (`QrPanel`, `CheckinPanel`, `WarningTable`...).
- **Minh chứng Artifact**: [ux/flutter-handoff.md](file:///d:/FPTU/Semester%208/fapcheckin/ux/flutter-handoff.md)
- **Kịch bản nói (Script 45s)**: *"Tài liệu Flutter Handoff cung cấp đầy đủ thông số kỹ thuật và bảng ánh xạ 1-1 giúp lập trình viên hiện thực chính xác giao diện mà không cần hỏi lại designer. Xin cảm ơn giảng viên!"*

---

## 2. Kịch bản Demo Trực tiếp (7 Bước Demo Kỹ thuật)

Khi giảng viên yêu cầu demo trực tiếp file Figma và Repository:

1. **Bước 01**: Mở file Figma, bật danh sách 6 Pages kiểm tra đúng cấu trúc: `01 User Flow`, `02 Wireframe`, `03 Final UI`, `04 Design System`, `05 Components`, `06 Prototype`.
2. **Bước 02**: Chuyển sang Page `03 Final UI`, chỉ ra tối thiểu 8 màn hình KHÁC nhau (Login, Dashboard, Live QR Session, Class Management, Attendance History, Absence Warning Report, Schedule, Settings).
3. **Bước 03**: Chạy Figma Prototype (Page `06 Prototype`), diễn lại cả 3 user flow từ điểm bắt đầu đến khi hoàn thành mục tiêu.
4. **Bước 04**: Trên Prototype, bấm mở Overlay Dialog (`ManualAttendanceDialog`) và trình diễn chuyển cảnh Loading $\rightarrow$ Result. Bấm nút Back kiểm tra không bị ngõ cụt.
5. **Bước 05**: Mở Page `05 Components`, bấm vào 1 Component chỉ ra cấu trúc Auto Layout, Variants (Default/Hover/Active/Disabled) và mở panel Variables để chứng minh Tokens được dùng thật.
6. **Bước 06**: Mở file `ux/ai-design-log.md`, chọn 1 vòng tinh chỉnh để chứng minh chuỗi quyết định: *Prompt $\rightarrow$ Output $\rightarrow$ Critique $\rightarrow$ Decision $\rightarrow$ Figma Change*.
7. **Bước 07**: Mở GitHub repo [fapcheckin](file:///d:/FPTU/Semester%208/fapcheckin/README.md), cho xem cấu trúc repo, file `README.md` đã gắn link đủ các artifact và mở file `ux/flutter-handoff.md` với 2 bảng mapping.

---

## 3. Checklist Kỹ thuật Kiểm tra trước khi Chấm (Technical Checklist)

| Yêu cầu Kỹ thuật (Technical Requirement) | Trạng thái | Vị trí Minh chứng |
| :--- | :--- | :--- |
| $\checkmark$ **Tối thiểu 8 màn hình cuối** | **ĐẠT (8/8)** | `ux/flutter-handoff.md`, Figma Page `03 Final UI` |
| $\checkmark$ **3 User Flows (Happy, Alternate, Error/Recovery)** | **ĐẠT (3/3)** | `ux/user-flow.md`, Figma Page `01 User Flow` |
| $\checkmark$ **AI Log giữ prompt, ảnh, >= 3 vòng lặp, >= 5 Nielsen critique** | **ĐẠT** | `ux/ai-design-log.md` |
| $\checkmark$ **Design System 9 nhóm components & tokens** | **ĐẠT** | `lib/core/constants/app_colors.dart`, Figma Page `04/05` |
| $\checkmark$ **Accessibility (Contrast $\ge$ 4.5:1, Target $\ge$ 48dp, Font $\ge$ 14sp)** | **ĐẠT** | `ux/design-decisions.md` |
| $\checkmark$ **Flutter Handoff 6 mục spec / screen + 2 bảng Mapping** | **ĐẠT** | `ux/flutter-handoff.md` |
| $\checkmark$ **README ghi đủ link các artifact** | **ĐẠT** | `README.md` |

---

## 4. Bộ Câu hỏi & Trả lời Phản biện cho Hội đồng / Giảng viên (Q&A Preparation)

### Câu 1: Persona có nhu cầu gì khiến nhóm chọn cấu trúc điều hướng này?
> **Trả lời**: Giảng viên dạy liên tục nhiều ca trong ngày, cần truy cập phiên điểm danh chỉ trong 1-2 click. Do đó nhóm chọn cấu trúc Navigation Rail / Sidebar cố định bên trái trên Desktop, giúp truy cập trực tiếp vào Màn hình Live Session hoặc Thời khóa biểu mà không cần đi qua các cấp menu trung gian rườm rà.

### Câu 2: Flow nào dễ thất bại nhất? Khi xảy ra lỗi người dùng có thể phục hồi ra sao?
> **Trả lời**: Flow dễ thất bại nhất là Flow 3 khi mạng Internet tại phòng học bị chập chờn hoặc ngắt kết nối với Firestore. Hệ thống tự động phục hồi bằng cách hiển thị Banner đỏ thông báo ngắt kết nối, cho phép bấm nút "Retry" tái khôi phục token, hoặc tự động kích hoạt chế độ điểm danh Offline tạm thời vào bộ nhớ cache.

### Câu 3: Một đề xuất AI nào đã bị nhóm từ chối? Vì sao?
> **Trả lời**: Nhóm đã từ chối đề xuất sử dụng Mã QR cố định (Static QR) và đề xuất bắt sinh viên tải App chuyên dụng từ App Store. Lý do: Mã QR cố định rất dễ bị sinh viên chụp ảnh gửi ra ngoài điểm danh hộ; còn bắt tải app gây rào cản UX quá lớn cho sinh viên. Nhóm đã thay thế bằng Mã QR động nhảy 5s và Web PWA không cần cài app.

### Câu 4: Ba vòng lặp chỉnh sửa đã giải quyết ba vấn đề UX khác nhau như thế nào?
> **Trả lời**: Vòng 1 giải quyết vấn đề hiển thị (Visual Hierarchy) cho máy chiếu xa. Vòng 2 giải quyết vấn đề ngoại lệ (Fallback UX) khi sinh viên hỏng camera. Vòng 3 giải quyết mật độ dữ liệu (Data Density) và nổi bật cảnh báo cấm thi cho Giảng viên.

### Câu 5: Nếu đổi primary color hoặc spacing token, các màn hình nào tự cập nhật?
> **Trả lời**: Tất cả 8 màn hình đều tự động cập nhật lập tức vì toàn bộ giao diện đều tham chiếu đến Figma Color Variables (`color.primary`) và trong mã nguồn Flutter tham chiếu đến `AppColors.primary` và `ReportColors.primary`.

### Câu 6: Làm thế nào chứng minh màn hình rộng 412 dp không vỡ layout?
> **Trả lời**: Nhóm đã thiết kế Responsive Breakpoint. Trên màn hình 412dp (Tablet/Large Phone), layout chuyển từ 2 cột Split Canvas sang dạng 1 cột cuộn dọc (Single Column Vertical Stack). Tất cả các khung thẻ (Card) đều sử dụng thuộc tính Flex / Expanded và Auto Layout Hug/Fill container.

### Câu 7: Một lập trình viên Flutter chưa biết dự án sẽ dựa vào đâu để hiện thực màn hình và states?
> **Trả lời**: Lập trình viên sẽ dựa vào file `ux/flutter-handoff.md`. File này quy định chính xác 6 mục cho từng màn hình: từ Layout, Components, States (Default/Loading/Error/Empty), Interactions đến UI Constraints, kèm 2 bảng mapping từ Token sang Code Flutter (`AppColors`, `AppTextStyles`).
