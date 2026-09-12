[← Mục lục](README.md)

# 03 · Dữ liệu & cấu trúc Google Sheet

Một file Sheet, mỗi bảng nghiệp vụ là một tab riêng. **Backend là bên duy nhất ghi trực tiếp** — app không bao giờ mở Sheets API.

| Tab | Cột chính | Ghi chú |
|---|---|---|
| **Users** | `userId, email, fullName, role, code, active` | `role = GV \| SV`, suy ra từ domain/email khi đăng nhập lần đầu. |
| **Classes** | `classId, className, subjectCode, teacherId, room, schedule` | `schedule` ví dụ: "Thứ 3 · Tiết 4–6". |
| **Enrollment** | `classId, studentId` | Danh sách lớp — dùng để chặn SV quét nhầm lớp khác. |
| **Sessions** | `sessionId, classId, date, startTime, endTime, status, qrSecret, teacherIp` | `status = open \| closed \| expired`. `teacherIp` là IP công khai của GV lúc bấm điểm danh, dùng để đối chiếu mạng với SV. |
| **AttendanceLog** | `logId, sessionId, studentId, checkinTime, status, method, studentIp, ipMatch, syncedToFap` | `status = Present \| Late \| Absent \| ManualByGV`. `ipMatch = TRUE/FALSE` cho biết IP của SV có trùng `teacherIp` không. `syncedToFap` để job đồng bộ biết dòng nào chưa gửi. |

> **Absent** được backend tự sinh cuối buổi: mọi `studentId` có trong `Enrollment` của lớp nhưng không xuất hiện trong `AttendanceLog` của `sessionId` đó.

[→ 04 Kiến trúc App Giảng viên & Trang Web Sinh viên](04-kien-truc-app-va-web.md)
