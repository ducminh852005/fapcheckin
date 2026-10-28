# PRM323 Lab 2 - Information Architecture & User Flows

## 1. Kiến trúc thông tin (Information Architecture / Sitemap)

Hệ thống **FAP Check-in** được thiết kế chuẩn Material 3 cho Flutter Desktop/Mobile App (Giảng viên) và PWA Web Portal (Sinh viên). 

### Sitemap Tổng thể (>= 8 Màn hình chính)

```mermaid
graph TD
    AppRoot[FAP Check-in System] --> AuthScreen[01. Màn hình Đăng nhập OAuth]
    AuthScreen --> MainLayout[Main Navigation Shell]
    
    MainLayout --> DashboardScreen[02. Màn hình Tổng quan / Dashboard]
    MainLayout --> LiveSessionScreen[03. Màn hình Phiên Điểm danh QR]
    MainLayout --> ClassMgmtScreen[04. Màn hình Quản lý Lớp học]
    MainLayout --> HistoryScreen[05. Màn hình Lịch sử Điểm danh]
    MainLayout --> ReportScreen[06. Màn hình Báo cáo & Cảnh báo Cấm thi]
    MainLayout --> ScheduleScreen[07. Màn hình Thời khóa biểu Ca dạy]
    MainLayout --> SettingsScreen[08. Màn hình Cài đặt & Cấu hình An ninh QR]
    
    LiveSessionScreen --> StartSessionDialog[Dialog: Khởi tạo Phiên & Cấu hình IP/Geofence]
    LiveSessionScreen --> ManualDialog[Dialog: Điểm danh Thủ công Khẩn cấp]
    ClassMgmtScreen --> ImportDialog[Dialog: Import TKB qua OCR / Excel]
    
    AppRoot --> StudentWebPortal[09. Web Check-in Portal Sinh viên - Firebase Hosting]
```

---

## 2. Ba luồng người dùng chi tiết (Three Detailed User Flows)

### Flow 1: Luồng Chính - Khởi tạo & Chiếu mã QR điểm danh (Happy Path)
*Mục tiêu*: Giảng viên mở phiên điểm danh nhanh và sinh viên check-in tự động thành công.

```mermaid
sequenceDiagram
    autonumber
    actor T as Giảng viên
    participant APP as App Flutter (GV)
    participant FS as Firebase Firestore
    participant WEB as Web Check-in (SV)
    actor S as Sinh viên

    T->>APP: 1. Đăng nhập Google Workspace FPT
    T->>APP: 2. Chọn lớp học từ Dashboard / Thời khóa biểu
    T->>APP: 3. Nhấp "Bắt đầu điểm danh" -> Mở StartSessionDialog
    T->>APP: 4. Cấu hình (Bật/Tắt IP Check, Thời gian đổi QR = 5s) -> Bấm "Xác nhận"
    APP->>FS: 5. Tạo Document Session (status: 'ACTIVE', secretToken)
    APP->>APP: 6. Hiển thị QrPanel (Mã QR động tự đổi mỗi 5 giây) & CheckinPanel (Danh sách real-time)
    S->>WEB: 7. Mở Camera điện thoại quét mã QR chiếu trên màn hình
    WEB->>FS: 8. Gửi payload {studentId, sessionId, currentToken, userIp}
    FS-->>APP: 9. Firestore Listener push real-time event check-in mới
    APP->>APP: 10. CheckinPanel cập nhật badge "Present", tăng đếm sĩ số (28/30)
    T->>APP: 11. Bấm "Kết thúc phiên" -> Đồng bộ trạng thái về FAP/Firestore
```

---

### Flow 2: Luồng Thay Thế - Điểm danh thủ công khẩn cấp (Alternate Path)
*Mục tiêu*: Xử lý trường hợp sinh viên bị hỏng camera, hết dung lượng 4G hoặc gặp sự cố điện thoại.

```mermaid
flowchart TD
    A[Bắt đầu: Giảng viên đang ở Màn hình Live QR Session] --> B[Sinh viên báo sự cố: Hỏng camera/Mất mạng]
    B --> C[Giảng viên nhấp nút 'Điểm danh thủ công' trên CheckinPanel]
    C --> D[Mở ManualAttendanceDialog dạng Overlay]
    D --> E[Giảng viên tìm kiếm MSSV / Tên sinh viên trong danh sách]
    E --> F[Chọn Trạng thái: Present / Late / Excused]
    F --> G[Nhập ghi chú lý do: 'Hỏng camera điện thoại']
    G --> H[Bấm 'Lưu thay đổi']
    H --> I[Cập nhật trạng thái tức thì trên CheckinPanel với Badge 'Manual']
    I --> J[Gửi log ghi nhận thao tác thủ công lên Firebase audit log]
    J --> K[Đóng Dialog & Quay lại luồng Live QR]
```

---

### Flow 3: Luồng Lỗi & Phục Hồi - Sự cố mất mạng / Mất kết nối Token QR (Error & Recovery Path)
*Mục tiêu*: Tự động phát hiện lỗi ngắt kết nối mạng hoặc hết hạn Token QR, hỗ trợ Giảng viên khôi phục phiên mà không làm gián đoạn lớp học.

```mermaid
flowchart TD
    A[Giảng viên đang chiếu QR trên LiveSessionScreen] --> B{Mất kết nối Internet / Firestore Timeout}
    B -- Có sự cố --> C[QrPanel phát hiện ngắt kết nối websocket/listener]
    C --> D[Hiển thị Error Toast & Banner màu đỏ: 'Mất kết nối mạng! Mã QR đã tạm dừng']
    D --> E[Nút QR bị mờ xám, đồng hồ đếm ngược chuyển sang biểu tượng Cảnh báo Warning]
    E --> F[Giảng viên nhấp nút 'Thử lại kết nối' Retry Button]
    F --> G{Kiểm tra lại kết nối mạng thành công?}
    G -- Thất bại --> H[Hiển thị gợi ý: 'Chuyển sang chế độ Offline / Điểm danh thủ công']
    H --> I[Cho phép giảng viên tick chọn thủ công danh sách và lưu tạm Cache cục bộ]
    G -- Thành công --> J[Hệ thống tái khởi tạo Secret Token & Khôi phục Firestore Listener]
    J --> K[Hiển thị Success Banner: 'Đã khôi phục kết nối! Mã QR tiếp tục nhảy']
    K --> L[Quay lại trạng thái điểm danh tự động bình thường]
```

---

## 3. Bảng ánh xạ Flow - Screen (Flow to Screen Mapping Table)

| Luồng người dùng (User Flow) | Màn hình & Component tham gia | Vai trò của Màn hình / Component |
| :--- | :--- | :--- |
| **Flow 1: Live QR Session (Happy Path)** | `01. LoginScreen`<br>`02. DashboardScreen`<br>`03. LiveSessionScreen`<br>└─ `StartSessionDialog`<br>└─ `QrPanel`<br>└─ `CheckinPanel`<br>`09. StudentWebPortal` | Authenticate giảng viên -> Chọn ca dạy -> Mở modal chọn tham số -> Hiển thị QR động -> Cập nhật danh sách SV quét thành công real-time. |
| **Flow 2: Manual Override (Alternate Path)** | `03. LiveSessionScreen`<br>└─ `CheckinPanel`<br>└─ `ManualAttendanceDialog` | Giảng viên bấm nút điểm danh tay -> Modal tra cứu MSSV -> Đổi trạng thái sang Present/Late -> Đóng modal & cập nhật UI. |
| **Flow 3: Error & Recovery Path** | `03. LiveSessionScreen`<br>└─ `QrPanel` (Error State)<br>`05. AttendanceHistoryScreen` (Offline Cache) | Xử lý lỗi ngắt kết nối -> Hiển thị Banner Error & Retry Button -> Khôi phục token hoặc chuyển sang lưu Offline Cache. |
