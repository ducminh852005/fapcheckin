# PRM323 Lab 2 - Flutter Handoff Specifications

Tài liệu Handoff dành cho Lập trình viên Flutter hiện thực giao diện từ thiết kế Figma / Design System của dự án **FAP Check-in**.

---

## 1. Bảng ánh xạ Design Tokens -> Mã nguồn Flutter (Token Mapping Table)

### A. Color Tokens Mapping (`lib/core/constants/app_colors.dart`)

| Design Token Name (Figma) | Giá trị Hex / Token | Flutter Code Reference | Ứng dụng trong Giao diện |
| :--- | :--- | :--- | :--- |
| `color.primary` | `#087C87` (Teal) | `ReportColors.primary` / `AppColors.primary` | Primary buttons, active tabs, header borders |
| `color.primary.light` | `#E6F5F7` | `ReportColors.primaryLight` | Card background highlight, chip active state |
| `color.accent.orange` | `#F2A51D` | `ReportColors.orange` | Live status badge, dynamic timer ring |
| `color.status.present` | `#2E7D32` | `AppColors.statusPresent` | Badge Check-in thành công |
| `color.status.absent` | `#C62828` | `AppColors.statusAbsent` | Badge Vắng mặt, cảnh báo nguy cơ cấm thi |
| `color.status.late` | `#ED8B00` | `AppColors.statusLate` | Badge Đi học muộn |
| `color.status.manual` | `#1976D2` | `AppColors.statusManual` | Badge Điểm danh thủ công khẩn cấp |
| `color.surface` | `#FFFFFF` | `AppColors.surface` | Card background, dialog background |
| `color.background` | `#F6F8F9` | `ReportColors.background` | Main scaffold background |
| `color.border` | `#E8ECEF` | `ReportColors.border` | Table dividers, card outlines |

---

### B. Typography Tokens Mapping (`lib/core/constants/app_text_styles.dart`)

| Typography Token (Figma) | Font / Size / Weight | Flutter Code Reference | Ứng dụng trong Giao diện |
| :--- | :--- | :--- | :--- |
| `type.headline.lg` | Inter 28px / 600 SemiBold | `AppTextStyles.headlineLg` | Dashboard main title, Screen headers |
| `type.headline.md` | Inter 20px / 600 SemiBold | `AppTextStyles.headlineMd` | Card section titles, Dialog headers |
| `type.headline.sm` | Inter 16px / 600 SemiBold | `AppTextStyles.headlineSm` | Table column headers, Sub-titles |
| `type.body.md` | Inter 15px / 400 Regular | `AppTextStyles.bodyMd` | Standard body content, list items |
| `type.body.sm` | Inter 14px / 400 Regular | `AppTextStyles.bodySm` | Secondary label text, table cells |
| `type.code.mono` | JetBrains Mono 13px / 400 | `AppTextStyles.code` | Secret token string, Student ID codes |

---

## 2. Bảng ánh xạ Component Figma -> Flutter Widgets (Component Mapping Table)

| Figma Component Group | Sub-component / Variant | Flutter Implementation Class | File Path |
| :--- | :--- | :--- | :--- |
| **01. Navigation** | Sidebar / Rail Navigation | `Sidebar` / `NavDestinations` | `lib/views/teacher/dashboard/components/sidebar.dart` |
| **02. Top Bar** | Header with Profile & Actions | `TopBar` / `ReportHeader` | `lib/views/teacher/dashboard/components/top_bar.dart` |
| **03. QR Generator** | Dynamic QR Panel & Timer | `QrPanel` | `lib/views/teacher/live_session/components/qr_panel.dart` |
| **04. Live Feed** | Real-time Student Check-in Table | `CheckinPanel` | `lib/views/teacher/live_session/components/checkin_panel.dart` |
| **05. Dialogs / Modals** | Start Session Settings | `StartSessionDialog` | `lib/views/teacher/live_session/dialogs/start_session_dialog.dart` |
| **05. Dialogs / Modals** | Manual Attendance Override | `ManualAttendanceDialog` | `lib/views/teacher/live_session/dialogs/manual_attendance_dialog.dart` |
| **05. Dialogs / Modals** | Timetable OCR Import | `ImportTimetableDialog` | `lib/views/teacher/class_management/dialogs/import_timetable_dialog.dart` |
| **06. Analytics / Cards** | Stat Overview Card | `StatCard` / `ReportKpis` | `lib/views/teacher/report/components/report_kpis.dart` |
| **07. Warning Analytics** | Absence Threshold Table (>20%) | `WarningTable` | `lib/views/teacher/report/components/warning_table.dart` |
| **08. History Data** | Attendance History Table | `HistoryTable` | `lib/views/teacher/attendance_history/components/history_table.dart` |

---

## 3. Quy chuẩn 6 mục chi tiết cho 8 Màn hình chính (8 Screens Handoff Spec)

### Màn hình 01: Login & Authentication Screen (`lib/views/auth/login_screen.dart`)
1. **Layout**: Căn giữa màn hình (Centered Card Layout), kích thước Card 420x540dp trên Desktop.
2. **Components**: `LogoBrand`, `GoogleSignInButtonWeb`, `EnvironmentTag`, `FooterCopyright`.
3. **States**: 
   - *Default*: Hiển thị nút "Sign in with Google FPT Workspace".
   - *Loading*: Nút disabled, hiển thị `CircularProgressIndicator` xoay tròn.
   - *Error*: Banner thông báo màu đỏ "Email không thuộc tên miền @fpt.edu.vn".
4. **Interactions**: Click nút Sign In -> Mở popup Google OAuth 2.0.
5. **Navigation**: Đăng nhập thành công -> Điều hướng sang `DashboardScreen`.
6. **UI Constraints**: Button height = 48dp, elevation = 2, Google Logo offset 12dp.

---

### Màn hình 02: Teacher Dashboard Screen (`lib/views/teacher/dashboard/`)
1. **Layout**: Responsive Shell Layout (Sidebar bên trái 260dp, TopBar cố định 64dp, Content Area cuộn tự do).
2. **Components**: `Sidebar`, `TopBar`, `StatCard` (4 cards), `WeeklyTimetable`, `ActiveSessionCard`.
3. **States**:
   - *Default*: Hiển thị 4 thẻ KPI (Tổng số lớp, Số SV check-in hôm nay, Ca dạy tiếp theo, Tỷ lệ chuyên cần).
   - *Empty*: Khi giảng viên không có ca dạy hôm nay -> Hiện Illustration `EmptyStateCard`.
4. **Interactions**: Click vào Ca dạy đang diễn ra -> Chuyển nhanh sang Màn hình Live Session.
5. **Navigation**: Menu Sidebar điều hướng sang 7 màn hình còn lại.
6. **UI Constraints**: Card padding = 20dp, border-radius = 12dp, gap = 16dp.

---

### Màn hình 03: Live QR Session Screen (`lib/views/teacher/live_session/live_session_body.dart`)
1. **Layout**: Desktop Split Layout (50% `QrPanel` bên trái, 50% `CheckinPanel` bên phải).
2. **Components**: `QrPanel`, `CheckinPanel`, `CountdownRing`, `ManualAttendanceDialog`, `StartSessionDialog`.
3. **States**:
   - *Default*: Mã QR hiển thị rõ nét 320x320dp, danh sách SV nhảy real-time.
   - *Loading*: Bật hiệu ứng Skeleton loading khi đang tạo token mới từ Firestore.
   - *Error*: Khi ngắt kết nối mạng -> Hiển thị Retry Banner và dừng đếm ngược QR.
4. **Interactions**: Hover mã QR để mở rộng Fullscreen; Click nút "Điểm danh tay" để mở Overlay Dialog.
5. **Navigation**: Bấm "Kết thúc phiên" -> Đóng phiên và chuyển sang `AttendanceHistoryScreen`.
6. **UI Constraints**: Target touch size nút điều khiển = 48dp, QR canvas ratio = 1:1.

---

### Màn hình 04: Class Management Screen (`lib/views/teacher/class_management/class_management_body.dart`)
1. **Layout**: Grid Card Layout (3 cột trên Desktop, 1 cột trên Mobile).
2. **Components**: `ClassCard`, `CreateClassDialog`, `ImportTimetableDialog`, `SearchBar`.
3. **States**:
   - *Default*: Hiển thị danh sách các lớp môn PRM323, SWP391... kèm sĩ số và nút chi tiết.
   - *Loading*: Shimmer effect loading grid.
4. **Interactions**: Click "Import TKB OCR" -> Mở modal upload ảnh lịch học FAP để tự động bóc tách dữ liệu.
5. **Navigation**: Click vào thẻ Lớp -> Mở danh sách sinh viên chi tiết của lớp đó.
6. **UI Constraints**: Card min-width = 320dp, gap = 16dp.

---

### Màn hình 05: Attendance History Screen (`lib/views/teacher/attendance_history/attendance_history_body.dart`)
1. **Layout**: Data Table Layout kết hợp Bộ lọc Filter Header phía trên.
2. **Components**: `ClassSelector`, `KpiDashboard`, `HistoryTable`, `SessionDetailDialog`.
3. **States**:
   - *Default*: Bảng dữ liệu hiển thị lịch sử các buổi học đã điểm danh, ngày giờ, số SV có mặt/vắng.
   - *Empty*: "Chưa có phiên điểm danh nào trong tuần này".
4. **Interactions**: Click nút "Xuất báo cáo" -> Xuất file Excel / Sync trực tiếp lên hệ thống FAP.
5. **Navigation**: Click từng hàng phiên -> Mở `SessionDetailDialog` xem danh sách từng sinh viên.
6. **UI Constraints**: Table row height = 52dp, Status badge padding = 6dp 12dp.

---

### Màn hình 06: Absence Report & Warning Analytics Screen (`lib/views/teacher/report/report_body.dart`)
1. **Layout**: Executive Dashboard Layout (KPI Cards -> Charts -> Warning Table).
2. **Components**: `ReportHeader`, `ReportKpis`, `ReportCharts`, `WarningTable`, `SubjectComparison`.
3. **States**:
   - *Default*: Hiển thị biểu đồ phân bổ điểm danh (QR vs Manual) và danh sách SV vắng > 20%.
   - *Warning State*: Tô nền màu vàng cảnh báo `#FFFFFAF0` cho các dòng sinh viên nguy cơ cấm thi.
4. **Interactions**: Click "Gửi cảnh báo" -> Tự động gửi email/thông báo nhắc nhở sinh viên.
5. **Navigation**: Có thể lọc dữ liệu theo từng Lớp học hoặc từng Môn học.
6. **UI Constraints**: Chart height = 280dp, Warning row border-left = 4px solid `#E56B57`.

---

### Màn hình 07: Teacher Schedule View Screen (`lib/views/teacher/schedule/schedule_body.dart`)
1. **Layout**: Weekly Calendar Grid Layout (7 cột từ Thứ 2 đến Chủ nhật, các Slot 1-6).
2. **Components**: `ScheduleHeader`, `TimeSlotCard`, `RoomBadge`, `ClassFilterChip`.
3. **States**:
   - *Default*: Ca học hiện tại được highlight màu cam rực rỡ `#F2A51D`.
4. **Interactions**: Click vào Ca dạy sắp tới -> Nút "Mở phòng điểm danh" xuất hiện ngay trên Slot Card.
5. **Navigation**: Click Ca học -> Điều hướng trực tiếp sang `LiveSessionScreen`.
6. **UI Constraints**: Slot card height = 90dp, active slot elevation = 4.

---

### Màn hình 08: Settings & Security Screen (`lib/views/teacher/settings/settings_body.dart`)
1. **Layout**: Two-column Master-Detail Settings Layout (Sidebar danh mục bên trái, Form bên phải).
2. **Components**: `SettingsSidebar`, `SettingsSectionSecurity`, `SettingsSectionSync`, `SettingsSectionQr`.
3. **States**:
   - *Default*: Cho phép cấu hình: Thời gian đổi token QR (3s, 5s, 10s), Giới hạn IP Wifi trường, Geofence GPS.
4. **Interactions**: Toggle Switch để Bật/Tắt tính năng Kiểm tra IP mạng trường khi sinh viên check-in.
5. **Navigation**: Thay đổi cấu hình -> Tự động áp dụng cho tất cả các phiên QR tiếp theo.
6. **UI Constraints**: Input field height = 44dp, switch accent color = `#087C87`.
