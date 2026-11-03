# PRM323 Lab 2 - AI UI Generation & Critique Log

## 1. Prompt gốc tạo UI ban đầu (Original Prompt for AI UI Generation)

**Tool sử dụng**: Google Stitch / AI UI Generator & Figma Assistant  
**Platform**: Flutter Desktop / Tablet (Dành cho Giảng viên) & Mobile Web PWA (Dành cho Sinh viên)  
**Design System target**: Material 3 / Custom Tailwind System (Deep Teal & Burnt Orange Accent)

### Prompt nguyên văn (Raw Prompt):
```text
Role: Senior Mobile & Web UX/UI Designer.
Task: Design a modern Smart Attendance System UI for FPT University Lecturers and Students named 'FAP Check-in'.

Target Personas:
1. Primary User: FPTU Lecturer running classes on Windows Laptop connected to Projector. Needs fast 1-click QR session launch, dynamic auto-refreshing QR code display, real-time live check-in student list, and quick manual attendance fallback.
2. Secondary User: FPTU Student scanning QR via web browser without downloading any app. Needs instant green confirmation badge.

Constraints & Style Guidelines:
- Mobile & Desktop responsive layout (360dp, 412dp, and 1200dp desktop width).
- Palette: Primary Teal (#087C87), Accent Orange (#F2A51D), Alert Red (#E56B57), Surface (#FFFFFF), Background (#F6F8F9).
- Typography: Inter font family, minimum 14sp body text, high contrast headers.
- Accessibility: Minimum 48x48dp touch targets, color-blind safe badges (Icons + Text + Colors).
- Screens required: Login, Dashboard, Live QR Session, Class Management, Attendance History, Absence Warning Reports, Schedule, and Settings.
```

---

## 2. Kết quả UI sơ khởi từ AI (Initial AI UI Baseline Output)

Giao diện ban đầu được khởi tạo bởi AI có bố cục cơ bản nhưng bộc lộ nhiều hạn chế về mặt UX và thực tế phòng học:
- Mã QR Code quá nhỏ ở góc màn hình, khó quét khi chiếu qua máy chiếu phòng học FPT.
- Không có nút điểm danh thủ công nhanh khi sinh viên gặp sự cố thiết bị.
- Bảng danh sách điểm danh thiếu chỉ số sĩ số tổng quan (Present / Absent / Total counter).
- Màn hình báo cáo chỉ dùng màu đỏ/xanh đơn thuần để chỉ sinh viên vắng, vi phạm nguyên tắc Accessibility (mù màu không nhận biết được).

---

## 3. 3 Vòng lặp tinh chỉnh thiết kế có Mục tiêu Khác nhau (3 Iteration Cycles)

### Vòng 1 (Iteration 1): Tối ưu hóa Visual Hierarchy & Độ hiển thị máy chiếu (Projection Clarity)
- **Mục tiêu**: Nâng cao trải nghiệm thị giác cho Giảng viên khi chiếu giao diện lên máy chiếu khoảng cách xa (3 - 5 mét).
- **Prompt tinh chỉnh**:
  > *"Redesign QrPanel on LiveSessionScreen. Increase QR Code canvas size to at least 320x320dp with a crisp white card wrapper, high contrast border, animated countdown ring, and prominent token status text. Make the QR visible from 5 meters away on projector."*
- **So sánh Before / After**:
  - *Before*: Mã QR 150x150dp, chìm vào hình nền xám, không có đếm ngược thời gian đổi token.
  - *After*: Mã QR 320x320dp đặt trên thẻ nổi Canvas trắng, bo góc 16dp, viền Teal #087C87 2px, có thanh Progress Bar đếm ngược 5s đổi mã token trực quan.

### Vòng 2 (Iteration 2): Xử lý luồng ngoại lệ & Điểm danh thủ công khẩn cấp (Fallback & Edge-case Handling)
- **Mục tiêu**: Giải quyết các trường hợp sinh viên bị hỏng camera, mất mạng 4G hoặc lỗi thiết bị tại lớp.
- **Prompt tinh chỉnh**:
  > *"Add an emergency Manual Attendance dialog overlay triggered from CheckinPanel. Include a fast search bar by Student ID or Name, quick radio buttons for Present/Late/Excused, a required reason text field, and immediate state update with a 'Manual' blue badge."*
- **So sánh Before / After**:
  - *Before*: Giảng viên phải thoát phiên QR, mở lại danh sách chính mới sửa được trạng thái sinh viên (Mất 4-5 thao tác).
  - *After*: Mở `ManualAttendanceDialog` dạng Overlay trực tiếp trên màn hình Live QR chỉ với 1-click. Cập nhật ngay badge xanh dương `[Manual]` trong bảng Real-time.

### Vòng 3 (Iteration 3): Mật độ dữ liệu & Cảnh báo Cấm thi (Data Density & Absence Warning Analytics)
- **Mục tiêu**: Tối ưu màn hình Báo cáo (`ReportScreen`) giúp Giảng viên nhận diện ngay sinh viên nghỉ quá 20% (nguy cơ cấm thi).
- **Prompt tinh chỉnh**:
  > *"Redesign Warning Table in ReportScreen. Highlight students with absence rate > 20% using warning card background (#FFFFFAF0), amber border (#F0DFB9), warning icon, explicit percentage badge, and quick action button 'Send Warning Alert'."*
- **So sánh Before / After**:
  - *Before*: Danh sách sinh viên phẳng (flat list), tỉ lệ vắng ghi bằng chữ nhỏ 12sp, không phân biệt màu sắc thẻ.
  - *After*: Bảng `WarningTable` tự động đưa các case nguy cơ cấm thi lên top, tô nền vàng cảnh báo `#FFFFFAF0`, thẻ Badge đỏ rực `25% (5/20 buổi)` kèm icon tam giác cảnh báo `Icons.warning_amber_rounded`.

---

## 4. Đánh giá Phản biện UX (UX Critique & 5 Finding Evaluation)

Dựa trên 10 Nguyên tắc Nielsen Heuristics và Tiêu chuẩn Truy cập (WCAG 2.1 AA), 5 vấn đề UX chính đã được phát hiện và khắc phục:

| STT | Vấn đề UX phát hiện (UX Issue) | Nguyên tắc vi phạm (Heuristic / Standard) | Giải pháp khắc phục trong Thiết kế cuối |
| :--- | :--- | :--- | :--- |
| **01** | Mã QR không có đồng hồ báo hiệu thời gian đếm ngược khi nào đổi token. | **Nielsen #1**: Visibility of system status | Thêm vòng tròn Progress Countdown (5s) xung quanh mã QR để Giảng viên và Sinh viên biết khi nào token nhảy. |
| **02** | Sinh viên quét QR thành công trên web nhưng không có thông báo xác nhận rõ ràng. | **Nielsen #1 & #4**: System Feedback & Consistency | Thiết kế Badge thành công màu xanh lá tươi `[Check-in Successful]`, rung haptic nhẹ và hiện Toast thông tin slot học. |
| **03** | Điểm danh sai không có cách nào sửa nhanh nếu không thoát khỏi phiên chiếu. | **Nielsen #3**: User control and freedom | Thêm nút chỉnh sửa tức thì (Quick Edit Action) ngay tại hàng tên sinh viên trong `CheckinPanel`. |
| **04** | Chỉ dùng màu Xanh/Đỏ để phân biệt trạng thái Điểm danh / Vắng mặt. | **WCAG 2.1 AA #1.4.1**: Use of Color | Bổ sung Icon trực quan (Checkmark `✓` cho Present, Cross `✕` cho Absent, Clock `🕒` cho Late) đi kèm nhãn Text rõ ràng. |
| **05** | Nút bấm thao tác chính (Bắt đầu phiên, Điểm danh tay) quá nhỏ trên màn hình cảm ứng di động. | **Accessibility / Target Size**: Target Size ≥ 48x48 dp | Quy chuẩn tất cả `IconButton` và `ElevatedButton` đạt chiều cao tối thiểu 48dp, padding 16dp cho môi trường cảm ứng. |
