# db-erd.mermaid — ghi chú

```text
FAP Check-in — ERD thiết kế lại (Google Sheet + Apps Script -> Firebase)

RULE SCHEDULE (A = AM sáng, P = PM chiều; thứ 2 = Mon ... thứ 7 = Sat)
  A1-A2 / P1-P2 : slot 1-2 trong buổi, thứ 2 + thứ 5
  A3-A4 / P3-P4 : slot 1-2 trong buổi, thứ 3 + thứ 6
  A5-A6 / P5-P6 : slot 1-2 trong buổi, thứ 4 + thứ 7
  Lẻ (A1,A3,A5,P1,P3,P5) = slot 1 của buổi; chẵn (A2,A4,A6,P2,P4,P6) = slot 2.
  1 ngày có 4 slot thường: A slot1 = slot 1, A slot2 = slot 2,
  P slot1 = slot 3, P slot2 = slot 4 (P đánh số nối tiếp sau A).
  Không có slot tối: chỉ giữ A và P (xóa E5/E6 và P7-P9). Lớp học bù dùng lại slot A/P vào ngày bất kỳ
  (CLASS_SCHEDULE.lessonType); thứ của slot chỉ áp dụng cho thời khóa biểu thường, không ép với học bù.
  Giờ chỉ lưu ở TIME_SLOT (4 dòng); SLOT (12 dòng) và SLOT_WEEKDAY (24 dòng) không lặp giờ.
  API/Cloud Function join SLOT -> TIME_SLOT để vẫn trả slotCode, period, startTime, endTime cho client cũ.

CLASS_SCHEDULE vs HỆ THỐNG SLOT (phương án A)
  Lịch thường = CLASS_SECTION.slotCode + SLOT_WEEKDAY. CLASS_SCHEDULE chỉ chứa buổi ngoài lịch (makeup/workshop/review).
  Đã bỏ CLASS_SCHEDULE.startTime/endTime: giờ lấy từ SLOT -> TIME_SLOT (getClasses không còn ghi đè giờ slot).
  Giữ teacherMemberCode (denormalized) để query theo GV trên Firestore; luôn phải bằng CLASS_SECTION.teacherMemberCode.
  Kiểm tra xung đột (ScheduleService.create): so theo timeSlotId cùng ngày (A1/A3/A5 cùng khung A-1), không so khoảng giờ.
  Nối buổi học bù với phiên điểm danh: ATTENDANCE_SESSION.scheduleId (nullable); buổi thường vẫn để trống.
  getSessions: ưu tiên ghép theo scheduleId, dữ liệu cũ chưa có scheduleId mới fallback theo ngày + slotCode.
  Chưa làm (để sau): sinh sẵn buổi thường thành hàng CLASS_SCHEDULE (phương án B); totalSessions vẫn 30 cố định.

DỌN SHEET KHI MIGRATE
  Tab Class_Schedule: bỏ cột startTime, endTime (ScheduleService.COLUMNS, dto, create, getClasses cần sửa theo).
  Tab Slot: xóa P7, P8, P9; bổ sung A3, A6 (đang thiếu); đổi giờ về HH:mm (hiện lẫn số serial và chuỗi).
  Code mặc định ScheduleService.slots() và TimetableOCRService.DEFAULT_SLOT_TIMES còn E5/E6 và giờ cũ 07:30-09:50 -> cập nhật.
  TeacherService.getClasses ghép nhãn 'Slot ' + slotCode (VD "Slot P1"); theo rule P1 hiển thị "Slot 3" -> dùng TIME_SLOT.daySlotNo.

FIRESTORE MAPPING (collection <- entity, docId)
  users <- USERS (memberCode) | subjects <- SUBJECT (subjectCode)
  timeSlots <- TIME_SLOT (timeSlotId) | slots <- SLOT (slotCode; weekdays = array field thay SLOT_WEEKDAY)
  classSections <- CLASS_SECTION (classCode) | enrollments <- ENROLLMENT ({classCode}_{rollNumber})
  classSchedules <- CLASS_SCHEDULE (scheduleId) | attendanceSessions <- ATTENDANCE_SESSION (sessionId)
  attendanceRecords <- ATTENDANCE_RECORD ({sessionId}_{rollNumber}: chặn trùng, thay LockService)
  Index gợi ý: attendanceRecords(sessionId), attendanceRecords(syncedToFap),
    attendanceSessions(classCode, sessionStatus), classSchedules(teacherMemberCode, scheduleDate),
    enrollments(classCode), users(email), attendanceSessions(qrSecret, sessionStatus)
  Firestore không enforce FK -> kiểm tra bằng Cloud Functions / security rules.
  Token đăng nhập (CacheService auth:*) và nonce -> thay bằng Firebase Auth (users.authUid).
```
