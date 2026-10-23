[← Mục lục](README.md)

# 02 · Luồng điểm danh bằng QR

Mã QR tự động xoay mỗi 60 giây (tham số Remote Config `qr_refresh_seconds`) trong khi phiên còn mở. "Gần lớp học" được xác nhận bằng địa chỉ IP mạng (tùy chọn theo phiên), không đụng tới GPS.

## Sequence: mở phiên → quét → ghi nhận

```mermaid
sequenceDiagram
    participant GV as GV (app mobile)
    participant FS as Firestore + Rules
    participant SV as SV (web/checkin)

    GV->>GV: hộp thoại mở phiên: tích/không tích "Kiểm tra IP mạng" (mặc định không)
    GV->>FS: create sessions/{id} (open, qrSecret, ipCheck, teacherIp nếu bật)
    GV->>GV: hiện QR = /?s={id}&t={qrSecret}&ic={0|1}, tự xoay qrSecret mỗi 60s

    SV->>SV: quét QR bằng camera, trình duyệt mở trang
    SV->>FS: đăng nhập Google (Firebase Auth); lần đầu tạo users/{uid} từ user_invites/{email}
    SV->>FS: đọc enrollments của mình (rollNumber) để lấy classCode, teacherMemberCode
    opt ic=1 (phiên kiểm tra IP)
        SV->>SV: lấy IP công khai (ipify)
    end
    SV->>FS: create attendance_records/{s}_{rollNumber} {qrToken, status: Present, checkinTime, ipAddress...}
    FS-->>SV: Rules đối chiếu: qrToken == sessions.qrSecret, phiên open, có ghi danh, IP, chưa có bản ghi
    FS-->>SV: OK → "Điểm danh thành công" / permission-denied → trang chẩn đoán lý do

    GV->>FS: đóng phiên: sessions.sessionStatus = closed + tạo Absent (AutoAbsent) cho SV chưa quét
```

URL trong QR có ba tham số: `s` (id phiên), `t` (mã bí mật hiện tại), `ic` (1 nếu phiên bật kiểm tra IP — chỉ để trang biết có cần lấy IP; Rules tự kiểm tra thật). SV **không đọc được** `sessions` nên không thể lấy `qrSecret` ngoài QR đang hiển thị.

## Rules quyết định gì khi SV tạo bản ghi

Điều kiện `studentCheckin()` trong [`firebase/firestore.rules`](../firebase/firestore.rules) — tất cả phải đúng:

| Điều kiện | Ý nghĩa |
|---|---|
| Người gọi có `role == 'user'` và `active` | Chỉ SV đang hoạt động. |
| `recordId == sessionId + '_' + rollNumber`, `rollNumber` = của chính SV | Không điểm danh hộ; id xác định → không trùng. |
| `sessions/{sessionId}.sessionStatus == 'open'` | Phiên đã đóng thì từ chối. |
| `qrToken == sessions.qrSecret` | Đúng mã QR hiện tại (mã cũ hết hiệu lực khi GV xoay). |
| `classCode`, `teacherMemberCode` khớp phiên; tồn tại `enrollments/{classCode}_{rollNumber}` | SV thuộc lớp. |
| `status == 'Present'`, `checkinTime == request.time`, `syncedToFap == false` | Không tự khai trạng thái/giờ. |
| `ipCheck == true` → `ipAddress == teacherIp` và `Match`; ngược lại `ipAddress == ''` và `Skipped` | Kiểm tra IP tùy chọn. |
| Chỉ `create`, tập khóa cố định (`hasOnly`) | Không sửa/xóa sau khi điểm danh, không thêm trường lạ. |

## Kiểm tra qua địa chỉ IP mạng (tùy chọn, mặc định tắt)

Khi GV bấm "Điểm danh", hộp thoại **Mở phiên điểm danh** có ô **"Kiểm tra IP mạng (tùy chọn)"**, mặc định không tích (Remote Config `ip_check_default`). Thiết lập riêng của từng phiên (`sessions.ipCheck`):

| | Tắt (mặc định) | Bật |
|---|---|---|
| App GV | Không lấy IP, không lưu `teacherIp`. | Lấy IP công khai (ipify), lưu `teacherIp`; không lấy được thì không mở phiên. |
| Trang SV | Không phụ thuộc dịch vụ lấy IP. | Lấy IP công khai rồi gửi kèm. |
| Rules | Chấp nhận SV ở mạng bất kỳ (vẫn kiểm tra QR, ghi danh, trùng). Ghi `Skipped`. | `ipAddress` phải bằng `teacherIp`, ghi `Match`. |

Giới hạn: đây là kiểm tra "cùng mạng Wi-Fi trường", không phải đo khoảng cách. NAT chung cho cả tòa nhà có thể làm hai lớp khác phòng trùng IP; VPN/proxy làm đổi IP. Xem [06](06-rui-ro-va-mo-rong.md).

## Chống điểm danh trùng

Bản ghi có id `{sessionId}_{rollNumber}`; SV chỉ được `create`. Lần quét thứ hai (kể cả đồng thời) bị Rules từ chối, trang đọc bản ghi của chính mình và hiện "Đã ghi nhận" thay vì báo lỗi.

## Thông báo lỗi cho sinh viên

Rules chỉ trả `permission-denied`. Trang `web/checkin` phân loại bằng cách đọc thêm những gì SV được phép đọc:

| Tình huống | Cách nhận biết | Thông báo |
|---|---|---|
| Đã điểm danh rồi | Đọc được `attendance_records/{s}_{roll}` của chính mình | "Đã ghi nhận" |
| Không thuộc lớp nào | Truy vấn `enrollments` của mình trả rỗng | `NOT_ENROLLED` |
| Còn lại, phiên bật kiểm tra IP | `ic=1` | `IP_MISMATCH` (mạng khác, hoặc QR hết hạn) |
| Còn lại | — | `SESSION_NOT_FOUND` (QR hết hạn / phiên đóng) |
| Email chưa được cấp quyền | Không có `user_invites/{email}` | `DOMAIN_NOT_ALLOWED` |
| Tài khoản GV/admin mở trang SV | `role != 'user'` | `WRONG_ROLE` |
| Mất mạng | lỗi khác `permission-denied` | `NETWORK_ERROR` + nút "Thử lại" |

## Đăng nhập một lần, các lần sau tự động

SV đăng nhập Google lần đầu; Firebase Auth lưu phiên trong trình duyệt. Các buổi sau, quét QR mới trong cùng trình duyệt → trang tự điểm danh ngay khi tải xong, không cần bấm gì — đúng tinh thần "đã đăng nhập thì tự điểm danh" của đề bài.

[→ 03 Dữ liệu & cấu trúc Firestore](03-du-lieu-firestore.md)
