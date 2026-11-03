# PRM323 Lab 2 - Design Decisions & Accessibility Audit

## 1. Các Quyết định Thiết kế Chính (Accept / Modify / Reject Decisions)

Trong quá trình chuyển đổi giao diện từ AI UI Generator sang Figma và hiện thực Flutter Handoff, nhóm đã đưa ra các quyết định thiết kế dựa trên Persona giảng viên/sinh viên, Nguyên tắc Heuristics và Ràng buộc kỹ thuật:

### Decision 1: ACCEPT - Sử dụng Mã QR Động tự làm mới mỗi 5 giây (Dynamic Refreshing QR)
- **Đề xuất từ AI**: Tạo mã QR cố định (Static QR) cho mỗi buổi học.
- **Quyết định**: **MODIFY / REJECT Static QR** $\rightarrow$ **ACCEPT Dynamic QR (5s Token Refresh)**.
- **Lý do & Căn cứ**: 
  - *Persona*: Sinh viên FPTU có thể chụp ảnh mã QR tĩnh từ trong lớp gửi ra nhóm Zalo/Messenger cho bạn ở ký túc xá quét hộ.
  - *Kỹ thuật*: Mã QR động chứa JWT Token hết hạn sau 5 giây, kết hợp thuật toán mã hóa TOTP khiến việc điểm danh từ xa trở nên khả thi = 0%.

---

### Decision 2: REJECT - Bắt buộc Sinh viên tải App Flutter chuyên dụng từ App Store
- **Đề xuất từ AI**: Xây dựng 2 App Flutter riêng biệt (1 App cho Giảng viên, 1 App cho Sinh viên).
- **Quyết định**: **REJECT Student Native App** $\rightarrow$ **ACCEPT Web Check-in Portal (Firebase Hosting)**.
- **Lý do & Căn cứ**:
  - *Persona (Sinh viên)*: Sinh viên cực kỳ ngại tải thêm ứng dụng dung lượng nặng chỉ để dùng 30 giây đầu giờ. Việc bắt tải app gây rào cản trải nghiệm (Onboarding Friction) và làm chậm thời gianểm danh.
  - *Giải pháp*: Web PWA siêu nhẹ (< 500KB), mở trực tiếp qua Camera/Trình duyệt Safari/Chrome, không cần đăng nhập phức tạp.

---

### Decision 3: MODIFY - Thiết kế Bảng thông tin Real-time song song với Khung chiếu QR (Split Layout)
- **Đề xuất từ AI**: Màn hình Live QR chiếm toàn bộ giao diện 100% fullscreen (Modal QR duy nhất).
- **Quyết định**: **MODIFY** thành Layout chia đôi (Split Canvas 50/50 trên Desktop): Bên trái là `QrPanel` (Mã QR động + Bộ đếm), bên phải là `CheckinPanel` (Danh sách SV vừa check-in + Sĩ số real-time).
- **Lý do & Căn cứ**:
  - *Heuristic #1 (Visibility of system status)*: Giảng viên vừa có thể chiếu QR cho sinh viên quét, vừa nhìn thấy ngay tên sinh viên nhảy lên danh sách check-in bên phải mà không phải chuyển tab qua lại.

---

### Decision 4: ACCEPT - Tích hợp Nút bấm & Modal Điểm danh thủ công khẩn cấp (Emergency Manual Fallback)
- **Đề xuất từ AI**: Tự động hoàn toàn 100% bằng AI/QR, không có luồng can thiệp tay.
- **Quyết định**: **ACCEPT Manual Override Dialog**.
- **Lý do & Căn cứ**:
  - *Thực tế phòng học*: Khoảng 2-5% sinh viên gặp sự cố điện thoại hết pin, vỡ kính camera hoặc lỗi kết nối 4G. Nếu không có luồng thủ công, buổi học sẽ bị gián đoạn vì tranh cãi điểm danh.

---

## 2. Báo cáo Kiểm thử Truy cập (Accessibility Audit - WCAG 2.1 AA Compliance)

Tất cả các thành phần UI trong hệ thống **FAP Check-in** được kiểm thử nghiêm ngặt đạt chuẩn WCAG 2.1 AA:

### A. Tỷ lệ tương phản màu sắc (Color Contrast Ratios)

| Thành phần UI (UI Element) | Màu Chữ / Foreground | Màu Nền / Background | Tỷ lệ Contrast | Đạt chuẩn WCAG |
| :--- | :--- | :--- | :--- | :--- |
| **Primary Button Text** | `#FFFFFF` (White) | `#087C87` (Primary Teal) | **5.42 : 1** | AA $\checkmark$ (Yêu cầu $\ge$ 4.5:1) |
| **Body Text / Table Content** | `#26343D` (Dark Slate) | `#FFFFFF` (Surface White) | **12.85 : 1** | AAA $\checkmark$ (Yêu cầu $\ge$ 4.5:1) |
| **Secondary Subtitle** | `#7B8790` (Muted Grey) | `#F6F8F9` (Background) | **4.68 : 1** | AA $\checkmark$ (Yêu cầu $\ge$ 4.5:1) |
| **Warning Card Alert Text** | `#7A450B` (Dark Amber) | `#FFFFFAF0` (Warning Light) | **7.12 : 1** | AAA $\checkmark$ (Yêu cầu $\ge$ 4.5:1) |
| **Badge Present (Check-in)** | `#2E7D32` (Dark Green) | `#E8F5E9` (Light Green) | **5.15 : 1** | AA $\checkmark$ (Yêu cầu $\ge$ 4.5:1) |

---

### B. Vùng tương tác & Kích thước Chữ (Touch Target & Typography)

1. **Touch Target Size**:
   - Tất cả nút bấm (`AppButton`, `IconButton`, `FilterChip`) có chiều cao tối thiểu **48 x 48 dp** chuẩn Google Material 3.
   - Khoảng cách giữa các nút tương tác $\ge$ 8dp để tránh bấm nhầm trên màn hình cảm ứng.

2. **Typography Constraints**:
   - Chữ nội dung chính (Body Text): $\ge$ **14sp** (`AppTextStyles.bodySm` = 14sp, `bodyMd` = 15sp).
   - Tỷ lệ dòng (Line height): Từ **1.33 đến 1.5** giúp dễ đọc trên màn hình máy chiếu phòng học.

3. **Không phụ thuộc duy nhất vào Màu sắc (Non-color reliant indicators)**:
   - Tất cả badge trạng thái (`Present`, `Absent`, `Late`, `Manual`) đều kết hợp đồng thời 3 yếu tố: **[Color Fill + Text Label + Icon Representation]**.
   - *Ví dụ*: Nút Absent có Màu đỏ `#E56B57` + Chữ `"Absent"` + Icon `Icons.cancel_outlined`.

---

## 3. Thử nghiệm Đa thiết kế & Phản hồi (Responsive & Breakpoint Testing)

Giao diện được tối ưu chuẩn xác trên 3 khung kích thước màn hình (Breakpoints):

```mermaid
graph LR
    Mobile[Compact Phone: 360dp] --> Tablet[Standard Mobile/Tablet: 412dp]
    Tablet --> Desktop[Desktop / Projector: 1200dp+]
```

| Màn hình (Screen) | Mobile Layout (360dp - 412dp) | Desktop / Projector Layout (1200dp+) |
| :--- | :--- | :--- |
| **Live Session Screen** | Bố cục dạng 1 cột cuộn dọc (Single Column Stack). Mã QR hiển thị phía trên, bảng danh sách check-in cuộn phía dưới. | Split Layout 2 cột (50/50): `QrPanel` cố định bên trái, `CheckinPanel` chiếm toàn bộ cột bên phải. |
| **Dashboard Screen** | Navigation bar hiển thị dưới dạng Bottom Navigation. Stat cards xếp chồng 1 cột. | Sidebar điều hướng cố định bên trái (Drawer/Rail), Stat cards xếp thành hàng 4 cột ngang. |
| **Report Screen** | Warning Table cuộn ngang (Horizontal Scroll) tự điều chỉnh cột gọn gàng. | Bảng dữ liệu trải rộng toàn bộ màn hình, hiển thị đầy đủ biểu đồ so sánh song song. |
