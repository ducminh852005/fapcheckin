[← Mục lục](README.md)

# 02 · Luồng điểm danh bằng QR

Mã QR tự động xoay mỗi 60 giây trong khi phiên còn mở. "Gần lớp học" được xác nhận bằng địa chỉ IP mạng, không đụng tới GPS của máy.

## Sequence: Bắt đầu phiên → Quét → (Kiểm tra IP nếu bật) → Ghi nhận

```mermaid
sequenceDiagram
    participant GV as GV (app)
    participant BE as Backend (Apps Script)
    participant DB as Firestore
    participant SV as SV (web, Firebase Hosting)

    GV->>GV: hộp thoại mở phiên: tích/không tích "Kiểm tra IP mạng" (mặc định không tích)
    GV->>BE: POST startSession (ipCheck; teacherIp từ ipify chỉ khi ipCheck = true)
    BE->>DB: tạo attendanceSessions (qrSecret, open, ipCheck)
    BE-->>GV: sessionId, qrToken
    GV->>GV: hiện QR (qrToken, xoay 60s)

    SV->>SV: quét QR, mở trang check-in kèm ?token=
    SV->>SV: đăng nhập Google (lần đầu)
    SV->>BE: POST checkin (qrToken, chưa kèm IP)
    BE->>DB: tìm phiên theo qrSecret + open, kiểm tra enrollments
    alt phiên tắt kiểm tra IP (mặc định)
        BE->>DB: tạo attendanceRecords/{sessionId}_{rollNumber} (Skipped)
        BE-->>SV: kết quả (Present)
    else phiên bật kiểm tra IP
        BE-->>SV: lỗi IP_REQUIRED
        SV->>SV: lấy IP công khai (ipify)
        SV->>BE: POST checkin (qrToken, studentIp)
        BE->>BE: so sánh studentIp == teacherIp
        BE->>DB: tạo attendanceRecords/{sessionId}_{rollNumber} (Match)
        BE-->>SV: kết quả (Present) hoặc IP_MISMATCH
    end
```

> **Trạng thái hiện tại:** QR vẫn trỏ tới trang check-in do Apps Script phục vụ (`?page=checkin&token=…`); trang trên Firebase Hosting (`https://<project>.web.app/?token=…`) đã sẵn sàng nhưng chưa được dùng cho QR. Khi chuyển, sequence trên là luồng thực tế. Xem [deploy-firebase.md §6](deploy-firebase.md#6-chuyển-qr-của-sinh-viên-sang-hosting-chưa-làm).

## Kiểm tra qua địa chỉ IP mạng (tùy chọn, mặc định tắt)

Khi GV bấm "Điểm danh", hộp thoại **Mở phiên điểm danh** có ô tích **"Kiểm tra IP mạng (tùy chọn)"**, **mặc định không tích**. Đây là thiết lập riêng của từng phiên (`attendanceSessions.ipCheck`):

| | Ô tích **tắt** (mặc định) | Ô tích **bật** |
|---|---|---|
| App GV | Không lấy IP, không gửi `teacherIp`. | Gọi dịch vụ lấy IP công khai (ví dụ `api.ipify.org`), gửi kèm `teacherIp`; không lấy được thì báo lỗi và không mở phiên. |
| Trang SV | Gửi `checkin` không kèm IP, **không phụ thuộc** dịch vụ lấy IP. | Backend trả `IP_REQUIRED`, trang tự lấy IP công khai rồi gửi lại. |
| Backend | Chấp nhận SV ở bất kỳ mạng nào (vẫn kiểm tra QR, ghi danh, trùng). Ghi `networkVerificationResult = Skipped`. | So sánh hai chuỗi IP — khác nhau thì từ chối `IP_MISMATCH`. Ghi `Match`. |

Không cần bất kỳ quyền định vị nào từ trình duyệt hay thiết bị. Phiên đã mở trước khi có tùy chọn này (không có giá trị `ipCheck`) vẫn được kiểm tra IP như cũ. Nếu mở lại một phiên đang mở, phiên giữ nguyên thiết lập ban đầu; muốn đổi phải kết thúc phiên và mở phiên mới.

## Chống điểm danh trùng

Bản ghi điểm danh có document id `{sessionId}_{rollNumber}`. Nếu một SV quét cùng QR hai lần (kể cả đồng thời), lần ghi thứ hai bị Firestore từ chối và API trả `ALREADY_CHECKED_IN`; không có dòng trùng như khi ghi vào Sheet.

## Giới hạn cần biết

Khi bật, đây là kiểm tra "cùng mạng Wi-Fi trường", **không phải** đo khoảng cách vật lý chính xác theo mét như GPS. Nếu cả toà nhà dùng chung một IP công khai (NAT chung), hai lớp khác phòng vẫn có thể trùng IP. Đổi lại: không xin quyền vị trí, không lo GPS sai lệch trong nhà, và triển khai đơn giản hơn nhiều trong 2 tuần. Xem thêm [09 · Rủi ro & giới hạn](09-rui-ro-va-gioi-han.md).

## Đăng nhập một lần, các lần sau tự động

SV mở trang lần đầu (từ QR) vẫn phải đăng nhập Google 1 lần; trang lưu một token phiên ngắn hạn vào `localStorage` của trình duyệt đó. Các buổi sau, quét QR mới mở đúng trình duyệt đã đăng nhập → trang tự gửi `checkin` ngay khi tải xong, không cần bấm gì thêm — đúng tinh thần "đã đăng nhập thì tự điểm danh" của đề bài, chỉ đổi "app" thành "trình duyệt".

## Nếu mất mạng giữa lúc gửi checkin

Trang hiện nút "Thử lại" và thông báo rõ lý do (mất mạng, không phải sai lớp). QR giữ nguyên trong một phút để sinh viên có đủ thời gian quét và đăng nhập Google.

[→ 03 Dữ liệu & cấu trúc Firestore](03-du-lieu-firestore.md)
